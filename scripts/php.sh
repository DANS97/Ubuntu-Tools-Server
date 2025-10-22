#!/bin/bash

# PHP installation with version selection from official repository

# Function to get available PHP versions from repository
get_php_versions() {
    echo -e "\e[36mFetching available PHP versions from repository...\e[0m"
    sudo apt update -qq 2>/dev/null
    
    # Add ondrej PPA if not already added
    if ! grep -q "ondrej/php" /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null; then
        echo "Adding Ondrej PHP PPA..."
        sudo apt install -y software-properties-common
        sudo add-apt-repository ppa:ondrej/php -y
        sudo apt update -qq 2>/dev/null
    fi
}

# Function to list all available PHP versions
list_php_versions() {
    echo -e "\e[33m======================================\e[0m"
    echo -e "\e[33m    Available PHP Versions\e[0m"
    echo -e "\e[33m======================================\e[0m"
    
    apt-cache search --names-only '^php[0-9]+\.[0-9]+$' | awk '{print $1}' | sort -V | while read pkg; do
        version=$(echo $pkg | sed 's/php//')
        if apt-cache show $pkg &>/dev/null; then
            pkg_version=$(apt-cache policy $pkg | grep Candidate | awk '{print $2}')
            echo -e "  \e[32m✓\e[0m PHP $version ($pkg_version)"
        fi
    done
    echo -e "\e[33m======================================\e[0m"
}

# Function to install PHP with extensions
install_php_version() {
    local php_version=$1
    local php_pkg="php${php_version}"
    
    echo -e "\e[36mInstalling PHP ${php_version}...\e[0m"
    
    # Common PHP extensions
    local extensions=(
        "cli"
        "fpm"
        "mysql"
        "pgsql"
        "sqlite3"
        "curl"
        "gd"
        "mbstring"
        "xml"
        "zip"
        "bcmath"
        "intl"
        "soap"
        "opcache"
        "readline"
    )
    
    # Ask for extensions
    echo ""
    echo "Install common extensions? (recommended)"
    echo "Extensions: ${extensions[*]}"
    read -p "Install all extensions? (y/n): " install_ext
    
    if [[ $install_ext =~ ^[Yy]$ ]]; then
        # Build package list
        local packages="$php_pkg"
        for ext in "${extensions[@]}"; do
            packages="$packages ${php_pkg}-${ext}"
        done
        
        echo -e "\e[36mInstalling PHP ${php_version} with extensions...\e[0m"
        sudo apt install -y $packages
    else
        echo -e "\e[36mInstalling PHP ${php_version} (basic)...\e[0m"
        sudo apt install -y $php_pkg
    fi
    
    # Configure PHP-FPM
    if systemctl list-unit-files | grep -q "${php_pkg}-fpm"; then
        sudo systemctl enable ${php_pkg}-fpm
        sudo systemctl start ${php_pkg}-fpm
        echo -e "\e[32mPHP ${php_version} FPM enabled and started.\e[0m"
    fi
    
    # Show installed version
    if command -v php${php_version} &> /dev/null; then
        echo -e "\e[32m✓ PHP ${php_version} installed successfully!\e[0m"
        php${php_version} -v | head -1
    fi
}

# Function to switch default PHP version
switch_php_version() {
    echo -e "\e[36mAvailable installed PHP versions:\e[0m"
    local installed_versions=()
    
    for version in 7.0 7.1 7.2 7.3 7.4 8.0 8.1 8.2 8.3 8.4; do
        if command -v php${version} &> /dev/null; then
            installed_versions+=("$version")
            echo "  - PHP $version"
        fi
    done
    
    if [ ${#installed_versions[@]} -eq 0 ]; then
        echo -e "\e[31mNo PHP versions found.\e[0m"
        return
    fi
    
    echo ""
    read -p "Enter PHP version to set as default (e.g., 8.3): " target_version
    
    if command -v php${target_version} &> /dev/null; then
        sudo update-alternatives --set php /usr/bin/php${target_version}
        sudo update-alternatives --set phar /usr/bin/phar${target_version}
        sudo update-alternatives --set phar.phar /usr/bin/phar.phar${target_version}
        
        echo -e "\e[32mDefault PHP switched to ${target_version}\e[0m"
        php -v | head -1
    else
        echo -e "\e[31mPHP ${target_version} is not installed.\e[0m"
    fi
}

# Main PHP installation function
install_php() {
    while true; do
        echo ""
        echo -e "\e[33m======================================\e[0m"
        echo -e "\e[33m       PHP Installation Menu\e[0m"
        echo -e "\e[33m======================================\e[0m"
        echo "1. List all available PHP versions from repository"
        echo "2. Install PHP (choose version manually)"
        echo "3. Install PHP 7.4 (Stable/Legacy)"
        echo "4. Install PHP 8.1 (LTS)"
        echo "5. Install PHP 8.2 (Stable)"
        echo "6. Install PHP 8.3 (Latest Stable)"
        echo "7. Install PHP 8.4 (Newest)"
        echo "8. Switch default PHP version"
        echo "9. Show installed PHP versions"
        echo "0. Back to main menu"
        echo -e "\e[33m======================================\e[0m"
        read -p "Choose an option: " php_choice

        case $php_choice in
            1)
                get_php_versions
                list_php_versions
                ;;
            2)
                get_php_versions
                echo ""
                read -p "Enter PHP version to install (e.g., 8.3, 7.4): " custom_version
                if [[ $custom_version =~ ^[0-9]+\.[0-9]+$ ]]; then
                    install_php_version $custom_version
                else
                    echo -e "\e[31mInvalid version format. Use format: 8.3 or 7.4\e[0m"
                fi
                ;;
            3)
                get_php_versions
                install_php_version "7.4"
                ;;
            4)
                get_php_versions
                install_php_version "8.1"
                ;;
            5)
                get_php_versions
                install_php_version "8.2"
                ;;
            6)
                get_php_versions
                install_php_version "8.3"
                ;;
            7)
                get_php_versions
                install_php_version "8.4"
                ;;
            8)
                switch_php_version
                ;;
            9)
                echo -e "\e[36mInstalled PHP versions:\e[0m"
                for version in 7.0 7.1 7.2 7.3 7.4 8.0 8.1 8.2 8.3 8.4; do
                    if command -v php${version} &> /dev/null; then
                        current=""
                        if [ "$(php -v | grep -oP 'PHP \K[0-9]+\.[0-9]+')" = "$version" ]; then
                            current=" \e[32m(default)\e[0m"
                        fi
                        echo -e "  \e[32m✓\e[0m PHP $version$current"
                        php${version} -v | head -1 | sed 's/^/    /'
                    fi
                done
                ;;
            0)
                return
                ;;
            *)
                echo -e "\e[31mInvalid option.\e[0m"
                ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
    done
}
