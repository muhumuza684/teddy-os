import React, { useRef, useCallback } from 'react';

const WIN_STYLE = { position: 'absolute', background: 'var(--bg-surface)', border: '0.5px solid var(--border-strong)', borderRadius: 'var(--radius-lg)', boxShadow: 'var(--shadow)', display: 'flex', flexDirection: 'column', overflow: 'hidden', minWidth: 280, minHeight: 200 };
const TITLE_STYLE = { height: 36, background: 'var(--bg-raised)', borderBottom: '0.5px solid var(--border)', display: 'flex', alignItems: 'center', padding: '0 12px', gap: 8, flexShrink: 0, cursor: 'grab', userSelect: 'none' };

export default function Window({ id, title, icon, x, y, w, h, zIndex, onClose, onMinimize, onFocus, onMove, onResize, children }) {
  const dragRef = useRef(null);

  const onMouseDown = useCallback((e) => {
    if (e.target.closest('button')) return;
    onFocus(id);
    const startX = e.clientX - x;
    const startY = e.clientY - y;
    const onMove_ = (ev) => onMove(id, ev.clientX - startX, ev.clientY - startY);
    const onUp = () => { document.removeEventListener('mousemove', onMove_); document.removeEventListener('mouseup', onUp); };
    document.addEventListener('mousemove', onMove_);
    document.addEventListener('mouseup', onUp);
  }, [id, x, y, onFocus, onMove]);

  return (
    <div style={{ ...WIN_STYLE, left: x, top: y, width: w, height: h, zIndex }} onMouseDown={() => onFocus(id)}>
      <div style={TITLE_STYLE} ref={dragRef} onMouseDown={onMouseDown}>
        <div style={{ display: 'flex', gap: 6 }}>
          <button onClick={() => onClose(id)} style={DOT('#ff5f57')} title="Close" />
          <button onClick={() => onMinimize(id)} style={DOT('#febc2e')} title="Minimize" />
          <button style={DOT('#28c840')} title="Maximize" />
        </div>
        {icon && <span style={{ fontSize: 14 }}>{icon}</span>}
        <span style={{ fontSize: 13, fontWeight: 500, color: 'var(--text-primary)', flex: 1, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{title}</span>
      </div>
      <div style={{ flex: 1, overflow: 'hidden', display: 'flex', flexDirection: 'column' }}>{children}</div>
      <ResizeHandle id={id} onResize={onResize} w={w} h={h} />
    </div>
  );
}

function ResizeHandle({ id, onResize, w, h }) {
  const onMouseDown = (e) => {
    e.stopPropagation();
    const startX = e.clientX, startY = e.clientY, startW = w, startH = h;
    const onMove = (ev) => onResize(id, Math.max(280, startW + ev.clientX - startX), Math.max(200, startH + ev.clientY - startY));
    const onUp = () => { document.removeEventListener('mousemove', onMove); document.removeEventListener('mouseup', onUp); };
    document.addEventListener('mousemove', onMove);
    document.addEventListener('mouseup', onUp);
  };
  return (
    <div onMouseDown={onMouseDown} style={{ position: 'absolute', right: 0, bottom: 0, width: 16, height: 16, cursor: 'se-resize', zIndex: 10 }}>
      <svg width="10" height="10" style={{ position: 'absolute', right: 3, bottom: 3 }}>
        <path d="M9 1 L1 9 M9 5 L5 9 M9 9 L9 9" stroke="var(--border-strong)" strokeWidth="1.5" strokeLinecap="round" />
      </svg>
    </div>
  );
}

function DOT(color) { return { width: 12, height: 12, borderRadius: '50%', background: color, border: 'none', cursor: 'pointer', flexShrink: 0 }; }
