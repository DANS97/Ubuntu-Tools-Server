#!/bin/bash

# PostgreSQL installation with version selection from official repository

# Function to configure PostgreSQL for remote access
configure_postgresql_remote_access() {
    local pg_version=$1
    
    echo -e "\e[36mConfiguring remote access for PostgreSQL ${pg_version}...\e[0m"
    
    # Find PostgreSQL config directory
    local pg_conf_dir="/etc/postgresql/$pg_version/main"
    local pg_conf="$pg_conf_dir/postgresql.conf"
    local pg_hba="$pg_conf_dir/pg_hba.conf"
    
    # Check if config files exist
    if [ ! -f "$pg_conf" ]; then
        echo -e "\e[31m✗ PostgreSQL config not found at: $pg_conf\e[0m"
        return 1
    fi
    
    # Backup configs
    echo "  - Backing up configuration files..."
    sudo cp "$pg_conf" "${pg_conf}.backup.$(date +%Y%m%d_%H%M%S)"
    sudo cp "$pg_hba" "${pg_hba}.backup.$(date +%Y%m%d_%H%M%S)"
    
    # Enable listen on all addresses
    echo "  - Configuring listen_addresses..."
    if grep -q "^listen_addresses = '\*'" "$pg_conf"; then
        echo "    Already configured to listen on all addresses"
    else
        sudo sed -i "s/^#*listen_addresses = 'localhost'/listen_addresses = '*'/" "$pg_conf"
        sudo sed -i "s/^#*listen_addresses = '127.0.0.1'/listen_addresses = '*'/" "$pg_conf"
        echo -e "    \e[32m✓ Set listen_addresses = '*'\e[0m"
    fi
    
    # Add remote access rule to pg_hba.conf
    echo "  - Configuring authentication (pg_hba.conf)..."
    echo ""
    echo "  Select access type:"
    echo "    1. Allow from SPECIFIC NETWORK (recommended)"
    echo "       Examples: 192.168.1.0/24 (1 subnet)"
    echo "                 10.0.0.0/8 (entire private network)"
    echo "                 172.16.0.0/16 (1 network segment)"
    echo "    2. Allow from SPECIFIC IP(s) - most secure"
    echo "       Examples: 192.168.1.50 (single IP)"
    echo "                 192.168.1.50,192.168.1.51 (multiple IPs)"
    echo "    3. Allow from ALL IPs (0.0.0.0/0) - NOT recommended for production"
    read -p "  Choose (1-3): " access_type
    
    if [ "$access_type" = "3" ]; then
        echo -e "    \e[33m⚠ Warning: This will allow connections from ANY IP address!\e[0m"
        read -p "    Are you sure? (yes/no): " confirm
        if [ "$confirm" = "yes" ]; then
            allowed_ip="0.0.0.0/0"
        else
            echo "    Cancelled. Please choose option 1 or 2."
            return 1
        fi
    elif [ "$access_type" = "2" ]; then
        # Specific IP(s)
        echo ""
        echo "    Enter IP address(es) - you can add multiple IPs separated by comma"
        echo "    Examples:"
        echo "      Single IP: 192.168.1.50"
        echo "      Multiple IPs: 192.168.1.50,192.168.1.51,192.168.1.52"
        echo ""
        read -p "  Enter IP(s): " allowed_ip
        
        if [ -z "$allowed_ip" ]; then
            echo "    No IP provided, cancelled."
            return 1
        fi
        
        # Validate IP format (basic check)
        if [[ ! $allowed_ip =~ ^[0-9,.]+ ]]; then
            echo -e "    \e[31m✗ Invalid IP format!\e[0m"
            return 1
        fi
        
        echo -e "    \e[32m✓ Will allow connections from: $allowed_ip\e[0m"
    else
        # Network CIDR
        # Auto-detect current network
        current_ip=$(hostname -I | awk '{print $1}')
        if [ -n "$current_ip" ]; then
            # Suggest network based on current IP
            suggested_network=$(echo $current_ip | cut -d. -f1-3).0/24
            echo ""
            echo "    Your server IP: $current_ip"
            echo "    Suggested network: $suggested_network (Class C - 254 hosts)"
            echo ""
        fi
        
        read -p "  Enter network CIDR (e.g., 192.168.1.0/24): " allowed_ip
        
        # Validate CIDR format
        if [[ ! $allowed_ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/[0-9]+$ ]]; then
            echo -e "    \e[31m✗ Invalid CIDR format! Use format: 192.168.1.0/24\e[0m"
            return 1
        fi
        
        if [ -z "$allowed_ip" ]; then
            echo "    No network provided, cancelled."
            return 1
        fi
        
        echo -e "    \e[32m✓ Will allow connections from network: $allowed_ip\e[0m"
    fi
    
    if grep -q "host.*all.*all.*${allowed_ip}.*md5" "$pg_hba"; then
        echo "    Remote access rule for $allowed_ip already exists"
    else
        echo "# Allow remote connections (added by ubuntu-tools)" | sudo tee -a "$pg_hba" > /dev/null
        
        # Handle multiple IPs (comma-separated)
        if [[ "$allowed_ip" == *","* ]]; then
            IFS=',' read -ra IPS <<< "$allowed_ip"
            for ip in "${IPS[@]}"; do
                ip=$(echo "$ip" | xargs)  # Trim whitespace
                echo "host    all             all             ${ip}/32            md5" | sudo tee -a "$pg_hba" > /dev/null
            done
            echo -e "    \e[32m✓ Added ${#IPS[@]} IP address(es) to access list\e[0m"
        else
            # Single IP or network CIDR
            if [[ "$allowed_ip" =~ / ]]; then
                # CIDR notation (network)
                echo "host    all             all             ${allowed_ip}       md5" | sudo tee -a "$pg_hba" > /dev/null
            else
                # Single IP without CIDR, add /32
                echo "host    all             all             ${allowed_ip}/32    md5" | sudo tee -a "$pg_hba" > /dev/null
            fi
            
            if [ "$allowed_ip" = "0.0.0.0/0" ]; then
                echo "host    all             all             ::/0                md5" | sudo tee -a "$pg_hba" > /dev/null
            fi
            echo -e "    \e[32m✓ Added remote access rules for: $allowed_ip\e[0m"
        fi
    fi
    
    # Configure UFW
    echo "  - Configuring firewall (UFW)..."
    if command -v ufw &> /dev/null; then
        if sudo ufw status | grep -q "5432.*ALLOW"; then
            echo "    Port 5432 already allowed in UFW"
        else
            sudo ufw allow 5432/tcp comment 'PostgreSQL'
            echo -e "    \e[32m✓ Allowed port 5432/tcp in UFW\e[0m"
        fi
    else
        echo -e "    \e[33m⚠ UFW not installed, skipping firewall configuration\e[0m"
    fi
    
    # Restart PostgreSQL
    echo "  - Restarting PostgreSQL service..."
    sudo systemctl restart postgresql
    
    if systemctl is-active --quiet postgresql; then
        echo -e "\e[32m✓ PostgreSQL remote access configured successfully!\e[0m"
        echo ""
        echo -e "\e[36m📋 Connection Information:\e[0m"
        echo "  Host: $(hostname -I | awk '{print $1}' || echo 'your-server-ip')"
        echo "  Port: 5432"
        echo "  User: postgres"
        echo "  Database: postgres"
        echo "  Allowed from: $allowed_ip"
        echo ""
        echo -e "\e[36m📝 Example Connection String:\e[0m"
        echo "  psql: psql -h $(hostname -I | awk '{print $1}') -U postgres -d postgres"
        echo "  Node.js: postgresql://postgres:password@$(hostname -I | awk '{print $1}'):5432/postgres"
        echo "  Laravel: DB_HOST=$(hostname -I | awk '{print $1}'), DB_PORT=5432, DB_DATABASE=postgres"
        echo ""
        echo -e "\e[33m⚠ Security Notice:\e[0m"
        echo "  - Make sure to set a strong password: sudo -u postgres psql -c \"ALTER USER postgres PASSWORD 'your_password';\""
        if [ "$allowed_ip" = "0.0.0.0/0" ]; then
            echo -e "  - \e[31m⚠ CRITICAL: Allowing ALL IPs is DANGEROUS for production!\e[0m"
            echo "  - This should ONLY be used for testing/development"
            echo "  - Reconfigure with option 8 to restrict to specific network"
        elif [[ "$allowed_ip" == *","* ]] || [[ ! "$allowed_ip" =~ / ]]; then
            echo -e "  - \e[32m✓ Excellent! Access restricted to specific IP(s) only\e[0m"
            echo "  - This is the most secure option"
            echo "  - Add more IPs by editing /etc/postgresql/*/main/pg_hba.conf"
        else
            echo -e "  - \e[32m✓ Good! Access restricted to network: $allowed_ip\e[0m"
            echo "  - Network range examples:"
            echo "      /32 = 1 host only"
            echo "      /24 = 254 hosts (Class C network)"
            echo "      /16 = 65,534 hosts (Class B network)"
        fi
        echo "  - For production, enable SSL/TLS connections"
        echo "  - Use 'sudo ufw status' to verify firewall rules"
    else
        echo -e "\e[31m✗ Failed to restart PostgreSQL. Check configuration.\e[0m"
        return 1
    fi
}

