// Teddy OS system IPC: Software Center, fingerprint, keyboard/mouse.
// Registered from electron/main.js; exposed to the UI through electron/preload.js (window.electronAPI).
// Everything here is Linux-only: on Windows/macOS dev machines the handlers answer "unavailable" instead of failing.
const { spawn, execFile } = require('child_process');

const CATALOG = {
  wine:    { pkg: 'wine',     check: 'wine' },
  docker:  { pkg: 'docker.io', check: 'docker' },
  fprintd: { pkg: 'fprintd libpam-fprintd', check: 'fprintd-list' },
  gimp:    { pkg: 'gimp',     check: 'gimp' },
  vlc:     { pkg: 'vlc',      check: 'vlc' },
  codium:  { pkg: 'codium',   check: 'codium' },
};

function checkCommand(cmd) {
  return new Promise((resolve) => {
    execFile('sh', ['-c', `command -v ${cmd}`], (err, out) => resolve(!err && !!out.trim()));
  });
}
const run = (cmd, args) => new Promise((resolve) =>
  execFile(cmd, args, { timeout: 15000 }, (err, stdout, stderr) =>
    resolve({ ok: !err, stdout: stdout || '', stderr: stderr || (err ? err.message : '') })));

const IS_LINUX = () => process.platform === 'linux';

function register(ipcMain) {
  ipcMain.handle('software:check', async (_e, id) => {
    if (!IS_LINUX()) return { id, installed: false, error: 'Software Center needs Teddy OS (Linux)' };
    const item = CATALOG[id];
    return item ? { id, installed: await checkCommand(item.check) } : { id, installed: false, error: 'unknown package' };
  });

  // Streams apt output back to the renderer on 'software:progress'.
  ipcMain.handle('software:install', (e, id) => new Promise((resolve) => {
    const item = CATALOG[id];
    if (!item) return resolve({ ok: false, error: 'unknown package' });
    if (!IS_LINUX()) return resolve({ ok: false, error: 'Installing software needs Teddy OS (Linux)' });
    const p = spawn('pkexec', ['apt-get', 'install', '-y', ...item.pkg.split(' ')],
      { env: { ...process.env, DEBIAN_FRONTEND: 'noninteractive' } });
    const send = (d) => e.sender.send('software:progress', { id, line: d.toString() });
    p.stdout.on('data', send); p.stderr.on('data', send);
    p.on('error', (err) => resolve({ ok: false, error: err.message }));
    p.on('close', (code) => resolve({ ok: code === 0, code }));
  }));

  ipcMain.handle('fprintd:list', async () => {
    if (!IS_LINUX()) return { available: false, reason: 'Fingerprint login needs Teddy OS (Linux)' };
    if (!(await checkCommand('fprintd-list'))) return { available: false, reason: 'fprintd is not installed' };
    const r = await run('fprintd-list', [process.env.USER || '']);
    if (!r.ok || /No devices/i.test(r.stdout + r.stderr)) return { available: false, reason: 'No fingerprint reader found' };
    return { available: true, output: r.stdout };
  });
  ipcMain.handle('fprintd:enroll', async (_e, finger = 'right-index-finger') => {
    if (!IS_LINUX()) return { ok: false, reason: 'Fingerprint login needs Teddy OS (Linux)' };
    if (!(await checkCommand('fprintd-enroll'))) return { ok: false, reason: 'fprintd is not installed' };
    if (!/^[a-z-]+$/.test(finger)) return { ok: false, reason: 'bad finger name' };
    const r = await run('fprintd-enroll', ['-f', finger]);
    return { ok: r.ok, output: r.stdout, reason: r.ok ? undefined : r.stderr };
  });

  ipcMain.handle('input:setKeyRepeat', async (_e, delay, rate) => {
    if (!IS_LINUX()) return { ok: false, stderr: 'Needs Teddy OS (Linux)' };
    const d = Math.max(100, Math.min(2000, Number(delay) | 0)), r = Math.max(2, Math.min(100, Number(rate) | 0));
    return run('xset', ['r', 'rate', String(d), String(r)]);
  });
  ipcMain.handle('input:setPointerAccel', async (_e, accel, threshold) => {
    if (!IS_LINUX()) return { ok: false, stderr: 'Needs Teddy OS (Linux)' };
    const a = Math.max(1, Math.min(10, Number(accel) | 0)), t = Math.max(1, Math.min(20, Number(threshold) | 0));
    return run('xset', ['m', String(a), String(t)]);
  });
}
module.exports = { register, checkCommand, CATALOG };
