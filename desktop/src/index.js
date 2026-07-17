import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';
import { AuthProvider } from './components/Auth';
import { NotifProvider } from './components/Notifications';
import './index.css';

if ('serviceWorker' in navigator) {
  window.addEventListener('load', () => {
    navigator.serviceWorker.register('/sw.js').catch(() => {});
  });
}

const root = ReactDOM.createRoot(document.getElementById('root'));
root.render(
  <React.StrictMode>
    <NotifProvider>
      <AuthProvider>
        <App />
      </AuthProvider>
    </NotifProvider>
  </React.StrictMode>
);
