#!/bin/bash

# Ubuntu Tools Server Menu
# Created by Mahardian Ramadhani
# Compatible with Ubuntu 22.04 and 24.04

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load all script modules
source "$SCRIPT_DIR/scripts/network.sh"
source "$SCRIPT_DIR/scripts/ssh.sh"
source "$SCRIPT_DIR/scripts/apache.sh"
source "$SCRIPT_DIR/scripts/nginx.sh"
source "$SCRIPT_DIR/scripts/mysql.sh"
source "$SCRIPT_DIR/scripts/postgresql.sh"
source "$SCRIPT_DIR/scripts/php.sh"
source "$SCRIPT_DIR/scripts/docker.sh"
source "$SCRIPT_DIR/scripts/nodejs.sh"
source "$SCRIPT_DIR/scripts/python.sh"
source "$SCRIPT_DIR/scripts/git.sh"
source "$SCRIPT_DIR/scripts/odbc.sh"
source "$SCRIPT_DIR/scripts/composer.sh"
source "$SCRIPT_DIR/scripts/ssl.sh"
source "$SCRIPT_DIR/scripts/laravel.sh"
source "$SCRIPT_DIR/scripts/monitoring.sh"
source "$SCRIPT_DIR/scripts/ufw.sh"
source "$SCRIPT_DIR/scripts/uninstaller.sh"
source "$SCRIPT_DIR/scripts/status.sh"

# Function to get system info
get_system_info() {
    echo -e "\e[33m======================================\e[0m"
    echo -e "\e[33m         System Information\e[0m"
    echo -e "\e[33m======================================\e[0m"
    printf "\e[36m%-20s %s\e[0m\n" "OS:" "$(lsb_release -d | cut -f2)"
    printf "\e[36m%-20s %s\e[0m\n" "Kernel:" "$(uname -r)"
    printf "\e[36m%-20s %s\e[0m\n" "Hostname:" "$(hostname)"
    local cpu_info
    cpu_info=$(lscpu | grep 'Model name' | cut -d: -f2 | xargs)
    printf "\e[36m%-20s %s\e[0m\n" "CPU:" "$cpu_info"
    printf "\e[36m%-20s %s\e[0m\n" "RAM:" "$(free -h | grep Mem | awk '{print $2}')"
    printf "\e[36m%-20s %s\e[0m\n" "Disk Usage:" "$(df -h / | tail -1 | awk '{print "Total: " $2 ", Used: " $3 ", Free: " $4}')"
    printf "\e[36m%-20s %s\e[0m\n" "Uptime:" "$(uptime -p)"
    printf "\e[36m%-20s %s\e[0m\n" "Open Ports:" "$(ss -tuln | grep LISTEN | awk '{print $5}' | cut -d: -f2 | sort -u | tr '\n' ',' | sed 's/,$//')"
    echo -e "\e[33m======================================\e[0m"
}

# Function to get service status with icon
get_service_status() {
    local service=$1
    if systemctl is-active --quiet "$service" 2>/dev/null; then
        echo -e "\e[32m●\e[0m"  # Green dot
    else
        echo -e "\e[31m○\e[0m"  # Red dot
    fi
}

# Function to check if command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Function to get SSL certificate info
get_ssl_info() {
    local domain=$1
    local cert_file=$2
    
    if [ -f "$cert_file" ]; then
        local expiry days_left
        expiry=$(openssl x509 -in "$cert_file" -noout -enddate 2>/dev/null | cut -d= -f2)
        days_left=$(( ($(date -d "$expiry" +%s) - $(date +%s)) / 86400 ))
        
        if [ $days_left -lt 0 ]; then
            echo -e "\e[31m✗ Expired\e[0m"
        elif [ $days_left -lt 30 ]; then
            echo -e "\e[33m⚠ ${days_left}d left\e[0m"
        else
            echo -e "\e[32m✓ ${days_left}d left\e[0m"
        fi
    else
        echo -e "\e[90m- Not configured\e[0m"
    fi
}

