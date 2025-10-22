#!/bin/bash

# UFW (Uncomplicated Firewall) Management Script

# Function to check if UFW is installed
check_ufw_installed() {
    if ! command -v ufw &> /dev/null; then
        echo -e "\e[31m✗ UFW is not installed.\e[0m"
        read -p "Do you want to install UFW? (y/n): " install_ufw
        if [[ $install_ufw =~ ^[Yy]$ ]]; then
            echo "Installing UFW..."
            sudo apt update
            sudo apt install -y ufw
            echo -e "\e[32m✓ UFW installed successfully!\e[0m"
        else
            return 1
        fi
    fi
    return 0
}

# Function to display UFW status
show_ufw_status() {
    clear
    echo -e "\e[36m╔════════════════════════════════════════════════════════════════════╗\e[0m"
    echo -e "\e[36m║                    UFW Firewall Status                             ║\e[0m"
    echo -e "\e[36m╚════════════════════════════════════════════════════════════════════╝\e[0m"
    echo ""
    
    # Check if UFW is active
    local ufw_status
    ufw_status=$(sudo ufw status | head -1)
    if echo "$ufw_status" | grep -q "Status: active"; then
        echo -e "\e[32m● UFW is ACTIVE\e[0m"
    elif echo "$ufw_status" | grep -q "Status: inactive"; then
        echo -e "\e[33m○ UFW is INACTIVE\e[0m"
    else
        echo -e "\e[90m- UFW status unknown\e[0m"
    fi
    
    echo ""
    echo -e "\e[1m\e[33m🔥 FIREWALL RULES\e[0m"
    echo -e "─────────────────────────────────────────────────────────────────────"
    
    # Show rules with better formatting
    sudo ufw status numbered | tail -n +4 | while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            # Parse rule
            if echo "$line" | grep -q "ALLOW"; then
                echo -e "\e[32m✓\e[0m $line"
            elif echo "$line" | grep -q "DENY"; then
                echo -e "\e[31m✗\e[0m $line"
            elif echo "$line" | grep -q "LIMIT"; then
                echo -e "\e[33m⚠\e[0m $line"
            else
                echo "  $line"
            fi
        fi
    done
    
    # Count rules
    local rule_count
    rule_count=$(sudo ufw status numbered | tail -n +4 | grep -c "^\[")
    if [ $rule_count -eq 0 ]; then
        echo -e "\e[90m  No firewall rules configured\e[0m"
    fi
    
    echo ""
    echo -e "\e[1m\e[33m📊 STATISTICS\e[0m"
    echo -e "─────────────────────────────────────────────────────────────────────"
    printf "%-25s %s\n" "Total Rules:" "$rule_count"
    printf "%-25s %s\n" "Default Incoming:" "$(sudo ufw status verbose | grep 'Default:' | awk '{print $2}')"
    printf "%-25s %s\n" "Default Outgoing:" "$(sudo ufw status verbose | grep 'Default:' | awk '{print $4}')"
    printf "%-25s %s\n" "Logging:" "$(sudo ufw status verbose | grep 'Logging:' | awk '{print $2}')"
    
    echo ""
    echo -e "\e[36m═════════════════════════════════════════════════════════════════════\e[0m"
}

# Function to enable UFW
enable_ufw() {
    echo -e "\e[36mEnabling UFW Firewall...\e[0m"
    
    # Check if SSH port is allowed
    if ! sudo ufw status | grep -q "22.*ALLOW"; then
        echo -e "\e[33m⚠ Warning: SSH port (22) is not in the allow list!\e[0m"
        read -p "Add SSH port 22 to prevent lockout? (y/n): " add_ssh
        if [[ $add_ssh =~ ^[Yy]$ ]]; then
            sudo ufw allow 22/tcp comment 'SSH'
            echo -e "\e[32m✓ SSH port 22 allowed\e[0m"
        else
            echo -e "\e[31m⚠ Proceeding without SSH rule - you may lose access!\e[0m"
            read -p "Are you sure? (yes/no): " confirm
            if [[ $confirm != "yes" ]]; then
                echo "Cancelled."
                return
            fi
        fi
    fi
    
    # Enable UFW
    echo "y" | sudo ufw enable
    
    if sudo ufw status | grep -q "Status: active"; then
        echo -e "\e[32m✓ UFW enabled successfully!\e[0m"
    else
        echo -e "\e[31m✗ Failed to enable UFW\e[0m"
    fi
}

# Function to disable UFW
disable_ufw() {
    echo -e "\e[36mDisabling UFW Firewall...\e[0m"
    
    read -p "Are you sure you want to disable the firewall? (y/n): " confirm
    if [[ $confirm =~ ^[Yy]$ ]]; then
        sudo ufw disable
        echo -e "\e[33m⚠ UFW disabled. Your system is now unprotected!\e[0m"
    else
        echo "Cancelled."
    fi
}

