import React, { useEffect, useRef, useState } from 'react';
import { useNotif } from '../components/Notifications';

const CITIES = [
  { name: 'Kampala', tz: 'Africa/Kampala' }, { name: 'London', tz: 'Europe/London' },
  { name: 'New York', tz: 'America/New_York' }, { name: 'Tokyo', tz: 'Asia/Tokyo' },
];
const pad = (n) => String(n).padStart(2, '0');
const fmtMs = (ms) => `${pad(Math.floor(ms / 60000))}:${pad(Math.floor(ms / 1000) % 60)}.${pad(Math.floor(ms / 10) % 100)}`;
const tabBtn = (on) => ({ padding: '6px 14px', border: 0, borderRadius: 6, cursor: 'pointer', background: on ? 'var(--accent)' : 'var(--border)', color: 'var(--text-primary)' });

function World() {
  const [now, setNow] = useState(new Date());
  useEffect(() => { const t = setInterval(() => setNow(new Date()), 1000); return () => clearInterval(t); }, []);
  return CITIES.map((c) => (
    <div key={c.tz} style={{ display: 'flex', justifyContent: 'space-between', padding: '10px 0', borderBottom: '1px solid var(--border)' }}>
      <span>{c.name}</span>
      <b>{now.toLocaleTimeString('en-GB', { timeZone: c.tz })}</b>
    </div>
  ));
}

function Alarm() {
  const notif = useNotif();
  const [time, setTime] = useState('07:00');
  const [alarms, setAlarms] = useState([]);
  useEffect(() => {
    const t = setInterval(() => {
      const d = new Date(), hhmm = `${pad(d.getHours())}:${pad(d.getMinutes())}`;
      setAlarms((list) => list.map((a) => {
        if (a.on && a.time === hhmm && a.firedAt !== `${d.toDateString()} ${hhmm}`) {
          notif?.notify({ title: 'Alarm', message: a.time, type: 'info', app: 'Clock' }); window.electronAPI?.notify?.('Alarm', a.time);
          return { ...a, firedAt: `${d.toDateString()} ${hhmm}` };
        }
        return a;
      }));
    }, 1000);
    return () => clearInterval(t);
  }, [notif]);
  return (<div>
    <input type="time" value={time} onChange={(e) => setTime(e.target.value)} />
    <button onClick={() => setAlarms((l) => [...l, { id: Date.now(), time, on: true }])}>Add</button>
    {alarms.map((a) => (
      <div key={a.id} style={{ display: 'flex', gap: 8, padding: '8px 0' }}>
        <b style={{ flex: 1 }}>{a.time}</b>
        <button onClick={() => setAlarms((l) => l.map((x) => (x.id === a.id ? { ...x, on: !x.on } : x)))}>{a.on ? 'On' : 'Off'}</button>
        <button onClick={() => setAlarms((l) => l.filter((x) => x.id !== a.id))}>✕</button>
      </div>))}
  </div>);
}

function Timer() {
  const notif = useNotif();
  const [mins, setMins] = useState(5);
  const [left, setLeft] = useState(null);
  const end = useRef(0);
  useEffect(() => {
    if (left === null) return;
    const t = setInterval(() => {
      if (!end.current) return;                       // already fired - never notify twice
      const r = end.current - Date.now();
      if (r <= 0) { end.current = 0; setLeft(null); notif?.notify({ title: 'Timer', message: 'Time is up', type: 'info', app: 'Clock' }); window.electronAPI?.notify?.('Timer', 'Time is up'); }
      else setLeft(r);
    }, 200);
    return () => clearInterval(t);
  }, [left === null]);
  return (<div>
    {left === null ? <>
      <input type="number" min="1" value={mins} onChange={(e) => setMins(+e.target.value)} /> min
      <button onClick={() => { end.current = Date.now() + mins * 60000; setLeft(mins * 60000); }}>Start</button>
    </> : <>
      <div style={{ fontSize: 40 }}>{fmtMs(left).slice(0, 5)}</div>
      <button onClick={() => setLeft(null)}>Cancel</button>
    </>}
  </div>);
}

function Stopwatch() {
  const [ms, setMs] = useState(0), [run, setRun] = useState(false), [laps, setLaps] = useState([]);
  const base = useRef(0);
  useEffect(() => {
    if (!run) return;
    const start = Date.now() - base.current;
    const t = setInterval(() => { base.current = Date.now() - start; setMs(base.current); }, 30);
    return () => clearInterval(t);
  }, [run]);
  return (<div>
    <div style={{ fontSize: 40 }}>{fmtMs(ms)}</div>
    <button onClick={() => setRun(!run)}>{run ? 'Stop' : 'Start'}</button>
    <button disabled={!run} onClick={() => setLaps((l) => [ms, ...l])}>Lap</button>
    <button onClick={() => { setRun(false); base.current = 0; setMs(0); setLaps([]); }}>Reset</button>
    {laps.map((l, i) => <div key={i}>Lap {laps.length - i}: {fmtMs(l)}</div>)}
  </div>);
}

export default function Clock() {
  const [tab, setTab] = useState('World');
  const tabs = { World, Alarm, Timer, Stopwatch };
  const Body = tabs[tab];
  return (
    <div style={{ padding: 16, color: 'var(--text-primary)', height: '100%', overflow: 'auto' }}>
      <div style={{ display: 'flex', gap: 6, marginBottom: 12 }}>
        {Object.keys(tabs).map((t) => <button key={t} style={tabBtn(t === tab)} onClick={() => setTab(t)}>{t}</button>)}
      </div>
      <Body />
    </div>
  );
}