# Function to get available PostgreSQL versions
get_postgresql_versions() {
    echo -e "\e[36mFetching available PostgreSQL versions from official repository...\e[0m"
    
    # Add PostgreSQL official repository if not already added
    if ! grep -q "apt.postgresql.org" /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null; then
        echo "Adding PostgreSQL official APT repository..."
        sudo apt install -y wget ca-certificates
        
        # Import repository signing key
        wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
        
        # Add repository
        echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" | sudo tee /etc/apt/sources.list.d/pgdg.list
        
        sudo apt update -qq 2>/dev/null
        echo -e "\e[32mPostgreSQL repository added successfully.\e[0m"
    else
        sudo apt update -qq 2>/dev/null
    fi
}

# Function to list all available PostgreSQL versions
list_postgresql_versions() {
    echo -e "\e[33m======================================\e[0m"
    echo -e "\e[33m  Available PostgreSQL Versions\e[0m"
    echo -e "\e[33m======================================\e[0m"
    
    apt-cache search --names-only '^postgresql-[0-9]+$' | awk '{print $1}' | sort -V | while read pkg; do
        version=$(echo $pkg | sed 's/postgresql-//')
        if apt-cache show $pkg &>/dev/null; then
            pkg_version=$(apt-cache policy $pkg | grep Candidate | awk '{print $2}')
            
            # Add labels
            label=""
            case $version in
                12|13) label=" \e[33m(Legacy)\e[0m" ;;
                14) label=" \e[36m(LTS)\e[0m" ;;
                15) label=" \e[32m(Stable)\e[0m" ;;
                16) label=" \e[32m(Latest Stable)\e[0m" ;;
                17) label=" \e[35m(Newest)\e[0m" ;;
            esac
            
            echo -e "  \e[32m✓\e[0m PostgreSQL $version ($pkg_version)$label"
        fi
    done
    echo -e "\e[33m======================================\e[0m"
}

