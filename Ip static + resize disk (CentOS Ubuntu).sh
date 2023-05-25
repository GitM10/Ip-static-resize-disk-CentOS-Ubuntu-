#!/bin/bash

# Banner
echo -e "\e[31m========================================="
echo -e "     WARNING: ROOT PRIVILEGES REQUIRED     "
echo -e "=========================================\e[0m"
echo

# Disclaimer
echo -e "\e[31mDISCLAIMER:\e[0m"
echo -e "\e[31mThis script will modify system configurations and resize disk partitions.\e[0m"
echo -e "\e[31mexecuted as the root user and NOT through an SSH session.\e[0m"
echo

# Confirmation prompt
read -p "Press Enter to continue or Ctrl+C to exit."

# Function to resize disk
resize_disk() {
    # Check if the parted command is available
    if ! command -v parted &> /dev/null; then
        echo "Parted command not found. Please install it."
        exit 1
    fi

    # Get the root partition device
    root_device=$(findmnt / -o source -n)

    # Get the filesystem type of the root partition
    filesystem=$(lsblk -no FSTYPE $root_device)

    # Resize the partition and filesystem based on the filesystem type
    case $filesystem in
        ext2 | ext3 | ext4)
            # Resize ext2/ext3/ext4 partition and filesystem
            parted $root_device resizepart 1 100%
            resize2fs $root_device
            ;;
        xfs)
            # Resize XFS partition and filesystem
            parted $root_device resizepart 1 100%
            xfs_growfs $root_device
            ;;
        *)
            echo "Unsupported filesystem: $filesystem"
            exit 1
            ;;
    esac

    echo "Disk resize completed successfully."
}

# Function to set static IP for CentOS
set_static_ip_centos() {
    read -p "Enter the IP address: " ip_address
    read -p "Enter the subnet mask es. 255.255.255.0: " subnet_mask
    read -p "Enter the default gateway: " default_gateway
    read -p "Enter the primary DNS server: " primary_dns

    # Update network configuration file
    cat << EOF | sudo tee /etc/sysconfig/network-scripts/ifcfg-eth0 > /dev/null
DEVICE=eth0
ONBOOT=yes
BOOTPROTO=static
TYPE=Ethernet
NM_CONTROLLED=no
IPADDR=$ip_address
NETMASK=$subnet_mask
GATEWAY=$default_gateway
DNS1=$primary_dns
EOF

    # Restart network service
    sudo systemctl restart network
    echo "Static IP set successfully for CentOS."

    # Resize root partition
    resize_disk
}

# Function to set static IP for Ubuntu
set_static_ip_ubuntu() {
    read -p "Enter the IP address: " ip_address
    read -p "Enter the subnet mask es. 24 (without /): " subnet_mask
    read -p "Enter the default gateway: " default_gateway
    read -p "Enter the primary DNS server: " primary_dns
    read -p "Enter the secondary DNS server: " secondary_dns

    # Update network configuration file
    cat << EOF | sudo tee /etc/netplan/01-netcfg.yaml > /dev/null
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: no
      addresses: [$ip_address/$subnet_mask]
      gateway4: $default_gateway
      nameservers:
        addresses: [$primary_dns, $secondary_dns]
EOF

    # Apply network configuration
    sudo netplan apply
    echo "Static IP set successfully for Ubuntu."

    # Resize root partition
    resize_disk
}

# Determine the current Linux system
if [[ -f /etc/centos-release ]]; then
    echo "Detected CentOS system."
    set_static_ip_centos

    # Add cronjob for CentOS
    (crontab -l 2>/dev/null; echo "0 3 * * * sudo yum update && sudo yum upgrade -y") | crontab -
    echo "Cronjob added successfully for updating and upgrading the system at 3 a.m. daily for CentOS."

elif [[ -f /etc/lsb-release ]]; then
    echo "Detected Ubuntu system."
    set_static_ip_ubuntu

    # Add cronjob for Ubuntu
    (crontab -l 2>/dev/null; echo "0 3 * * * sudo apt update && sudo apt upgrade -y") | crontab -
    echo "Cronjob added successfully for updating and upgrading the system at 3 a.m. daily for Ubuntu."

else
    echo "Unsupported Linux system."
fi
