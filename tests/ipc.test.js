import { describe, it, expect } from 'vitest';
import { createRequire } from 'module';
import fs from 'fs';
import path from 'path';
const require = createRequire(import.meta.url);
// Git on Windows does not keep the executable bit, so set it here instead of relying on it.
for (const f of fs.readdirSync('fakebin')) fs.chmodSync(path.join('fakebin', f), 0o755);
const ipc = require('./electron/system-ipc.cjs');
const handlers = {}; ipc.register({ handle: (n, f) => { handlers[n] = f; } });
const call = (n, ...a) => handlers[n]({ sender: { send: (c, d) => (call.sent ||= []).push([c, d]) } }, ...a);

describe('system-ipc', () => {
  it('registers all 7 channels', () => {
    ['software:check','software:install','fprintd:list','fprintd:enroll','input:setKeyRepeat','input:setPointerAccel']
      .forEach((c) => expect(typeof handlers[c]).toBe('function'));
  });
  it('catalog has the 6 apps', () => expect(Object.keys(ipc.CATALOG).sort()).toEqual(['codium','docker','fprintd','gimp','vlc','wine']));
  it('checkCommand true for sh, false for nonsense', async () => {
    expect(await ipc.checkCommand('sh')).toBe(true);
    expect(await ipc.checkCommand('definitely-not-a-cmd-xyz')).toBe(false);
  });
  it('software:check wine -> not installed (real round trip)', async () => {
    expect(await call('software:check', 'wine')).toEqual({ id: 'wine', installed: false });
  });
  it('software:check unknown id rejected', async () => {
    expect((await call('software:check', 'rm -rf /')).error).toBeTruthy();
  });
  it('software:install unknown id rejected (no shell injection)', async () => {
    expect((await call('software:install', 'x; reboot')).ok).toBe(false);
  });
  it('software:install streams output and reports success/failure', async () => {
    process.env.PATH = process.cwd() + '/fakebin:' + process.env.PATH;
    call.sent = []; const r = await call('software:install', 'vlc');
    expect(r.ok).toBe(true);
    const text = call.sent.map((s) => s[1].line).join('');
    expect(text).toMatch(/FAKE-PKEXEC apt-get install -y vlc/);
    expect(text).toMatch(/Setting up pkg/);
    expect(call.sent[0][0]).toBe('software:progress');
    process.env.FAKE_RC = '100';
    const bad = await call('software:install', 'vlc'); expect(bad.ok).toBe(false); expect(bad.code).toBe(100);
    delete process.env.FAKE_RC;
    call.sent = []; await call('software:install', 'fprintd');
    expect(call.sent.map((s) => s[1].line).join('')).toMatch(/fprintd libpam-fprintd/);
  });
  it('fprintd:list reports unavailable with no reader/daemon', async () => {
    const r = await call('fprintd:list'); expect(r.available).toBe(false); expect(r.reason).toBeTruthy();
  });
  it('fprintd:enroll reports unavailable / rejects bad finger', async () => {
    expect((await call('fprintd:enroll')).ok).toBe(false);
    expect((await call('fprintd:enroll', 'x; rm -rf /')).ok).toBe(false);
  });
  it('input:setKeyRepeat / setPointerAccel: real xset accepts the command (Xvfb cannot store the values)', async () => {
    if (!process.env.DISPLAY) return; // run under xvfb-run
    const path = process.env.PATH; process.env.PATH = path.split(':').filter((p) => !p.endsWith('fakebin')).join(':');
    expect((await call('input:setKeyRepeat', 300, 40)).ok).toBe(true);
    expect((await call('input:setPointerAccel', 3, 4)).ok).toBe(true);
    process.env.PATH = path;
  });
  it('xset gets the exact arguments, clamped to safe ranges', async () => {
    const fs = require('fs'); process.env.XSET_LOG = process.cwd() + '/xset.log'; fs.writeFileSync(process.env.XSET_LOG, '');
    await call('input:setKeyRepeat', 300, 40); await call('input:setKeyRepeat', 1, 9999);
    await call('input:setPointerAccel', 3, 4); await call('input:setPointerAccel', 9999, -5);
    await call('input:setKeyRepeat', 'x; reboot', 'y');
    expect(fs.readFileSync(process.env.XSET_LOG, 'utf8').trim().split('\n')).toEqual([
      'r rate 300 40', 'r rate 100 100', 'm 3 4', 'm 10 1', 'r rate 100 2']);
  });
});
