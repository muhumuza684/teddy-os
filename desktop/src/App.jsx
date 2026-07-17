import React, { useState, useEffect, useRef, useCallback } from 'react';
import Window from './components/Window';
import { useWindowManager } from './hooks/useWindowManager';
import { useAuth } from './components/Auth';
import { useNotif } from './components/Notifications';
import Editor from './apps/Editor';
import AIAssistant from './apps/AIAssistant';
import Calculator from './apps/Calculator';
import Calendar from './apps/Calendar';
import Terminal from './apps/Terminal';
import FileManager from './apps/FileManager';
import Settings from './apps/Settings';

const APP_META = {
  editor: { title: 'Document Editor', icon: '📝' }, ai: { title: 'AI Assistant', icon: '✨' },
  files: { title: 'File Manager', icon: '📁' }, calc: { title: 'Calculator', icon: '🔢' },
  calendar: { title: 'Calendar', icon: '📅' }, terminal: { title: 'Terminal', icon: '💻' },
  settings: { title: 'Settings', icon: '⚙️' },
};
const TASKBAR_APPS = [
  { id: 'editor', icon: 'ti-file-text', label: 'Editor' }, { id: 'files', icon: 'ti-folder', label: 'Files' },
  { id: 'calc', icon: 'ti-calculator', label: 'Calc' }, { id: 'calendar', icon: 'ti-calendar', label: 'Calendar' },
  { id: 'terminal', icon: 'ti-terminal', label: 'Terminal' }, { id: 'ai', icon: 'ti-robot', label: 'AI' },
  { id: 'settings', icon: 'ti-settings', label: 'Settings' },
];
const DEFAULT_SETTINGS = { fontSize: 15, lineHeight: 1.75, spellCheck: true, fontFamily: '-apple-system,sans-serif', autosave: true, autosaveInterval: 30 };

