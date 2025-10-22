#!/bin/bash

# MySQL Server installation with version selection

# Function to get available MySQL versions
get_mysql_versions() {
    echo -e "\e[36mAvailable MySQL versions:\e[0m"
    echo ""
    echo -e "\e[33m======================================\e[0m"
    echo -e "\e[33m     MySQL Version Options\e[0m"
    echo -e "\e[33m======================================\e[0m"
    echo -e "\e[32mOfficial MySQL Repository:\e[0m"
    echo "  • MySQL 8.0 (Latest GA)"
    echo "  • MySQL 8.4 (Innovation)"
    echo ""
    echo -e "\e[36mUbuntu Default Repository:\e[0m"
    echo "  • MySQL 8.0 (System default)"
    echo ""
    echo -e "\e[33mAlternatives:\e[0m"
    echo "  • MariaDB 10.11 (LTS)"
    echo "  • MariaDB 11.x (Latest)"
    echo -e "\e[33m======================================\e[0m"
}

# Function to add MySQL official repository
setup_mysql_repo() {
    if ! grep -q "mysql.com" /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null; then
        echo -e "\e[36mAdding MySQL official repository...\e[0m"
        
        # Download and install MySQL APT config
        cd /tmp
        wget https://dev.mysql.com/get/mysql-apt-config_0.8.29-1_all.deb
        sudo dpkg -i mysql-apt-config_0.8.29-1_all.deb
        rm mysql-apt-config_0.8.29-1_all.deb
        
        sudo apt update
        echo -e "\e[32m✓ MySQL repository added.\e[0m"
    else
        sudo apt update -qq 2>/dev/null
    fi
}

# Function to install MySQL
install_mysql_version() {
    local mysql_type=$1
    
    case $mysql_type in
        "default")
            echo -e "\e[36mInstalling MySQL 8.0 (Ubuntu default)...\e[0m"
            sudo apt update
            sudo apt install -y mysql-server mysql-client
            ;;
        "official")
            setup_mysql_repo
            echo -e "\e[36mInstalling MySQL from official repository...\e[0m"
            sudo apt install -y mysql-server mysql-client
            ;;
        "mariadb")
            echo -e "\e[36mInstalling MariaDB...\e[0m"
            sudo apt update
            sudo apt install -y mariadb-server mariadb-client
            ;;
    esac
    
    # Start and enable service
    if systemctl list-unit-files | grep -q "mysql.service"; then
        sudo systemctl enable mysql
        sudo systemctl start mysql
        service_name="mysql"
    elif systemctl list-unit-files | grep -q "mariadb.service"; then
        sudo systemctl enable mariadb
        sudo systemctl start mariadb
        service_name="mariadb"
    fi
    
    # Show version
    if command -v mysql &> /dev/null; then
        echo -e "\e[32m✓ Database server installed successfully!\e[0m"
        mysql --version
        
        # Secure installation
        echo ""
        echo -e "\e[33m======================================\e[0m"
        echo -e "\e[33m    MySQL/MariaDB Configuration\e[0m"
        echo -e "\e[33m======================================\e[0m"
        read -p "Run secure installation now? (y/n): " run_secure
        if [[ $run_secure =~ ^[Yy]$ ]]; then
            sudo mysql_secure_installation
        else
            echo -e "\e[33m⚠ Run 'sudo mysql_secure_installation' later to secure your installation.\e[0m"
        fi
        
        # Quick setup
        echo ""
        read -p "Configure database now? (y/n): " config_now
        if [[ $config_now =~ ^[Yy]$ ]]; then
            configure_mysql
        fi
    else
        echo -e "\e[31m✗ Installation failed.\e[0m"
        return 1
    fi
}

