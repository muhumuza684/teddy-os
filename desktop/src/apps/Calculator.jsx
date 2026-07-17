import React, { useState, useEffect } from 'react';

const BTN_TYPES = { num: { bg: 'var(--bg-hover)', color: 'var(--text-primary)' }, op: { bg: '#2d1f4e', color: '#c084fc' }, fn: { bg: 'var(--bg-raised)', color: 'var(--text-secondary)' }, eq: { bg: 'var(--accent)', color: 'white' } };

export default function Calculator() {
  const [display, setDisplay] = useState('0');
  const [expr, setExpr] = useState('');
  const [prev, setPrev] = useState(null);
  const [op, setOp] = useState(null);
  const [fresh, setFresh] = useState(false);
  const [history, setHistory] = useState([]);

  function pressNum(n) {
    if (n === '.' && display.includes('.')) return;
    if (fresh) { setDisplay(n === '.' ? '0.' : n); setFresh(false); }
    else setDisplay(display === '0' && n !== '.' ? n : display + n);
  }
  function pressOp(o) { setPrev(parseFloat(display)); setOp(o); setExpr(display + ' ' + { '+':'+','-':'−','*':'×','/':'÷' }[o]); setFresh(true); }
  function pressEq() {
    if (op === null || prev === null) return;
    const curr = parseFloat(display); let result;
    if (op === '+') result = prev + curr; else if (op === '-') result = prev - curr;
    else if (op === '*') result = prev * curr; else if (op === '/') result = curr === 0 ? 'Error' : prev / curr;
    const resStr = result === 'Error' ? 'Error' : String(parseFloat(result.toFixed(10)));
    setHistory(h => [`${expr} ${curr} = ${resStr}`, ...h.slice(0, 9)]);
    setExpr(`${expr} ${curr} = ${resStr}`); setDisplay(resStr); setOp(null); setPrev(null); setFresh(true);
  }
  function pressFn(f) {
    if (f === 'clear') { setDisplay('0'); setExpr(''); setOp(null); setPrev(null); setFresh(false); }
    else if (f === 'sign') setDisplay(String(-parseFloat(display)));
    else if (f === 'pct') setDisplay(String(parseFloat(display) / 100));
    else if (f === 'back') setDisplay(display.length > 1 ? display.slice(0, -1) : '0');
  }

  const BUTTONS = [[['AC','fn','clear'],['±','fn','sign'],['%','fn','pct'],['÷','op','/']],[['7','num','7'],['8','num','8'],['9','num','9'],['×','op','*']],[['4','num','4'],['5','num','5'],['6','num','6'],['−','op','-']],[['1','num','1'],['2','num','2'],['3','num','3'],['+','op','+']],[['⌫','fn','back'],['0','num','0'],['.','num','.'],['=','eq','eq']]];

  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100%' }}>
      <div style={{ padding: '16px 16px 10px', background: '#06030f', textAlign: 'right' }}>
        <div style={{ fontSize: 11, color: 'var(--text-muted)', minHeight: 16, marginBottom: 6 }}>{expr || ' '}</div>
        <div style={{ fontSize: 38, fontWeight: 200, color: 'var(--text-primary)', fontFamily: 'var(--font-mono)' }}>{display}</div>
      </div>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 1, background: 'var(--border)', flex: 1 }}>
        {BUTTONS.flat().map(([label, type, action]) => {
          const style = BTN_TYPES[type] || BTN_TYPES.num;
          return (
            <button key={label + action} onClick={() => type === 'fn' ? pressFn(action) : type === 'op' ? pressOp(action) : action === 'eq' ? pressEq() : pressNum(label)}
              style={{ ...style, border: 'none', cursor: 'pointer', fontSize: 16, padding: 0 }}>{label}</button>
          );
        })}
      </div>
      {history.length > 0 && (
        <div style={{ padding: '6px 10px', borderTop: '0.5px solid var(--border)', background: 'var(--bg-raised)', maxHeight: 80, overflowY: 'auto' }}>
          {history.map((h, i) => <div key={i} style={{ fontSize: 10, color: 'var(--text-muted)', fontFamily: 'var(--font-mono)' }}>{h}</div>)}
        </div>
      )}
    </div>
  );
}
