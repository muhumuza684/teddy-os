const { app, BrowserWindow, ipcMain } = require('electron');
const http = require('http');
const path = require('path');
require('../../desktop/electron/system-ipc.js').register(ipcMain);
const srv = http.createServer((q, r) => { r.setHeader('content-type','text/html'); r.end(`<title>Page ${q.url}</title><h1>hi</h1>`); }).listen(0, '127.0.0.1');
app.commandLine.appendSwitch('no-sandbox');
app.whenReady().then(async () => {
  const port = srv.address().port;
  const win = new BrowserWindow({ show: false, webPreferences: { webviewTag: true, contextIsolation: false, nodeIntegration: true } });
  await win.loadURL('data:text/html,<body></body>');
  const result = await win.webContents.executeJavaScript(`new Promise((resolve) => {
    const out = {}; const w = document.createElement('webview');
    w.src = 'http://127.0.0.1:${port}/a'; document.body.appendChild(w);
    w.addEventListener('did-stop-loading', () => {
      if (!out.first) { out.first = { url: w.getURL(), title: w.getTitle(), canGoBack: w.canGoBack() }; w.loadURL('http://127.0.0.1:${port}/b'); return; }
      if (!out.second) { out.second = { url: w.getURL(), title: w.getTitle(), canGoBack: w.canGoBack() }; w.goBack(); return; }
      out.back = { url: w.getURL(), canGoForward: w.canGoForward() }; resolve(out);
    });
    setTimeout(() => resolve({ timeout: true, out }), 20000);
  })`);
  const ipc = await win.webContents.executeJavaScript(`require('electron').ipcRenderer.invoke('software:check','wine')`);
  console.log('RESULT ' + JSON.stringify({ result, ipc }));
  app.exit(0);
});
