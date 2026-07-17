import React, { createContext, useContext, useState, useEffect } from 'react';
import { dbGet, dbPut, dbAll } from '../utils/db';

const AuthContext = createContext(null);

export function AuthProvider({ children }) {
  const [stage, setStage] = useState('loading');
  const [currentUser, setCurrentUser] = useState(null);
  const [users, setUsers] = useState([]);

  useEffect(() => { init(); }, []);

  async function init() {
    const all = await dbAll('users').catch(() => []);
    setUsers(all);
    if (!all || all.length === 0) { setStage('setup'); }
    else {
      const saved = localStorage.getItem('teddy_user');
      if (saved) {
        const u = all.find(u => u.username === saved);
        if (u) { setCurrentUser(u); setStage('desktop'); return; }
      }
      setStage('login');
    }
  }

  async function createUser(username, password, avatar = '🐻') {
    if (!username.trim() || !password.trim()) return { error: 'Username and password required' };
    const existing = await dbGet('users', username).catch(() => null);
    if (existing) return { error: 'Username already taken' };
    const user = { username, password: btoa(password), avatar, created: Date.now(), role: users.length === 0 ? 'admin' : 'user' };
    await dbPut('users', user);
    setUsers(prev => [...prev, user]);
    return { success: true };
  }

  async function login(username, password) {
    const user = await dbGet('users', username).catch(() => null);
    if (!user) return { error: 'User not found' };
    if (atob(user.password) !== password) return { error: 'Incorrect password' };
    setCurrentUser(user);
    localStorage.setItem('teddy_user', username);
    setStage('desktop');
    return { success: true };
  }

  function logout() { localStorage.removeItem('teddy_user'); setCurrentUser(null); setStage('login'); }
  function lock() { setStage('locked'); }
  function unlock(password) {
    if (currentUser && atob(currentUser.password) === password) { setStage('desktop'); return true; }
    return false;
  }

  return (
    <AuthContext.Provider value={{ stage, currentUser, users, createUser, login, logout, lock, unlock, setStage }}>
      {stage === 'loading'  && <LoadingScreen />}
      {stage === 'setup'    && <SetupScreen createUser={createUser} onDone={() => setStage('login')} />}
      {stage === 'login'    && <LoginScreen users={users} login={login} createUser={createUser} />}
      {stage === 'locked'   && <LockScreen user={currentUser} unlock={unlock} logout={logout} />}
      {stage === 'desktop'  && children}
    </AuthContext.Provider>
  );
}

export function useAuth() { return useContext(AuthContext); }

function LoadingScreen() {
  return (
    <div style={FULL}>
      <div style={{ textAlign: 'center' }}>
        <div style={{ fontSize: 64, marginBottom: 16 }}>🐻</div>
        <div style={{ fontSize: 18, fontWeight: 500, color: '#c084fc', marginBottom: 8 }}>Teddy OS</div>
        <div style={{ fontSize: 12, color: '#6b6085' }}>Starting up...</div>
      </div>
    </div>
  );
}