# Function to install PostgreSQL with specific version
install_postgresql_version() {
    local pg_version=$1
    
    echo -e "\e[36mInstalling PostgreSQL ${pg_version}...\e[0m"
    
    # Install PostgreSQL
    sudo apt install -y postgresql-${pg_version} postgresql-contrib-${pg_version}
    
    # Install additional tools
    echo ""
    read -p "Install pgAdmin4 tools? (y/n): " install_pgadmin
    if [[ $install_pgadmin =~ ^[Yy]$ ]]; then
        sudo apt install -y postgresql-client-${pg_version}
    fi
    
    # Install common extensions
    echo ""
    read -p "Install common extensions (postgis, uuid, etc)? (y/n): " install_ext
    if [[ $install_ext =~ ^[Yy]$ ]]; then
        sudo apt install -y postgresql-${pg_version}-postgis-3 postgresql-${pg_version}-postgis-3-scripts
    fi
    
    # Start and enable PostgreSQL
    sudo systemctl enable postgresql
    sudo systemctl start postgresql
    
    # Show status
    echo -e "\e[32m✓ PostgreSQL ${pg_version} installed successfully!\e[0m"
    sudo -u postgres psql -c "SELECT version();" 2>/dev/null | head -3
    
    # Auto-configure remote access
    echo ""
    read -p "Enable remote access (recommended for development)? (y/n): " enable_remote
    if [[ $enable_remote =~ ^[Yy]$ ]]; then
        configure_postgresql_remote_access "$pg_version"
    fi
    
    # Setup instructions
    echo ""
    echo -e "\e[33m======================================\e[0m"
    echo -e "\e[33m  PostgreSQL Setup Instructions\e[0m"
    echo -e "\e[33m======================================\e[0m"
    echo -e "\e[36m1. Set postgres user password:\e[0m"
    echo "   sudo -u postgres psql -c \"ALTER USER postgres PASSWORD 'your_password';\""
    echo ""
    echo -e "\e[36m2. Create new database:\e[0m"
    echo "   sudo -u postgres createdb mydatabase"
    echo ""
    echo -e "\e[36m3. Create new user:\e[0m"
    echo "   sudo -u postgres createuser -P myuser"
    echo ""
    echo -e "\e[36m4. Access PostgreSQL:\e[0m"
    echo "   sudo -u postgres psql"
    echo -e "\e[33m======================================\e[0m"
    
    # Ask to configure now
    echo ""
    read -p "Configure PostgreSQL (create user/database) now? (y/n): " config_now
    if [[ $config_now =~ ^[Yy]$ ]]; then
        configure_postgresql
    fi
}

