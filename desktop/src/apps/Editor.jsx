import React, { useRef, useState, useEffect, useCallback } from 'react';
import { dbGet, dbPut, dbAll, dbDel } from '../utils/db';

const BTN = ({ onClick, title, children }) => (
  <button onClick={onClick} title={title} style={{ padding: '3px 7px', borderRadius: 5, cursor: 'pointer', fontSize: 12, fontWeight: 500, border: '0.5px solid transparent', color: 'var(--text-secondary)', background: 'transparent', lineHeight: 1.3 }}
    onMouseEnter={e => { e.target.style.background = 'var(--bg-base)'; e.target.style.color = 'var(--text-primary)'; }}
    onMouseLeave={e => { e.target.style.background = 'transparent'; e.target.style.color = 'var(--text-secondary)'; }}
  >{children}</button>
);
const SEP = () => <div style={{ width: 1, height: 18, background: 'var(--border)', margin: '0 3px', flexShrink: 0 }} />;
const FSEL = ({ onChange, children, title }) => (
  <select onChange={onChange} title={title} style={{ fontSize: 11, padding: '3px 4px', borderRadius: 5, border: '0.5px solid var(--border)', background: 'var(--bg-base)', color: 'var(--text-primary)', cursor: 'pointer' }}>{children}</select>
);

