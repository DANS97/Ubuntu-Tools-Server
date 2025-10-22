#!/bin/bash

# Network related functions

# Function to set static IP
set_static_ip() {
    echo "Setting Static IP Address..."
    echo "Available network interfaces:"
    ip link show | grep -E '^[0-9]+:' | awk '{print $2}' | sed 's/://' | grep -v lo
    echo ""
    echo "Enter network interface (e.g., enp0s3):"
    read -r interface
    echo "Enter IP address (e.g., 192.168.1.100/24):"
    read -r ip_address
    echo "Enter gateway (e.g., 192.168.1.1):"
    read -r gateway
    echo "Enter DNS (e.g., 8.8.8.8):"
    read -r dns

    # Backup current netplan config
    sudo cp /etc/netplan/*.yaml /etc/netplan/backup.yaml 2>/dev/null || true

    # Create new netplan config
    cat <<EOF | sudo tee /etc/netplan/01-netcfg.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    $interface:
      dhcp4: no
      addresses:
        - $ip_address
      gateway4: $gateway
      nameservers:
        addresses:
          - $dns
EOF

    sudo netplan apply
    echo -e "\e[32mStatic IP configured successfully.\e[0m"
}

# Function to allow port
allow_port() {
    echo "Allowing Port..."
    echo "Enter port number to allow:"
    read -r port
    echo "Enter protocol (tcp/udp):"
    read -r protocol

    sudo ufw allow $port/$protocol
    echo -e "\e[32mPort $port/$protocol allowed.\e[0m"
}

# Function to change hostname
change_hostname() {
    echo "Current hostname: $(hostname)"
    echo "Enter new hostname:"
    read -r new_hostname
    sudo hostnamectl set-hostname "$new_hostname"
    echo "Hostname changed to $new_hostname. You may need to reboot for changes to take effect."
}