# Function to configure PostgreSQL
configure_postgresql() {
    echo -e "\e[36mPostgreSQL Configuration\e[0m"
    echo ""
    
    # Set postgres password
    read -p "Set password for postgres user? (y/n): " set_pass
    if [[ $set_pass =~ ^[Yy]$ ]]; then
        read -sp "Enter password for postgres user: " postgres_pass
        echo ""
        sudo -u postgres psql -c "ALTER USER postgres PASSWORD '$postgres_pass';"
        echo -e "\e[32m✓ Password set for postgres user.\e[0m"
    fi
    
    echo ""
    # Create database
    read -p "Create a new database? (y/n): " create_db
    if [[ $create_db =~ ^[Yy]$ ]]; then
        read -p "Enter database name: " db_name
        sudo -u postgres createdb $db_name
        echo -e "\e[32m✓ Database '$db_name' created.\e[0m"
    fi
    
    echo ""
    # Create user
    read -p "Create a new user? (y/n): " create_user
    if [[ $create_user =~ ^[Yy]$ ]]; then
        read -p "Enter username: " db_user
        read -sp "Enter password: " db_pass
        echo ""
        sudo -u postgres psql -c "CREATE USER $db_user WITH PASSWORD '$db_pass';"
        
        if [[ ! -z $db_name ]]; then
            read -p "Grant all privileges on '$db_name' to '$db_user'? (y/n): " grant_priv
            if [[ $grant_priv =~ ^[Yy]$ ]]; then
                sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $db_name TO $db_user;"
                echo -e "\e[32m✓ Privileges granted.\e[0m"
            fi
        fi
    fi
    
    echo ""
    # Configure remote access
    read -p "Enable remote access? (y/n): " remote_access
    if [[ $remote_access =~ ^[Yy]$ ]]; then
        pg_version=$(ls /etc/postgresql/ | head -1)
        configure_postgresql_remote_access "$pg_version"
    fi
}

