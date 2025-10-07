#!/bin/bash

# Ubuntu Tools Server Menu
# Created by Mahardian Ramadhani
# Compatible with Ubuntu 22.04 and 24.04

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
    echo -e "\e[34m╔══════════════════════════════════════╗\e[0m"
    echo -e "\e[34m║        Ubuntu Tools Server Menu      ║\e[0m"
    echo -e "\e[34m╚══════════════════════════════════════╝\e[0m"
    echo -e "\e[31m0. Exit\e[0m"
    echo ""
    printf "\e[32m%-40s %s\e[0m\n" "1. Set Static IP Address" "10. Install Python3 and Pip"
    printf "\e[32m%-40s %s\e[0m\n" "2. Allow Port" "11. Install Git"
    printf "\e[32m%-40s %s\e[0m\n" "3. Install SSH Server" "12. Change Hostname"
    printf "\e[32m%-40s %s\e[0m\n" "4. Install Apache Web Server" "13. Install ODBC SQL Server 17"
    printf "\e[32m%-40s %s\e[0m\n" "5. Install Nginx Web Server" "14. Install Nginx + ODBC SQL Server 17"
    printf "\e[32m%-40s %s\e[0m\n" "6. Install MySQL Server" "15. Show Installed Tools Status"
    printf "\e[32m%-40s %s\e[0m\n" "7. Install PHP" "16. Setup Nginx Configuration"
    printf "\e[32m%-40s %s\e[0m\n" "8. Install Docker" "17. Install Composer"
    printf "\e[32m%-40s %s\e[0m\n" "9. Install Node.js" "18. Setup Project Folder for Nginx"
    echo -e "\e[33m═══════════════════════════════════════\e[0m"
    echo -e "\e[37mCreated by Mahardian Ramadhani\e[0m"
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

# Function to install SSH server
install_ssh_server() {
    echo "Installing SSH Server..."
    sudo apt update
    sudo apt install -y openssh-server
    sudo systemctl enable ssh
    sudo systemctl start ssh
    echo -e "\e[32mSSH Server installed and started.\e[0m"
    echo -e "\e[33mDefault SSH port is 22. Make sure to allow it in firewall if needed.\e[0m"
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

    echo "Do you want to install ODBC SQL Server 17 as well? (y/n):"
    read -r odbc_choice
    if [[ $odbc_choice =~ ^[Yy]$ ]]; then
        install_odbc_sqlserver
    fi
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

# Function to show installed tools status
show_status() {
    echo -e "\e[33mChecking status of installed tools...\e[0m"
    echo -e "\e[33m======================================\e[0m"

    # Check services
    echo -e "\e[36mService Status:\e[0m"
    services=("ssh" "apache2" "nginx" "mysql" "docker")
    service_names=("SSH Server" "Apache Web Server" "Nginx Web Server" "MySQL Server" "Docker")
    for i in "${!services[@]}"; do
        service="${services[$i]}"
        name="${service_names[$i]}"
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            echo -e "  \e[32m$name: Running\e[0m"
        elif systemctl is-enabled --quiet "$service" 2>/dev/null; then
            echo -e "  \e[33m$name: Installed (not running)\e[0m"
        else
            echo -e "  \e[31m$name: Not installed\e[0m"
        fi
    done

    echo ""
    echo -e "\e[36mPackage Status:\e[0m"
    packages=("openssh-server" "apache2" "nginx" "mysql-server" "php" "php7.3" "php8.3" "php8.4" "docker-ce" "nodejs" "python3" "git")
    package_names=("SSH Server" "Apache" "Nginx" "MySQL Server" "PHP (Latest)" "PHP 7.3" "PHP 8.3" "PHP 8.4" "Docker" "Node.js" "Python3" "Git")
    for i in "${!packages[@]}"; do
        pkg="${packages[$i]}"
        name="${package_names[$i]}"
        if dpkg -l | grep -q "^ii.*$pkg"; then
            version=$(dpkg -l | grep "^ii.*$pkg" | head -1 | awk '{print $3}')
            echo -e "  \e[32m$name: Installed (v$version)\e[0m"
        else
            echo -e "  \e[31m$name: Not installed\e[0m"
        fi
    done

    # Special check for ODBC SQL Server 17
    if [ -d "/opt/microsoft/msodbcsql17" ] || apt list --installed 2>/dev/null | grep -q msodbcsql17; then
        odbc_version=$(apt list --installed 2>/dev/null | grep msodbcsql17 | awk '{print $2}' | cut -d: -f2 || echo "17.x")
        echo -e "  \e[32mODBC SQL Server 17: Installed (v$odbc_version)\e[0m"
    else
        echo -e "  \e[31mODBC SQL Server 17: Not installed\e[0m"
    fi

    # Check for Composer
    if command -v composer &> /dev/null; then
        composer_version=$(composer --version | grep -oP 'version \K[^\s]+')
        echo -e "  \e[32mComposer: Installed (v$composer_version)\e[0m"
    else
        echo -e "  \e[31mComposer: Not installed\e[0m"
    fi

    echo ""
    echo -e "\e[36mFirewall Status:\e[0m"
    if sudo ufw status | grep -q "Status: active"; then
        echo -e "  \e[32mUFW: Active\e[0m"
        sudo ufw status | grep -E "^[0-9]+|^--"
    else
        echo -e "  \e[31mUFW: Inactive\e[0m"
    fi

    echo ""
    echo -e "\e[36mNetwork Configuration:\e[0m"
    echo -e "  \e[35mCurrent IP:\e[0m $(hostname -I | awk '{print $1}')"
    echo -e "  \e[35mHostname:\e[0m $(hostname)"

    echo -e "\e[33m======================================\e[0m"
}

# Function to setup Nginx configuration
setup_nginx_config() {
    echo "Setting up Nginx Configuration..."
    echo "Choose configuration type:"
    echo "1. Basic PHP-FPM setup"
    echo "2. Custom site configuration"
    echo "3. Back to main menu"
    read -r config_choice

    case $config_choice in
        1)
            # Check if PHP is installed
            if ! dpkg -l | grep -q "^ii.*php.*fpm"; then
                echo "PHP-FPM not found. Installing PHP Latest..."
                install_php
            fi

            # Create basic PHP site
            sudo tee /etc/nginx/sites-available/default_php > /dev/null <<EOF
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    root /var/www/html;
    index index.php index.html index.htm;

    server_name _;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php-fpm.sock;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

            # Enable site
            sudo ln -sf /etc/nginx/sites-available/default_php /etc/nginx/sites-enabled/
            sudo nginx -t && sudo systemctl reload nginx
            echo "Nginx configured with PHP-FPM. Site enabled at /etc/nginx/sites-enabled/default_php"
            ;;
        2)
            echo "Enter site name (e.g., mysite):"
            read -r site_name
            echo "Enter document root path (e.g., /var/www/mysite):"
            read -r doc_root
            echo "Enter server name (e.g., example.com or _ for default):"
            read -r server_name

            # Create custom site
            sudo tee /etc/nginx/sites-available/$site_name > /dev/null <<EOF
