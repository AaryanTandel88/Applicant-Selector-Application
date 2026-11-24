# Applicant Selector — Desktop Application (Electron)

This desktop client wraps the **RAC DRDO Applicant Selector Application** using Electron JS, replacing the macOS-only Swift/AppKit implementation with a cross-platform desktop wrapper.

---

## 🚀 Features
- **Cross-Platform**: Runs on macOS, Windows, and Linux.
- **Window Specs**: Default dimensions 1440×960 with a minimum size of 1000×700 (matching the original Swift window specifications).
- **Navigation Security**: Restricts in-app navigation strictly to the official application domain (`applicant-selector-application.onrender.com`), opening any external links safely in the default system browser.
- **Process Isolation**: Built following Electron security best practices (`contextIsolation: true`, `nodeIntegration: false`, sandboxed renderer).

---

## 🛠️ Setup & Running

From the `desktop` directory:

```bash
# 1. Install Electron dependencies
npm install

# 2. Run the desktop app locally
npm start
```

### Running with a Local Server
By default, the desktop client connects to the hosted Render server. To point it to a local backend development server:

```bash
APP_URL=http://localhost:5000 npm start
```

---

## 📦 Building Distributables

```bash
# Build macOS (.dmg, .zip)
npm run build:mac

# Build Windows installer (.exe)
npm run build:win

# Build Linux (.AppImage, .deb)
npm run build:linux
```
Outputs are generated in `../dist-desktop/`.
