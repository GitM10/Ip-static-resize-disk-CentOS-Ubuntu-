# Ip-static-resize-disk-CentOS-Ubuntu-
This script is script that make a system configuration (static IP) and disk resizing tool for CentOS and Ubuntu Linux systems. It allows users to set a static IP address and resize the root partition of their system.

The script detects the Linux distribution and prompts the user to enter network configuration details for setting a static IP address. It then applies the network configuration changes and proceeds to resize the root partition.

The resizing process varies depending on the filesystem type. For CentOS systems using ext2, ext3, or ext4 filesystems, the script uses the parted and resize2fs commands. For Ubuntu systems using an XFS filesystem, it utilizes the parted and xfs_growfs commands.

Additionally, the script adds a cronjob for automatic system updates and upgrades, scheduling them to run at 3 a.m. daily. This ensures that the system stays up to date with the latest security patches and software updates.

It is important to run the script as the root user and not through an SSH session for proper execution.

Please note that this is a summary of the script's functionality, and more detailed information can be found in the script itself.
