#!/opt/bin/bash
# LUKS Container Manager for Asustor NAS
# Manages encrypted LUKS container mounting/unmounting
# Usage: asustor_luks_manager.sh {mount|dismount} [passphrase]

set -euo pipefail

# Configuration - Edit these for your setup
readonly LUKS_IMAGE="${LUKS_IMAGE:-/volumeX/yourpath/.my_encrypted.img}"
readonly LUKS_DEVICE="${LUKS_DEVICE:-myencrypted}"
readonly MOUNT_POINT="${MOUNT_POINT:-/volumeX/encrypted}"
readonly CRYPTSETUP_PATH="/usr/builtin/bin/cryptsetup"

# Check if LUKS device is open
is_device_open() {
    [[ -e "/dev/mapper/$LUKS_DEVICE" ]]
}

# Check if mounted
is_mounted() {
    mountpoint -q "$MOUNT_POINT" 2>/dev/null
}

# Mount encrypted volume
cmd_mount() {
    local passphrase="${1:-}"
    
    # Create mount point if needed
    if [[ ! -d "$MOUNT_POINT" ]]; then
        sudo mkdir -p "$MOUNT_POINT"
    fi
    
    # Already mounted?
    if is_mounted; then
        echo "✓ $MOUNT_POINT is already mounted"
        return 0
    fi
    
    # Check LUKS image exists
    if [[ ! -f "$LUKS_IMAGE" ]]; then
        echo "✗ LUKS image not found: $LUKS_IMAGE"
        exit 1
    fi
    
    # Open LUKS device if not already open
    if ! is_device_open; then
        echo "Opening LUKS container: $LUKS_IMAGE"
        if [[ -n "$passphrase" ]]; then
            echo "$passphrase" | sudo "$CRYPTSETUP_PATH" open "$LUKS_IMAGE" "$LUKS_DEVICE" -
        else
            sudo "$CRYPTSETUP_PATH" open "$LUKS_IMAGE" "$LUKS_DEVICE"
        fi
        echo "✓ LUKS device opened: /dev/mapper/$LUKS_DEVICE"
    fi
    
    # Mount
    echo "Mounting /dev/mapper/$LUKS_DEVICE to $MOUNT_POINT"
    sudo mount -t ext4 "/dev/mapper/$LUKS_DEVICE" "$MOUNT_POINT"
    echo "✓ Mounted successfully"
    echo ""
    df -h "$MOUNT_POINT" | tail -n 1
}

# Unmount and close
cmd_dismount() {
    # Unmount if mounted
    if is_mounted; then
        echo "Unmounting $MOUNT_POINT"
        sudo umount "$MOUNT_POINT" 2>/dev/null || sudo umount -l "$MOUNT_POINT"
        echo "✓ Unmounted successfully"
    else
        echo "✓ $MOUNT_POINT is not mounted"
    fi
    
    # Close LUKS device if open
    if is_device_open; then
        echo "Closing LUKS device: /dev/mapper/$LUKS_DEVICE"
        sync
        sleep 1
        sudo "$CRYPTSETUP_PATH" close "$LUKS_DEVICE"
        echo "✓ LUKS device closed"
    else
        echo "✓ LUKS device is already closed"
    fi
}

# Main
main() {
    local action="${1:-}"
    local passphrase="${2:-}"
    
    case "$action" in
        mount)
            cmd_mount "$passphrase"
            ;;
        dismount|umount|unmount)
            cmd_dismount
            ;;
        *)
            echo "Usage: $0 {mount|dismount} [passphrase]"
            echo ""
            echo "Commands:"
            echo "  mount      - Open LUKS container and mount to $MOUNT_POINT"
            echo "  dismount   - Unmount and close LUKS container"
            echo ""
            echo "Environment Variables (override defaults):"
            echo "  LUKS_IMAGE     - Path to LUKS image file"
            echo "  LUKS_DEVICE    - Device mapper name"
            echo "  MOUNT_POINT    - Mount location"
            exit 1
            ;;
    esac
}

main "$@"
