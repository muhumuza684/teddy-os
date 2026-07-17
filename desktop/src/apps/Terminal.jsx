import React, { useState, useRef, useEffect } from 'react';

const BANNER = [
  { text: '  🐻 Teddy OS Terminal v1.0', color: '#a855f7' },
  { text: '  Built by Bryt Ma Tech Uganda', color: '#6b6085' },
  { text: '  Type "help" for available commands.', color: '#6b6085' },
  { text: '' },
];

export default function Terminal() {
  const [lines, setLines] = useState(BANNER);
  const [input, setInput] = useState('');
  const [history, setHistory] = useState([]);
  const [hIdx, setHIdx] = useState(-1);
  const inputRef = useRef(null);
  const bottomRef = useRef(null);

  useEffect(() => { bottomRef.current?.scrollIntoView(); }, [lines]);
  useEffect(() => { inputRef.current?.focus(); }, []);

  function print(text, color = '#94a3b8') { setLines(prev => [...prev, { text, color }]); }

  function handleKey(e) {
    if (e.key === 'Enter') {
      const cmd = input.trim();
      if (!cmd) { print(''); return; }
      setHistory(h => [cmd, ...h]); setHIdx(-1);
      print(`teddy@os:~$ ${cmd}`, '#a855f7');
      setInput(''); execute(cmd);
    } else if (e.key === 'ArrowUp') { e.preventDefault(); const ni = Math.min(hIdx + 1, history.length - 1); setHIdx(ni); setInput(history[ni] || ''); }
    else if (e.key === 'ArrowDown') { e.preventDefault(); const ni = Math.max(hIdx - 1, -1); setHIdx(ni); setInput(ni === -1 ? '' : history[ni] || ''); }
  }

  function execute(raw) {
    const parts = raw.trim().split(/\s+/);
    const cmd = parts[0]; const args = parts.slice(1);
    const commands = {
      help: () => { print('Commands: help, clear, echo, date, pwd, ls, whoami, uname, uptime, calc, history, open <app>', '#60a5fa'); },
      clear: () => setLines([]),
      echo: () => print(args.join(' ')),
      date: () => print(new Date().toString(), '#4ade80'),
      pwd: () => print('/home/teddy'),
      whoami: () => print('teddy-user', '#4ade80'),
      uname: () => print('TeddyOS 1.0.0 (Bryt Ma Tech Uganda)', '#4ade80'),
      uptime: () => print(`up ${Math.floor(performance.now() / 60000)} min`, '#4ade80'),
      history: () => history.forEach((h, i) => print(`  ${i + 1}  ${h}`)),
      ls: () => print('Documents  Projects  Downloads', '#60a5fa'),
      calc: () => {
        if (!args.length) { print('Usage: calc <expression>', '#f87171'); return; }
        try { const expr = args.join('').replace(/[^0-9+\-*/.()%]/g, ''); const r = Function('"use strict";return (' + expr + ')')(); print(`= ${r}`, '#4ade80'); }
        catch { print('calc: invalid expression', '#f87171'); }
      },
      open: () => {
        const app = args[0]; const valid = ['editor','files','calc','calendar','terminal','settings','ai'];
        if (!app || !valid.includes(app)) { print(`open: unknown app. Try: ${valid.join(', ')}`, '#f87171'); return; }
        window.dispatchEvent(new CustomEvent('teddy:openApp', { detail: app }));
        print(`Opening ${app}...`, '#4ade80');
      },
    };
    if (commands[cmd]) commands[cmd]();
    else print(`${cmd}: command not found. Type "help".`, '#f87171');
  }

  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100%', background: '#06030f' }} onClick={() => inputRef.current?.focus()}>
      <div style={{ flex: 1, overflowY: 'auto', padding: '10px 14px', fontFamily: 'var(--font-mono)', fontSize: 12.5, lineHeight: 1.65 }}>
        {lines.map((line, i) => <div key={i} style={{ color: line.color || '#94a3b8', whiteSpace: 'pre-wrap' }}>{line.text}</div>)}
        <div ref={bottomRef} />
      </div>
      <div style={{ display: 'flex', alignItems: 'center', padding: '7px 14px', borderTop: '0.5px solid #111', background: '#030209', gap: 6, flexShrink: 0 }}>
        <span style={{ fontFamily: 'var(--font-mono)', fontSize: 12.5, color: '#a855f7' }}>teddy@os:~$</span>
        <input ref={inputRef} value={input} onChange={e => setInput(e.target.value)} onKeyDown={handleKey} autoComplete="off" spellCheck={false}
          style={{ flex: 1, background: 'transparent', border: 'none', outline: 'none', fontFamily: 'var(--font-mono)', fontSize: 12.5, color: '#e2e8f0' }} />
      </div>
    </div>
  );
}
