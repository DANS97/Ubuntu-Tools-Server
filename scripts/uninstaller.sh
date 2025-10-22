#!/bin/bash

# Auto Uninstaller - Remove installed applications

# Function to detect installed applications
detect_installed_apps() {
    local apps=()
    
    # Check Nginx
    if command -v nginx &> /dev/null; then
        apps+=("nginx")
    fi
    
    # Check Apache
    if command -v apache2 &> /dev/null; then
        apps+=("apache2")
    fi
    
    # Check MySQL
    if command -v mysql &> /dev/null || systemctl list-units --full --all | grep -q "mysql.service"; then
        apps+=("mysql")
    fi
    
    # Check PostgreSQL
    if command -v psql &> /dev/null || [ -d /etc/postgresql ]; then
        apps+=("postgresql")
    fi
    
    # Check PHP versions
    for version in 8.4 8.3 8.2 8.1 8.0 7.4; do
        if command -v php${version} &> /dev/null; then
            apps+=("php${version}")
        fi
    done
    
    # Check Docker
    if command -v docker &> /dev/null; then
        apps+=("docker")
    fi
    
    # Check Node.js
    if command -v node &> /dev/null; then
        apps+=("nodejs")
    fi
    
    # Check Composer
    if command -v composer &> /dev/null; then
        apps+=("composer")
    fi
    
    # Check Git
    if command -v git &> /dev/null; then
        apps+=("git")
    fi
    
    # Check Python3
    if command -v python3 &> /dev/null; then
        apps+=("python3")
    fi
    
    # Check ODBC Driver 17
    local odbc_found=false
    for file in /opt/microsoft/msodbcsql17/lib64/libmsodbcsql-17*.so*; do
        if [ -f "$file" ]; then
            odbc_found=true
            break
        fi
    done
    if [ "$odbc_found" = true ]; then
        apps+=("odbc17")
    fi
    
    # Check Node Exporter
    if systemctl list-unit-files | grep -q "node_exporter"; then
        apps+=("node_exporter")
    fi
    
    echo "${apps[@]}"
}

# Function to display installed applications
display_installed_apps() {
    clear
    echo -e "\e[36m╔════════════════════════════════════════════════════════════════════╗\e[0m"
    echo -e "\e[36m║                  Installed Applications Detector                   ║\e[0m"
    echo -e "\e[36m╚════════════════════════════════════════════════════════════════════╝\e[0m"
    echo ""
    
    local apps=($(detect_installed_apps))
    
    if [ ${#apps[@]} -eq 0 ]; then
        echo -e "\e[33m⚠ No applications detected or all core applications are system packages.\e[0m"
        return 1
    fi
    
    echo -e "\e[1m\e[32m📦 INSTALLED APPLICATIONS\e[0m"
    echo -e "─────────────────────────────────────────────────────────────────────"
    
    local index=1
    for app in "${apps[@]}"; do
        case $app in
            nginx)
                version=$(nginx -v 2>&1 | grep -oP '(?<=nginx/)[0-9.]+')
                echo -e "  \e[32m[$index]\e[0m Nginx \e[36m(v$version)\e[0m"
                ;;
            apache2)
                version=$(apache2 -v 2>&1 | grep -oP '(?<=Apache/)[0-9.]+')
                echo -e "  \e[32m[$index]\e[0m Apache \e[36m(v$version)\e[0m"
                ;;
            mysql)
                version=$(mysql --version 2>&1 | grep -oP '(?<=Distrib )[0-9.]+' | head -1)
                echo -e "  \e[32m[$index]\e[0m MySQL \e[36m(v$version)\e[0m"
                ;;
            postgresql)
                versions=$(ls /etc/postgresql/ 2>/dev/null | tr '\n' ', ' | sed 's/,$//')
                echo -e "  \e[32m[$index]\e[0m PostgreSQL \e[36m(versions: $versions)\e[0m"
                ;;
            php*)
                php_ver=$(echo $app | grep -oP '\d+\.\d+')
                echo -e "  \e[32m[$index]\e[0m PHP $php_ver \e[36m(FPM + Extensions)\e[0m"
                ;;
            docker)
                version=$(docker --version 2>&1 | grep -oP '(?<=Docker version )[0-9.]+')
                echo -e "  \e[32m[$index]\e[0m Docker \e[36m(v$version)\e[0m"
                ;;
            nodejs)
                version=$(node --version 2>&1)
                echo -e "  \e[32m[$index]\e[0m Node.js \e[36m($version)\e[0m"
                ;;
            composer)
                version=$(composer --version 2>&1 | grep -oP '(?<=Composer version )[0-9.]+')
                echo -e "  \e[32m[$index]\e[0m Composer \e[36m(v$version)\e[0m"
                ;;
            git)
                version=$(git --version 2>&1 | grep -oP '(?<=git version )[0-9.]+')
                echo -e "  \e[32m[$index]\e[0m Git \e[36m(v$version)\e[0m"
                ;;
            python3)
                version=$(python3 --version 2>&1 | grep -oP '\d+\.\d+\.\d+')
                echo -e "  \e[32m[$index]\e[0m Python3 \e[36m(v$version)\e[0m"
                ;;
            odbc17)
                echo -e "  \e[32m[$index]\e[0m ODBC Driver 17 for SQL Server"
                ;;
            node_exporter)
                version=$(node_exporter --version 2>&1 | grep -oP '(?<=version )[0-9.]+' | head -1)
                echo -e "  \e[32m[$index]\e[0m Node Exporter \e[36m(v$version)\e[0m"
                ;;
        esac
        index=$((index + 1))
    done
    
    echo ""
    echo -e "\e[36m═════════════════════════════════════════════════════════════════════\e[0m"
    
    return 0
}

