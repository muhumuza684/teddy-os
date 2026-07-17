import React, { useState, useEffect } from 'react';
import { dbGet, dbPut } from '../utils/db';

const DAYS = ['Sun','Mon','Tue','Wed','Thu','Fri','Sat'];
const MONTHS = ['January','February','March','April','May','June','July','August','September','October','November','December'];
function dayKey(d) { return `${d.getFullYear()}-${d.getMonth()}-${d.getDate()}`; }

export default function Calendar() {
  const today = new Date();
  const [view, setView] = useState(new Date(today.getFullYear(), today.getMonth(), 1));
  const [selected, setSelected] = useState(today);
  const [events, setEvents] = useState({});
  const [input, setInput] = useState('');
  const [inputTime, setInputTime] = useState('');

  useEffect(() => { loadEvents(); }, []);
  async function loadEvents() { const rec = await dbGet('events', 'all'); if (rec?.data) setEvents(rec.data); }
  async function saveEvents(ev) { setEvents(ev); await dbPut('events', { id: 'all', data: ev }); }

  function addEvent() {
    const val = input.trim(); if (!val) return;
    const k = dayKey(selected);
    saveEvents({ ...events, [k]: [...(events[k] || []), { text: val, time: inputTime || '' }] });
    setInput(''); setInputTime('');
  }
  function deleteEvent(k, i) { const arr = [...(events[k] || [])]; arr.splice(i, 1); saveEvents({ ...events, [k]: arr }); }
  function navigate(dir) { setView(v => new Date(v.getFullYear(), v.getMonth() + dir, 1)); }

  const firstDay = view.getDay();
  const daysInMonth = new Date(view.getFullYear(), view.getMonth() + 1, 0).getDate();
  const selKey = dayKey(selected);
  const selEvents = events[selKey] || [];

  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100%', padding: 14 }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 12 }}>
        <button onClick={() => navigate(-1)} style={navBtnStyle}>‹</button>
        <span style={{ fontSize: 15, fontWeight: 500, color: 'var(--text-primary)' }}>{MONTHS[view.getMonth()]} {view.getFullYear()}</span>
        <button onClick={() => navigate(1)} style={navBtnStyle}>›</button>
      </div>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(7, 1fr)', gap: 2, marginBottom: 4 }}>
        {DAYS.map(d => <div key={d} style={{ textAlign: 'center', fontSize: 10, color: 'var(--text-muted)', fontWeight: 500, padding: '2px 0' }}>{d}</div>)}
      </div>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(7, 1fr)', gap: 2 }}>
        {Array(firstDay).fill(null).map((_, i) => <div key={'e' + i} />)}
        {Array(daysInMonth).fill(null).map((_, i) => {
          const d = new Date(view.getFullYear(), view.getMonth(), i + 1);
          const k = dayKey(d);
          const isToday = d.toDateString() === today.toDateString();
          const isSel = d.toDateString() === selected.toDateString();
          const hasEv = events[k]?.length > 0;
          return (
            <div key={i} onClick={() => setSelected(d)} style={{ borderRadius: 7, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', minHeight: 36, cursor: 'pointer', position: 'relative', fontSize: 13, background: isSel ? 'var(--accent)' : isToday ? 'var(--accent-dim)' : 'transparent', color: isSel ? 'white' : isToday ? 'var(--accent)' : 'var(--text-secondary)', fontWeight: isToday || isSel ? 600 : 400 }}>
              {i + 1}
              {hasEv && <div style={{ width: 4, height: 4, borderRadius: '50%', background: isSel ? 'white' : 'var(--accent)', position: 'absolute', bottom: 4 }} />}
            </div>
          );
        })}
      </div>
      <div style={{ flex: 1, marginTop: 12, overflowY: 'auto' }}>
        <div style={{ fontSize: 11, color: 'var(--text-muted)', marginBottom: 6, fontWeight: 500 }}>{selected.toLocaleDateString([], { weekday: 'long', month: 'long', day: 'numeric' })}</div>
        {selEvents.length === 0 && <div style={{ fontSize: 12, color: 'var(--text-muted)', fontStyle: 'italic' }}>No events. Add one below.</div>}
        {selEvents.map((ev, i) => (
          <div key={i} style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '6px 10px', borderRadius: 7, background: 'var(--accent-dim)', marginBottom: 4 }}>
            <div>{ev.time && <span style={{ fontSize: 10, color: 'var(--accent)', marginRight: 6, fontFamily: 'var(--font-mono)' }}>{ev.time}</span>}<span style={{ fontSize: 12, color: 'var(--text-primary)' }}>{ev.text}</span></div>
            <button onClick={() => deleteEvent(selKey, i)} style={{ background: 'none', border: 'none', cursor: 'pointer', color: 'var(--text-muted)', fontSize: 14 }}>×</button>
          </div>
        ))}
      </div>
      <div style={{ display: 'flex', gap: 5, marginTop: 8 }}>
        <input type="time" value={inputTime} onChange={e => setInputTime(e.target.value)} style={{ width: 80, fontSize: 11, padding: '5px 6px', borderRadius: 6, border: '0.5px solid var(--border)', background: 'var(--bg-base)', color: 'var(--text-primary)', outline: 'none' }} />
        <input value={input} onChange={e => setInput(e.target.value)} onKeyDown={e => e.key === 'Enter' && addEvent()} placeholder="Add event..." style={{ flex: 1, fontSize: 12, padding: '5px 8px', borderRadius: 6, border: '0.5px solid var(--border)', background: 'var(--bg-base)', color: 'var(--text-primary)', outline: 'none' }} />
        <button onClick={addEvent} style={{ padding: '5px 12px', borderRadius: 6, background: 'var(--accent)', border: 'none', color: 'white', fontSize: 12, cursor: 'pointer' }}>Add</button>
      </div>
    </div>
  );
}
const navBtnStyle = { width: 30, height: 30, borderRadius: 7, border: '0.5px solid var(--border)', background: 'transparent', color: 'var(--text-secondary)', cursor: 'pointer', fontSize: 16 };