export default function App() {
  const { windows, openApp, closeApp, minimizeApp, focusApp, moveApp, resizeApp, getZ } = useWindowManager();
  const { currentUser, logout, lock } = useAuth();
  const { notify, unread, openTray, trayOpen } = useNotif();
  const [clock, setClock] = useState('');
  const [launcher, setLauncher] = useState(false);
  const [userMenu, setUserMenu] = useState(false);
  const [settings, setSettings] = useState(DEFAULT_SETTINGS);
  const [activeDocName, setActiveDocName] = useState(null);
  const launcherRef = useRef(null);

  useEffect(() => {
    const tick = () => { const n = new Date(); setClock(n.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) + ' · ' + n.toLocaleDateString([], { weekday: 'short', month: 'short', day: 'numeric' })); };
    tick(); const t = setInterval(tick, 1000); return () => clearInterval(t);
  }, []);

  useEffect(() => {
    openApp('editor'); openApp('ai');
    setTimeout(() => notify({ title: 'Welcome to Teddy OS', message: `Good to see you, ${currentUser?.username || 'user'}!`, type: 'success' }), 1200);
  }, []);

  useEffect(() => {
    const handler = (e) => openApp(e.detail);
    window.addEventListener('teddy:openApp', handler);
    return () => window.removeEventListener('teddy:openApp', handler);
  }, [openApp]);

  useEffect(() => {
    const handler = (e) => { if (launcherRef.current && !launcherRef.current.contains(e.target)) { setLauncher(false); setUserMenu(false); } };
    document.addEventListener('mousedown', handler);
    return () => document.removeEventListener('mousedown', handler);
  }, []);

  const updateSetting = useCallback((key, val) => setSettings(prev => ({ ...prev, [key]: val })), []);
  function handleOpenDocFromFiles(name) { setActiveDocName(name); openApp('editor'); }
  const isOpen = (id) => !!windows[id] && !windows[id].minimized;

  return (
    <div style={{ width: '100vw', height: '100vh', background: 'var(--bg-base)', display: 'flex', flexDirection: 'column', overflow: 'hidden', position: 'relative' }}>
      <div style={{ height: 44, background: 'rgba(6,3,14,0.98)', borderBottom: '0.5px solid var(--border)', display: 'flex', alignItems: 'center', padding: '0 10px', gap: 4, flexShrink: 0, zIndex: 1000 }}>
        <div ref={launcherRef} style={{ position: 'relative', marginRight: 4 }}>
          <button onClick={() => { setLauncher(l => !l); setUserMenu(false); }} style={{ display: 'flex', alignItems: 'center', gap: 6, padding: '4px 10px', borderRadius: 7, background: launcher ? 'rgba(168,85,247,0.18)' : 'rgba(168,85,247,0.08)', border: `0.5px solid rgba(168,85,247,0.2)`, cursor: 'pointer', color: '#c084fc', fontSize: 13, fontWeight: 600 }}>🐻 Teddy OS</button>
          {launcher && (
            <div style={{ position: 'absolute', top: 42, left: 0, background: 'rgba(10,6,22,0.98)', border: '0.5px solid rgba(255,255,255,0.1)', borderRadius: 14, padding: 16, width: 300, zIndex: 2000 }}>
              <div style={{ fontSize: 10, color: 'rgba(255,255,255,0.3)', marginBottom: 10, fontWeight: 600, textTransform: 'uppercase' }}>All Apps</div>
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(5, 1fr)', gap: 5 }}>
                {TASKBAR_APPS.map(({ id, icon, label }) => (
                  <button key={id} onClick={() => { openApp(id); setLauncher(false); }} style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4, padding: '8px 4px', borderRadius: 8, cursor: 'pointer', background: 'transparent', border: 'none' }}>
                    <i className={`ti ${icon}`} style={{ fontSize: 20, color: 'rgba(255,255,255,0.75)' }} />
                    <span style={{ fontSize: 9, color: 'rgba(255,255,255,0.4)' }}>{label}</span>
                  </button>
                ))}
              </div>
              <div style={{ borderTop: '0.5px solid rgba(255,255,255,0.08)', marginTop: 12, paddingTop: 10, fontSize: 10, color: 'rgba(255,255,255,0.25)', textAlign: 'center' }}>Bryt Ma Tech Uganda</div>
            </div>
          )}
        </div>
        {TASKBAR_APPS.map(({ id, icon, label }) => (
          <button key={id} onClick={() => isOpen(id) ? minimizeApp(id) : openApp(id)} style={{ display: 'flex', alignItems: 'center', gap: 4, padding: '4px 8px', borderRadius: 6, cursor: 'pointer', fontSize: 11, color: isOpen(id) ? '#d8b4fe' : 'rgba(255,255,255,0.45)', background: isOpen(id) ? 'rgba(192,132,252,0.14)' : 'transparent' }}>
            <i className={`ti ${icon}`} style={{ fontSize: 13 }} /><span>{label}</span>
          </button>
        ))}
        <div style={{ marginLeft: 'auto', display: 'flex', alignItems: 'center', gap: 8 }}>
          <span style={{ fontSize: 11, color: 'rgba(255,255,255,0.35)', fontFamily: 'var(--font-mono)' }}>{clock}</span>
          <button onClick={() => { openTray(); setLauncher(false); }} style={{ position: 'relative', background: trayOpen ? 'rgba(168,85,247,0.15)' : 'transparent', border: 'none', borderRadius: 6, padding: '4px 7px', cursor: 'pointer', color: unread > 0 ? '#c084fc' : 'rgba(255,255,255,0.45)' }}>
            <i className="ti ti-bell" style={{ fontSize: 14 }} />
            {unread > 0 && <span style={{ position: 'absolute', top: 2, right: 2, width: 8, height: 8, borderRadius: '50%', background: '#a855f7' }} />}
          </button>
          <div style={{ position: 'relative' }}>
            <button onClick={() => { setUserMenu(u => !u); setLauncher(false); }} style={{ display: 'flex', alignItems: 'center', gap: 6, padding: '3px 8px', borderRadius: 6, background: userMenu ? 'rgba(255,255,255,0.08)' : 'transparent', border: 'none', cursor: 'pointer' }}>
              <span style={{ fontSize: 16 }}>{currentUser?.avatar || '🐻'}</span>
              <span style={{ fontSize: 11, color: 'rgba(255,255,255,0.6)' }}>{currentUser?.username}</span>
            </button>
            {userMenu && (
              <div style={{ position: 'absolute', top: 38, right: 0, background: 'rgba(10,6,22,0.98)', border: '0.5px solid rgba(255,255,255,0.1)', borderRadius: 10, padding: 6, minWidth: 160, zIndex: 2000 }}>
                {[['ti-settings', 'Settings', () => { openApp('settings'); setUserMenu(false); }], ['ti-lock', 'Lock screen', () => { lock(); setUserMenu(false); }], ['ti-logout', 'Sign out', () => { logout(); setUserMenu(false); }]].map(([icon, label, action]) => (
                  <button key={label} onClick={action} style={{ display: 'flex', alignItems: 'center', gap: 8, width: '100%', padding: '8px 10px', borderRadius: 6, background: 'transparent', border: 'none', cursor: 'pointer', fontSize: 12, color: label === 'Sign out' ? '#f87171' : '#f0eeff', textAlign: 'left' }}>
                    <i className={`ti ${icon}`} style={{ fontSize: 14 }} /> {label}
                  </button>
                ))}
              </div>
            )}
          </div>
        </div>
      </div>
      <div style={{ flex: 1, position: 'relative', overflow: 'hidden' }} onClick={() => { setLauncher(false); setUserMenu(false); }}>
        <div style={{ position: 'absolute', inset: 0, backgroundImage: 'radial-gradient(circle at 20% 30%, rgba(168,85,247,0.06) 0%, transparent 50%), radial-gradient(circle at 80% 70%, rgba(96,165,250,0.04) 0%, transparent 50%)', pointerEvents: 'none' }} />
        {Object.entries(windows).map(([id, win]) => !win.minimized && (
          <Window key={id} id={id} title={APP_META[id]?.title || id} icon={APP_META[id]?.icon} x={win.x} y={win.y} w={win.w} h={win.h} zIndex={getZ(id)}
            onClose={closeApp} onMinimize={minimizeApp} onFocus={focusApp} onMove={moveApp} onResize={resizeApp}>
            {id === 'editor' && <Editor />}
            {id === 'ai' && <AIAssistant />}
            {id === 'calc' && <Calculator />}
            {id === 'calendar' && <Calendar />}
            {id === 'terminal' && <Terminal />}
            {id === 'files' && <FileManager onOpenDoc={handleOpenDocFromFiles} />}
            {id === 'settings' && <Settings settings={settings} onUpdate={updateSetting} currentUser={currentUser} onLock={lock} onLogout={logout} />}
          </Window>
        ))}
        {Object.entries(windows).some(([, w]) => w.minimized) && (
          <div style={{ position: 'absolute', bottom: 14, left: '50%', transform: 'translateX(-50%)', display: 'flex', gap: 6, background: 'rgba(10,6,22,0.92)', border: '0.5px solid rgba(255,255,255,0.1)', borderRadius: 12, padding: '6px 10px' }}>
            {Object.entries(windows).filter(([, w]) => w.minimized).map(([id]) => (
              <button key={id} onClick={() => openApp(id)} style={{ padding: '5px 10px', borderRadius: 7, background: 'rgba(168,85,247,0.15)', border: '0.5px solid rgba(168,85,247,0.3)', color: '#d8b4fe', cursor: 'pointer', fontSize: 12 }}>{APP_META[id]?.icon} {APP_META[id]?.title}</button>
            ))}
          </div>
        )}
      </div>
      <div style={{ height: 22, background: 'rgba(6,3,14,0.92)', borderTop: '0.5px solid var(--border)', display: 'flex', alignItems: 'center', padding: '0 14px', gap: 12, flexShrink: 0 }}>
        <span style={{ fontSize: 10, color: 'rgba(255,255,255,0.2)' }}>🐻 Teddy OS v1.0</span>
        <span style={{ fontSize: 10, color: 'rgba(255,255,255,0.2)' }}>·</span>
        <span style={{ fontSize: 10, color: 'rgba(255,255,255,0.2)' }}>Built by Bryt Ma Tech Uganda</span>
        <span style={{ marginLeft: 'auto', fontSize: 10, color: 'rgba(255,255,255,0.2)' }}>{Object.keys(windows).length} app{Object.keys(windows).length !== 1 ? 's' : ''} open</span>
      </div>
    </div>
  );
}
