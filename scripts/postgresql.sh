#!/bin/bash

# PostgreSQL installation with version selection from official repository

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
    read -p "Configure PostgreSQL now? (y/n): " config_now
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
        pg_conf="/etc/postgresql/$pg_version/main/postgresql.conf"
        pg_hba="/etc/postgresql/$pg_version/main/pg_hba.conf"
        
        # Backup configs
        sudo cp $pg_conf ${pg_conf}.backup
        sudo cp $pg_hba ${pg_hba}.backup
        
        # Enable listen on all addresses
        sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" $pg_conf
        
        # Add remote access rule
        echo "host    all             all             0.0.0.0/0               md5" | sudo tee -a $pg_hba
        
        # Restart PostgreSQL
        sudo systemctl restart postgresql
        
        echo -e "\e[32m✓ Remote access enabled.\e[0m"
        echo -e "\e[33m⚠ Don't forget to configure firewall (ufw allow 5432/tcp)\e[0m"
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
        echo "8. Switch PostgreSQL version"
        echo "9. Show PostgreSQL status"
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
                switch_postgresql_version
                ;;
            9)
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
