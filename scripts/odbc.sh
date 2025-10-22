#!/bin/bash

# ODBC SQL Server 17 installation with PHP extensions and OpenSSL configuration

# Function to configure OpenSSL for SQL Server 2014 compatibility
configure_openssl_for_sqlserver() {
    echo ""
    echo -e "\e[36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
    echo -e "\e[36m   OpenSSL Configuration for SQL Server\e[0m"
    echo -e "\e[36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
    echo ""
    echo "SQL Server 2014 only supports TLS 1.0/1.1"
    echo "Ubuntu 24.04 disables TLS 1.0 by default"
    echo ""
    read -p "Configure OpenSSL for SQL Server 2014 compatibility? (y/n): " config_ssl
    
    if [[ ! $config_ssl =~ ^[Yy]$ ]]; then
        echo "Skipping OpenSSL configuration."
        return 0
    fi
    
    local openssl_conf="/etc/ssl/openssl.cnf"
    
    # Check if already configured
    if grep -q "\[openssl_init\]" "$openssl_conf" 2>/dev/null; then
        echo -e "\e[33m⚠ OpenSSL already configured for SQL Server\e[0m"
        read -p "Reconfigure? (y/n): " reconfig
        if [[ ! $reconfig =~ ^[Yy]$ ]]; then
            return 0
        fi
        # Remove old configuration
        sudo sed -i '/\[openssl_init\]/,/CipherString = DEFAULT@SECLEVEL=0/d' "$openssl_conf"
    fi
    
    echo ""
    echo "Backing up OpenSSL configuration..."
    sudo cp "$openssl_conf" "${openssl_conf}.backup.$(date +%Y%m%d_%H%M%S)"
    
    echo "Adding SQL Server compatibility configuration..."
    cat <<'EOF' | sudo tee -a "$openssl_conf" > /dev/null

# SQL Server 2014 TLS 1.0/1.1 Compatibility
[openssl_init]
ssl_conf = ssl_sect

[ssl_sect]
system_default = system_default_sect

[system_default_sect]
MinProtocol = TLSv1
CipherString = DEFAULT@SECLEVEL=0
EOF

    if [ $? -eq 0 ]; then
        echo -e "\e[32m✓ OpenSSL configured for SQL Server 2014\e[0m"
        echo "  MinProtocol: TLSv1"
        echo "  CipherString: DEFAULT@SECLEVEL=0"
        echo ""
        echo -e "\e[33mNote: This enables TLS 1.0 (less secure but required for SQL Server 2014)\e[0m"
    else
        echo -e "\e[31m✗ Failed to configure OpenSSL\e[0m"
        return 1
    fi
}

