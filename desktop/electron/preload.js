const { contextBridge, ipcRenderer } = require('electron');
contextBridge.exposeInMainWorld('electronAPI', {
  openFile: () => ipcRenderer.invoke('dialog:openFile'),
  saveFile: (content, name) => ipcRenderer.invoke('dialog:saveFile', content, name),
  notify: (title, body) => ipcRenderer.invoke('os:notify', { title, body }),
  isElectron: true,
});