# Function to uninstall Nginx
uninstall_nginx() {
    echo -e "\e[36mUninstalling Nginx...\e[0m"
    
    # Stop service
    sudo systemctl stop nginx
    sudo systemctl disable nginx
    
    # Remove packages
    sudo apt remove --purge -y nginx nginx-common nginx-core
    sudo apt autoremove -y
    
    # Ask to remove configs
    read -p "Remove Nginx configuration files? (y/n): " remove_config
    if [[ $remove_config =~ ^[Yy]$ ]]; then
        sudo rm -rf /etc/nginx
        sudo rm -rf /var/log/nginx
        sudo rm -rf /var/www/html
        echo -e "\e[32m✓ Configuration files removed\e[0m"
    fi
    
    echo -e "\e[32m✓ Nginx uninstalled successfully\e[0m"
}

# Function to uninstall Apache
uninstall_apache() {
    echo -e "\e[36mUninstalling Apache...\e[0m"
    
    # Stop service
    sudo systemctl stop apache2
    sudo systemctl disable apache2
    
    # Remove packages
    sudo apt remove --purge -y apache2 apache2-utils apache2-bin
    sudo apt autoremove -y
    
    # Ask to remove configs
    read -p "Remove Apache configuration files? (y/n): " remove_config
    if [[ $remove_config =~ ^[Yy]$ ]]; then
        sudo rm -rf /etc/apache2
        sudo rm -rf /var/log/apache2
        echo -e "\e[32m✓ Configuration files removed\e[0m"
    fi
    
    echo -e "\e[32m✓ Apache uninstalled successfully\e[0m"
}

# Function to uninstall MySQL
uninstall_mysql() {
    echo -e "\e[36mUninstalling MySQL...\e[0m"
    echo -e "\e[31m⚠ WARNING: This will remove ALL MySQL databases!\e[0m"
    read -p "Are you sure? Type 'yes' to confirm: " confirm
    
    if [ "$confirm" != "yes" ]; then
        echo "Cancelled."
        return
    fi
    
    # Stop service
    sudo systemctl stop mysql
    sudo systemctl disable mysql
    
    # Remove packages
    sudo apt remove --purge -y mysql-server mysql-client mysql-common mysql-server-core-* mysql-client-core-*
    sudo apt autoremove -y
    
    # Ask to remove data
    read -p "Remove MySQL data directory (/var/lib/mysql)? (y/n): " remove_data
    if [[ $remove_data =~ ^[Yy]$ ]]; then
        sudo rm -rf /var/lib/mysql
        sudo rm -rf /etc/mysql
        sudo rm -rf /var/log/mysql
        echo -e "\e[32m✓ Data and configuration files removed\e[0m"
    fi
    
    echo -e "\e[32m✓ MySQL uninstalled successfully\e[0m"
}

# Function to uninstall PostgreSQL
uninstall_postgresql() {
    echo -e "\e[36mUninstalling PostgreSQL...\e[0m"
    echo -e "\e[31m⚠ WARNING: This will remove ALL PostgreSQL databases!\e[0m"
    read -p "Are you sure? Type 'yes' to confirm: " confirm
    
    if [ "$confirm" != "yes" ]; then
        echo "Cancelled."
        return
    fi
    
    # Detect versions
    local versions=$(ls /etc/postgresql/ 2>/dev/null)
    
    # Stop services
    for version in $versions; do
        sudo systemctl stop postgresql@${version}-main 2>/dev/null
    done
    sudo systemctl stop postgresql 2>/dev/null
    sudo systemctl disable postgresql 2>/dev/null
    
    # Remove packages
    sudo apt remove --purge -y postgresql postgresql-*
    sudo apt autoremove -y
    
    # Ask to remove data
    read -p "Remove PostgreSQL data and configs? (y/n): " remove_data
    if [[ $remove_data =~ ^[Yy]$ ]]; then
        sudo rm -rf /var/lib/postgresql
        sudo rm -rf /etc/postgresql
        sudo rm -rf /var/log/postgresql
        sudo deluser postgres 2>/dev/null
        echo -e "\e[32m✓ Data and configuration files removed\e[0m"
    fi
    
    echo -e "\e[32m✓ PostgreSQL uninstalled successfully\e[0m"
}