server {
    listen 80;
    listen [::]:80;

    root $doc_root;
    index index.html index.htm index.php;

    server_name $server_name;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php-fpm.sock;
    }
}
EOF

            # Enable site
            sudo ln -sf /etc/nginx/sites-available/$site_name /etc/nginx/sites-enabled/
            sudo nginx -t && sudo systemctl reload nginx
            echo "Custom site '$site_name' created and enabled."
            ;;
        3)
            return
            ;;
        *)
            echo "Invalid option."
            ;;
    esac
}

# Function to install Composer
install_composer() {
    echo "Installing Composer..."
    # Check if PHP is installed
    if ! command -v php &> /dev/null; then
        echo "PHP not found. Installing PHP Latest first..."
        install_php
    fi

    # Download and install Composer
    curl -sS https://getcomposer.org/installer | php
    sudo mv composer.phar /usr/local/bin/composer
    sudo chmod +x /usr/local/bin/composer
    echo "Composer installed globally. Version: $(composer --version)"
}

# Function to setup project folder for Nginx
setup_project_nginx() {
    echo -e "\e[36mSetting up project folder for Nginx...\e[0m"
    echo "Enter project folder path (e.g., /home/dans/smart-klaim):"
    read -r project_path

    if [ ! -d "$project_path" ]; then
        echo -e "\e[31mFolder does not exist. Creating...\e[0m"
        mkdir -p "$project_path"
    fi

    echo "Enter site name (e.g., smart-klaim):"
    read -r site_name

    echo "Enter server name (e.g., smart-klaim.local or _ for default):"
    read -r server_name

    # Create Nginx site configuration
    sudo tee /etc/nginx/sites-available/$site_name > /dev/null <<EOF
server {
    listen 80;
    listen [::]:80;

    root $project_path;
    index index.php index.html index.htm;

    server_name $server_name;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php-fpm.sock;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

    # Enable site
    sudo ln -sf /etc/nginx/sites-available/$site_name /etc/nginx/sites-enabled/

    # Disable default site if server_name is not default
    if [ "$server_name" != "_" ]; then
        sudo rm -f /etc/nginx/sites-enabled/default
        echo -e "\e[33mDefault Nginx site disabled.\e[0m"
    fi

    sudo nginx -t && sudo systemctl reload nginx
    echo -e "\e[32mProject folder '$project_path' configured for Nginx.\e[0m"
    echo -e "\e[32mSite '$site_name' enabled. Access via http://$server_name\e[0m"
}

# Main menu loop
while true; do
    display_menu
    echo -e "\e[36mChoose an option (0-18):\e[0m"
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
            install_nginx_odbc
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
        *)
            echo -e "\e[31mInvalid option. Please choose 0-18.\e[0m"
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