# Function to switch PostgreSQL version
switch_postgresql_version() {
    echo -e "\e[36mAvailable installed PostgreSQL versions:\e[0m"
    local installed_versions=()
    
    for version in 12 13 14 15 16 17; do
        if systemctl list-unit-files | grep -q "postgresql@${version}"; then
            installed_versions+=("$version")
            status=$(systemctl is-active postgresql@${version}-main 2>/dev/null || echo "inactive")
            echo "  - PostgreSQL $version [$status]"
        fi
    done
    
    if [ ${#installed_versions[@]} -eq 0 ]; then
        echo -e "\e[31mNo PostgreSQL versions found.\e[0m"
        return
    fi
    
    echo ""
    read -p "Enter PostgreSQL version to activate: " target_version
    
    if systemctl list-unit-files | grep -q "postgresql@${target_version}"; then
        # Stop other versions
        for version in "${installed_versions[@]}"; do
            if [ "$version" != "$target_version" ]; then
                sudo systemctl stop postgresql@${version}-main
                echo "Stopped PostgreSQL $version"
            fi
        done
        
        # Start target version
        sudo systemctl start postgresql@${target_version}-main
        sudo systemctl enable postgresql@${target_version}-main
        
        echo -e "\e[32mPostgreSQL ${target_version} activated.\e[0m"
    else
        echo -e "\e[31mPostgreSQL ${target_version} is not installed.\e[0m"
    fi
}

# Main PostgreSQL installation function
install_postgresql() {
    while true; do
        echo ""
        echo -e "\e[33m======================================\e[0m"
        echo -e "\e[33m   PostgreSQL Installation Menu\e[0m"
        echo -e "\e[33m======================================\e[0m"
        echo "1. List all available PostgreSQL versions"
        echo "2. Install PostgreSQL (choose version manually)"
        echo "3. Install PostgreSQL 14 (LTS)"
        echo "4. Install PostgreSQL 15 (Stable)"
        echo "5. Install PostgreSQL 16 (Latest Stable)"
        echo "6. Install PostgreSQL 17 (Newest)"
        echo "7. Configure existing PostgreSQL"
        echo "8. Enable/Configure remote access"
        echo "9. Switch PostgreSQL version"
        echo "10. Show PostgreSQL status"
        echo "0. Back to main menu"
        echo -e "\e[33m======================================\e[0m"
        read -p "Choose an option: " pg_choice

        case $pg_choice in
            1)
                get_postgresql_versions
                list_postgresql_versions
                ;;
            2)
                get_postgresql_versions
                echo ""
                read -p "Enter PostgreSQL version to install (e.g., 16, 15): " custom_version
                if [[ $custom_version =~ ^[0-9]+$ ]]; then
                    install_postgresql_version $custom_version
                else
                    echo -e "\e[31mInvalid version format. Use format: 16 or 15\e[0m"
                fi
                ;;
            3)
                get_postgresql_versions
                install_postgresql_version "14"
                ;;
            4)
                get_postgresql_versions
                install_postgresql_version "15"
                ;;
            5)
                get_postgresql_versions
                install_postgresql_version "16"
                ;;
            6)
                get_postgresql_versions
                install_postgresql_version "17"
                ;;
            7)
                configure_postgresql
                ;;
            8)
                # Enable remote access for existing installation
                echo -e "\e[36mAvailable PostgreSQL versions:\e[0m"
                ls /etc/postgresql/ 2>/dev/null | while read version; do
                    echo "  - PostgreSQL $version"
                done
                echo ""
                read -p "Enter PostgreSQL version to configure for remote access: " remote_version
                if [ -d "/etc/postgresql/$remote_version" ]; then
                    configure_postgresql_remote_access "$remote_version"
                else
                    echo -e "\e[31mPostgreSQL $remote_version not found.\e[0m"
                fi
                ;;
            9)
                switch_postgresql_version
                ;;
            10)
                echo -e "\e[36mPostgreSQL Status:\e[0m"
                systemctl status postgresql --no-pager -l
                echo ""
                echo -e "\e[36mInstalled versions:\e[0m"
                ls /etc/postgresql/ 2>/dev/null | while read version; do
                    echo "  - PostgreSQL $version"
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
