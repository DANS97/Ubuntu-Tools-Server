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
source "$SCRIPT_DIR/scripts/status.sh"

# Function to get system info
get_system_info() {
    echo -e "\e[33m======================================\e[0m"
    echo -e "\e[33m         System Information\e[0m"
    echo -e "\e[33m======================================\e[0m"
    printf "\e[36m%-20s %s\e[0m\n" "OS:" "$(lsb_release -d | cut -f2)"
    printf "\e[36m%-20s %s\e[0m\n" "Kernel:" "$(uname -r)"
    printf "\e[36m%-20s %s\e[0m\n" "Hostname:" "$(hostname)"
    printf "\e[36m%-20s %s\e[0m\n" "CPU:" "$(lscpu | grep 'Model name' | cut -d: -f2 | xargs)"
    printf "\e[36m%-20s %s\e[0m\n" "RAM:" "$(free -h | grep Mem | awk '{print $2}')"
    printf "\e[36m%-20s %s\e[0m\n" "Disk Usage:" "$(df -h / | tail -1 | awk '{print "Total: " $2 ", Used: " $3 ", Free: " $4}')"
    printf "\e[36m%-20s %s\e[0m\n" "Uptime:" "$(uptime -p)"
    printf "\e[36m%-20s %s\e[0m\n" "Open Ports:" "$(ss -tuln | grep LISTEN | awk '{print $5}' | cut -d: -f2 | sort -u | tr '\n' ',' | sed 's/,$//')"
    echo -e "\e[33m======================================\e[0m"
}

# Function to display menu
display_menu() {
    get_system_info
    printf "\e[32m%-40s %s\e[0m\n" "1. Set Static IP Address" "11. Install Git"
    printf "\e[32m%-40s %s\e[0m\n" "2. Allow Port" "12. Change Hostname"
    printf "\e[32m%-40s %s\e[0m\n" "3. Install SSH Server" "13. Install ODBC SQL Server 17"
    printf "\e[32m%-40s %s\e[0m\n" "4. Install Apache Web Server" "14. Install PostgreSQL Server"
    printf "\e[32m%-40s %s\e[0m\n" "5. Install Nginx Web Server" "15. Show Installed Tools Status"
    printf "\e[32m%-40s %s\e[0m\n" "6. Install MySQL Server" "16. Setup Nginx Configuration"
    printf "\e[32m%-40s %s\e[0m\n" "7. Install PHP (Multi-Version)" "17. Install Composer"
    printf "\e[32m%-40s %s\e[0m\n" "8. Install Docker" "18. Setup Project Folder for Nginx"
    printf "\e[32m%-40s %s\e[0m\n" "9. Install Node.js (Multi-Version)" "19. Install Python3 and Pip"
    printf "\e[32m%-40s %s\e[0m\n" "10. Install Python3 and Pip" ""
    echo -e "\e[33m═══════════════════════════════════════\e[0m"
    echo -e "\e[31m0. Exit\e[0m"
    echo -e "\e[37mCreated by Mahardian Ramadhani\e[0m"
}

# Main menu loop
while true; do
    display_menu
    echo -e "\e[36mChoose an option (0-19):\e[0m"
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
            allow_port
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
            install_python
            ;;
        11)
            install_git
            ;;
        12)
            change_hostname
            ;;
        13)
            install_odbc_sqlserver
            ;;
        14)
            install_postgresql
            ;;
        15)
            show_status
            ;;
        16)
            setup_nginx_config
            ;;
        17)
            install_composer
            ;;
        18)
            setup_project_nginx
            ;;
        19)
            install_python
            ;;
        *)
            echo -e "\e[31mInvalid option. Please choose 0-19.\e[0m"
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