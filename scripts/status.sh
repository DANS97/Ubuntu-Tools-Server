#!/bin/bash

# Show installed tools status

show_status() {
    echo -e "\e[33mChecking status of installed tools...\e[0m"
    echo -e "\e[33m======================================\e[0m"

    # Check services
    echo -e "\e[36mService Status:\e[0m"
    services=("ssh" "apache2" "nginx" "mysql" "mariadb" "postgresql" "docker")
    service_names=("SSH Server" "Apache Web Server" "Nginx Web Server" "MySQL Server" "MariaDB Server" "PostgreSQL Server" "Docker")
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
    packages=("openssh-server" "apache2" "nginx" "mysql-server" "mariadb-server" "postgresql" "php" "php7.3" "php7.4" "php8.0" "php8.1" "php8.2" "php8.3" "php8.4" "docker-ce" "nodejs" "python3" "git")
    package_names=("SSH Server" "Apache" "Nginx" "MySQL Server" "MariaDB Server" "PostgreSQL" "PHP (Latest)" "PHP 7.3" "PHP 7.4" "PHP 8.0" "PHP 8.1" "PHP 8.2" "PHP 8.3" "PHP 8.4" "Docker" "Node.js" "Python3" "Git")
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
    
    # Check for NVM
    if [ -d "$HOME/.nvm" ]; then
        echo -e "  \e[32mNVM (Node Version Manager): Installed\e[0m"
    else
        echo -e "  \e[31mNVM: Not installed\e[0m"
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
