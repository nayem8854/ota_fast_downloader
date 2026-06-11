# OTA Fast Downloader Script

A powerful and optimized Bash script designed to download large files (like OTA updates, firmware packages, or ROMs) at maximum speed. It automatically checks and installs required packages, switches to the fastest mirror links, and lets you choose custom download directories.

## Features

- 🏎️ **Max Speed Download:** Utilizes `aria2c` with multi-connection support (16 threads) and falls back to `wget` if it fails.
- 📦 **Auto-Dependency Installer:** Automatically checks, updates, and installs missing packages (`aria2`, `wget`, `detox`, `ripgrep`) on Ubuntu/Colab.
- 📂 **Custom Save Directory:** Use the `-d` flag to save files directly to Google Drive, external drives, or custom folders.
- 🔄 **Smart Mirror Selection:** Automatically resolves and selects the fastest mirrors for Xiaomi (`://miui.com`) and Pixeldrain links.

## Installation

Clone the repository or download the script directly:

```bash
git clone https://github.com
cd YOUR_REPO_NAME
chmod +x ota_fast_downloader.sh
```

## Usage

### 1. Default Download (Saves to `download_ota`)
```bash
./ota_fast_downloader.sh https://example.com
```

## Requirements
The script automatically handles the installation of these tools if run with root/sudo privileges:
- `aria2`
- `wget`
- `detox`
- `ripgrep`

## License
This project is licensed under the MIT License.