# Function to uninstall PHP
uninstall_php() {
    local php_version=$1
    echo -e "\e[36mUninstalling PHP ${php_version}...\e[0m"
    
    # Stop service
    sudo systemctl stop php${php_version}-fpm 2>/dev/null
    sudo systemctl disable php${php_version}-fpm 2>/dev/null
    
    # Remove packages
    sudo apt remove --purge -y php${php_version}*
    sudo apt autoremove -y
    
    # Ask to remove configs
    read -p "Remove PHP ${php_version} configuration files? (y/n): " remove_config
    if [[ $remove_config =~ ^[Yy]$ ]]; then
        sudo rm -rf /etc/php/${php_version}
        echo -e "\e[32m✓ Configuration files removed\e[0m"
    fi
    
    echo -e "\e[32m✓ PHP ${php_version} uninstalled successfully\e[0m"
}

# Function to uninstall Docker
uninstall_docker() {
    echo -e "\e[36mUninstalling Docker...\e[0m"
    echo -e "\e[33m⚠ This will remove Docker and all containers, images, volumes, and networks\e[0m"
    read -p "Are you sure? Type 'yes' to confirm: " confirm
    
    if [ "$confirm" != "yes" ]; then
        echo "Cancelled."
        return
    fi
    
    # Stop service
    sudo systemctl stop docker
    sudo systemctl disable docker
    
    # Remove packages
    sudo apt remove --purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo apt autoremove -y
    
    # Ask to remove data
    read -p "Remove Docker data (/var/lib/docker)? (y/n): " remove_data
    if [[ $remove_data =~ ^[Yy]$ ]]; then
        sudo rm -rf /var/lib/docker
        sudo rm -rf /var/lib/containerd
        sudo rm -rf /etc/docker
        sudo groupdel docker 2>/dev/null
        echo -e "\e[32m✓ Docker data removed\e[0m"
    fi
    
    echo -e "\e[32m✓ Docker uninstalled successfully\e[0m"
}

# Function to uninstall Node.js
uninstall_nodejs() {
    echo -e "\e[36mUninstalling Node.js...\e[0m"
    
    # Check if nvm is used
    if [ -d "$HOME/.nvm" ]; then
        echo "Node.js installed via NVM detected"
        read -p "Remove NVM and all Node.js versions? (y/n): " remove_nvm
        if [[ $remove_nvm =~ ^[Yy]$ ]]; then
            rm -rf "$HOME/.nvm"
            # Remove from bashrc/zshrc
            sed -i '/NVM_DIR/d' ~/.bashrc ~/.zshrc 2>/dev/null
            echo -e "\e[32m✓ NVM removed\e[0m"
        fi
    else
        # System Node.js
        sudo apt remove --purge -y nodejs npm
        sudo apt autoremove -y
        sudo rm -rf /usr/local/lib/node_modules
        sudo rm -rf ~/.npm
        echo -e "\e[32m✓ Node.js uninstalled\e[0m"
    fi
}

# Function to uninstall Composer
uninstall_composer() {
    echo -e "\e[36mUninstalling Composer...\e[0m"
    
    sudo rm -f /usr/local/bin/composer
    rm -rf ~/.composer
    
    echo -e "\e[32m✓ Composer uninstalled successfully\e[0m"
}

# Function to uninstall Git
uninstall_git() {
    echo -e "\e[36mUninstalling Git...\e[0m"
    
    read -p "Remove Git configuration files (~/.gitconfig)? (y/n): " remove_config
    
    sudo apt remove --purge -y git
    sudo apt autoremove -y
    
    if [[ $remove_config =~ ^[Yy]$ ]]; then
        rm -f ~/.gitconfig
        echo -e "\e[32m✓ Git config removed\e[0m"
    fi
    
    echo -e "\e[32m✓ Git uninstalled successfully\e[0m"
}

# Function to uninstall Python3
uninstall_python() {
    echo -e "\e[36mUninstalling Python3 and pip...\e[0m"
    echo -e "\e[33m⚠ Warning: Python3 is used by many system tools\e[0m"
    read -p "Are you sure? (y/n): " confirm
    
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        echo "Cancelled."
        return
    fi
    
    sudo apt remove --purge -y python3-pip python3-venv
    sudo apt autoremove -y
    
    rm -rf ~/.local/lib/python*
    
    echo -e "\e[32m✓ Python3 packages uninstalled\e[0m"
    echo -e "\e[33m⚠ Note: Python3 base package kept (system dependency)\e[0m"
}