# Function to add firewall rule
add_ufw_rule() {
    echo -e "\e[36m╔════════════════════════════════════════════════════════════════════╗\e[0m"
    echo -e "\e[36m║                     Add UFW Firewall Rule                          ║\e[0m"
    echo -e "\e[36m╚════════════════════════════════════════════════════════════════════╝\e[0m"
    echo ""
    
    # Choose rule type
    echo "Select rule type:"
    echo "1. Allow port (TCP)"
    echo "2. Allow port (UDP)"
    echo "3. Allow port (Both TCP/UDP)"
    echo "4. Allow from specific IP"
    echo "5. Allow from specific IP to port"
    echo "6. Deny port"
    echo "7. Custom rule"
    echo "0. Cancel"
    echo ""
    read -p "Choose option (0-7): " rule_type
    
    case $rule_type in
        1)
            read -p "Enter port number: " port
            read -p "Enter comment (optional): " comment
            if [ -n "$comment" ]; then
                sudo ufw allow $port/tcp comment "$comment"
            else
                sudo ufw allow $port/tcp
            fi
            echo -e "\e[32m✓ Rule added: Allow port $port/tcp\e[0m"
            ;;
        2)
            read -p "Enter port number: " port
            read -p "Enter comment (optional): " comment
            if [ -n "$comment" ]; then
                sudo ufw allow $port/udp comment "$comment"
            else
                sudo ufw allow $port/udp
            fi
            echo -e "\e[32m✓ Rule added: Allow port $port/udp\e[0m"
            ;;
        3)
            read -p "Enter port number: " port
            read -p "Enter comment (optional): " comment
            if [ -n "$comment" ]; then
                sudo ufw allow $port comment "$comment"
            else
                sudo ufw allow $port
            fi
            echo -e "\e[32m✓ Rule added: Allow port $port (TCP/UDP)\e[0m"
            ;;
        4)
            read -p "Enter IP address: " ip
            read -p "Enter comment (optional): " comment
            if [ -n "$comment" ]; then
                sudo ufw allow from $ip comment "$comment"
            else
                sudo ufw allow from $ip
            fi
            echo -e "\e[32m✓ Rule added: Allow from $ip\e[0m"
            ;;
        5)
            read -p "Enter IP address: " ip
            read -p "Enter port number: " port
            read -p "Protocol (tcp/udp/both): " proto
            read -p "Enter comment (optional): " comment
            
            if [ "$proto" = "both" ]; then
                if [ -n "$comment" ]; then
                    sudo ufw allow from $ip to any port $port comment "$comment"
                else
                    sudo ufw allow from $ip to any port $port
                fi
            else
                if [ -n "$comment" ]; then
                    sudo ufw allow from $ip to any port $port proto $proto comment "$comment"
                else
                    sudo ufw allow from $ip to any port $port proto $proto
                fi
            fi
            echo -e "\e[32m✓ Rule added: Allow from $ip to port $port\e[0m"
            ;;
        6)
            read -p "Enter port number: " port
            read -p "Protocol (tcp/udp/both): " proto
            read -p "Enter comment (optional): " comment
            
            if [ "$proto" = "both" ]; then
                if [ -n "$comment" ]; then
                    sudo ufw deny $port comment "$comment"
                else
                    sudo ufw deny $port
                fi
            else
                if [ -n "$comment" ]; then
                    sudo ufw deny $port/$proto comment "$comment"
                else
                    sudo ufw deny $port/$proto
                fi
            fi
            echo -e "\e[32m✓ Rule added: Deny port $port\e[0m"
            ;;
        7)
            echo "Enter custom UFW command (without 'sudo ufw'):"
            read -p "Example: allow from 192.168.1.0/24 to any port 80: " custom_rule
            sudo ufw $custom_rule
            echo -e "\e[32m✓ Custom rule added\e[0m"
            ;;
        0)
            return
            ;;
        *)
            echo -e "\e[31mInvalid option\e[0m"
            ;;
    esac
}

# Function to delete firewall rule
delete_ufw_rule() {
    echo -e "\e[36m╔════════════════════════════════════════════════════════════════════╗\e[0m"
    echo -e "\e[36m║                    Delete UFW Firewall Rule                        ║\e[0m"
    echo -e "\e[36m╚════════════════════════════════════════════════════════════════════╝\e[0m"
    echo ""
    
    # Show numbered rules
    sudo ufw status numbered
    
    echo ""
    read -p "Enter rule number to delete (or 0 to cancel): " rule_num
    
    if [ "$rule_num" = "0" ]; then
        echo "Cancelled."
        return
    fi
    
    # Confirm deletion
    read -p "Are you sure you want to delete rule #$rule_num? (y/n): " confirm
    if [[ $confirm =~ ^[Yy]$ ]]; then
        echo "y" | sudo ufw delete $rule_num
        echo -e "\e[32m✓ Rule #$rule_num deleted\e[0m"
    else
        echo "Cancelled."
    fi
}