# Function to configure MySQL
configure_mysql() {
    echo -e "\e[36mMySQL/MariaDB Configuration\e[0m"
    echo ""
    
    # Create database
    read -p "Create a new database? (y/n): " create_db
    if [[ $create_db =~ ^[Yy]$ ]]; then
        read -p "Enter database name: " db_name
        sudo mysql -e "CREATE DATABASE IF NOT EXISTS $db_name;"
        echo -e "\e[32m✓ Database '$db_name' created.\e[0m"
    fi
    
    echo ""
    # Create user
    read -p "Create a new user? (y/n): " create_user
    if [[ $create_user =~ ^[Yy]$ ]]; then
        read -p "Enter username: " db_user
        read -sp "Enter password: " db_pass
        echo ""
        
        sudo mysql -e "CREATE USER IF NOT EXISTS '$db_user'@'localhost' IDENTIFIED BY '$db_pass';"
        
        if [[ ! -z $db_name ]]; then
            read -p "Grant all privileges on '$db_name' to '$db_user'? (y/n): " grant_priv
            if [[ $grant_priv =~ ^[Yy]$ ]]; then
                sudo mysql -e "GRANT ALL PRIVILEGES ON $db_name.* TO '$db_user'@'localhost';"
                sudo mysql -e "FLUSH PRIVILEGES;"
                echo -e "\e[32m✓ User '$db_user' created and granted privileges.\e[0m"
            fi
        else
            echo -e "\e[32m✓ User '$db_user' created.\e[0m"
        fi
    fi
    
    echo ""
    # Enable remote access
    read -p "Enable remote access? (y/n): " remote_access
    if [[ $remote_access =~ ^[Yy]$ ]]; then
        # Find MySQL config file
        if [ -f "/etc/mysql/mysql.conf.d/mysqld.cnf" ]; then
            mysql_conf="/etc/mysql/mysql.conf.d/mysqld.cnf"
        elif [ -f "/etc/mysql/mariadb.conf.d/50-server.cnf" ]; then
            mysql_conf="/etc/mysql/mariadb.conf.d/50-server.cnf"
        else
            mysql_conf="/etc/mysql/my.cnf"
        fi
        
        # Backup config
        sudo cp $mysql_conf ${mysql_conf}.backup
        
        # Change bind-address
        sudo sed -i 's/bind-address.*/bind-address = 0.0.0.0/' $mysql_conf
        
        # Create remote user if requested
        if [[ ! -z $db_user ]] && [[ ! -z $db_pass ]]; then
            read -p "Allow '$db_user' to connect remotely? (y/n): " remote_user
            if [[ $remote_user =~ ^[Yy]$ ]]; then
                sudo mysql -e "CREATE USER IF NOT EXISTS '$db_user'@'%' IDENTIFIED BY '$db_pass';"
                if [[ ! -z $db_name ]]; then
                    sudo mysql -e "GRANT ALL PRIVILEGES ON $db_name.* TO '$db_user'@'%';"
                fi
                sudo mysql -e "FLUSH PRIVILEGES;"
                echo -e "\e[32m✓ Remote access enabled for '$db_user'.\e[0m"
            fi
        fi
        
        # Restart MySQL
        sudo systemctl restart mysql 2>/dev/null || sudo systemctl restart mariadb
        
        echo -e "\e[32m✓ Remote access enabled.\e[0m"
        echo -e "\e[33m⚠ Don't forget to configure firewall (ufw allow 3306/tcp)\e[0m"
    fi
}

# Main MySQL installation function
install_mysql() {
    while true; do
        echo ""
        echo -e "\e[33m======================================\e[0m"
        echo -e "\e[33m   MySQL/MariaDB Installation Menu\e[0m"
        echo -e "\e[33m======================================\e[0m"
        echo "1. Show available versions"
        echo "2. Install MySQL 8.0 (Ubuntu default - Quick)"
        echo "3. Install MySQL (Official repository)"
        echo "4. Install MariaDB (MySQL alternative)"
        echo "5. Configure existing MySQL/MariaDB"
        echo "6. Show MySQL/MariaDB status"
        echo "7. Access MySQL shell"
        echo "0. Back to main menu"
        echo -e "\e[33m======================================\e[0m"
        read -p "Choose an option: " mysql_choice

        case $mysql_choice in
            1)
                get_mysql_versions
                ;;
            2)
                install_mysql_version "default"
                ;;
            3)
                install_mysql_version "official"
                ;;
            4)
                install_mysql_version "mariadb"
                ;;
            5)
                configure_mysql
                ;;
            6)
                echo -e "\e[36mMySQL/MariaDB Status:\e[0m"
                systemctl status mysql --no-pager 2>/dev/null || systemctl status mariadb --no-pager
                ;;
            7)
                echo -e "\e[36mOpening MySQL shell...\e[0m"
                echo "Type 'exit' to return to menu"
                sudo mysql
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
