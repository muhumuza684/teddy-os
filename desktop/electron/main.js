const { app, BrowserWindow, Menu, shell, ipcMain, dialog, Notification } = require('electron');
const path = require('path');
const isDev = !app.isPackaged;
let mainWindow;

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 1280, height: 800, minWidth: 900, minHeight: 600,
    title: 'Teddy OS',
    icon: path.join(__dirname, '../public/icons/icon.png'),
    webPreferences: { nodeIntegration: false, contextIsolation: true, preload: path.join(__dirname, 'preload.js') },
    backgroundColor: '#0f0c1a', show: false,
  });
  mainWindow.loadURL(isDev ? 'http://localhost:3000' : `file://${path.join(__dirname, '../build/index.html')}`);
  mainWindow.once('ready-to-show', () => { mainWindow.show(); if (isDev) mainWindow.webContents.openDevTools(); });
  mainWindow.on('closed', () => { mainWindow = null; });
}

function buildMenu() {
  Menu.setApplicationMenu(Menu.buildFromTemplate([
    { label: 'Teddy OS', submenu: [
      { label: 'About Teddy OS', click: () => dialog.showMessageBox(mainWindow, { title: 'Teddy OS', message: 'Teddy OS v1.0\nBuilt by Bryt Ma Tech Uganda\n🐻', buttons: ['OK'] }) },
      { type: 'separator' },
      { label: 'Quit', accelerator: 'CmdOrCtrl+Q', click: () => app.quit() },
    ]},
    { label: 'Edit', submenu: [{ role: 'undo' },{ role: 'redo' },{ type: 'separator' },{ role: 'cut' },{ role: 'copy' },{ role: 'paste' },{ role: 'selectAll' }] },
    { label: 'View', submenu: [{ role: 'reload' },{ type: 'separator' },{ role: 'togglefullscreen' },{ role: 'zoomIn' },{ role: 'zoomOut' },{ role: 'resetZoom' }] },
    { label: 'Help', submenu: [{ label: 'GitHub', click: () => shell.openExternal('https://github.com/YOUR_USERNAME/teddy-os') }] },
  ]));
}

app.whenReady().then(() => { createWindow(); buildMenu(); app.on('activate', () => { if (BrowserWindow.getAllWindows().length === 0) createWindow(); }); });
app.on('window-all-closed', () => { if (process.platform !== 'darwin') app.quit(); });
ipcMain.handle('dialog:openFile', async () => dialog.showOpenDialog(mainWindow, { properties: ['openFile'], filters: [{ name: 'Documents', extensions: ['txt','html','md'] }] }));
ipcMain.handle('dialog:saveFile', async (_, content, name='document') => {
  const r = await dialog.showSaveDialog(mainWindow, { defaultPath: name, filters: [{ name: 'HTML', extensions: ['html'] },{ name: 'Text', extensions: ['txt'] }] });
  if (!r.canceled && r.filePath) { require('fs').writeFileSync(r.filePath, content, 'utf8'); return r.filePath; }
  return null;
});
ipcMain.handle('os:notify', (_, { title, body }) => {
  if (Notification.isSupported()) new Notification({ title, body }).show();
});