# Function to display interactive dashboard
display_dashboard() {
    clear
    echo -e "\e[36m╔════════════════════════════════════════════════════════════════════╗\e[0m"
    echo -e "\e[36m║           Ubuntu Tools Server - Interactive Dashboard              ║\e[0m"
    echo -e "\e[36m╚════════════════════════════════════════════════════════════════════╝\e[0m"
    echo ""
    
    # System Overview
    echo -e "\e[1m\e[33m📊 SYSTEM OVERVIEW\e[0m"
    echo -e "─────────────────────────────────────────────────────────────────────"
    printf "%-25s %s\n" "OS:" "$(lsb_release -ds 2>/dev/null || echo 'Unknown')"
    printf "%-25s %s\n" "Hostname:" "$(hostname)"
    printf "%-25s %s\n" "IP Address:" "$(hostname -I | awk '{print $1}')"
    printf "%-25s %s\n" "Uptime:" "$(uptime -p | sed 's/up //')"
    
    # Get memory info
    local mem_total mem_used mem_percent
    mem_total=$(free -h | grep Mem | awk '{print $2}')
    mem_used=$(free -h | grep Mem | awk '{print $3}')
    mem_percent=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100}')
    printf "%-25s %s / %s (%s%%)\n" "Memory:" "$mem_used" "$mem_total" "$mem_percent"
    
    # Get disk info
    local disk_usage
    disk_usage=$(df -h / | tail -1 | awk '{print $3 " / " $2 " (" $5 ")}')
    printf "%-25s %s\n" "Disk Usage:" "$disk_usage"
    
    echo ""
    
    # Services Status
    echo -e "\e[1m\e[33m🔧 SERVICES STATUS\e[0m"
    echo -e "─────────────────────────────────────────────────────────────────────"
    
    # Web Servers
    echo -e "\e[1mWeb Servers:\e[0m"
    printf "  %s %-20s" "$(get_service_status nginx)" "Nginx"
    if systemctl is-active --quiet nginx; then
        echo -e "\e[32m[Running]\e[0m"
    else
        echo -e "\e[90m[Not installed]\e[0m"
    fi
    
    printf "  %s %-20s" "$(get_service_status apache2)" "Apache"
    if systemctl is-active --quiet apache2; then
        echo -e "\e[32m[Running]\e[0m"
    else
        echo -e "\e[90m[Not installed]\e[0m"
    fi
    
    # PHP Versions
    echo -e "\n\e[1mPHP-FPM:\e[0m"
    local php_found=false
    for version in 8.4 8.3 8.2 8.1 8.0 7.4; do
        if systemctl list-units --full --all | grep -q "php${version}-fpm.service"; then
            printf "  %s %-20s" "$(get_service_status php${version}-fpm)" "PHP ${version}-FPM"
            if systemctl is-active --quiet php${version}-fpm; then
                echo -e "\e[32m[Running]\e[0m"
            else
                echo -e "\e[31m[Stopped]\e[0m"
            fi
            php_found=true
        fi
    done
    if [ "$php_found" = false ]; then
        echo -e "  \e[90m○ No PHP-FPM installed\e[0m"
    fi
    
    # Databases
    echo -e "\n\e[1mDatabases:\e[0m"
    printf "  %s %-20s" "$(get_service_status mysql)" "MySQL"
    if systemctl is-active --quiet mysql; then
        echo -e "\e[32m[Running]\e[0m"
    else
        echo -e "\e[90m[Not installed]\e[0m"
    fi
    
    printf "  %s %-20s" "$(get_service_status postgresql)" "PostgreSQL"
    if systemctl is-active --quiet postgresql; then
        echo -e "\e[32m[Running]\e[0m"
    else
        echo -e "\e[90m[Not installed]\e[0m"
    fi
    
    # Other Services
    echo -e "\n\e[1mOther Services:\e[0m"
    printf "  %s %-20s" "$(get_service_status docker)" "Docker"
    if systemctl is-active --quiet docker; then
        echo -e "\e[32m[Running]\e[0m"
    else
        echo -e "\e[90m[Not installed]\e[0m"
    fi
    
    printf "  %s %-20s" "$(get_service_status node_exporter)" "Node Exporter"
    if systemctl is-active --quiet node_exporter; then
        echo -e "\e[32m[Running]\e[0m"
    else
        echo -e "\e[90m[Not installed]\e[0m"
    fi
    
    # UFW Firewall Status
    if command -v ufw &> /dev/null; then
        local ufw_status
        ufw_status=$(timeout 1 sudo -n ufw status 2>/dev/null | grep -i "Status:" | awk '{print $2}' || echo "unknown")
        printf "  "
        if [ "$ufw_status" = "active" ]; then
            echo -e "\e[32m● UFW Firewall        [Active]\e[0m"
        elif [ "$ufw_status" = "inactive" ]; then
            echo -e "\e[33m○ UFW Firewall        [Inactive]\e[0m"
        else
            echo -e "\e[90m○ UFW Firewall        [Status unknown]\e[0m"
        fi
    else
        printf "  \e[90m○ UFW Firewall        [Not installed]\e[0m\n"
    fi
    
    echo ""
    
    # Installed Tools
    echo -e "\e[1m\e[33m📦 INSTALLED TOOLS\e[0m"
    echo -e "─────────────────────────────────────────────────────────────────────"
    
    # Check each tool
    printf "  "
    if command_exists composer; then
        echo -ne "\e[32m✓\e[0m Composer $(composer --version 2>/dev/null | head -1 | awk '{print $3}')  "
    else
        echo -ne "\e[90m✗ Composer\e[0m  "
    fi
    
    if command_exists git; then
        echo -ne "\e[32m✓\e[0m Git $(git --version | awk '{print $3}')  "
    else
        echo -ne "\e[90m✗ Git\e[0m  "
    fi
    
    if command_exists node; then
        echo -ne "\e[32m✓\e[0m Node.js $(node --version)  "
    else
        echo -ne "\e[90m✗ Node.js\e[0m  "
    fi
    echo ""
    
    printf "  "
    if command_exists python3; then
        echo -ne "\e[32m✓\e[0m Python $(python3 --version | awk '{print $2}')  "
    else
        echo -ne "\e[90m✗ Python\e[0m  "
    fi
    
    # Check ODBC using for loop
    local odbc_found=false
    for file in /opt/microsoft/msodbcsql17/lib64/libmsodbcsql-17*.so*; do
        if [ -f "$file" ]; then
            odbc_found=true
            break
        fi
    done
    if [ "$odbc_found" = true ]; then
        echo -ne "\e[32m✓\e[0m ODBC 17  "
    else
        echo -ne "\e[90m✗ ODBC 17\e[0m  "
    fi
    
    if command_exists node_exporter; then
        echo -ne "\e[32m✓\e[0m Node Exporter  "
    else
        echo -ne "\e[90m✗ Node Exporter\e[0m  "
    fi
    echo ""
    
    echo ""
    
    # Network Configuration
    echo -e "\e[1m\e[33m🌐 NETWORK CONFIGURATION\e[0m"
    echo -e "─────────────────────────────────────────────────────────────────────"
    
    # DNS Servers
    local dns_servers
    dns_servers=$(grep "^nameserver" /etc/resolv.conf 2>/dev/null | awk '{print $2}' | tr '\n' ', ' | sed 's/,$//')
    if [ -n "$dns_servers" ]; then
        printf "%-25s %s\n" "DNS Servers:" "$dns_servers"
    else
        printf "%-25s %s\n" "DNS Servers:" "Default"
    fi
    
    # Hostname & FQDN
    printf "%-25s %s\n" "Hostname:" "$(hostname)"
    printf "%-25s %s\n" "FQDN:" "$(hostname -f 2>/dev/null || echo 'Not configured')"
    
    # Open Ports
    local open_ports
    open_ports=$(ss -tuln | grep LISTEN | awk '{print $5}' | cut -d: -f2 | sort -un | head -10 | tr '\n' ',' | sed 's/,$//')
    printf "%-25s %s\n" "Open Ports:" "$open_ports"
    
    echo ""
    
    # SSL Certificates Status
    echo -e "\e[1m\e[33m🔒 SSL CERTIFICATES\e[0m"
    echo -e "─────────────────────────────────────────────────────────────────────"
    
    # Count SSL certificates
    local ssl_count=0
    
    # Check Nginx SSL configs
    if [ -d /etc/nginx/sites-enabled ]; then
        for site in /etc/nginx/sites-enabled/*; do
            if [ -f "$site" ] && grep -q "ssl_certificate" "$site" 2>/dev/null; then
                local domain cert_file
                domain=$(basename "$site")
                cert_file=$(grep "ssl_certificate " "$site" | grep -v "ssl_certificate_key" | head -1 | awk '{print $2}' | tr -d ';')
                
                printf "  %-30s " "$domain"
                
                if [ -f "$cert_file" ]; then
                    # Check if Let's Encrypt or self-signed
                    if echo "$cert_file" | grep -q "letsencrypt"; then
                        echo -ne "\e[36m[Let's Encrypt]\e[0m "
                    else
                        echo -ne "\e[35m[Self-Signed]\e[0m   "
                    fi
                    
                    # Get expiry info
                    local expiry days_left
                    expiry=$(openssl x509 -in "$cert_file" -noout -enddate 2>/dev/null | cut -d= -f2)
                    if [ -n "$expiry" ]; then
                        days_left=$(( ($(date -d "$expiry" +%s 2>/dev/null || echo 0) - $(date +%s)) / 86400 ))
                        
                        if [ $days_left -lt 0 ]; then
                            echo -e "\e[31m✗ Expired\e[0m"
                        elif [ $days_left -lt 30 ]; then
                            echo -e "\e[33m⚠ Expires in ${days_left} days\e[0m"
                        else
                            echo -e "\e[32m✓ Valid (${days_left} days left)\e[0m"
                        fi
                    else
                        echo -e "\e[90m- Unknown\e[0m"
                    fi
                    ssl_count=$((ssl_count + 1))
                else
                    echo -e "\e[31m✗ Certificate file not found\e[0m"
                fi
            fi
        done
    fi
    
    if [ $ssl_count -eq 0 ]; then
        echo -e "  \e[90mNo SSL certificates configured\e[0m"
    fi
    
    echo ""
    
    # Laravel Projects
    echo -e "\e[1m\e[33m🚀 LARAVEL PROJECTS\e[0m"
    echo -e "─────────────────────────────────────────────────────────────────────"
    
    if [ -d /var/www ]; then
        local laravel_found=false
        for project in /var/www/*; do
            if [ -d "$project" ] && [ -f "$project/artisan" ]; then
                local project_name owner
                project_name=$(basename "$project")
                printf "  %-30s " "$project_name"
                
                # Check if has .env
                if [ -f "$project/.env" ]; then
                    echo -ne "\e[32m[Configured]\e[0m "
                else
                    echo -ne "\e[33m[Not configured]\e[0m "
                fi
                
                # Check ownership
                owner=$(stat -c '%U' "$project")
                echo -e "Owner: $owner"
                
                laravel_found=true
            fi
        done
        
        if [ "$laravel_found" = false ]; then
            echo -e "  \e[90mNo Laravel projects found in /var/www\e[0m"
        fi
    else
        echo -e "  \e[90m/var/www directory not found\e[0m"
    fi
    
    echo ""
    echo -e "\e[36m═════════════════════════════════════════════════════════════════════\e[0m"
    echo -e "\e[90mLast updated: $(date '+%Y-%m-%d %H:%M:%S')\e[0m"
    echo -e "\e[36m═════════════════════════════════════════════════════════════════════\e[0m"
}

# Function to display menu
display_menu() {
    display_dashboard
    echo ""
    echo -e "\e[1m\e[32m📋 MENU OPTIONS\e[0m"
    echo -e "\e[32m─────────────────────────────────────────────────────────────────────\e[0m"
    echo -e "\e[32m1.  Set Static IP Address             13. Install PostgreSQL Server\e[0m"
    echo -e "\e[91m2.  UFW Firewall Management\e[32m            14. Show Installed Tools Status\e[0m"
    echo -e "\e[32m3.  Install SSH Server                 15. Setup Nginx Configuration\e[0m"
    echo -e "\e[32m4.  Install Apache Web Server          16. Install Composer\e[0m"
    echo -e "\e[32m5.  Install Nginx Web Server           17. Setup Project Folder for Nginx\e[0m"
    echo -e "\e[32m6.  Install MySQL Server               18. Install Python3 and Pip\e[0m"
    echo -e "\e[32m7.  Install PHP (Multi-Version)        19. Change Hostname & FQDN\e[0m"
    echo -e "\e[32m8.  Install Docker                     20. Configure DNS Nameservers\e[0m"
    echo -e "\e[32m9.  Install Node.js (Multi-Version)\e[35m    21. SSL: Local (Self-Signed)\e[0m"
    echo -e "\e[32m10. Install Git\e[36m                        22. SSL: Public (Let's Encrypt)\e[0m"
    echo -e "\e[32m11. Install ODBC SQL Server 17\e[93m         23. Deploy Laravel from GitHub\e[0m"
    echo -e "\e[32m12. Manage GitHub SSH Key\e[95m              24. Monitoring: Node Exporter\e[0m"
    echo -e "\e[31m                                       25. Auto Uninstaller (Remove Apps)\e[0m"
    echo -e "\e[33m─────────────────────────────────────────────────────────────────────\e[0m"
    echo -e "\e[31m0. Exit\e[0m"
    echo -e "\e[90mCreated by Mahardian Ramadhani\e[0m"
}

# Main menu loop
while true; do
    display_menu
    echo -e "\e[36mChoose an option (0-25):\e[0m"
    read -r choice

    case $choice in
        0)
            echo -e "\e[31mExiting...\e[0m"
            exit 0
            ;;
        1)
            set_static_ip
            ;;
        2)
            ufw_menu
            ;;
        3)
            install_ssh_server
            ;;
        4)
            install_apache
            ;;
        5)
            install_nginx
            ;;
        6)
            install_mysql
            ;;
        7)
            install_php
            ;;
        8)
            install_docker
            ;;
        9)
            install_nodejs
            ;;
        10)
            install_git
            ;;
        11)
            install_odbc_sqlserver
            ;;
        12)
            manage_github_ssh
            ;;
        13)
            install_postgresql
            ;;
        14)
            show_status
            ;;
        15)
            setup_nginx_config
            ;;
        16)
            install_composer
            ;;
        17)
            setup_project_nginx
            ;;
        18)
            install_python
            ;;
        19)
            change_hostname
            ;;
        20)
            configure_dns
            ;;
        21)
            setup_local_ssl
            ;;
        22)
            setup_letsencrypt_ssl
            ;;
        23)
            deploy_laravel_project
            ;;
        24)
            monitoring_menu
            ;;
        25)
            uninstaller_menu
            ;;
        *)
            echo -e "\e[31mInvalid option. Please choose 0-25.\e[0m"
            ;;
    esac
    echo ""
    while true; do
        read -p "Kembali ke menu utama? (y/n): " back_choice
        case $back_choice in
            y|Y)
                break
                ;;
            n|N)
                echo "Exiting..."
                exit 0
                ;;
            *)
                echo "Please enter y or n."
                ;;
        esac
    done
done