# Function to add common service ports
add_common_service() {
    echo -e "\e[36m╔════════════════════════════════════════════════════════════════════╗\e[0m"
    echo -e "\e[36m║                   Add Common Service Ports                         ║\e[0m"
    echo -e "\e[36m╚════════════════════════════════════════════════════════════════════╝\e[0m"
    echo ""
    
    echo "Select service to allow:"
    echo "1.  SSH (22/tcp)"
    echo "2.  HTTP (80/tcp)"
    echo "3.  HTTPS (443/tcp)"
    echo "4.  MySQL/MariaDB (3306/tcp)"
    echo "5.  PostgreSQL (5432/tcp)"
    echo "6.  MongoDB (27017/tcp)"
    echo "7.  Redis (6379/tcp)"
    echo "8.  FTP (21/tcp)"
    echo "9.  SMTP (25/tcp)"
    echo "10. DNS (53/tcp & udp)"
    echo "11. Docker (2375-2376/tcp)"
    echo "12. Node Exporter (9100/tcp)"
    echo "13. Prometheus (9090/tcp)"
    echo "14. Grafana (3000/tcp)"
    echo "15. SQL Server (1433/tcp)"
    echo "0.  Cancel"
    echo ""
    read -p "Choose service (0-15): " service
    
    case $service in
        1)
            sudo ufw allow 22/tcp comment 'SSH'
            echo -e "\e[32m✓ Allowed SSH (22/tcp)\e[0m"
            ;;
        2)
            sudo ufw allow 80/tcp comment 'HTTP'
            echo -e "\e[32m✓ Allowed HTTP (80/tcp)\e[0m"
            ;;
        3)
            sudo ufw allow 443/tcp comment 'HTTPS'
            echo -e "\e[32m✓ Allowed HTTPS (443/tcp)\e[0m"
            ;;
        4)
            sudo ufw allow 3306/tcp comment 'MySQL'
            echo -e "\e[32m✓ Allowed MySQL (3306/tcp)\e[0m"
            ;;
        5)
            sudo ufw allow 5432/tcp comment 'PostgreSQL'
            echo -e "\e[32m✓ Allowed PostgreSQL (5432/tcp)\e[0m"
            ;;
        6)
            sudo ufw allow 27017/tcp comment 'MongoDB'
            echo -e "\e[32m✓ Allowed MongoDB (27017/tcp)\e[0m"
            ;;
        7)
            sudo ufw allow 6379/tcp comment 'Redis'
            echo -e "\e[32m✓ Allowed Redis (6379/tcp)\e[0m"
            ;;
        8)
            sudo ufw allow 21/tcp comment 'FTP'
            echo -e "\e[32m✓ Allowed FTP (21/tcp)\e[0m"
            ;;
        9)
            sudo ufw allow 25/tcp comment 'SMTP'
            echo -e "\e[32m✓ Allowed SMTP (25/tcp)\e[0m"
            ;;
        10)
            sudo ufw allow 53/tcp comment 'DNS'
            sudo ufw allow 53/udp comment 'DNS'
            echo -e "\e[32m✓ Allowed DNS (53/tcp & udp)\e[0m"
            ;;
        11)
            sudo ufw allow 2375:2376/tcp comment 'Docker'
            echo -e "\e[32m✓ Allowed Docker (2375-2376/tcp)\e[0m"
            ;;
        12)
            sudo ufw allow 9100/tcp comment 'Node Exporter'
            echo -e "\e[32m✓ Allowed Node Exporter (9100/tcp)\e[0m"
            ;;
        13)
            sudo ufw allow 9090/tcp comment 'Prometheus'
            echo -e "\e[32m✓ Allowed Prometheus (9090/tcp)\e[0m"
            ;;
        14)
            sudo ufw allow 3000/tcp comment 'Grafana'
            echo -e "\e[32m✓ Allowed Grafana (3000/tcp)\e[0m"
            ;;
        15)
            sudo ufw allow 1433/tcp comment 'SQL Server'
            echo -e "\e[32m✓ Allowed SQL Server (1433/tcp)\e[0m"
            ;;
        0)
            return
            ;;
        *)
            echo -e "\e[31mInvalid option\e[0m"
            ;;
    esac
}

