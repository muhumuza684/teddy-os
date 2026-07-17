import React, { useState, useRef, useEffect } from 'react';

export default function AIAssistant() {
  const [messages, setMessages] = useState([{ role: 'bot', text: 'Hi! I\'m your Teddy OS AI assistant. Ask me anything.' }]);
  const [input, setInput] = useState('');
  const [loading, setLoading] = useState(false);
  const bottomRef = useRef(null);

  useEffect(() => { bottomRef.current?.scrollIntoView({ behavior: 'smooth' }); }, [messages]);

  async function send(prompt) {
    const msg = prompt || input.trim();
    if (!msg) return;
    setInput('');
    setMessages(prev => [...prev, { role: 'user', text: msg }]);
    setLoading(true);
    try {
      const res = await fetch('https://api.anthropic.com/v1/messages', {
        method: 'POST', headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ model: 'claude-sonnet-4-6', max_tokens: 1000, system: 'You are a helpful assistant inside Teddy OS, built by Bryt Ma Tech Uganda.', messages: [{ role: 'user', content: msg }] }),
      });
      const data = await res.json();
      setMessages(prev => [...prev, { role: 'bot', text: data.content?.[0]?.text || 'Sorry, something went wrong.' }]);
    } catch { setMessages(prev => [...prev, { role: 'bot', text: 'Error connecting to AI.' }]); }
    setLoading(false);
  }

  const QUICK = [['✨','Improve','Improve the writing quality of my document'],['📝','Summarize','Summarize my document in 2-3 sentences'],['✓','Grammar','Fix grammar and spelling issues'],['🧠','Brainstorm','Give me 5 ideas on this topic']];

  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100%' }}>
      <div style={{ flex: 1, overflowY: 'auto', padding: '10px', display: 'flex', flexDirection: 'column', gap: 8 }}>
        {messages.map((m, i) => (
          <div key={i} style={{ padding: '8px 11px', borderRadius: 10, fontSize: 12.5, lineHeight: 1.6, maxWidth: '90%', alignSelf: m.role === 'user' ? 'flex-end' : 'flex-start', background: m.role === 'user' ? 'var(--accent-dim)' : 'var(--bg-raised)', color: m.role === 'user' ? 'var(--accent)' : 'var(--text-primary)', whiteSpace: 'pre-wrap' }}>{m.text}</div>
        ))}
        {loading && <div style={{ padding: '8px 11px', fontSize: 12, color: 'var(--text-muted)', fontStyle: 'italic' }}>Thinking...</div>}
        <div ref={bottomRef} />
      </div>
      <div style={{ padding: '0 8px 6px', display: 'flex', gap: 4, flexWrap: 'wrap' }}>
        {QUICK.map(([icon, label, prompt]) => (
          <button key={label} onClick={() => send(prompt)} style={{ fontSize: 10, padding: '3px 7px', borderRadius: 5, border: '0.5px solid var(--border)', color: 'var(--text-secondary)', background: 'transparent', cursor: 'pointer' }}>{icon} {label}</button>
        ))}
      </div>
      <div style={{ padding: 8, borderTop: '0.5px solid var(--border)', display: 'flex', gap: 6 }}>
        <textarea value={input} onChange={e => setInput(e.target.value)} onKeyDown={e => { if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); send(); } }} placeholder="Ask AI anything..." style={{ flex: 1, fontSize: 12, padding: '6px 8px', borderRadius: 6, border: '0.5px solid var(--border)', background: 'var(--bg-base)', color: 'var(--text-primary)', outline: 'none', resize: 'none', height: 38 }} />
        <button onClick={() => send()} disabled={loading} style={{ width: 34, height: 38, borderRadius: 6, background: 'var(--accent)', border: 'none', color: 'white', cursor: 'pointer' }}><i className="ti ti-send" /></button>
      </div>
    </div>
  );
}
