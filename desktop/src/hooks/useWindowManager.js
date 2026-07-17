import { useState, useCallback } from 'react';

const DEFAULT_POSITIONS = {
  editor: { x: 60, y: 50, w: 720, h: 580 },
  ai:     { x: 800, y: 50, w: 320, h: 580 },
  files:  { x: 80, y: 60, w: 800, h: 520 },
  calc:   { x: 100, y: 80, w: 300, h: 440 },
  calendar: { x: 120, y: 60, w: 420, h: 520 },
  terminal: { x: 80, y: 100, w: 680, h: 420 },
  settings: { x: 150, y: 80, w: 520, h: 500 },
};

export function useWindowManager() {
  const [windows, setWindows] = useState({});
  const [zOrder, setZOrder] = useState([]);

  const openApp = useCallback((id) => {
    setWindows((prev) => ({
      ...prev,
      [id]: prev[id] ? { ...prev[id], minimized: false } : { ...DEFAULT_POSITIONS[id], minimized: false },
    }));
    setZOrder((prev) => [...prev.filter((z) => z !== id), id]);
  }, []);

  const closeApp = useCallback((id) => {
    setWindows((prev) => { const n = { ...prev }; delete n[id]; return n; });
    setZOrder((prev) => prev.filter((z) => z !== id));
  }, []);

  const minimizeApp = useCallback((id) => {
    setWindows((prev) => ({ ...prev, [id]: { ...prev[id], minimized: true } }));
  }, []);

  const focusApp = useCallback((id) => {
    setZOrder((prev) => [...prev.filter((z) => z !== id), id]);
  }, []);

  const moveApp = useCallback((id, x, y) => {
    setWindows((prev) => ({ ...prev, [id]: { ...prev[id], x, y } }));
  }, []);

  const resizeApp = useCallback((id, w, h) => {
    setWindows((prev) => ({ ...prev, [id]: { ...prev[id], w, h } }));
  }, []);

  const getZ = useCallback((id) => (zOrder.indexOf(id) + 1) * 10, [zOrder]);

  return { windows, openApp, closeApp, minimizeApp, focusApp, moveApp, resizeApp, getZ };
}
