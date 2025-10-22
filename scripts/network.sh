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

# Function to change hostname and setup FQDN
change_hostname() {
    echo -e "\e[36m=== Hostname & FQDN Configuration ===\e[0m"
    echo ""
    echo "Current hostname: $(hostname)"
    echo "Current FQDN: $(hostname -f 2>/dev/null || echo 'Not set')"
    echo ""
    
    # Ask for hostname
    echo "Enter new hostname (e.g., rawjal):"
    read -r new_hostname
    
    # Ask if user wants to set FQDN
    echo ""
    echo "Do you want to set FQDN (Fully Qualified Domain Name)? (y/n)"
    read -r set_fqdn
    
    if [[ $set_fqdn =~ ^[Yy]$ ]]; then
        echo "Enter domain name (e.g., rsakudus.com):"
        read -r domain_name
        fqdn="${new_hostname}.${domain_name}"
        
        echo ""
        echo -e "\e[33mSetting hostname and FQDN...\e[0m"
        
        # Set hostname
        sudo hostnamectl set-hostname "$new_hostname"
        
        # Get server IP
        server_ip=$(hostname -I | awk '{print $1}')
        
        # Update /etc/hosts
        sudo sed -i '/127.0.1.1/d' /etc/hosts
        echo "127.0.1.1 ${fqdn} ${new_hostname}" | sudo tee -a /etc/hosts > /dev/null
        
        # Also add actual IP if available
        if [ -n "$server_ip" ]; then
            sudo sed -i "/${server_ip}/d" /etc/hosts
            echo "${server_ip} ${fqdn} ${new_hostname}" | sudo tee -a /etc/hosts > /dev/null
        fi
        
        echo ""
        echo -e "\e[32m✓ Hostname set to: $new_hostname\e[0m"
        echo -e "\e[32m✓ FQDN set to: $fqdn\e[0m"
        echo ""
        echo "Verification:"
        echo "  Hostname: $(hostname)"
        echo "  FQDN: $(hostname -f)"
        
    else
        # Set hostname only
        sudo hostnamectl set-hostname "$new_hostname"
        
        # Update /etc/hosts
        sudo sed -i '/127.0.1.1/d' /etc/hosts
        echo "127.0.1.1 ${new_hostname}" | sudo tee -a /etc/hosts > /dev/null
        
        echo ""
        echo -e "\e[32m✓ Hostname changed to: $new_hostname\e[0m"
    fi
    
    echo ""
    echo -e "\e[33mNote: You may need to reboot for all changes to take effect.\e[0m"
}

# Function to configure DNS nameservers
configure_dns() {
    echo -e "\e[36m=== DNS Nameserver Configuration ===\e[0m"
    echo ""
    echo "Current DNS servers:"
    resolvectl status | grep "DNS Servers" | head -5
    echo ""
    
    echo "Select DNS configuration:"
    echo "1. Google DNS (8.8.8.8, 8.8.4.4)"
    echo "2. Cloudflare DNS (1.1.1.1, 1.0.0.1)"
    echo "3. Quad9 DNS (9.9.9.9, 149.112.112.112)"
    echo "4. Custom DNS"
    echo "0. Back"
    echo ""
    echo -n "Choose option: "
    read -r dns_choice
    
    case $dns_choice in
        1)
            dns1="8.8.8.8"
            dns2="8.8.4.4"
            dns_name="Google DNS"
            ;;
        2)
            dns1="1.1.1.1"
            dns2="1.0.0.1"
            dns_name="Cloudflare DNS"
            ;;
        3)
            dns1="9.9.9.9"
            dns2="149.112.112.112"
            dns_name="Quad9 DNS"
            ;;
        4)
            echo "Enter primary DNS:"
            read -r dns1
            echo "Enter secondary DNS:"
            read -r dns2
            dns_name="Custom DNS"
            ;;
        0)
            return 0
            ;;
        *)
            echo -e "\e[31mInvalid option.\e[0m"
            return 1
            ;;
    esac
    
    echo ""
    echo -e "\e[33mConfiguring $dns_name...\e[0m"
    
    # Check if using netplan or systemd-resolved
    if [ -d /etc/netplan ]; then
        # Update netplan configuration
        netplan_file=$(ls /etc/netplan/*.yaml 2>/dev/null | head -1)
        
        if [ -n "$netplan_file" ]; then
            # Backup
            sudo cp "$netplan_file" "${netplan_file}.backup-$(date +%Y%m%d)"
            
            # Add or update DNS in netplan
            if grep -q "nameservers:" "$netplan_file"; then
                sudo sed -i "/nameservers:/,/addresses:/c\      nameservers:\n        addresses:\n          - $dns1\n          - $dns2" "$netplan_file"
            else
                echo "      nameservers:" | sudo tee -a "$netplan_file" > /dev/null
                echo "        addresses:" | sudo tee -a "$netplan_file" > /dev/null
                echo "          - $dns1" | sudo tee -a "$netplan_file" > /dev/null
                echo "          - $dns2" | sudo tee -a "$netplan_file" > /dev/null
            fi
            
            sudo netplan apply
        fi
    fi
    
    # Also configure systemd-resolved
    echo "[Resolve]" | sudo tee /etc/systemd/resolved.conf.d/dns.conf > /dev/null
    echo "DNS=$dns1 $dns2" | sudo tee -a /etc/systemd/resolved.conf.d/dns.conf > /dev/null
    echo "FallbackDNS=$dns2" | sudo tee -a /etc/systemd/resolved.conf.d/dns.conf > /dev/null
    
    sudo systemctl restart systemd-resolved
    
    echo ""
    echo -e "\e[32m✓ DNS configured: $dns1, $dns2\e[0m"
    echo ""
    echo "Verification:"
    resolvectl status | grep "DNS Servers" | head -3
}
