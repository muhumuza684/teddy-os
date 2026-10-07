import React, { useEffect, useRef, useState } from 'react';
import { dbAll, dbPut, dbDel } from '../utils/db';

const Row = ({ label, sub, children }) => (
  <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '10px 14px', borderBottom: '0.5px solid var(--border)' }}>
    <div><div style={{ fontSize: 13, color: 'var(--text-primary)' }}>{label}</div>{sub && <div style={{ fontSize: 11, color: 'var(--text-muted)', marginTop: 2 }}>{sub}</div>}</div>
    <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>{children}</div>
  </div>
);
const Toggle = ({ on, onChange }) => (
  <button onClick={() => onChange(!on)} style={{ width: 36, height: 20, borderRadius: 10, background: on ? 'var(--accent)' : 'var(--border)', border: 'none', cursor: 'pointer', position: 'relative' }}>
    <div style={{ position: 'absolute', top: 3, left: on ? 19 : 3, width: 14, height: 14, borderRadius: '50%', background: 'white' }} />
  </button>
);

const INPUT_DEFAULTS = { keyDelay: 500, keyRate: 30, ptrAccel: 2, ptrThreshold: 4 };
const smallBtn = { fontSize: 11, padding: '4px 10px', borderRadius: 6, border: '0.5px solid var(--border)', background: 'transparent', color: 'var(--text-secondary)', cursor: 'pointer' };

