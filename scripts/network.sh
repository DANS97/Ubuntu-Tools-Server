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

# Function to add local domain mapping (hosts file)
add_local_domain() {
    echo -e "\e[36m=== Add Local Domain Mapping ===\e[0m"
    echo ""
    echo "This will add domain mapping to /etc/hosts for local access"
    echo "(No internet DNS required)"
    echo ""
    
    # Show current custom entries (excluding localhost)
    echo -e "\e[33mCurrent local domain mappings:\e[0m"
    echo "─────────────────────────────────────────────────────"
    grep -v "^#" /etc/hosts | grep -v "127.0.0.1.*localhost" | grep -v "127.0.1.1" | grep -v "::1" | grep -v "^$" || echo "  (No custom entries)"
    echo "─────────────────────────────────────────────────────"
    echo ""
    
    # Get server IP (auto-detect)
    local default_ip
    default_ip=$(hostname -I | awk '{print $1}')
    
    echo "Enter IP address (default: $default_ip for this server):"
    echo "Examples:"
    echo "  - 127.0.0.1           (localhost)"
    echo "  - $default_ip  (this server's IP)"
    echo "  - 192.168.1.100       (other local server)"
    read -r ip_address
    ip_address=${ip_address:-$default_ip}
    
    # Validate IP address format
    if ! [[ $ip_address =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        echo -e "\e[31m✗ Invalid IP address format\e[0m"
        return 1
    fi
    
    echo ""
    echo "Enter domain name:"
    echo "Examples:"
    echo "  - rawat-inap.rsaisyiyahudus.com"
    echo "  - myapp.local"
    echo "  - dev.example.com"
    read -r domain_name
    
    if [ -z "$domain_name" ]; then
        echo -e "\e[31m✗ Domain name is required\e[0m"
        return 1
    fi
    
    # Check if entry already exists
    if grep -q "^.*[[:space:]]${domain_name}[[:space:]]*$" /etc/hosts; then
        echo ""
        echo -e "\e[33m⚠ Domain '$domain_name' already exists in /etc/hosts\e[0m"
        grep "${domain_name}" /etc/hosts
        echo ""
        read -p "Update existing entry? (y/n): " update_entry
        if [[ ! $update_entry =~ ^[Yy]$ ]]; then
            return 0
        fi
        # Remove old entry
        sudo sed -i "/[[:space:]]${domain_name}[[:space:]]*$/d" /etc/hosts
        echo -e "\e[32m✓ Old entry removed\e[0m"
    fi
    
    # Add alias (optional)
    echo ""
    echo "Add alias/subdomain? (optional, press Enter to skip)"
    echo "Example: www.${domain_name}, api.${domain_name}"
    read -r alias_domain
    
    # Backup hosts file
    sudo cp /etc/hosts /etc/hosts.backup-$(date +%Y%m%d-%H%M%S)
    
    # Add new entry
    echo ""
    echo -e "\e[33mAdding entry to /etc/hosts...\e[0m"
    
    if [ -n "$alias_domain" ]; then
        echo "${ip_address} ${domain_name} ${alias_domain}" | sudo tee -a /etc/hosts > /dev/null
        echo -e "\e[32m✓ Added: ${ip_address} → ${domain_name}, ${alias_domain}\e[0m"
    else
        echo "${ip_address} ${domain_name}" | sudo tee -a /etc/hosts > /dev/null
        echo -e "\e[32m✓ Added: ${ip_address} → ${domain_name}\e[0m"
    fi
    
    # Test resolution
    echo ""
    echo -e "\e[33mTesting domain resolution...\e[0m"
    if ping -c 1 -W 2 "$domain_name" &>/dev/null; then
        echo -e "\e[32m✓ Domain '$domain_name' is now resolvable!\e[0m"
        echo "  Ping result: $(ping -c 1 "$domain_name" | grep "bytes from" | awk '{print $4}' | tr -d ':')"
    else
        echo -e "\e[33m⚠ Domain added but ping test failed (this is normal if host is unreachable)\e[0m"
    fi
    
    echo ""
    echo -e "\e[36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
    echo -e "\e[32m✓ Local domain mapping configured!\e[0m"
    echo -e "\e[36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
    echo ""
    echo "You can now access:"
    echo "  http://${domain_name}"
    if [ -n "$alias_domain" ]; then
        echo "  http://${alias_domain}"
    fi
    echo ""
    echo -e "\e[33mNote:\e[0m"
    echo "  - This only works on THIS machine"
    echo "  - For web access, configure Nginx/Apache virtual host"
    echo "  - Other computers need same /etc/hosts entry"
    echo "  - Backup saved: /etc/hosts.backup-*"
}

# Function to manage local domains
manage_local_domains() {
    while true; do
        echo -e "\e[36m=== Local Domain Management ===\e[0m"
        echo ""
        echo "1. Add new domain mapping"
        echo "2. View all domain mappings"
        echo "3. Remove domain mapping"
        echo "4. Restore hosts backup"
        echo "0. Back"
        echo ""
        read -p "Choose option: " domain_choice
        
        case $domain_choice in
            1)
                add_local_domain
                ;;
            2)
                echo ""
                echo -e "\e[33mAll entries in /etc/hosts:\e[0m"
                echo "─────────────────────────────────────────────────────"
                cat -n /etc/hosts
                echo "─────────────────────────────────────────────────────"
                ;;
            3)
                echo ""
                echo "Enter domain name to remove:"
                read -r remove_domain
                if grep -q "[[:space:]]${remove_domain}[[:space:]]*$" /etc/hosts; then
                    sudo sed -i "/[[:space:]]${remove_domain}[[:space:]]*$/d" /etc/hosts
                    echo -e "\e[32m✓ Domain '$remove_domain' removed\e[0m"
                else
                    echo -e "\e[31m✗ Domain '$remove_domain' not found\e[0m"
                fi
                ;;
            4)
                echo ""
                echo "Available backups:"
                ls -lh /etc/hosts.backup-* 2>/dev/null || echo "No backups found"
                echo ""
                echo "Enter backup filename to restore (or press Enter to cancel):"
                read -r backup_file
                if [ -n "$backup_file" ] && [ -f "$backup_file" ]; then
                    sudo cp "$backup_file" /etc/hosts
                    echo -e "\e[32m✓ Hosts file restored from backup\e[0m"
                elif [ -n "$backup_file" ]; then
                    echo -e "\e[31m✗ Backup file not found\e[0m"
                fi
                ;;
            0)
                return 0
                ;;
            *)
                echo -e "\e[31mInvalid option\e[0m"
                ;;
        esac
        echo ""
        read -p "Press Enter to continue..."
        clear
    done
}

