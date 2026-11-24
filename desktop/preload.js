// Preload script running in an isolated context
const { contextBridge, ipcRenderer } = require('electron');

// Expose safe, selected desktop APIs to the renderer window
contextBridge.exposeInMainWorld('desktopAPI', {
  platform: process.platform,
  version: process.versions.electron,
  appVersion: '1.0.0',
  send: (channel, data) => {
    const validChannels = ['toMain'];
    if (validChannels.includes(channel)) {
      ipcRenderer.send(channel, data);
    }
  },
  receive: (channel, func) => {
    const validChannels = ['fromMain'];
    if (validChannels.includes(channel)) {
      ipcRenderer.on(channel, (event, ...args) => func(...args));
    }
  }
});
