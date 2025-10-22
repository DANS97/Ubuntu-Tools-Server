#!/bin/bash

# Nginx Web Server installation and configuration

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
        source "$(dirname "$0")/scripts/odbc.sh"
        install_odbc_sqlserver
    fi
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
                source "$(dirname "$0")/scripts/php.sh"
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
