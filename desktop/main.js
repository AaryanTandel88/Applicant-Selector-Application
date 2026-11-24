const { app, BrowserWindow, shell, Menu } = require('electron');
const path = require('path');

// Remote URL or fallback to local port if running locally
const APP_URL = process.env.APP_URL || 'https://applicant-selector-application.onrender.com/';
const ALLOWED_HOST = new URL(APP_URL).host;

let mainWindow = null;

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 1440,
    height: 960,
    minWidth: 1000,
    minHeight: 700,
    title: 'Applicant Selector',
    show: false, // Don't show until ready-to-show to prevent white flicker
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      nodeIntegration: false,
      contextIsolation: true,
      sandbox: true,
      spellcheck: true
    }
  });

  // Load the web application
  mainWindow.loadURL(APP_URL);

  mainWindow.once('ready-to-show', () => {
    mainWindow.show();
  });

  // Restrict navigation to allowed origin (matches original Swift WKNavigationAction logic)
  mainWindow.webContents.on('will-navigate', (event, targetUrl) => {
    try {
      const parsedUrl = new URL(targetUrl);
      if (parsedUrl.host !== ALLOWED_HOST && parsedUrl.protocol !== 'devtools:') {
        event.preventDefault();
        shell.openExternal(targetUrl); // Open external links in default OS browser
      }
    } catch {
      event.preventDefault();
    }
  });

  // Prevent creation of unauthorized new windows (e.g. window.open)
  mainWindow.webContents.setWindowOpenHandler(({ url }) => {
    try {
      const parsedUrl = new URL(url);
      if (parsedUrl.host === ALLOWED_HOST) {
        return { action: 'allow' };
      }
    } catch { }
    shell.openExternal(url);
    return { action: 'deny' };
  });

  mainWindow.on('closed', () => {
    mainWindow = null;
  });
}

// App lifecycle
app.whenReady().then(() => {
  createWindow();

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) {
      createWindow();
    }
  });
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit();
  } else {
    app.quit();
  }
});
