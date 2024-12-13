#!/bin/bash

# Quit script and print error message to screen
error_exit() {
    echo "Error: $1" >&2
    exit 1
}

# Display attached disks to the user for them to decide which partition to mount
list_disks() {
    echo "Attached disks and partitions:"
    lsblk | grep -E 'disk|part'
    echo -e "\nPartitions available to mount:"
    lsblk -o NAME,SIZE,TYPE,MOUNTPOINT | awk '$4 == ""' | grep -E 'disk|part'
}

validate_disk() {
    local disk="$1"
    [[ -b "/dev/$disk" ]] || return 1
}

# Select the partition to mount
# The AFTER_TARGET variable will make sure the mount unit waits until the specific partition is made available before attempting to mount
select_disk() {
    local selected_disk
    read -p "Enter the disk name (e.g., sda, sdb, sdc ...): " selected_disk
    echo "$selected_disk"
}

is_mounted() {
    local disk="$1"
    mount | grep -q "/dev/$disk"
}

# Create a name for the mount point
# Note that the systemd mount unit requires a canonical name (ie symlinks will not work) Therefore, the mount unit will specify /var/mount/$MOUNT_NAME to mount.
get_mount_name() {
    local selected_disk="$1"
    local custom_name

    read -p "Enter a name for the mount point (e.g., games). Defaults to the disk name (e.g. sda1, sdb2 ...): " custom_name

    if [[ -n "$custom_name" ]]; then
        echo "$custom_name"
    else
        echo "$selected_disk"
    fi
}

# Get the filesystem type and UUID of the partition
get_disk_fstype() {
    local disk_path="/dev/$1"
    local fs_type=$(lsblk -no FSTYPE "$disk_path")

    if [ -z "$fs_type" ]; then
        error_exit "Error: Unable to retrieve filesystem type for $fs_type."
    fi
    echo "$fs_type"
}

get_disk_uuid() {
    local disk_path="/dev/$1"
    local disk_uuid=$(lsblk -no UUID "$disk_path")
    if [ -z "$disk_uuid" ]; then
        error_exit "Error: Unable to retrieve UUID for $disk_uuid."
    fi

    echo "$disk_uuid"
}

# Create the systemd mount unit
create_systemd_mount_unit() {
    local selected_disk="$1"
    local mount_name="$2"
    local fs_type="$3"
    local disk_uuid="$4"

    local mount_point="/var/mnt/$mount_name"
    local disk_path="/dev/$selected_disk"
    local after_target="dev-${selected_disk//\//-}.device"
    local unit_name="$(systemd-escape -p "$mount_point").mount"
    local unit_path="/etc/systemd/system/$unit_name"

    cat <<EOF | sudo tee "$unit_path"
[Unit]
Description=Mount $disk_path at $mount_point
After=$after_target

[Mount]
What=UUID=$disk_uuid
Where=$mount_point
Type=$fs_type
Options=defaults

[Install]
WantedBy=multi-user.target
EOF

    echo "Created systemd mount unit: $unit_path"
}

# Make the mount directory then enable and start the mount unit
enable_mount_unit() {
    local mount_name="$1"
    local mount_point="/var/mnt/$mount_name"
    local unit_name="$(systemd-escape -p "$mount_point").mount"
    local unit_path="/etc/systemd/system/$unit_name"

    sudo mkdir -p "$mount_point"
    sudo systemctl daemon-reload
    sudo systemctl enable "$(basename "$unit_path")"
    sudo systemctl start "$(basename "$unit_path")"

    local symlinked_mount_point="/mnt/$mount_name"
    echo "Mount unit enabled and started. The disk will be mounted at $mount_point on boot and available at $symlinked_mount_point"
}

main() {
    echo "=== Disk Mount Unit Creation Script ==="
    list_disks

    local selected_disk=$(select_disk) || error_exit "Invalid disk selection"

    if is_mounted "$selected_disk"; then
        error_exit "Disk is already mounted"
    fi
    
    validate_disk "$selected_disk"

    local mount_name=$(get_mount_name "$selected_disk")
    local fs_type=$(get_disk_fstype "$selected_disk")
    local disk_uuid=$(get_disk_uuid "$selected_disk")

    create_systemd_mount_unit "$selected_disk" "$mount_name" "$fs_type" "$disk_uuid"
    enable_mount_unit "$mount_name"
}

main
