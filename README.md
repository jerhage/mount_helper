# Systemd Mount Unit Creation Helper


This script simplifies the process of creating systemd mount units for mounting disks and partitions. It guides the user through selecting a disk, creating a mount point, and generating a systemd mount unit to ensure the disk is mounted automatically on boot.

Please note, I made this script for personal use on my personal computer running Bazzite.  This script should work well for other Fedora atomic desktops like those the team at Universal Blue manage. Therefore, keep in mind this is specifically designed with Fedora atomic distros like Bazzite and Bluefin in mind. As such, the canonical names for mount points will be at /var/mnt/<mount_point>.

With these distros moving in the direction of systemd extensions, I thought it would be convenient to create a script that also leans on systemd.

Before using the script, I highly suggest learning more about systemd and their types of unit files.  I find Red Hat's documentation to be good: [systemd docs](https://docs.redhat.com/en/documentation/Red_Hat_Enterprise_Linux/7/html/System_Administrators_Guide/chap-Managing_Services_with_systemd.html#sect-Managing_Services_with_systemd-Introduction)

# TODO
- Add better logic for suggesting available disks and partitions to mount
- Add ability to manage mount units
- Add ability to customize mount unit options

# Dependencies

- systemd: If you prefer to manage mounts using fstab, this script will not be of any use.
- lsblk: mount systems should have this available by default. If not, install it with your package manager

# Usage

## Running the Script

1. Make the script executable:

`chmod +x mount_helper.sh`

2. Run the script:

`sudo ./mount_helper.sh`

## How it works

1. The script lists all attached disks and partitions. It will then show disks and partitions that currently have no mount point.

2. You are then prompted to select a disk or partition to mount (e.g., sda1, sdb1, etc.).

3. You are then prompted to provide a name for the mount point (defaults to the disk name if not specified).

4. The script detects the filesystem type and UUID of the selected disk.

5. A systemd mount unit is created and saved in /etc/systemd/system/.

6. The mount point is created, and the systemd unit is enabled and started.

With this, the new mount point should be mounted and made available now and in all future boots.

# Systemd Mount Unit Structure

The script creates a systemd unit file with the following structure:
```
# Assume you select sdb1 as the partition to mount at the mount point called "games"
[Unit]
Description=Mount /dev/sdb1 at /var/mnt/games
After=dev-sdb.device # This ensures that the mounting only happens after the physical disk is available.

[Mount]
What=UUID=<disk-uuid> # Using the disk UUID makes mounting predictable across boots instead of directly relying on the mount name like sdb1
Where=/var/mnt/games
Type=<filesystem-type>
Options=defaults

[Install]
WantedBy=multi-user.target
```

# Final Notes

Bazzite and Bluefin symlink /var/mnt to /mnt. Therefore, the disk is mounted at /var/mnt/<mount_name>, but also conveniently available at /mnt/<mount_name>.

Again, this creates a systemd mount unit that will immediately mount a disk or partition and also do so in future boots automatically.  That is it.  I do have plans to iterate to add functionality to manage these mount units, but that is for later.

License

This script is provided under the MIT License.
