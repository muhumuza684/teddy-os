import React, { useState, useEffect } from 'react';
import { dbAll, dbDel } from '../utils/db';

export default function FileManager({ onOpenDoc }) {
  const [docs, setDocs] = useState([]);
  const [search, setSearch] = useState('');

  useEffect(() => { loadDocs(); }, []);
  async function loadDocs() { const all = await dbAll('docs'); setDocs(all.sort((a, b) => b.updated - a.updated)); }
  async function deleteDoc(name, e) { e.stopPropagation(); if (!window.confirm(`Delete "${name}"?`)) return; await dbDel('docs', name); loadDocs(); }

  const filtered = docs.filter(d => d.name.toLowerCase().includes(search.toLowerCase()));

  return (
    <div style={{ display: 'flex', height: '100%' }}>
      <div style={{ width: 140, borderRight: '0.5px solid var(--border)', padding: 10, background: 'var(--bg-raised)', flexShrink: 0 }}>
        {[['ti-home','Home'],['ti-file-text','Documents'],['ti-star','Starred'],['ti-trash','Trash']].map(([ic, label]) => (
          <div key={label} style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '6px 8px', borderRadius: 6, cursor: 'pointer', fontSize: 12, color: 'var(--text-secondary)' }}>
            <i className={`ti ${ic}`} style={{ fontSize: 14 }} /> {label}
          </div>
        ))}
        <div style={{ marginTop: 14, fontSize: 10, color: 'var(--text-muted)', padding: '0 8px' }}>{docs.length} document{docs.length !== 1 ? 's' : ''}</div>
      </div>
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', overflow: 'hidden' }}>
        <div style={{ padding: '8px 12px', borderBottom: '0.5px solid var(--border)', background: 'var(--bg-raised)' }}>
          <input value={search} onChange={e => setSearch(e.target.value)} placeholder="Search documents..." style={{ width: '100%', fontSize: 12, padding: '5px 9px', borderRadius: 6, border: '0.5px solid var(--border)', background: 'var(--bg-base)', color: 'var(--text-primary)', outline: 'none' }} />
        </div>
        <div style={{ flex: 1, overflowY: 'auto', padding: 14 }}>
          {filtered.length === 0 && <div style={{ textAlign: 'center', color: 'var(--text-muted)', fontSize: 13, marginTop: 40 }}>No documents yet. Create one in the Editor.</div>}
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(110px, 1fr))', gap: 10 }}>
            {filtered.map(doc => (
              <div key={doc.name} onDoubleClick={() => onOpenDoc(doc.name)} style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6, padding: '12px 8px', borderRadius: 9, cursor: 'pointer', textAlign: 'center', position: 'relative' }}
                onMouseEnter={e => e.currentTarget.style.background = 'var(--bg-hover)'} onMouseLeave={e => e.currentTarget.style.background = 'transparent'}>
                <i className="ti ti-file-text" style={{ fontSize: 36, color: '#378add' }} />
                <span style={{ fontSize: 11, color: 'var(--text-secondary)' }}>{doc.name}</span>
                <button onClick={(e) => deleteDoc(doc.name, e)} style={{ position: 'absolute', top: 4, right: 4, background: 'none', border: 'none', color: 'var(--text-muted)', cursor: 'pointer', fontSize: 13 }}>×</button>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
