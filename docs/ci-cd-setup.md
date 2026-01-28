# CI/CD Setup Guide

## Overview

The project has two GitHub Actions workflows:

1. **CI** (`ci.yml`) - Runs on every push/PR to `main` and `develop`
   - Linting and formatting check
   - Running tests with coverage
   - Debug build verification

2. **Release** (`release.yml`) - Runs on version tags (`v*`)
   - Tests and linting
   - Builds signed release APK
   - Deploys to your server
   - Creates GitHub Release

## Required GitHub Secrets

Go to **Repository → Settings → Secrets and variables → Actions** and add:

### Signing Secrets

| Secret | Description |
|--------|-------------|
| `KEYSTORE_BASE64` | Base64-encoded keystore file |
| `KEYSTORE_PASSWORD` | Keystore password |
| `KEY_ALIAS` | Key alias in keystore |
| `KEY_PASSWORD` | Key password |

### Server Deployment Secrets

| Secret | Description |
|--------|-------------|
| `SSH_PRIVATE_KEY` | Private SSH key for server access |
| `SSH_HOST` | Server hostname or IP |
| `SSH_USER` | SSH username |
| `DEPLOY_PATH` | Path on server (e.g., `/var/www/releases`) |

## How to Generate Keystore Base64

```bash
# If you already have a keystore
base64 -i your-keystore.jks | pbcopy  # macOS
base64 -w 0 your-keystore.jks         # Linux

# If you need to create a new keystore
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

## How to Create Release

```bash
# Create and push a tag
git tag -a v1.0.0 -m "Release version 1.0.0

- Feature 1
- Bug fix 2
- Improvement 3"

git push origin v1.0.0
```

The workflow will:
1. Run all tests
2. Build signed APK
3. Upload to your server at `DEPLOY_PATH/v1.0.0/FishFeed-v1.0.0.apk`
4. Create release notes at `DEPLOY_PATH/v1.0.0/release-notes.txt`
5. Update `latest` symlink
6. Generate `index.json` with all releases
7. Create GitHub Release with APK attached

## Server Structure

After releases, your server will have:

```
/var/www/releases/
├── latest -> v1.2.0           # Symlink to latest release
├── index.json                  # JSON list of all releases
├── v1.0.0/
│   ├── FishFeed-v1.0.0.apk
│   └── release-notes.txt
├── v1.1.0/
│   ├── FishFeed-v1.1.0.apk
│   └── release-notes.txt
└── v1.2.0/
    ├── FishFeed-v1.2.0.apk
    └── release-notes.txt
```

## Server Requirements

Your server needs:
- SSH access
- Directory for releases with write permissions
- Optional: web server (nginx/apache) to serve APKs

### Example Nginx Config

```nginx
server {
    listen 80;
    server_name releases.yourserver.com;

    location /fishfeed/ {
        alias /var/www/releases/;
        autoindex on;
    }
}
```

Testers can then download from:
- Latest: `https://releases.yourserver.com/fishfeed/latest/FishFeed-v1.2.0.apk`
- Specific: `https://releases.yourserver.com/fishfeed/v1.0.0/FishFeed-v1.0.0.apk`
- Index: `https://releases.yourserver.com/fishfeed/index.json`