# Function to install PHP SQL Server extensions
install_php_sqlsrv_extensions() {
    echo ""
    echo -e "\e[36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
    echo -e "\e[36m   PHP SQL Server Extensions\e[0m"
    echo -e "\e[36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
    echo ""
    echo "Detecting installed PHP versions..."
    
    local installed_php=()
    for version in 8.4 8.3 8.2 8.1 8.0 7.4; do
        if command -v php${version} &> /dev/null; then
            installed_php+=("$version")
        fi
    done
    
    if [ ${#installed_php[@]} -eq 0 ]; then
        echo -e "\e[33m⚠ No PHP installation found\e[0m"
        echo "PHP SQL Server extensions will be skipped."
        echo "Install PHP first (Menu #7), then run this menu again."
        return 0
    fi
    
    echo -e "\e[32m✓ Found PHP versions:\e[0m"
    for ver in "${installed_php[@]}"; do
        echo "  - PHP $ver"
    done
    echo ""
    
    read -p "Install SQL Server extensions for all PHP versions? (y/n): " install_ext
    if [[ ! $install_ext =~ ^[Yy]$ ]]; then
        echo "Skipping PHP extensions."
        return 0
    fi
    
    echo ""
    echo "Installing PECL and build dependencies..."
    sudo apt install -y gcc make autoconf libc-dev pkg-config php-pear
    
    # Install unixODBC development files
    sudo apt install -y unixodbc-dev
    
    echo ""
    for php_ver in "${installed_php[@]}"; do
        echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
        echo -e "\e[33m   Installing for PHP $php_ver\e[0m"
        echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
        
        # Install PHP dev package
        sudo apt install -y php${php_ver}-dev
        
        # Install sqlsrv extension
        echo "Installing sqlsrv extension..."
        sudo pecl -d php_suffix=${php_ver} install sqlsrv 2>/dev/null || true
        
        # Install pdo_sqlsrv extension
        echo "Installing pdo_sqlsrv extension..."
        sudo pecl -d php_suffix=${php_ver} install pdo_sqlsrv 2>/dev/null || true
        
        # Create ini files if not exist
        local ini_dir="/etc/php/${php_ver}/mods-available"
        
        if [ -d "$ini_dir" ]; then
            # Create sqlsrv.ini
            if [ ! -f "$ini_dir/sqlsrv.ini" ]; then
                echo "extension=sqlsrv.so" | sudo tee "$ini_dir/sqlsrv.ini" > /dev/null
            fi
            
            # Create pdo_sqlsrv.ini
            if [ ! -f "$ini_dir/pdo_sqlsrv.ini" ]; then
                echo "extension=pdo_sqlsrv.so" | sudo tee "$ini_dir/pdo_sqlsrv.ini" > /dev/null
            fi
            
            # Enable extensions
            sudo phpenmod -v ${php_ver} sqlsrv 2>/dev/null || true
            sudo phpenmod -v ${php_ver} pdo_sqlsrv 2>/dev/null || true
            
            echo -e "\e[32m✓ Extensions enabled for PHP $php_ver\e[0m"
        fi
        
        # Restart PHP-FPM
        if systemctl is-active --quiet php${php_ver}-fpm; then
            sudo systemctl restart php${php_ver}-fpm
            echo -e "\e[32m✓ PHP $php_ver-FPM restarted\e[0m"
        fi
        
        echo ""
    done
    
    # Verify installation
    echo -e "\e[36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
    echo -e "\e[36m   Verification\e[0m"
    echo -e "\e[36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
    echo ""
    
    for php_ver in "${installed_php[@]}"; do
        echo -e "\e[33mPHP $php_ver loaded extensions:\e[0m"
        if php${php_ver} -m 2>/dev/null | grep -E "sqlsrv|pdo_sqlsrv" > /dev/null; then
            php${php_ver} -m 2>/dev/null | grep -E "sqlsrv|pdo_sqlsrv" | while read ext; do
                echo -e "  \e[32m✓\e[0m $ext"
            done
        else
            echo -e "  \e[31m✗ No SQL Server extensions found\e[0m"
            echo "  Manual installation may be required"
        fi
        echo ""
    done
}

# Main ODBC installation function
install_odbc_sqlserver() {
    echo -e "\e[36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
    echo -e "\e[36m   ODBC Driver for SQL Server 17\e[0m"
    echo -e "\e[36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
    echo ""
    echo "This will install:"
    echo "  ✓ Microsoft ODBC Driver 17 for SQL Server"
    echo "  ✓ PHP sqlsrv & pdo_sqlsrv extensions (if PHP installed)"
    echo "  ✓ OpenSSL configuration for SQL Server 2014 compatibility"
    echo ""
    
    # Install ODBC driver
    echo "Installing ODBC Driver for SQL Server 17..."
    sudo apt update
    sudo apt install -y curl apt-transport-https gnupg
    
    # Add Microsoft repository
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg
    
    local ubuntu_version=$(lsb_release -rs)
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft-prod.gpg] https://packages.microsoft.com/ubuntu/${ubuntu_version}/prod ${ubuntu_version%.*} main" | sudo tee /etc/apt/sources.list.d/mssql-release.list
    
    sudo apt update
    
    # Accept EULA and install
    echo ""
    echo "Installing msodbcsql17..."
    sudo ACCEPT_EULA=Y apt install -y msodbcsql17
    
    # Install unixODBC
    sudo apt install -y unixodbc
    
    if [ $? -eq 0 ]; then
        echo -e "\e[32m✓ ODBC Driver 17 for SQL Server installed\e[0m"
        
        # Show driver info
        if command -v odbcinst &> /dev/null; then
            echo ""
            echo "Installed ODBC drivers:"
            odbcinst -q -d | grep "SQL Server"
        fi
    else
        echo -e "\e[31m✗ Failed to install ODBC driver\e[0m"
        return 1
    fi
    
    # Install PHP extensions
    install_php_sqlsrv_extensions
    
    # Configure OpenSSL
    configure_openssl_for_sqlserver
    
    # Final summary
    echo ""
    echo -e "\e[32m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
    echo -e "\e[32m   Installation Complete!\e[0m"
    echo -e "\e[32m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
    echo ""
    echo "Test connection with sqlcmd:"
    echo "  sqlcmd -S server_name -U username -P password"
    echo ""
    echo "PHP Connection example:"
    echo '  $conn = new PDO("sqlsrv:Server=server_name;Database=db", "user", "pass");'
    echo ""
    echo -e "\e[33mNote: For SQL Server 2014, TLS 1.0 has been enabled\e[0m"
    echo ""
}
