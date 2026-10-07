const { contextBridge, ipcRenderer } = require('electron');
contextBridge.exposeInMainWorld('electronAPI', {
  openFile: () => ipcRenderer.invoke('dialog:openFile'),
  saveFile: (content, name) => ipcRenderer.invoke('dialog:saveFile', content, name),
  notify: (title, body) => ipcRenderer.invoke('os:notify', { title, body }),
  isElectron: true,
  // --- Teddy OS system bridge (Software Center, fingerprint, keyboard/mouse) ---
  softwareCheck: (id) => ipcRenderer.invoke('software:check', id),
  softwareInstall: (id) => ipcRenderer.invoke('software:install', id),
  onSoftwareProgress: (cb) => {
    const f = (_e, d) => cb(d);
    ipcRenderer.on('software:progress', f);
    return () => ipcRenderer.removeListener('software:progress', f);
  },
  fprintdList: () => ipcRenderer.invoke('fprintd:list'),
  fprintdEnroll: (finger) => ipcRenderer.invoke('fprintd:enroll', finger),
  setKeyRepeat: (delay, rate) => ipcRenderer.invoke('input:setKeyRepeat', delay, rate),
  setPointerAccel: (accel, threshold) => ipcRenderer.invoke('input:setPointerAccel', accel, threshold),
});
