#!/bin/bash

# Ubuntu Tools Server Menu
# Created by Mahardian Ramadhani
# Compatible with Ubuntu 22.04 and 24.04

# Function to get system info
get_system_info() {
    echo "======================================"
    echo "         System Information"
    echo "======================================"
    echo "OS: $(lsb_release -d | cut -f2)"
    echo "Kernel: $(uname -r)"
    echo "Hostname: $(hostname)"
    echo "CPU: $(lscpu | grep 'Model name' | cut -d: -f2 | xargs)"
    echo "RAM: $(free -h | grep Mem | awk '{print $2}')"
    echo "Disk Usage:"
    df -h / | tail -1 | awk '{print "  Total: " $2 ", Used: " $3 ", Free: " $4}'
    echo "======================================"
}

# Function to display menu
display_menu() {
    get_system_info
    echo "    Ubuntu Tools Server Menu"
    echo "    Created by Mahardian Ramadhani"
    echo "======================================"
    echo "1. Set Static IP Address"
    echo "2. Allow Port"
    echo "3. Install SSH Server"
    echo "4. Install Apache Web Server"
    echo "5. Install Nginx Web Server"
    echo "6. Install MySQL Server"
    echo "7. Install PHP"
    echo "8. Install Docker"
    echo "9. Install Node.js"
    echo "10. Install Python3 and Pip"
    echo "11. Install Git"
    echo "12. Change Hostname"
    echo "13. Install ODBC SQL Server 17"
    echo "14. Install Nginx + ODBC SQL Server 17"
    echo "15. Exit"
    echo "======================================"
}

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
    echo "Static IP configured successfully."
}

# Function to allow port
allow_port() {
    echo "Allowing Port..."
    echo "Enter port number to allow:"
    read -r port
    echo "Enter protocol (tcp/udp):"
    read -r protocol

    sudo ufw allow $port/$protocol
    echo "Port $port/$protocol allowed."
}

# Function to install SSH server
install_ssh_server() {
    echo "Installing SSH Server..."
    sudo apt update
    sudo apt install -y openssh-server
    sudo systemctl enable ssh
    sudo systemctl start ssh
    echo "SSH Server installed and started."
    echo "Default SSH port is 22. Make sure to allow it in firewall if needed."
}

# Function to install Apache
install_apache() {
    echo "Installing Apache Web Server..."
    sudo apt update
    sudo apt install -y apache2
    sudo systemctl enable apache2
    sudo systemctl start apache2
    echo "Apache installed and started. Default port 80."
}

# Function to install Nginx
install_nginx() {
    echo "Installing Nginx Web Server..."
    sudo apt update
    sudo apt install -y nginx
    sudo systemctl enable nginx
    sudo systemctl start nginx
    echo "Nginx installed and started. Default port 80."
}

# Function to install MySQL
install_mysql() {
    echo "Installing MySQL Server..."
    sudo apt update
    sudo apt install -y mysql-server
    sudo systemctl enable mysql
    sudo systemctl start mysql
    echo "MySQL installed. Run 'sudo mysql_secure_installation' to secure it."
}

# Function to install PHP
install_php() {
    echo "Select PHP version to install:"
    echo "1. PHP 7.3 (older version)"
    echo "2. PHP Latest (default)"
    echo "3. PHP 8.3"
    echo "4. PHP 8.4"
    echo "5. Back to main menu"
    read -r php_choice

    case $php_choice in
        1)
            echo "Installing PHP 7.3..."
            sudo apt update
            sudo apt install -y software-properties-common
            sudo add-apt-repository ppa:ondrej/php -y
            sudo apt update
            sudo apt install -y php7.3 php7.3-cli php7.3-fpm php7.3-mysql
            echo "PHP 7.3 installed."
            ;;
        2)
            echo "Installing PHP Latest..."
            sudo apt update
            sudo apt install -y php php-cli php-fpm php-mysql
            echo "PHP Latest installed."
            ;;
        3)
            echo "Installing PHP 8.3..."
            sudo apt update
            sudo apt install -y software-properties-common
            sudo add-apt-repository ppa:ondrej/php -y
            sudo apt update
            sudo apt install -y php8.3 php8.3-cli php8.3-fpm php8.3-mysql
            echo "PHP 8.3 installed."
            ;;
        4)
            echo "Installing PHP 8.4..."
            sudo apt update
            sudo apt install -y software-properties-common
            sudo add-apt-repository ppa:ondrej/php -y
            sudo apt update
            sudo apt install -y php8.4 php8.4-cli php8.4-fpm php8.4-mysql
            echo "PHP 8.4 installed."
            ;;
        5)
            return
            ;;
        *)
            echo "Invalid option."
            ;;
    esac
}

# Function to install Docker
install_docker() {
    echo "Installing Docker..."
    sudo apt update
    sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io
    sudo systemctl enable docker
    sudo systemctl start docker
    echo "Docker installed and started."
}

# Function to install Node.js
install_nodejs() {
    echo "Installing Node.js..."
    sudo apt update
    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
    sudo apt install -y nodejs
    echo "Node.js installed."
}

# Function to install Python3 and Pip
install_python() {
    echo "Installing Python3 and Pip..."
    sudo apt update
    sudo apt install -y python3 python3-pip
    echo "Python3 and Pip installed."
}

# Function to install Git
install_git() {
    echo "Installing Git..."
    sudo apt update
    sudo apt install -y git
    echo "Git installed."
}

# Function to change hostname
change_hostname() {
    echo "Current hostname: $(hostname)"
    echo "Enter new hostname:"
    read -r new_hostname
    sudo hostnamectl set-hostname "$new_hostname"
    echo "Hostname changed to $new_hostname. You may need to reboot for changes to take effect."
}

# Function to install ODBC SQL Server 17
install_odbc_sqlserver() {
    echo "Installing ODBC Driver for SQL Server 17..."
    sudo apt update
    sudo apt install -y curl apt-transport-https
    curl https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://packages.microsoft.com/ubuntu/$(lsb_release -rs)/prod $(lsb_release -cs) main"
    sudo apt update
    sudo apt install -y msodbcsql17
    echo "ODBC SQL Server 17 installed."
}

# Function to install Nginx + ODBC SQL Server 17
install_nginx_odbc() {
    echo "Installing Nginx and ODBC Driver for SQL Server 17..."
    install_nginx
    install_odbc_sqlserver
    echo "Nginx and ODBC SQL Server 17 installed."
}

# Main menu loop
while true; do
    display_menu
    echo "Choose an option (1-15):"
    read -r choice

    case $choice in
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
            install_nginx_odbc
            ;;
        15)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid option. Please choose 1-15."
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