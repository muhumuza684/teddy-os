import React, { createContext, useContext, useState, useCallback, useRef } from 'react';

const NotifContext = createContext(null);

export function NotifProvider({ children }) {
  const [notifs, setNotifs] = useState([]);
  const [trayOpen, setTrayOpen] = useState(false);
  const [unread, setUnread] = useState(0);
  const idRef = useRef(1);

  const notify = useCallback(({ title, message, type = 'info', duration = 5000, app = 'Teddy OS' }) => {
    const id = idRef.current++;
    const entry = { id, title, message, type, app, time: new Date(), read: false };
    setNotifs(prev => [entry, ...prev.slice(0, 49)]);
    setUnread(n => n + 1);
    if (duration > 0) setTimeout(() => dismissToast(id), duration);
    return id;
  }, []);

  const dismiss = useCallback((id) => setNotifs(prev => prev.filter(n => n.id !== id)), []);
  const dismissToast = useCallback((id) => setNotifs(prev => prev.map(n => n.id === id ? { ...n, toastDone: true } : n)), []);
  const markAllRead = useCallback(() => { setNotifs(prev => prev.map(n => ({ ...n, read: true }))); setUnread(0); }, []);
  const clearAll = useCallback(() => { setNotifs([]); setUnread(0); }, []);
  const openTray = useCallback(() => { setTrayOpen(true); markAllRead(); }, [markAllRead]);

  return (
    <NotifContext.Provider value={{ notifs, notify, dismiss, clearAll, unread, trayOpen, openTray, setTrayOpen }}>
      {children}
      <NotifToasts notifs={notifs} dismiss={dismissToast} />
      {trayOpen && <NotifTray notifs={notifs} dismiss={dismiss} clearAll={clearAll} onClose={() => setTrayOpen(false)} />}
    </NotifContext.Provider>
  );
}

export function useNotif() { return useContext(NotifContext); }

const TYPE_COLORS = {
  info:    { border: 'rgba(96,165,250,0.3)',  icon: 'ti-info-circle',    color: '#60a5fa' },
  success: { border: 'rgba(74,222,128,0.3)',  icon: 'ti-circle-check',   color: '#4ade80' },
  warning: { border: 'rgba(251,191,36,0.3)',  icon: 'ti-alert-triangle', color: '#fbbf24' },
  error:   { border: 'rgba(248,113,113,0.3)', icon: 'ti-circle-x',       color: '#f87171' },
};

function NotifToasts({ notifs, dismiss }) {
  const active = notifs.filter(n => !n.toastDone).slice(0, 4);
  if (active.length === 0) return null;
  return (
    <div style={{ position: 'fixed', bottom: 32, right: 16, display: 'flex', flexDirection: 'column-reverse', gap: 8, zIndex: 9999, width: 320 }}>
      {active.map(n => {
        const t = TYPE_COLORS[n.type] || TYPE_COLORS.info;
        return (
          <div key={n.id} style={{ background: 'var(--bg-surface)', border: `0.5px solid ${t.border}`, borderLeft: `3px solid ${t.color}`, borderRadius: 10, padding: '10px 12px', boxShadow: '0 4px 24px rgba(0,0,0,0.4)', display: 'flex', gap: 10, alignItems: 'flex-start' }}>
            <i className={`ti ${t.icon}`} style={{ fontSize: 16, color: t.color, flexShrink: 0, marginTop: 1 }} />
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontSize: 12, fontWeight: 500, color: 'var(--text-primary)', marginBottom: 2 }}>{n.title}</div>
              <div style={{ fontSize: 11, color: 'var(--text-secondary)', lineHeight: 1.4 }}>{n.message}</div>
              <div style={{ fontSize: 10, color: 'var(--text-muted)', marginTop: 4 }}>{n.app}</div>
            </div>
            <button onClick={() => dismiss(n.id)} style={{ background: 'none', border: 'none', cursor: 'pointer', color: 'var(--text-muted)', fontSize: 15, flexShrink: 0, padding: '0 2px', lineHeight: 1 }}>×</button>
          </div>
        );
      })}
    </div>
  );
}

function NotifTray({ notifs, dismiss, clearAll, onClose }) {
  return (
    <div style={{ position: 'fixed', top: 44, right: 0, width: 340, height: 'calc(100vh - 44px)', background: 'var(--bg-surface)', borderLeft: '0.5px solid var(--border-strong)', display: 'flex', flexDirection: 'column', zIndex: 900, boxShadow: '-4px 0 24px rgba(0,0,0,0.3)' }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '12px 16px', borderBottom: '0.5px solid var(--border)', flexShrink: 0 }}>
        <span style={{ fontSize: 13, fontWeight: 500, color: 'var(--text-primary)' }}>Notifications</span>
        <div style={{ display: 'flex', gap: 8 }}>
          {notifs.length > 0 && <button onClick={clearAll} style={{ fontSize: 11, color: 'var(--text-muted)', background: 'none', border: 'none', cursor: 'pointer' }}>Clear all</button>}
          <button onClick={onClose} style={{ background: 'none', border: 'none', cursor: 'pointer', color: 'var(--text-muted)', fontSize: 16 }}>×</button>
        </div>
      </div>
      <div style={{ flex: 1, overflowY: 'auto', padding: 12 }}>
        {notifs.length === 0 && (
          <div style={{ textAlign: 'center', color: 'var(--text-muted)', fontSize: 13, marginTop: 60 }}>
            <i className="ti ti-bell-off" style={{ fontSize: 32, display: 'block', marginBottom: 10 }} />No notifications
          </div>
        )}
        {notifs.map(n => {
          const t = TYPE_COLORS[n.type] || TYPE_COLORS.info;
          return (
            <div key={n.id} style={{ display: 'flex', gap: 10, padding: '10px 12px', borderRadius: 8, marginBottom: 6, background: n.read ? 'transparent' : 'rgba(168,85,247,0.06)', border: `0.5px solid ${n.read ? 'var(--border)' : 'rgba(168,85,247,0.2)'}`, alignItems: 'flex-start' }}>
              <i className={`ti ${t.icon}`} style={{ fontSize: 15, color: t.color, flexShrink: 0, marginTop: 2 }} />
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', gap: 6 }}>
                  <span style={{ fontSize: 12, fontWeight: 500, color: 'var(--text-primary)' }}>{n.title}</span>
                  <span style={{ fontSize: 10, color: 'var(--text-muted)', whiteSpace: 'nowrap', flexShrink: 0 }}>{n.time.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}</span>
                </div>
                <div style={{ fontSize: 11, color: 'var(--text-secondary)', marginTop: 2, lineHeight: 1.4 }}>{n.message}</div>
                <div style={{ fontSize: 10, color: 'var(--text-muted)', marginTop: 3 }}>{n.app}</div>
              </div>
              <button onClick={() => dismiss(n.id)} style={{ background: 'none', border: 'none', cursor: 'pointer', color: 'var(--text-muted)', fontSize: 14, flexShrink: 0 }}>×</button>
            </div>
          );
        })}
      </div>
    </div>
  );
}