function SetupScreen({ createUser, onDone }) {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [confirm, setConfirm] = useState('');
  const [avatar, setAvatar] = useState('🐻');
  const [error, setError] = useState('');
  const [step, setStep] = useState(1);
  const AVATARS = ['🐻', '🦁', '🐯', '🦊', '🐼', '🐨', '🦋', '🌟', '🚀', '💎'];

  async function submit() {
    if (password !== confirm) { setError('Passwords do not match'); return; }
    if (password.length < 4) { setError('Password must be at least 4 characters'); return; }
    const res = await createUser(username.trim(), password, avatar);
    if (res.error) { setError(res.error); return; }
    onDone();
  }

  return (
    <div style={FULL}>
      <div style={CARD}>
        <div style={{ textAlign: 'center', marginBottom: 28 }}>
          <div style={{ fontSize: 48 }}>{avatar}</div>
          <div style={{ fontSize: 20, fontWeight: 500, color: '#c084fc', marginTop: 8 }}>Welcome to Teddy OS</div>
          <div style={{ fontSize: 12, color: '#6b6085', marginTop: 4 }}>Built by Bryt Ma Tech Uganda</div>
          <div style={{ fontSize: 12, color: '#a89ec8', marginTop: 8 }}>Create your account to get started</div>
        </div>
        {step === 1 && (
          <>
            <div style={{ marginBottom: 12 }}>
              <div style={LABEL}>Choose your avatar</div>
              <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', marginTop: 6 }}>
                {AVATARS.map(a => (
                  <button key={a} onClick={() => setAvatar(a)} style={{ fontSize: 22, padding: '6px 10px', borderRadius: 8, border: `1.5px solid ${a === avatar ? '#a855f7' : 'rgba(255,255,255,0.1)'}`, background: a === avatar ? 'rgba(168,85,247,0.15)' : 'transparent', cursor: 'pointer' }}>{a}</button>
                ))}
              </div>
            </div>
            <div style={{ marginBottom: 12 }}>
              <div style={LABEL}>Username</div>
              <input value={username} onChange={e => setUsername(e.target.value)} placeholder="e.g. leka" style={INPUT} onKeyDown={e => e.key === 'Enter' && setStep(2)} autoFocus />
            </div>
            <button onClick={() => { if (!username.trim()) { setError('Enter a username'); return; } setError(''); setStep(2); }} style={BTN}>Continue →</button>
          </>
        )}
        {step === 2 && (
          <>
            <div style={{ marginBottom: 12 }}>
              <div style={LABEL}>Password</div>
              <input type="password" value={password} onChange={e => setPassword(e.target.value)} placeholder="Min 4 characters" style={INPUT} autoFocus />
            </div>
            <div style={{ marginBottom: 16 }}>
              <div style={LABEL}>Confirm password</div>
              <input type="password" value={confirm} onChange={e => setConfirm(e.target.value)} placeholder="Repeat password" style={INPUT} onKeyDown={e => e.key === 'Enter' && submit()} />
            </div>
            {error && <div style={ERR}>{error}</div>}
            <div style={{ display: 'flex', gap: 8 }}>
              <button onClick={() => setStep(1)} style={{ ...BTN, background: 'rgba(255,255,255,0.06)', flex: '0 0 auto', width: 80 }}>← Back</button>
              <button onClick={submit} style={{ ...BTN, flex: 1 }}>Create account</button>
            </div>
          </>
        )}
        {step === 1 && error && <div style={{ ...ERR, marginTop: 8 }}>{error}</div>}
      </div>
    </div>
  );
}

function LoginScreen({ users, login, createUser }) {
  const [selected, setSelected] = useState(users[0]?.username || '');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [adding, setAdding] = useState(false);
  const [newUser, setNewUser] = useState('');
  const [newPass, setNewPass] = useState('');
  const [newAvatar, setNewAvatar] = useState('🦁');
  const AVATARS = ['🐻', '🦁', '🐯', '🦊', '🐼', '🐨', '🦋', '🌟', '🚀', '💎'];

  async function doLogin() {
    const res = await login(selected, password);
    if (res.error) { setError(res.error); setPassword(''); }
  }
  async function doAdd() {
    if (!newUser.trim() || !newPass.trim()) { setError('Fill in all fields'); return; }
    const res = await createUser(newUser.trim(), newPass, newAvatar);
    if (res.error) { setError(res.error); return; }
    setAdding(false); setError('');
  }

  const selUser = users.find(u => u.username === selected);

  return (
    <div style={FULL}>
      <div style={{ ...CARD, minWidth: 340 }}>
        <div style={{ textAlign: 'center', marginBottom: 24 }}>
          <div style={{ fontSize: 52 }}>{selUser?.avatar || '🐻'}</div>
          <div style={{ fontSize: 18, fontWeight: 500, color: '#f0eeff', marginTop: 8 }}>{selected || 'Teddy OS'}</div>
          <div style={{ fontSize: 11, color: '#6b6085', marginTop: 2 }}>Teddy OS · Bryt Ma Tech Uganda</div>
        </div>
        {users.length > 1 && (
          <div style={{ display: 'flex', gap: 8, marginBottom: 16, justifyContent: 'center', flexWrap: 'wrap' }}>
            {users.map(u => (
              <button key={u.username} onClick={() => { setSelected(u.username); setPassword(''); setError(''); }} style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4, padding: '8px 12px', borderRadius: 8, border: `1.5px solid ${u.username === selected ? '#a855f7' : 'rgba(255,255,255,0.1)'}`, background: u.username === selected ? 'rgba(168,85,247,0.15)' : 'transparent', cursor: 'pointer' }}>
                <span style={{ fontSize: 20 }}>{u.avatar}</span>
                <span style={{ fontSize: 10, color: '#a89ec8' }}>{u.username}</span>
              </button>
            ))}
          </div>
        )}
        {!adding ? (
          <>
            <input type="password" value={password} onChange={e => setPassword(e.target.value)} placeholder="Enter password" style={INPUT} onKeyDown={e => e.key === 'Enter' && doLogin()} autoFocus />
            {error && <div style={ERR}>{error}</div>}
            <button onClick={doLogin} style={{ ...BTN, marginTop: 12 }}>Sign in</button>
            <button onClick={() => { setAdding(true); setError(''); }} style={{ marginTop: 8, width: '100%', padding: '8px', borderRadius: 8, background: 'transparent', border: '0.5px solid rgba(255,255,255,0.1)', color: '#6b6085', cursor: 'pointer', fontSize: 12 }}>+ Add another user</button>
          </>
        ) : (
          <>
            <div style={LABEL}>New username</div>
            <input value={newUser} onChange={e => setNewUser(e.target.value)} placeholder="Username" style={{ ...INPUT, marginBottom: 8 }} autoFocus />
            <div style={LABEL}>Password</div>
            <input type="password" value={newPass} onChange={e => setNewPass(e.target.value)} placeholder="Password" style={{ ...INPUT, marginBottom: 8 }} />
            <div style={LABEL}>Avatar</div>
            <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', marginBottom: 12 }}>
              {AVATARS.map(a => <button key={a} onClick={() => setNewAvatar(a)} style={{ fontSize: 18, padding: '4px 8px', borderRadius: 6, border: `1.5px solid ${a === newAvatar ? '#a855f7' : 'rgba(255,255,255,0.1)'}`, background: a === newAvatar ? 'rgba(168,85,247,0.15)' : 'transparent', cursor: 'pointer' }}>{a}</button>)}
            </div>
            {error && <div style={ERR}>{error}</div>}
            <div style={{ display: 'flex', gap: 8 }}>
              <button onClick={() => { setAdding(false); setError(''); }} style={{ ...BTN, background: 'rgba(255,255,255,0.06)', flex: '0 0 auto', width: 80 }}>Cancel</button>
              <button onClick={doAdd} style={{ ...BTN, flex: 1 }}>Create user</button>
            </div>
          </>
        )}
      </div>
    </div>
  );
}

