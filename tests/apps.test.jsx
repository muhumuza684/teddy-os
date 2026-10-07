import React from 'react';
import { render, screen, fireEvent, act, waitFor, cleanup } from '@testing-library/react';
import { vi, describe, it, expect, beforeEach, afterEach } from 'vitest';
import Clock from './src/apps/Clock.jsx';
import SoftwareCenter from './src/apps/SoftwareCenter.jsx';
import Browser from './src/apps/Browser.jsx';
import Settings from './src/apps/Settings.jsx';
import { NotifProvider } from './src/components/Notifications.jsx';

afterEach(() => { cleanup(); vi.useRealTimers(); delete window.electronAPI; localStorage.clear(); });
const renderClock = () => render(<NotifProvider><Clock /></NotifProvider>);

describe('Clock', () => {
  it('World clock shows 4 cities', () => {
    renderClock();
    ['Kampala', 'London', 'New York', 'Tokyo'].forEach((c) => expect(screen.getByText(c)).toBeTruthy());
  });
  it('Alarm fires a notification at the set time', () => {
    vi.useFakeTimers(); vi.setSystemTime(new Date(2026, 9, 2, 6, 59, 58));
    window.electronAPI = { notify: vi.fn() };
    renderClock();
    fireEvent.click(screen.getByText('Alarm'));
    fireEvent.change(document.querySelector('input[type=time]'), { target: { value: '07:00' } });
    fireEvent.click(screen.getByText('Add'));
    act(() => { vi.advanceTimersByTime(3000); });
    expect(screen.getAllByText('Alarm').length).toBeGreaterThan(1);       // toast from the real NotifProvider (tab button + toast)
    expect(window.electronAPI.notify).toHaveBeenCalledTimes(1);           // real desktop notification too
    act(() => { vi.advanceTimersByTime(5000); });
    expect(window.electronAPI.notify).toHaveBeenCalledTimes(1);           // fires once per minute only
  });
  it('Timer counts down and notifies', () => {
    vi.useFakeTimers();
    renderClock();
    fireEvent.click(screen.getByText('Timer'));
    fireEvent.change(document.querySelector('input[type=number]'), { target: { value: '1' } });
    fireEvent.click(screen.getByText('Start'));
    act(() => { vi.advanceTimersByTime(30000); });
    expect(screen.getByText('00:30')).toBeTruthy();
    act(() => { vi.advanceTimersByTime(31000); });
    expect(screen.getByText('Time is up')).toBeTruthy();
  });
  it('Stopwatch runs, laps, resets', () => {
    vi.useFakeTimers();
    renderClock();
    fireEvent.click(screen.getByText('Stopwatch'));
    fireEvent.click(screen.getByText('Start'));
    act(() => { vi.advanceTimersByTime(1500); });
    fireEvent.click(screen.getByText('Lap'));
    expect(screen.getByText(/Lap 1:/)).toBeTruthy();
    fireEvent.click(screen.getByText('Stop'));
    fireEvent.click(screen.getByText('Reset'));
    expect(screen.getByText('00:00.00')).toBeTruthy();
    expect(screen.queryByText(/Lap 1:/)).toBeNull();
  });
});

describe('SoftwareCenter', () => {
  const mk = (installed = {}) => {
    let cb; const calls = [];
    window.electronAPI = {
      softwareCheck: vi.fn(async (id) => ({ id, installed: !!installed[id] })),
      softwareInstall: vi.fn(async (id) => { cb?.({ id, line: `Setting up ${id}\n` }); installed[id] = true; return { ok: true }; }),
      onSoftwareProgress: (f) => { cb = f; return () => {}; },
    };
    return calls;
  };
  it('lists all 6 catalog apps with live status', async () => {
    mk({ vlc: true }); render(<SoftwareCenter />);
    await waitFor(() => expect(screen.getByText('Installed')).toBeTruthy());
    ['Wine', 'Docker', 'GIMP', 'VLC', 'Codium'].forEach((n) => expect(screen.getByText(n)).toBeTruthy());
    expect(screen.getAllByText('Install').length).toBe(5);
  });
  it('installs, streams output, refreshes status', async () => {
    mk(); render(<SoftwareCenter />);
    await waitFor(() => expect(screen.getAllByText('Install').length).toBe(6));
    fireEvent.click(screen.getAllByText('Install')[0]);
    await waitFor(() => expect(screen.getByText(/Setting up wine/)).toBeTruthy());
    await waitFor(() => expect(screen.getAllByText('Installed').length).toBe(1));
  });
  it('shows failure message', async () => {
    mk(); window.electronAPI.softwareInstall = vi.fn(async () => ({ ok: false, code: 100 }));
    render(<SoftwareCenter />);
    await waitFor(() => expect(screen.getAllByText('Install').length).toBe(6));
    fireEvent.click(screen.getAllByText('Install')[0]);
    await waitFor(() => expect(screen.getByText(/Install failed \(exit 100\)/)).toBeTruthy());
  });
  it('degrades gracefully without the bridge', () => {
    render(<SoftwareCenter />);
    expect(screen.getByText(/system bridge not found/)).toBeTruthy();
  });
});