# Function to reset UFW to defaults
reset_ufw() {
    echo -e "\e[31m⚠ WARNING: This will delete ALL firewall rules!\e[0m"
    read -p "Are you sure you want to reset UFW? (type 'yes' to confirm): " confirm
    
    if [ "$confirm" = "yes" ]; then
        echo "y" | sudo ufw reset
        echo -e "\e[32m✓ UFW reset to defaults\e[0m"
        echo -e "\e[33m⚠ UFW is now disabled. Enable it with option 2.\e[0m"
    else
        echo "Cancelled."
    fi
}

# Function to configure default policies
configure_defaults() {
    echo -e "\e[36m╔════════════════════════════════════════════════════════════════════╗\e[0m"
    echo -e "\e[36m║                   Configure Default Policies                       ║\e[0m"
    echo -e "\e[36m╚════════════════════════════════════════════════════════════════════╝\e[0m"
    echo ""
    
    echo "Current defaults:"
    sudo ufw status verbose | grep "Default:"
    echo ""
    
    echo "Set default policy for INCOMING traffic:"
    echo "1. Deny (recommended)"
    echo "2. Allow"
    echo "3. Reject"
    read -p "Choose (1-3): " incoming
    
    case $incoming in
        1) sudo ufw default deny incoming ;;
        2) sudo ufw default allow incoming ;;
        3) sudo ufw default reject incoming ;;
        *) echo "Invalid option" ; return ;;
    esac
    
    echo ""
    echo "Set default policy for OUTGOING traffic:"
    echo "1. Allow (recommended)"
    echo "2. Deny"
    echo "3. Reject"
    read -p "Choose (1-3): " outgoing
    
    case $outgoing in
        1) sudo ufw default allow outgoing ;;
        2) sudo ufw default deny outgoing ;;
        3) sudo ufw default reject outgoing ;;
        *) echo "Invalid option" ; return ;;
    esac
    
    echo ""
    echo -e "\e[32m✓ Default policies updated\e[0m"
    sudo ufw status verbose | grep "Default:"
}

# Function to enable/disable logging
configure_logging() {
    echo -e "\e[36m╔════════════════════════════════════════════════════════════════════╗\e[0m"
    echo -e "\e[36m║                      Configure UFW Logging                         ║\e[0m"
    echo -e "\e[36m╚════════════════════════════════════════════════════════════════════╝\e[0m"
    echo ""
    
    echo "Current logging level:"
    sudo ufw status verbose | grep "Logging:"
    echo ""
    
    echo "Select logging level:"
    echo "1. Off"
    echo "2. Low"
    echo "3. Medium"
    echo "4. High"
    echo "5. Full"
    read -p "Choose (1-5): " log_level
    
    case $log_level in
        1) sudo ufw logging off ;;
        2) sudo ufw logging low ;;
        3) sudo ufw logging medium ;;
        4) sudo ufw logging high ;;
        5) sudo ufw logging full ;;
        *) echo "Invalid option" ; return ;;
    esac
    
    echo -e "\e[32m✓ Logging level updated\e[0m"
}

# Main UFW management menu
ufw_menu() {
    if ! check_ufw_installed; then
        return
    fi
    
    while true; do
        show_ufw_status
        echo ""
        echo -e "\e[1m\e[32m📋 UFW MANAGEMENT MENU\e[0m"
        echo -e "\e[32m─────────────────────────────────────────────────────────────────────\e[0m"
        echo "1.  Enable UFW"
        echo "2.  Disable UFW"
        echo "3.  Add firewall rule (custom)"
        echo "4.  Add common service port"
        echo "5.  Delete firewall rule"
        echo "6.  Configure default policies"
        echo "7.  Configure logging"
        echo "8.  Reset UFW (delete all rules)"
        echo "9.  Reload UFW"
        echo "10. Show detailed status"
        echo "0.  Back to main menu"
        echo -e "\e[32m─────────────────────────────────────────────────────────────────────\e[0m"
        read -p "Choose an option (0-10): " choice
        
        case $choice in
            1)
                enable_ufw
                ;;
            2)
                disable_ufw
                ;;
            3)
                add_ufw_rule
                ;;
            4)
                add_common_service
                ;;
            5)
                delete_ufw_rule
                ;;
            6)
                configure_defaults
                ;;
            7)
                configure_logging
                ;;
            8)
                reset_ufw
                ;;
            9)
                sudo ufw reload
                echo -e "\e[32m✓ UFW reloaded\e[0m"
                ;;
            10)
                sudo ufw status verbose
                ;;
            0)
                return
                ;;
            *)
                echo -e "\e[31mInvalid option. Please choose 0-10.\e[0m"
                ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
    done
}