# Function to uninstall ODBC Driver 17
uninstall_odbc() {
    echo -e "\e[36mUninstalling ODBC Driver 17...\e[0m"
    
    # Remove ODBC Driver
    sudo apt remove --purge -y msodbcsql17 mssql-tools unixodbc-dev
    sudo apt autoremove -y
    
    # Remove PHP extensions
    for version in 8.4 8.3 8.2 8.1 8.0 7.4; do
        if command -v php${version} &> /dev/null; then
            sudo phpdismod -v ${version} sqlsrv pdo_sqlsrv 2>/dev/null
            sudo pecl uninstall sqlsrv pdo_sqlsrv 2>/dev/null
        fi
    done
    
    sudo rm -rf /opt/microsoft
    
    echo -e "\e[32m✓ ODBC Driver 17 uninstalled successfully\e[0m"
}

# Function to uninstall Node Exporter
uninstall_node_exporter() {
    echo -e "\e[36mUninstalling Node Exporter...\e[0m"
    
    # Stop and disable service
    sudo systemctl stop node_exporter 2>/dev/null
    sudo systemctl disable node_exporter 2>/dev/null
    
    # Remove service file
    sudo rm -f /etc/systemd/system/node_exporter.service
    sudo systemctl daemon-reload
    
    # Remove binary
    sudo rm -f /usr/local/bin/node_exporter
    
    # Remove user
    sudo userdel node_exporter 2>/dev/null
    
    # Remove config
    rm -f ~/.ubuntu-tools/node_exporter.conf
    
    echo -e "\e[32m✓ Node Exporter uninstalled successfully\e[0m"
}

# Main uninstaller menu
uninstaller_menu() {
    while true; do
        if ! display_installed_apps; then
            read -p "Press Enter to return to main menu..."
            return
        fi
        
        echo ""
        echo -e "\e[1m\e[31m🗑️  UNINSTALLER MENU\e[0m"
        echo -e "\e[31m─────────────────────────────────────────────────────────────────────\e[0m"
        echo "Enter application number(s) to uninstall (comma-separated for multiple)"
        echo "Examples: 1   or   1,3,5   or   all"
        echo ""
        echo "0. Back to main menu"
        echo -e "\e[31m─────────────────────────────────────────────────────────────────────\e[0m"
        read -p "Choose: " choice
        
        if [ "$choice" = "0" ]; then
            return
        fi
        
        local apps=($(detect_installed_apps))
        
        if [ "$choice" = "all" ]; then
            echo -e "\e[31m⚠ WARNING: This will uninstall ALL detected applications!\e[0m"
            read -p "Type 'yes' to confirm: " confirm
            if [ "$confirm" != "yes" ]; then
                echo "Cancelled."
                continue
            fi
            
            for i in "${!apps[@]}"; do
                uninstall_app "${apps[$i]}"
            done
        else
            # Split by comma
            local INDICES
            IFS=',' read -r -a INDICES <<< "$choice"
            
            for idx in "${INDICES[@]}"; do
                idx=$(echo "$idx" | xargs)  # Trim whitespace
                
                if [[ ! $idx =~ ^[0-9]+$ ]]; then
                    echo -e "\e[31m✗ Invalid input: $idx\e[0m"
                    continue
                fi
                
                local array_idx=$((idx - 1))
                
                if [ $array_idx -lt 0 ] || [ $array_idx -ge ${#apps[@]} ]; then
                    echo -e "\e[31m✗ Invalid number: $idx\e[0m"
                    continue
                fi
                
                uninstall_app "${apps[$array_idx]}"
            done
        fi
        
        echo ""
        read -p "Press Enter to continue..."
    done
}

# Function to route uninstall to appropriate function
uninstall_app() {
    local app=$1
    
    echo ""
    echo -e "\e[33m═══════════════════════════════════════════════════════════════════════\e[0m"
    
    case $app in
        nginx)
            uninstall_nginx
            ;;
        apache2)
            uninstall_apache
            ;;
        mysql)
            uninstall_mysql
            ;;
        postgresql)
            uninstall_postgresql
            ;;
        php*)
            php_ver=$(echo $app | grep -oP '\d+\.\d+')
            uninstall_php "$php_ver"
            ;;
        docker)
            uninstall_docker
            ;;
        nodejs)
            uninstall_nodejs
            ;;
        composer)
            uninstall_composer
            ;;
        git)
            uninstall_git
            ;;
        python3)
            uninstall_python
            ;;
        odbc17)
            uninstall_odbc
            ;;
        node_exporter)
            uninstall_node_exporter
            ;;
        *)
            echo -e "\e[31m✗ Unknown application: $app\e[0m"
            ;;
    esac
    
    echo -e "\e[33m═══════════════════════════════════════════════════════════════════════\e[0m"
}