export default function Editor() {
  const editorRef = useRef(null);
  const [docName, setDocName] = useState('Untitled Document');
  const [docs, setDocs] = useState([]);
  const [words, setWords] = useState(0);
  const [chars, setChars] = useState(0);
  const [saved, setSaved] = useState(false);
  const [ctxMenu, setCtxMenu] = useState(null);
  const savedSelRef = useRef(null);

  useEffect(() => {
    loadAllDocs();
    loadDoc('Untitled Document');
    const interval = setInterval(() => saveDoc(true), 30000);
    return () => clearInterval(interval);
  }, []);

  async function loadAllDocs() { setDocs(await dbAll('docs')); }

  async function loadDoc(name) {
    const doc = await dbGet('docs', name);
    if (doc && editorRef.current) { editorRef.current.innerHTML = doc.content; setDocName(name); updateStatus(); }
    else if (editorRef.current) {
      editorRef.current.innerHTML = `<h1>Welcome to Teddy OS</h1><p>Built by <strong>Bryt Ma Tech Uganda</strong>.</p><p>Start typing your document here...</p>`;
      updateStatus();
    }
  }

  async function saveDoc(silent = false) {
    if (!editorRef.current) return;
    await dbPut('docs', { name: docName, content: editorRef.current.innerHTML, updated: Date.now() });
    if (!silent) { setSaved(true); setTimeout(() => setSaved(false), 2000); }
    loadAllDocs();
  }

  async function newDoc() {
    const name = prompt('Document name:', 'New Document');
    if (!name) return;
    await saveDoc(true);
    setDocName(name);
    if (editorRef.current) editorRef.current.innerHTML = `<h1>${name}</h1><p></p>`;
    updateStatus();
  }

  async function deleteDoc(name, e) {
    e.stopPropagation();
    if (!window.confirm(`Delete "${name}"?`)) return;
    await dbDel('docs', name);
    if (name === docName) { setDocName('Untitled Document'); if (editorRef.current) editorRef.current.innerHTML = '<h1>Untitled Document</h1><p></p>'; }
    loadAllDocs();
  }

  function updateStatus() {
    const text = editorRef.current?.innerText || '';
    setWords(text.trim() ? text.trim().split(/\s+/).length : 0);
    setChars(text.length);
  }

  function fmt(cmd, val = null) { editorRef.current?.focus(); document.execCommand(cmd, false, val); updateStatus(); }

  function exportPDF() {
    const content = editorRef.current?.innerHTML || '';
    const w = window.open('', '_blank');
    if (!w) return;
    w.document.write(`<!DOCTYPE html><html><head><title>${docName}</title><meta charset="utf-8"><style>body{font-family:Georgia,serif;max-width:800px;margin:40px auto;padding:0 32px;line-height:1.8;font-size:15px;color:#1a1a1a}h1{font-size:26px;font-weight:600;margin-bottom:14px}h2{font-size:20px;font-weight:600;margin-bottom:10px}p{margin-bottom:8px}.footer{margin-top:48px;font-size:11px;color:#888;text-align:center;border-top:1px solid #eee;padding-top:12px}</style></head><body>${content}<div class="footer">Teddy OS · Built by Bryt Ma Tech Uganda · ${new Date().toLocaleDateString()}</div></body></html>`);
    w.document.close();
    setTimeout(() => { w.focus(); w.print(); }, 400);
  }

  const handleCtx = useCallback((e) => {
    const sel = window.getSelection();
    if (sel && sel.toString().trim().length > 0) { e.preventDefault(); savedSelRef.current = sel.getRangeAt(0).cloneRange(); setCtxMenu({ x: e.clientX, y: e.clientY }); }
  }, []);

  async function ctxAI(action) {
    setCtxMenu(null);
    const range = savedSelRef.current;
    if (!range) return;
    const selText = range.toString();
    const prompts = {
      rewrite: `Rewrite this text cleanly and professionally. Return ONLY the rewritten text:\n\n${selText}`,
      improve: `Improve the writing quality. Return ONLY the improved text:\n\n${selText}`,
      shorter: `Make this shorter and more concise. Return ONLY the result:\n\n${selText}`,
      expand:  `Expand this with more detail. Return ONLY the expanded text:\n\n${selText}`,
      fix:     `Fix grammar and spelling. Return ONLY the corrected text:\n\n${selText}`,
    };
    try {
      const res = await fetch('https://api.anthropic.com/v1/messages', {
        method: 'POST', headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ model: 'claude-sonnet-4-6', max_tokens: 800, messages: [{ role: 'user', content: prompts[action] }] }),
      });
      const data = await res.json();
      const reply = data.content?.[0]?.text || 'Error';
      const sel = window.getSelection();
      sel.removeAllRanges(); sel.addRange(range);
      document.execCommand('insertText', false, reply);
      updateStatus();
    } catch {}
  }

  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100%', position: 'relative' }} onClick={() => setCtxMenu(null)}>
      <div style={{ display: 'flex', gap: 2, padding: '5px 8px', borderBottom: '0.5px solid var(--border)', flexWrap: 'wrap', alignItems: 'center', background: 'var(--bg-raised)', flexShrink: 0 }}>
        <FSEL onChange={e => { editorRef.current.style.fontFamily = e.target.value; }} title="Font">
          <option value="-apple-system,sans-serif">Sans</option><option value="Georgia,serif">Georgia</option><option value="'Courier New',monospace">Mono</option>
        </FSEL>
        <FSEL onChange={e => fmt('fontSize', e.target.value)} title="Size">
          <option value="2">Sm</option><option value="3">Md</option><option value="4">Lg</option><option value="5">XL</option>
        </FSEL>
        <SEP />
        <BTN onClick={() => fmt('bold')} title="Bold"><b>B</b></BTN>
        <BTN onClick={() => fmt('italic')} title="Italic"><i>I</i></BTN>
        <BTN onClick={() => fmt('underline')} title="Underline"><u>U</u></BTN>
        <SEP />
        <BTN onClick={() => fmt('formatBlock', 'h1')} title="H1"><b>H1</b></BTN>
        <BTN onClick={() => fmt('formatBlock', 'h2')} title="H2"><b>H2</b></BTN>
        <BTN onClick={() => fmt('formatBlock', 'p')} title="Paragraph">¶</BTN>
        <SEP />
        <BTN onClick={() => fmt('insertUnorderedList')} title="Bullets"><i className="ti ti-list" /></BTN>
        <BTN onClick={() => fmt('insertOrderedList')} title="Numbered"><i className="ti ti-list-numbers" /></BTN>
        <SEP />
        <BTN onClick={() => fmt('justifyLeft')} title="Left"><i className="ti ti-align-left" /></BTN>
        <BTN onClick={() => fmt('justifyCenter')} title="Center"><i className="ti ti-align-center" /></BTN>
        <SEP />
        <BTN onClick={newDoc} title="New"><i className="ti ti-file-plus" /></BTN>
        <BTN onClick={() => saveDoc(false)} title="Save">{saved ? '✓' : <i className="ti ti-device-floppy" />}</BTN>
        <BTN onClick={exportPDF} title="Export PDF"><i className="ti ti-file-type-pdf" /></BTN>
      </div>
      <div style={{ display: 'flex', gap: 4, padding: '4px 8px', background: 'var(--bg-base)', borderBottom: '0.5px solid var(--border)', flexShrink: 0, overflowX: 'auto' }}>
        {docs.map(d => (
          <div key={d.name} onClick={() => loadDoc(d.name)} style={{ display: 'flex', alignItems: 'center', gap: 4, padding: '2px 8px', borderRadius: 5, background: d.name === docName ? 'var(--accent-dim)' : 'transparent', cursor: 'pointer', fontSize: 11, color: d.name === docName ? 'var(--accent)' : 'var(--text-muted)', whiteSpace: 'nowrap' }}>
            {d.name}<span onClick={(e) => deleteDoc(d.name, e)} style={{ fontSize: 13, marginLeft: 2 }}>×</span>
          </div>
        ))}
      </div>
      <div ref={editorRef} contentEditable spellCheck className="editor-content" onInput={updateStatus} onContextMenu={handleCtx}
        onKeyDown={(e) => { if (e.ctrlKey && e.key === 's') { e.preventDefault(); saveDoc(false); } }}
        style={{ flex: 1, padding: '20px 28px', overflowY: 'auto', outline: 'none', lineHeight: 1.8, fontSize: 15, color: 'var(--text-primary)' }} />
      <div style={{ height: 24, padding: '0 12px', borderTop: '0.5px solid var(--border)', display: 'flex', alignItems: 'center', gap: 16, background: 'var(--bg-raised)', flexShrink: 0 }}>
        <span style={{ fontSize: 10, color: 'var(--text-muted)' }}>Words: {words}</span>
        <span style={{ fontSize: 10, color: 'var(--text-muted)' }}>Chars: {chars}</span>
        <span style={{ fontSize: 10, color: 'var(--text-muted)', marginLeft: 'auto' }}>{docName}</span>
      </div>
      {ctxMenu && (
        <div style={{ position: 'fixed', left: ctxMenu.x, top: ctxMenu.y, background: 'var(--bg-raised)', border: '0.5px solid var(--border-strong)', borderRadius: 10, padding: 5, zIndex: 9999, minWidth: 180 }} onClick={e => e.stopPropagation()}>
          {[['rewrite','ti-sparkles','✨ Rewrite'],['improve','ti-wand','Improve writing'],['shorter','ti-arrows-minimize','Make shorter'],['expand','ti-arrows-maximize','Expand'],['fix','ti-check','Fix grammar']].map(([a,ic,label]) => (
            <div key={a} onClick={() => ctxAI(a)} style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '7px 10px', borderRadius: 6, cursor: 'pointer', fontSize: 12, color: 'var(--accent)' }}>
              <i className={`ti ${ic}`} /> {label}
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
