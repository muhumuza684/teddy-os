import React, { useRef, useState, useEffect } from 'react';

const normalize = (v) => {
  const t = v.trim();
  if (!t) return 'about:blank';
  if (/^https?:\/\//i.test(t)) return t;
  if (/^[\w-]+(\.[\w-]+)+(:\d+)?(\/.*)?$/.test(t)) return 'https://' + t;
  return 'https://duckduckgo.com/?q=' + encodeURIComponent(t);
};

export default function Browser() {
  const wv = useRef(null);
  const [url, setUrl] = useState('https://duckduckgo.com');
  const [input, setInput] = useState('https://duckduckgo.com');
  const [title, setTitle] = useState('');
  const [loading, setLoading] = useState(false);
  const [nav, setNav] = useState({ back: false, fwd: false });

  useEffect(() => {
    const w = wv.current; if (!w) return;
    const sync = () => { setNav({ back: w.canGoBack(), fwd: w.canGoForward() }); setTitle(w.getTitle() || ''); };
    const on = {
      'did-start-loading': () => setLoading(true),
      'did-stop-loading': () => { setLoading(false); sync(); },
      'did-navigate': (e) => { setInput(e.url); setUrl(e.url); sync(); },
      'did-navigate-in-page': (e) => { if (e.isMainFrame) setInput(e.url); sync(); },
      'page-title-updated': (e) => setTitle(e.title),
    };
    Object.entries(on).forEach(([k, f]) => w.addEventListener(k, f));
    return () => Object.entries(on).forEach(([k, f]) => w.removeEventListener(k, f));
  }, []);

  const go = (e) => { e.preventDefault(); const u = normalize(input); setUrl(u); wv.current?.loadURL(u); };
  const btn = { padding: '4px 10px', border: 0, borderRadius: 6, background: 'var(--border)', color: 'var(--text-primary)', cursor: 'pointer' };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100%', background: 'var(--bg-base)' }}>
      <form onSubmit={go} style={{ display: 'flex', gap: 6, padding: 8, alignItems: 'center' }}>
        <button type="button" style={btn} disabled={!nav.back} onClick={() => wv.current.goBack()}>←</button>
        <button type="button" style={btn} disabled={!nav.fwd} onClick={() => wv.current.goForward()}>→</button>
        <button type="button" style={btn} onClick={() => (loading ? wv.current.stop() : wv.current.reload())}>{loading ? '✕' : '⟳'}</button>
        <input value={input} onChange={(e) => setInput(e.target.value)} placeholder="Search or enter address"
          style={{ flex: 1, padding: '6px 10px', borderRadius: 6, border: '1px solid #333', background: 'var(--bg-raised)', color: 'var(--text-primary)' }} />
      </form>
      <div style={{ height: 2, background: loading ? 'var(--accent)' : 'transparent' }} />
      {/* requires webviewTag: true in BrowserWindow webPreferences */}
      <webview ref={wv} src={url} style={{ flex: 1 }} allowpopups="false" />
      <div style={{ padding: '2px 10px', fontSize: 11, color: 'var(--text-muted)' }}>{title}</div>
    </div>
  );
}