describe('Browser', () => {
  it('normalizes input, navigates, and tracks back/forward + loading', () => {
    const { container } = render(<Browser />);
    const wv = container.querySelector('webview');
    const loaded = []; Object.assign(wv, {
      loadURL: (u) => loaded.push(u), canGoBack: () => true, canGoForward: () => false,
      getTitle: () => 'T', reload: vi.fn(), stop: vi.fn(), goBack: vi.fn(), goForward: vi.fn(),
    });
    const input = screen.getByPlaceholderText(/Search or enter/);
    fireEvent.change(input, { target: { value: 'example.com' } });
    fireEvent.submit(input.closest('form'));
    expect(loaded.pop()).toBe('https://example.com');
    fireEvent.change(input, { target: { value: 'hello world' } });
    fireEvent.submit(input.closest('form'));
    expect(loaded.pop()).toBe('https://duckduckgo.com/?q=hello%20world');
    act(() => { wv.dispatchEvent(new Event('did-start-loading')); });
    expect(screen.getByText('✕')).toBeTruthy();
    act(() => { wv.dispatchEvent(new Event('did-stop-loading')); });
    expect(screen.getByText('⟳')).toBeTruthy();
    expect(screen.getByText('←').disabled).toBe(false);
    expect(screen.getByText('→').disabled).toBe(true);
    const ev = new Event('did-navigate'); ev.url = 'https://a.org/'; act(() => { wv.dispatchEvent(ev); });
    expect(input.value).toBe('https://a.org/');
    fireEvent.click(screen.getByText('←')); expect(wv.goBack).toHaveBeenCalled();
  });
});

describe('Settings: Security + Devices', () => {
  const props = { settings: { spellCheck: true, autosave: true }, onUpdate: () => {}, currentUser: { username: 'u', role: 'admin', avatar: '🐻' }, onLock: () => {}, onLogout: () => {} };
  it('shows why fingerprint is unavailable and disables enroll', async () => {
    window.electronAPI = { fprintdList: vi.fn(async () => ({ available: false, reason: 'No fingerprint reader found' })) };
    render(<Settings {...props} />);
    await waitFor(() => expect(screen.getByText('No fingerprint reader found')).toBeTruthy());
    expect(screen.getByText('Enroll finger').disabled).toBe(true);
  });
  it('enrolls when a reader exists', async () => {
    window.electronAPI = { fprintdList: async () => ({ available: true }), fprintdEnroll: vi.fn(async () => ({ ok: true })) };
    window.alert = vi.fn();
    render(<Settings {...props} />);
    await waitFor(() => expect(screen.getByText('Reader found')).toBeTruthy());
    fireEvent.click(screen.getByText('Enroll finger'));
    await waitFor(() => expect(window.electronAPI.fprintdEnroll).toHaveBeenCalled());
  });
  it('Save & apply persists to localStorage and calls xset bridge', async () => {
    window.electronAPI = { fprintdList: async () => ({ available: false, reason: 'x' }),
      setKeyRepeat: vi.fn(async () => ({ ok: true })), setPointerAccel: vi.fn(async () => ({ ok: true })) };
    render(<Settings {...props} />);
    fireEvent.click(screen.getByText('Save & apply'));
    await waitFor(() => expect(screen.getByText(/Re-applied automatically at every login/)).toBeTruthy());
    expect(window.electronAPI.setKeyRepeat).toHaveBeenCalledWith(500, 30);
    expect(window.electronAPI.setPointerAccel).toHaveBeenCalledWith(2, 4);
    expect(JSON.parse(localStorage.getItem('teddy:input'))).toEqual({ keyDelay: 500, keyRate: 30, ptrAccel: 2, ptrThreshold: 4 });
  });
  it('works outside Electron (no bridge) without crashing', () => {
    render(<Settings {...props} />);
    expect(screen.getByText('Security')).toBeTruthy();
  });
});