function LockScreen({ user, unlock, logout }) {
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [time, setTime] = useState(new Date());
  React.useEffect(() => { const t = setInterval(() => setTime(new Date()), 1000); return () => clearInterval(t); }, []);
  function doUnlock() { if (!unlock(password)) { setError('Incorrect password'); setPassword(''); } }

  return (
    <div style={{ ...FULL, backdropFilter: 'blur(20px)' }}>
      <div style={{ textAlign: 'center', marginBottom: 32 }}>
        <div style={{ fontSize: 52, color: '#f0eeff', fontWeight: 200, fontFamily: 'var(--font-mono)' }}>{time.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}</div>
        <div style={{ fontSize: 14, color: '#6b6085', marginTop: 4 }}>{time.toLocaleDateString([], { weekday: 'long', month: 'long', day: 'numeric' })}</div>
      </div>
      <div style={{ ...CARD, width: 300 }}>
        <div style={{ textAlign: 'center', marginBottom: 20 }}>
          <div style={{ fontSize: 44 }}>{user?.avatar || '🐻'}</div>
          <div style={{ fontSize: 15, fontWeight: 500, color: '#f0eeff', marginTop: 8 }}>{user?.username}</div>
        </div>
        <input type="password" value={password} onChange={e => setPassword(e.target.value)} placeholder="Enter password to unlock" style={INPUT} onKeyDown={e => e.key === 'Enter' && doUnlock()} autoFocus />
        {error && <div style={ERR}>{error}</div>}
        <button onClick={doUnlock} style={{ ...BTN, marginTop: 12 }}>🔓 Unlock</button>
        <button onClick={logout} style={{ marginTop: 8, width: '100%', padding: '7px', borderRadius: 8, background: 'transparent', border: 'none', color: '#6b6085', cursor: 'pointer', fontSize: 12 }}>Switch user</button>
      </div>
    </div>
  );
}

const FULL = { position: 'fixed', inset: 0, background: 'radial-gradient(ellipse at 30% 40%, rgba(168,85,247,0.12) 0%, transparent 60%), #0a0614', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 10000, fontFamily: 'var(--font-sans, sans-serif)' };
const CARD = { background: 'rgba(22,18,42,0.95)', border: '0.5px solid rgba(255,255,255,0.1)', borderRadius: 16, padding: '28px 28px 24px', width: 360, boxShadow: '0 16px 60px rgba(0,0,0,0.6)' };
const INPUT = { width: '100%', padding: '10px 12px', borderRadius: 8, border: '0.5px solid rgba(255,255,255,0.12)', background: 'rgba(255,255,255,0.04)', color: '#f0eeff', fontSize: 13, outline: 'none' };
const BTN = { width: '100%', padding: '10px', borderRadius: 8, background: '#a855f7', border: 'none', color: 'white', fontSize: 13, fontWeight: 500, cursor: 'pointer' };
const LABEL = { fontSize: 11, color: '#6b6085', marginBottom: 4, fontWeight: 500, textTransform: 'uppercase', letterSpacing: '0.4px' };
const ERR = { fontSize: 11, color: '#f87171', marginTop: 6, padding: '6px 10px', borderRadius: 6, background: 'rgba(248,113,113,0.1)', border: '0.5px solid rgba(248,113,113,0.2)' };
