import React from 'react';

export const MODE_META = {
  simple: {
    label: 'Simple Mode',
    icon: '🌱',
    color: '#79d89b',
    summary: 'Calm, clear, and focused on everyday tasks.',
    actions: ['Files', 'Write', 'Internet', 'Photos', 'Settings', 'Help'],
  },
  advanced: {
    label: 'Advanced Mode',
    icon: '🛠️',
    color: '#c084fc',
    summary: 'Detailed tools for experienced users and administrators.',
    actions: ['Editor', 'Files', 'Calculator', 'Calendar', 'Terminal', 'Settings'],
  },
  care: {
    label: 'Care Mode',
    icon: '🤝',
    color: '#f4c978',
    summary: 'Larger controls, extra guidance, and accessibility support.',
    actions: ['Files', 'Write', 'Settings', 'Help'],
  },
};

export const MODE_APPS = {
  simple: ['editor', 'files', 'browser', 'calc', 'clock', 'store', 'settings'],
  advanced: ['editor', 'files', 'browser', 'calc', 'calendar', 'clock', 'terminal', 'ai', 'store', 'settings'],
  care: ['editor', 'files', 'browser', 'clock', 'settings'], // no Store: reduced distractions
};

export default function ModeCenter({ mode, onChange, onClose }) {
  return (
    <div className="mode-center" role="dialog" aria-modal="true" aria-labelledby="mode-center-title">
      <div className="mode-center-header">
        <div>
          <div className="eyebrow">Personalize Teddy</div>
          <h2 id="mode-center-title">Choose how Teddy feels</h2>
          <p>All modes use the same files and safety rules. Only the experience changes.</p>
        </div>
        <button className="mode-close" onClick={onClose} aria-label="Close mode chooser">×</button>
      </div>
      <div className="mode-grid">
        {Object.entries(MODE_META).map(([id, meta]) => (
          <button
            key={id}
            className={`mode-card ${mode === id ? 'selected' : ''}`}
            style={{ '--mode-color': meta.color }}
            onClick={() => onChange(id)}
            aria-pressed={mode === id}
          >
            <span className="mode-card-icon" aria-hidden="true">{meta.icon}</span>
            <span className="mode-card-title">{meta.label}</span>
            <span className="mode-card-summary">{meta.summary}</span>
            <span className="mode-card-actions">{meta.actions.join(' · ')}</span>
            {mode === id && <span className="mode-active">Active</span>}
          </button>
        ))}
      </div>
      <div className="mode-safety-note"><strong>Safe in every mode.</strong> Switching modes never changes file permissions or administrator access.</div>
    </div>
  );
}

export function CareWelcome({ onOpenModes }) {
  return (
    <div className="care-welcome" role="status">
      <div className="care-bear" aria-hidden="true">🐻</div>
      <div>
        <strong>Teddy is ready to help.</strong>
        <p>Choose Files, Write, or Settings. You can change the size and guidance level anytime.</p>
      </div>
      <button onClick={onOpenModes}>Change mode</button>
    </div>
  );
}

export function SimpleWelcome({ onOpenModes }) {
  return (
    <div className="simple-welcome">
      <div>
        <div className="eyebrow">Teddy OS v2</div>
        <h1>What would you like to do?</h1>
        <p>Simple tools, clear steps, and your files protected.</p>
      </div>
      <button onClick={onOpenModes}>Choose mode</button>
    </div>
  );
}
