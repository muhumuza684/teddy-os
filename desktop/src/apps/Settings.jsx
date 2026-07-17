import React, { useState } from 'react';
import { dbAll, dbDel } from '../utils/db';

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

export default function Settings({ settings, onUpdate, currentUser, onLock, onLogout }) {
  const [docCount, setDocCount] = useState(null);
  async function countDocs() { setDocCount((await dbAll('docs')).length); }
  async function clearDocs() { if (!window.confirm('Delete ALL documents?')) return; const all = await dbAll('docs'); for (const d of all) await dbDel('docs', d.name); setDocCount(0); }

  const Section = ({ title, children }) => (
    <div style={{ border: '0.5px solid var(--border)', borderRadius: 10, overflow: 'hidden', marginBottom: 12 }}>
      <div style={{ padding: '9px 14px', background: 'var(--bg-raised)', fontSize: 11, fontWeight: 600, color: 'var(--text-muted)', textTransform: 'uppercase' }}>{title}</div>
      {children}
    </div>
  );

  return (
    <div style={{ flex: 1, overflowY: 'auto', padding: 16 }}>
      <div style={{ fontSize: 11, color: 'var(--text-muted)', marginBottom: 14 }}>Teddy OS v1.0 · Built by Bryt Ma Tech Uganda</div>
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
      <Section title="Storage">
        <Row label="Saved documents" sub={docCount !== null ? `${docCount} document${docCount !== 1 ? 's' : ''}` : 'Click to count'}>
          <button onClick={countDocs} style={{ fontSize: 11, padding: '4px 10px', borderRadius: 6, border: '0.5px solid var(--border)', background: 'transparent', color: 'var(--text-secondary)', cursor: 'pointer' }}>Count</button>
          <button onClick={clearDocs} style={{ fontSize: 11, padding: '4px 10px', borderRadius: 6, border: '0.5px solid rgba(248,113,113,0.3)', background: 'transparent', color: 'var(--red)', cursor: 'pointer' }}>Clear all</button>
        </Row>
      </Section>
      <Section title="About">
        <Row label="Teddy OS" sub="Version 1.0.0"><span style={{ fontSize: 11 }}>🐻</span></Row>
        <Row label="Developer" sub="Bryt Ma Tech Uganda"><span style={{ fontSize: 11, color: 'var(--accent)' }}>Uganda 🇺🇬</span></Row>
      </Section>
    </div>
  );
}
