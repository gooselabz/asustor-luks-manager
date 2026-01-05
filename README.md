![LUKS Manager](asustor-luks-manager.png)

# LUKS Container Manager for Asustor NAS

Simple script to mount and dismount LUKS-encrypted containers on Asustor NAS devices, with web UI via script-server.

Example use case: your NAS reboots and you'd like to securely re-mount your LUKS volume. For security it requires your human password (never stored on device) but you'd rather not spin up an entire SSH terminal.

## Why?

Asustor lacks general encrypted container tools. This script enables best-in-class encrypted container mount/dismount, with human password required (no keys on device). Useful for application runtimes, secure backend storage, etc. It also has a key advantage over full disk encryption: ability to mount and manage the container remotely without KVM hardware.

**For Docker using this approach**, see the companion [asustor-luks-docker](https://github.com/gooselabz/asustor-luks-docker).

## Key Challenges Overcome

- **Bash Works Better**: ADM defaults to BusyBox; bash is much better for this.
  - Solution: Install bash from entware.
- **ext4 Works Better**: The filesystem underlying LUKS drives what does/not work.
  - Solution: Store and mount your container on ext4 volumes, not btrfs.
- **Web GUI Works Better (For Most)**: For most scenarios eg after reboot, a simple web GUI is better than requiring SSH.
  - Solution (Optional): Install and configure script-server from App Central.

## Prerequisites

**Required:**

- Bash (e.g. install Entware from App Central, then `opkg update && opkg install bash`)

**Recommended (web UI):**

- script-server: Install from App Central

## Setup

### 1. Create LUKS Container

```bash
# Create sparse 10GB file (adjust size as needed)
# Recommended: place in Shared Folder so ADM manages access, backups, etc.
truncate -s 10G /volumeX/yourpath/.my_encrypted.img

# Format with LUKS (will prompt for passphrase)
sudo /usr/builtin/bin/cryptsetup luksFormat /volumeX/yourpath/.my_encrypted.img

# Open and create ext4 filesystem
sudo /usr/builtin/bin/cryptsetup open /volumeX/yourpath/.my_encrypted.img myencrypted
sudo mkfs.ext4 -L my_encrypted /dev/mapper/myencrypted
sudo /usr/builtin/bin/cryptsetup close myencrypted
```

### 2. Install Script

1. Download `asustor-luks-manager.sh` from this repo to your preferred location (e.g., `/volumeX/yourpath/.asustor_luks_manager/`)
2. Edit the configuration variables at the top of the script:
   - `LUKS_IMAGE`: Path to your `.img` file
   - `LUKS_DEVICE`: Device mapper name (must match what you used in cryptsetup open)
   - `MOUNT_POINT`: Where to mount (e.g., `/volumeX/encrypted`)
3. Make it executable: `chmod +x asustor-luks-manager.sh`
4. Create sudoers file (replace 'admin' with your selected username)

```bash
'sudo tee /etc/sudoers.d/90-luks-manager << 'EOF'
admin ALL=(ALL) NOPASSWD: /usr/builtin/bin/cryptsetup open *
admin ALL=(ALL) NOPASSWD: /usr/builtin/bin/cryptsetup close *
admin ALL=(ALL) NOPASSWD: /bin/mount -t ext4 /dev/mapper/* *
admin ALL=(ALL) NOPASSWD: /bin/umount *
admin ALL=(ALL) NOPASSWD: /bin/umount -l *
admin ALL=(ALL) NOPASSWD: /bin/mkdir -p *
EOF

sudo chmod 0440 /etc/sudoers.d/90-luks-manager
```

### 4. Install script-server Web UI

1. Download `asustor-luks-manager.json` from this repo to `/volumeX/.@plugins/AppCentral/scriptserver/script-server/conf/runners/`
2. Edit script_path in JSON to match your installation

## Usage

### Web UI (script-server)

1. Navigate to `http://YOUR_NAS_IP:SCRIPT-SERVER-PORT`
2. Click **Asustor** **LUKS Manager** item in left menu
3. Select action: `mount` or `dismount`
4. For mount: Enter passphrase in secure field (shown as dots)
5. Execute

### Command Line

```bash
# Mount encrypted volume
/volumeX/yourpath/.luks_manager/asustor-luks-manager.sh mount

# Mount with passphrase as argument (non-interactive)
/volumeX/yourpath/.luks_manager/asustor-luks-manager.sh mount "your-passphrase"

# Dismount and close
/volumeX/yourpath/.luks_manager/asustor-luks-manager.sh dismount
```

# Security Notes

- **No keyfiles**: Passphrase required every mount—no keys stored on device
- Security = passphrase strength
- Sudoers allows passwordless operations—restrict to trusted usernames only
- Mounted data accessible per normal Linux file permissions

## Related Projects

- [asustor-luks-docker](https://github.com/gooselabz/asustor-luks-docker) - Run Docker on LUKS-encrypted storage

## License

MIT License - see [LICENSE](LICENSE) file