export default function Settings({ settings, onUpdate, currentUser, onLock, onLogout }) {
  const [docCount, setDocCount] = useState(null);
  const backupInput = useRef(null);
  const api = window.electronAPI;
  const [fp, setFp] = useState(null);
  const [fpBusy, setFpBusy] = useState(false);
  const [input, setInput] = useState(() => { try { return { ...INPUT_DEFAULTS, ...JSON.parse(localStorage.getItem('teddy:input') || '{}') }; } catch { return INPUT_DEFAULTS; } });
  const [inputMsg, setInputMsg] = useState('');
  useEffect(() => { api?.fprintdList?.().then(setFp).catch(() => setFp({ available: false, reason: 'Not available' })); }, []);
  async function enrollFinger() {
    setFpBusy(true);
    const r = await api.fprintdEnroll();
    setFpBusy(false);
    window.alert(r.ok ? 'Fingerprint enrolled.' : `Could not enroll: ${r.reason || 'unknown error'}`);
  }
  async function applyInput() {
    localStorage.setItem('teddy:input', JSON.stringify(input));
    const a = await api?.setKeyRepeat?.(input.keyDelay, input.keyRate);
    const b = await api?.setPointerAccel?.(input.ptrAccel, input.ptrThreshold);
    setInputMsg(a?.ok && b?.ok ? 'Saved and applied. Re-applied automatically at every login.' : 'Saved. It will apply when running inside Teddy OS.');
  }
  async function countDocs() { setDocCount((await dbAll('docs')).length); }
  async function clearDocs() { if (!window.confirm('Delete ALL documents?')) return; const all = await dbAll('docs'); for (const d of all) await dbDel('docs', d.name); setDocCount(0); }
  async function exportBackup() {
    const docs = await dbAll('docs');
    const payload = { app: 'Teddy OS', version: '2.1', created: new Date().toISOString(), documents: docs };
    const blob = new Blob([JSON.stringify(payload, null, 2)], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a'); a.href = url; a.download = `teddy-os-backup-${new Date().toISOString().slice(0, 10)}.json`; a.click();
    URL.revokeObjectURL(url); setDocCount(docs.length);
  }
  async function importBackup(event) {
    const file = event.target.files?.[0]; if (!file) return;
    try {
      const payload = JSON.parse(await file.text());
      if (payload?.app !== 'Teddy OS' || !Array.isArray(payload.documents)) throw new Error('Invalid Teddy backup');
      if (!window.confirm(`Restore ${payload.documents.length} documents? Existing documents with the same names will be replaced.`)) return;
      for (const doc of payload.documents) if (doc?.name && typeof doc.content === 'string') await dbDel('docs', doc.name).catch(() => {}), await dbPut('docs', doc);
      setDocCount((await dbAll('docs')).length);
    } catch { window.alert('Teddy could not read that backup file.'); }
    event.target.value = '';
  }

  const Section = ({ title, children }) => (
    <div style={{ border: '0.5px solid var(--border)', borderRadius: 10, overflow: 'hidden', marginBottom: 12 }}>
      <div style={{ padding: '9px 14px', background: 'var(--bg-raised)', fontSize: 11, fontWeight: 600, color: 'var(--text-muted)', textTransform: 'uppercase' }}>{title}</div>
      {children}
    </div>
  );

  return (
    <div style={{ flex: 1, overflowY: 'auto', padding: 16 }}>
      <div style={{ fontSize: 11, color: 'var(--text-muted)', marginBottom: 14 }}>Teddy OS v2.1 · Built by Bryt Ma Tech UG</div>
      <Section title="Account">
        <Row label={currentUser?.username || 'User'} sub={currentUser?.role === 'admin' ? 'Administrator' : 'Standard user'}>
          <span style={{ fontSize: 20 }}>{currentUser?.avatar}</span>
        </Row>
        <Row label="Lock screen"><button onClick={onLock} style={{ fontSize: 11, padding: '4px 10px', borderRadius: 6, border: '0.5px solid var(--border)', background: 'transparent', color: 'var(--text-secondary)', cursor: 'pointer' }}>Lock now</button></Row>
        <Row label="Sign out"><button onClick={onLogout} style={{ fontSize: 11, padding: '4px 10px', borderRadius: 6, border: '0.5px solid rgba(248,113,113,0.3)', background: 'transparent', color: 'var(--red)', cursor: 'pointer' }}>Sign out</button></Row>
      </Section>
      <Section title="Editor">
        <Row label="Spell check"><Toggle on={settings.spellCheck} onChange={v => onUpdate('spellCheck', v)} /></Row>
        <Row label="Autosave"><Toggle on={settings.autosave} onChange={v => onUpdate('autosave', v)} /></Row>
      </Section>
      <Section title="Teddy Guardian · Storage">
        <Row label="Saved documents" sub={docCount !== null ? `${docCount} document${docCount !== 1 ? 's' : ''}` : 'Click to count'}>
          <button onClick={countDocs} style={{ fontSize: 11, padding: '4px 10px', borderRadius: 6, border: '0.5px solid var(--border)', background: 'transparent', color: 'var(--text-secondary)', cursor: 'pointer' }}>Count</button>
          <button onClick={exportBackup} style={{ fontSize: 11, padding: '4px 10px', borderRadius: 6, border: '0.5px solid var(--border)', background: 'transparent', color: 'var(--text-secondary)', cursor: 'pointer' }}>Backup</button>
          <button onClick={() => backupInput.current?.click()} style={{ fontSize: 11, padding: '4px 10px', borderRadius: 6, border: '0.5px solid var(--border)', background: 'transparent', color: 'var(--text-secondary)', cursor: 'pointer' }}>Restore</button>
          <input ref={backupInput} type="file" accept="application/json,.json" onChange={importBackup} style={{ display: 'none' }} />
          <button onClick={clearDocs} style={{ fontSize: 11, padding: '4px 10px', borderRadius: 6, border: '0.5px solid rgba(248,113,113,0.3)', background: 'transparent', color: 'var(--red)', cursor: 'pointer' }}>Clear all</button>
        </Row>
      </Section>
      <Section title="Security">
        <Row label="Fingerprint login" sub={fp === null ? 'Checking...' : fp.available ? 'Reader found' : fp.reason}>
          <button disabled={!fp?.available || fpBusy} onClick={enrollFinger} style={{ ...smallBtn, opacity: fp?.available ? 1 : 0.4 }}>{fpBusy ? 'Follow the reader...' : 'Enroll finger'}</button>
        </Row>
      </Section>
      <Section title="Devices">
        <Row label="Key repeat delay" sub={`${input.keyDelay} ms`}><input type="range" min="150" max="1000" step="50" value={input.keyDelay} onChange={e => setInput({ ...input, keyDelay: +e.target.value })} /></Row>
        <Row label="Key repeat rate" sub={`${input.keyRate} per second`}><input type="range" min="5" max="60" value={input.keyRate} onChange={e => setInput({ ...input, keyRate: +e.target.value })} /></Row>
        <Row label="Pointer acceleration" sub={`${input.ptrAccel}x`}><input type="range" min="1" max="10" value={input.ptrAccel} onChange={e => setInput({ ...input, ptrAccel: +e.target.value })} /></Row>
        <Row label="Apply" sub={inputMsg || 'Applies to the keyboard and mouse now'}><button onClick={applyInput} style={smallBtn}>Save & apply</button></Row>
      </Section>
      <Section title="About">
        <Row label="Teddy OS" sub="Version 2.1.0"><span style={{ fontSize: 11 }}>🐻</span></Row>
        <Row label="Developer" sub="Built by Bryt Ma Tech UG"><span style={{ fontSize: 11, color: 'var(--accent)' }}>Uganda 🇺🇬</span></Row>
      </Section>
    </div>
  );
}
