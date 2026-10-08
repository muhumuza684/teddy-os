import React, { useEffect, useState } from 'react';

const APPS = [
  { id: 'wine', name: 'Wine', desc: 'Run Windows programs' },
  { id: 'docker', name: 'Docker', desc: 'Containers' },
  { id: 'fprintd', name: 'Fingerprint (fprintd)', desc: 'Fingerprint login support' },
  { id: 'gimp', name: 'GIMP', desc: 'Image editor' },
  { id: 'vlc', name: 'VLC', desc: 'Media player' },
  { id: 'codium', name: 'Codium', desc: 'Code editor' },
];

export default function SoftwareCenter() {
  const sys = window.electronAPI?.softwareCheck ? window.electronAPI : null;
  const [status, setStatus] = useState({});
  const [busy, setBusy] = useState(null);
  const [log, setLog] = useState('');

  const refresh = async () => {
    if (!sys) return;
    const out = {};
    for (const a of APPS) out[a.id] = (await sys.softwareCheck(a.id)).installed;
    setStatus(out);
  };
  useEffect(() => { refresh(); }, []);
  useEffect(() => sys?.onSoftwareProgress?.(({ line }) => setLog((l) => (l + line).slice(-6000))), []);

  const install = async (id) => {
    setBusy(id); setLog('');
    const r = await sys.softwareInstall(id);
    if (!r.ok) setLog((l) => l + `\nInstall failed${r.error ? ': ' + r.error : ` (exit ${r.code})`}\n`);
    setBusy(null); refresh();
  };

  if (!sys) return <div style={{ padding: 16, color: 'var(--text-primary)' }}>Software Center needs the Teddy OS shell (system bridge not found).</div>;
  return (
    <div style={{ padding: 16, color: 'var(--text-primary)', height: '100%', overflow: 'auto' }}>
      <h2 style={{ marginTop: 0 }}>Software Center</h2>
      {APPS.map((a) => (
        <div key={a.id} style={{ display: 'flex', alignItems: 'center', padding: '8px 0', borderBottom: '1px solid var(--border)' }}>
          <div style={{ flex: 1 }}><b>{a.name}</b><div style={{ fontSize: 12, color: 'var(--text-muted)' }}>{a.desc}</div></div>
          {status[a.id] === undefined ? <span>…</span>
            : status[a.id] ? <span style={{ color: 'var(--green, #4ade80)' }}>Installed</span>
            : <button disabled={!!busy} onClick={() => install(a.id)}>{busy === a.id ? 'Installing…' : 'Install'}</button>}
        </div>
      ))}
      {log && <pre style={{ marginTop: 12, padding: 8, background: 'var(--bg-raised)', fontSize: 11, maxHeight: 200, overflow: 'auto' }}>{log}</pre>}
    </div>
  );
}
