import React, { useState, useRef, useEffect } from 'react';

const HELP = [
  { words: ['wifi', 'internet', 'network'], answer: 'To connect to the Internet, open Settings, choose Network, select your Wi-Fi name, and enter the password. Teddy will test the connection.' },
  { words: ['file', 'document', 'folder', 'save'], answer: 'Your documents are kept in Files. Use Save in the editor, and use Trash instead of permanent deletion so you can recover mistakes.' },
  { words: ['update', 'upgrade'], answer: 'Before an update, save your work and confirm that your backup is current. Teddy should keep the previous working system available for recovery.' },
  { words: ['slow', 'performance', 'memory'], answer: 'Close apps you are not using, check storage in Settings, and restart Teddy OS. Advanced Mode includes more detailed diagnostics.' },
  { words: ['password', 'login', 'account'], answer: 'Open Settings to manage your account. Never share your password. A system administrator may be required for protected changes.' },
];

function answerFor(text) {
  const query = text.toLowerCase();
  const match = HELP.find(item => item.words.some(word => query.includes(word)));
  if (match) return match.answer;
  if (query.includes('hello') || query.includes('hi')) return 'Hello. I am Teddy Help. I work offline and can explain files, Internet, updates, performance, and accounts.';
  if (query.includes('help')) return 'Try asking about Wi-Fi, files, updates, performance, passwords, or settings. Teddy Help works offline and does not send your question anywhere.';
  return 'I work offline and can currently explain common Teddy OS tasks. Try asking: “How do I connect to Wi-Fi?”, “Where are my files?”, or “How do I prepare for an update?”';
}

export default function AIAssistant() {
  const [messages, setMessages] = useState([{ role: 'bot', text: 'Hi! I am Teddy Help. I work offline and do not send your questions anywhere.' }]);
  const [input, setInput] = useState('');
  const bottomRef = useRef(null);

  useEffect(() => { bottomRef.current?.scrollIntoView({ behavior: 'smooth' }); }, [messages]);

  function send(prompt) {
    const msg = prompt || input.trim();
    if (!msg) return;
    setInput('');
    setMessages(prev => [...prev, { role: 'user', text: msg }, { role: 'bot', text: answerFor(msg) }]);
  }

  const QUICK = [['?', 'Wi-Fi', 'How do I connect to Wi-Fi?'], ['F', 'Files', 'Where are my files?'], ['↻', 'Updates', 'How do I prepare for an update?'], ['?', 'Help', 'What can you help me with?']];

  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100%' }}>
      <div style={{ padding: '10px 12px', borderBottom: '0.5px solid var(--border)', color: 'var(--green)', fontSize: 11 }}><strong>Teddy Help</strong> · Offline guidance</div>
      <div style={{ flex: 1, overflowY: 'auto', padding: '10px', display: 'flex', flexDirection: 'column', gap: 8 }}>
        {messages.map((m, i) => <div key={i} style={{ padding: '8px 11px', borderRadius: 10, fontSize: 12.5, lineHeight: 1.6, maxWidth: '90%', alignSelf: m.role === 'user' ? 'flex-end' : 'flex-start', background: m.role === 'user' ? 'var(--accent-dim)' : 'var(--bg-raised)', color: m.role === 'user' ? 'var(--accent)' : 'var(--text-primary)', whiteSpace: 'pre-wrap' }}>{m.text}</div>)}
        <div ref={bottomRef} />
      </div>
      <div style={{ padding: '0 8px 6px', display: 'flex', gap: 4, flexWrap: 'wrap' }}>
        {QUICK.map(([icon, label, prompt]) => <button key={label} onClick={() => send(prompt)} style={{ fontSize: 10, padding: '3px 7px', borderRadius: 5, border: '0.5px solid var(--border)', color: 'var(--text-secondary)', background: 'transparent', cursor: 'pointer' }}>{icon} {label}</button>)}
      </div>
      <div style={{ padding: 8, borderTop: '0.5px solid var(--border)', display: 'flex', gap: 6 }}>
        <textarea value={input} onChange={e => setInput(e.target.value)} onKeyDown={e => { if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); send(); } }} placeholder="Ask Teddy Help..." aria-label="Ask Teddy Help" style={{ flex: 1, fontSize: 12, padding: '6px 8px', borderRadius: 6, border: '0.5px solid var(--border)', background: 'var(--bg-base)', color: 'var(--text-primary)', outline: 'none', resize: 'none', height: 38 }} />
        <button onClick={() => send()} style={{ width: 34, height: 38, borderRadius: 6, background: 'var(--accent)', border: 'none', color: 'white', cursor: 'pointer' }} aria-label="Send question"><i className="ti ti-send" /></button>
      </div>
    </div>
  );
}
