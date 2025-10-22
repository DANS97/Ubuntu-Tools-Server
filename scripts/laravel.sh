#!/bin/bash

# Laravel Deployment Manager with GitHub SSH Integration

# Config files
CONFIG_DIR="$HOME/.ubuntu-tools"
SSH_KEY_FILE="$HOME/.ssh/github_deploy_key"
SSH_CONFIG_FILE="$HOME/.ssh/config"

# Function to setup GitHub SSH key
setup_github_ssh_key() {
    echo -e "\e[36m=== Setup GitHub SSH Key ===\e[0m"
    echo ""
    echo "SSH Key provides secure authentication for private repositories"
    echo ""
    
    # Check if SSH key already exists
    if [ -f "$SSH_KEY_FILE" ]; then
        echo -e "\e[33m⚠ GitHub SSH key already exists\e[0m"
        echo "  Location: $SSH_KEY_FILE"
        echo ""
        read -p "Use existing key? (y/n): " use_existing
        if [[ $use_existing =~ ^[Yy]$ ]]; then
            return 0
        fi
        
        read -p "Generate new key (will overwrite)? (y/n): " regenerate
        if [[ ! $regenerate =~ ^[Yy]$ ]]; then
            return 1
        fi
    fi
    
    echo "Enter your GitHub email address:"
    read -r github_email
    
    if [ -z "$github_email" ]; then
        echo -e "\e[31mEmail is required.\e[0m"
        return 1
    fi
    
    # Generate SSH key
    echo ""
    echo "Generating SSH key..."
    mkdir -p "$HOME/.ssh"
    ssh-keygen -t ed25519 -C "$github_email" -f "$SSH_KEY_FILE" -N "" -q
    
    if [ $? -ne 0 ]; then
        echo -e "\e[31m✗ Failed to generate SSH key\e[0m"
        return 1
    fi
    
    # Set proper permissions
    chmod 600 "$SSH_KEY_FILE"
    chmod 644 "${SSH_KEY_FILE}.pub"
    
    # Add to SSH agent
    eval "$(ssh-agent -s)" > /dev/null 2>&1
    ssh-add "$SSH_KEY_FILE" > /dev/null 2>&1
    
    # Configure SSH to use this key for GitHub
    mkdir -p "$(dirname "$SSH_CONFIG_FILE")"
    
    # Remove old GitHub config if exists
    if [ -f "$SSH_CONFIG_FILE" ]; then
        sed -i '/# GitHub Deploy Key/,+4d' "$SSH_CONFIG_FILE" 2>/dev/null
    fi
    
    # Add GitHub SSH config
    cat >> "$SSH_CONFIG_FILE" <<EOF

# GitHub Deploy Key
Host github.com
    HostName github.com
    User git
    IdentityFile $SSH_KEY_FILE
    IdentitiesOnly yes
    StrictHostKeyChecking no
EOF
    chmod 600 "$SSH_CONFIG_FILE"
    
    echo ""
    echo -e "\e[32m✓ SSH key generated successfully!\e[0m"
    echo ""
    echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
    echo -e "\e[33m⚠ IMPORTANT: Add this public key to GitHub\e[0m"
    echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
    echo ""
    echo "Your public key:"
    echo ""
    cat "${SSH_KEY_FILE}.pub"
    echo ""
    echo -e "\e[36mSteps to add key to GitHub:\e[0m"
    echo "  1. Copy the public key above (select and copy)"
    echo "  2. Open: https://github.com/settings/ssh/new"
    echo "  3. Title: Ubuntu Server Deploy"
    echo "  4. Key type: Authentication Key"
    echo "  5. Paste the public key"
    echo "  6. Click 'Add SSH key'"
    echo ""
    read -p "Press Enter after adding the key to GitHub..."
    
    # Test SSH connection
    echo ""
    echo "Testing GitHub SSH connection..."
    ssh_test=$(ssh -T git@github.com 2>&1)
    
    if echo "$ssh_test" | grep -q "successfully authenticated"; then
        echo -e "\e[32m✓ SSH connection successful!\e[0m"
        github_user=$(echo "$ssh_test" | grep -o "Hi [^!]*" | cut -d' ' -f2)
        echo "  GitHub User: $github_user"
        return 0
    else
        echo -e "\e[32m✓ SSH key is configured\e[0m"
        echo "  (GitHub authentication will be used during clone)"
        return 0
    fi
}

# Function to check if SSH key exists
check_ssh_key() {
    if [ -f "$SSH_KEY_FILE" ]; then
        return 0
    else
        return 1
    fi
}

# Function to clone repository using SSH
clone_repository_ssh() {
    local repo_url="$1"
    local target_dir="$2"
    
    # Convert HTTPS to SSH if needed
    if [[ $repo_url == https://github.com/* ]]; then
        repo_path=$(echo "$repo_url" | sed 's|https://github.com/||' | sed 's|.git$||')
        ssh_url="git@github.com:${repo_path}.git"
        echo "Converting to SSH URL: $ssh_url"
    elif [[ $repo_url == git@github.com:* ]]; then
        ssh_url="$repo_url"
    else
        echo -e "\e[31mInvalid GitHub URL format.\e[0m"
        echo "Supported formats:"
        echo "  - https://github.com/user/repo"
        echo "  - git@github.com:user/repo.git"
        return 1
    fi
    
    echo "Cloning repository via SSH..."
    if GIT_SSH_COMMAND="ssh -i $SSH_KEY_FILE -o StrictHostKeyChecking=no" git clone "$ssh_url" "$target_dir"; then
        echo -e "\e[32m✓ Repository cloned successfully!\e[0m"
        return 0
    else
        echo -e "\e[31m✗ Failed to clone repository\e[0m"
        echo ""
        echo "Possible reasons:"
        echo "  - SSH key not added to GitHub"
        echo "  - No access to private repository"
        echo "  - Repository doesn't exist"
        echo "  - Network issues"
        return 1
    fi
}

# Function to setup Laravel permissions
setup_laravel_permissions() {
    local project_path="$1"
    
    echo -e "\e[33mSetting Laravel permissions...\e[0m"
    
    # Set ownership to www-data
    sudo chown -R www-data:www-data "$project_path"
    
    # Set proper permissions
    sudo find "$project_path" -type f -exec chmod 644 {} \;
    sudo find "$project_path" -type d -exec chmod 755 {} \;
    
    # Special permissions for storage and bootstrap/cache
    if [ -d "$project_path/storage" ]; then
        sudo chmod -R 775 "$project_path/storage"
        sudo find "$project_path/storage" -type f -exec chmod 664 {} \;
    fi
    
    if [ -d "$project_path/bootstrap/cache" ]; then
        sudo chmod -R 775 "$project_path/bootstrap/cache"
        sudo find "$project_path/bootstrap/cache" -type f -exec chmod 664 {} \;
    fi
    
    # Make artisan executable
    if [ -f "$project_path/artisan" ]; then
        sudo chmod +x "$project_path/artisan"
    fi
    
    echo -e "\e[32m✓ Permissions configured\e[0m"
}

# Function to show Laravel post-deployment instructions
show_laravel_instructions() {
    local project_path="$1"
    # project_user parameter removed as it was unused
    
    echo ""
    echo -e "\e[36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
    echo -e "\e[36m   Laravel Setup Instructions\e[0m"
    echo -e "\e[36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
    echo ""
    echo "Project owner should complete these steps:"
    echo ""
    echo -e "\e[33m1. Navigate to project:\e[0m"
    echo "   cd $project_path"
    echo ""
    
    if [ -f "$project_path/composer.json" ]; then
        echo -e "\e[33m2. Install Composer dependencies:\e[0m"
        echo "   composer install"
        echo ""
    fi
    
    if [ -f "$project_path/.env.example" ] && [ ! -f "$project_path/.env" ]; then
        echo -e "\e[33m3. Setup environment file:\e[0m"
        echo "   cp .env.example .env"
        echo "   nano .env  # Configure database & other settings"
        echo ""
        echo -e "\e[33m4. Generate application key:\e[0m"
        echo "   php artisan key:generate"
        echo ""
    fi
    
    echo -e "\e[33m5. Database setup (if needed):\e[0m"
    echo "   php artisan migrate"
    echo "   php artisan db:seed  # Optional"
    echo ""
    echo -e "\e[33m6. Storage link:\e[0m"
    echo "   php artisan storage:link"
    echo ""
    echo -e "\e[33m7. Optimize (production):\e[0m"
    echo "   php artisan config:cache"
    echo "   php artisan route:cache"
    echo "   php artisan view:cache"
    echo ""
    echo -e "\e[36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
}

# Function to detect PHP version
detect_php_version() {
    local php_version=""
    
    # Check for PHP-FPM sockets
    for version in 8.4 8.3 8.2 8.1 8.0 7.4; do
        if [ -S "/var/run/php/php${version}-fpm.sock" ]; then
            php_version="$version"
            break
        fi
    done
    
    if [ -z "$php_version" ]; then
        # Fallback to default php command
        if command -v php &> /dev/null; then
            php_version=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')
        fi
    fi
    
    echo "$php_version"
}

# Function to select PHP version (if multiple installed)
select_php_version() {
    local available_versions=()
    
    echo -e "\e[33mDetecting installed PHP versions...\e[0m"
    echo ""
    
    # Check for all PHP-FPM sockets
    for version in 8.4 8.3 8.2 8.1 8.0 7.4; do
        if [ -S "/var/run/php/php${version}-fpm.sock" ]; then
            available_versions+=("$version")
        fi
    done
    
    if [ ${#available_versions[@]} -eq 0 ]; then
        echo -e "\e[31m✗ No PHP-FPM installation found\e[0m"
        echo ""
        echo "Please install PHP first (Menu option 7)"
        return 1
    fi
    
    if [ ${#available_versions[@]} -eq 1 ]; then
        # Only one version available
        echo -e "\e[32m✓ Found PHP ${available_versions[0]}-FPM\e[0m"
        echo "  Socket: /var/run/php/php${available_versions[0]}-fpm.sock"
        echo "${available_versions[0]}"
        return 0
    fi
    
    # Multiple versions available - let user choose
    echo -e "\e[32m✓ Found multiple PHP versions:\e[0m"
    echo ""
    
    local i=1
    for ver in "${available_versions[@]}"; do
        echo "  $i. PHP $ver-FPM"
        ((i++))
    done
    echo ""
    
    while true; do
        read -p "Select PHP version (1-${#available_versions[@]}): " selection
        if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le "${#available_versions[@]}" ]; then
            local selected_version="${available_versions[$((selection-1))]}"
            echo ""
            echo -e "\e[32m✓ Selected: PHP $selected_version\e[0m"
            echo "$selected_version"
            return 0
        else
            echo -e "\e[31mInvalid selection. Please choose 1-${#available_versions[@]}\e[0m"
        fi
    done
}

# Function to create Nginx configuration for Laravel
create_nginx_laravel_config() {
    local domain="$1"
    local project_path="$2"
    
    echo ""
    echo -e "\e[36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
    echo -e "\e[36m   PHP Version Selection for Nginx\e[0m"
    echo -e "\e[36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
    echo ""
    
    # Select PHP version
    local php_version
    php_version=$(select_php_version)
    
    if [ $? -ne 0 ] || [ -z "$php_version" ]; then
        echo -e "\e[31m✗ PHP selection failed. Please install PHP first (menu option 7).\e[0m"
        return 1
    fi
    
    local php_socket="/var/run/php/php${php_version}-fpm.sock"
    
    echo ""
    echo -e "\e[33mCreating Nginx configuration for Laravel...\e[0m"
    echo "  Domain: $domain"
    echo "  PHP Version: $php_version"
    echo "  PHP Socket: $php_socket"
    
    # Create Nginx configuration
    cat <<EOF | sudo tee /etc/nginx/sites-available/${domain} > /dev/null
server {
    listen 80;
    listen [::]:80;
    server_name ${domain} www.${domain};
    root ${project_path}/public;

    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-Content-Type-Options "nosniff";

    index index.php;

    charset utf-8;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    error_page 404 /index.php;

    location ~ \.php$ {
        fastcgi_pass unix:${php_socket};
        fastcgi_param SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;
        include fastcgi_params;
        fastcgi_hide_header X-Powered-By;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }

    # Optimize static assets
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot|otf)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        access_log off;
    }
}
EOF

    # Enable site
    sudo ln -sf /etc/nginx/sites-available/${domain} /etc/nginx/sites-enabled/${domain}
    
    # Remove default if not needed
    if [ -L /etc/nginx/sites-enabled/default ]; then
        echo ""
        read -p "Remove default Nginx site? (recommended: y): " remove_default
        if [[ $remove_default =~ ^[Yy]$ ]]; then
            sudo rm /etc/nginx/sites-enabled/default
            echo -e "\e[32m✓ Default site removed\e[0m"
        fi
    fi
    
    # Test and reload Nginx
    if sudo nginx -t 2>/dev/null; then
        sudo systemctl reload nginx
        echo -e "\e[32m✓ Nginx configured and reloaded\e[0m"
        return 0
    else
        echo -e "\e[31m✗ Nginx configuration test failed\e[0m"
        sudo nginx -t
        return 1
    fi
}

# Function to create Apache configuration for Laravel
create_apache_laravel_config() {
    local domain="$1"
    local project_path="$2"
    
    echo ""
    echo -e "\e[36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
    echo -e "\e[36m   PHP Version Selection for Apache\e[0m"
    echo -e "\e[36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
    echo ""
    
    # Select PHP version
    local php_version
    php_version=$(select_php_version)
    
    if [ $? -ne 0 ] || [ -z "$php_version" ]; then
        echo -e "\e[31m✗ PHP selection failed. Please install PHP first (menu option 7).\e[0m"
        return 1
    fi
    
    echo ""
    echo -e "\e[33mCreating Apache configuration for Laravel...\e[0m"
    echo "  Domain: $domain"
    echo "  PHP Version: $php_version"
    
    # Enable required modules
    sudo a2enmod rewrite headers 2>/dev/null
    
    # Set PHP version for Apache
    echo "Configuring Apache to use PHP $php_version..."
    if command -v a2enmod &> /dev/null; then
        # Disable all PHP modules first
        sudo a2dismod php* 2>/dev/null
        # Enable selected PHP version
        sudo a2enmod php${php_version} 2>/dev/null
    fi
    
    # Create Apache configuration
    cat <<EOF | sudo tee /etc/apache2/sites-available/${domain}.conf > /dev/null
<VirtualHost *:80>
    ServerName ${domain}
    ServerAlias www.${domain}
    ServerAdmin webmaster@${domain}
    DocumentRoot ${project_path}/public

    <Directory ${project_path}/public>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    # Optimize static assets
    <FilesMatch "\.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot|otf)$">
        Header set Cache-Control "max-age=31536000, public, immutable"
    </FilesMatch>

    ErrorLog \${APACHE_LOG_DIR}/${domain}-error.log
    CustomLog \${APACHE_LOG_DIR}/${domain}-access.log combined
</VirtualHost>
EOF

    # Enable site
    sudo a2ensite ${domain}.conf
    
    # Disable default if not needed
    if [ -f /etc/apache2/sites-enabled/000-default.conf ]; then
        echo ""
        read -p "Disable default Apache site? (recommended: y): " disable_default
        if [[ $disable_default =~ ^[Yy]$ ]]; then
            sudo a2dissite 000-default.conf
            echo -e "\e[32m✓ Default site disabled\e[0m"
        fi
    fi
    
    # Test and reload Apache
    if sudo apache2ctl configtest 2>/dev/null; then
        sudo systemctl reload apache2
        echo -e "\e[32m✓ Apache configured and reloaded\e[0m"
        return 0
    else
        echo -e "\e[31m✗ Apache configuration test failed\e[0m"
        sudo apache2ctl configtest
        return 1
    fi
}

# Main Laravel deployment function
deploy_laravel_project() {
    echo -e "\e[36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
    echo -e "\e[36m   Laravel Project Deployment\e[0m"
    echo -e "\e[36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
    echo ""
    echo "Clone Laravel repository with:"
    echo "  ✓ GitHub private repository support (SSH)"
    echo "  ✓ Auto-configure web server (Nginx/Apache)"
    echo "  ✓ Proper permissions (owner + www-data)"
    echo "  ✓ Laravel-ready folder structure"
    echo ""
    echo -e "\e[33mNote: Laravel setup (.env, artisan, composer) must be done\e[0m"
    echo -e "\e[33m      by the project owner after deployment.\e[0m"
    echo ""
    
    # Check/Setup SSH key
    if ! check_ssh_key; then
        echo -e "\e[33m⚠ No GitHub SSH key found\e[0m"
        echo ""
        read -p "Setup SSH key now? (required for private repos): " setup_ssh
        if [[ $setup_ssh =~ ^[Yy]$ ]]; then
            setup_github_ssh_key
            if [ $? -ne 0 ]; then
                echo -e "\e[31mSSH setup failed or cancelled.\e[0m"
                return 1
            fi
        else
            echo -e "\e[33mNote: Public repositories can still be cloned without SSH key\e[0m"
        fi
    else
        echo -e "\e[32m✓ GitHub SSH key configured\e[0m"
        fingerprint=$(ssh-keygen -lf "$SSH_KEY_FILE" 2>/dev/null | awk '{print $2}')
        echo "  Fingerprint: $fingerprint"
    fi
    
    # Get repository URL
    echo ""
    echo -e "\e[36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
    echo "GitHub Repository URL:"
    echo "Format: https://github.com/username/repository"
    echo "    or: git@github.com:username/repository.git"
    read -r repo_url
    
    if [ -z "$repo_url" ]; then
        echo -e "\e[31mRepository URL is required.\e[0m"
        return 1
    fi
    
    # Extract project name from URL
    default_project_name=$(basename "$repo_url" .git | tr '[:upper:]' '[:lower:]')
    echo ""
    echo "Project name (default: ${default_project_name}):"
    read -r project_name
    project_name=${project_name:-$default_project_name}
    
    # Set project path
    project_path="/var/www/${project_name}"
    
    echo ""
    echo -e "\e[33mDeployment target: $project_path\e[0m"
    read -p "Continue? (y/n): " continue_deploy
    if [[ ! $continue_deploy =~ ^[Yy]$ ]]; then
        return 0
    fi
    
    # Check if directory already exists
    if [ -d "$project_path" ]; then
        echo ""
        echo -e "\e[31m✗ Directory already exists: $project_path\e[0m"
        read -p "Remove and re-deploy? (y/n): " remove_existing
        if [[ $remove_existing =~ ^[Yy]$ ]]; then
            sudo rm -rf "$project_path"
        else
            return 1
        fi
    fi
    
    # Clone repository
    echo ""
    echo -e "\e[36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
    echo "Cloning repository..."
    echo -e "\e[36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
    
    clone_repository_ssh "$repo_url" "$project_path"
    
    if [ $? -ne 0 ]; then
        echo -e "\e[31m✗ Deployment failed at clone stage\e[0m"
        return 1
    fi
    
    # Setup Laravel permissions only
    echo ""
    setup_laravel_permissions "$project_path"
    
    # Detect the actual user (not root)
    echo ""
    echo -e "\e[36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
    echo "Setting project ownership..."
    
    # Get the actual user (not root)
    actual_user=$(whoami)
    if [ "$actual_user" = "root" ]; then
        # If running as root, try to get the original user
        if [ -n "$SUDO_USER" ]; then
            actual_user="$SUDO_USER"
        else
            # Ask for username
            echo ""
            echo -e "\e[33m⚠ Running as root detected\e[0m"
            echo "Enter the username who will own this project:"
            echo "Examples: ubuntu, deploy, mahar, yourname"
            read -r project_owner
            if [ -z "$project_owner" ] || [ "$project_owner" = "root" ]; then
                echo -e "\e[33m⚠ Using www-data as owner (not recommended for development)\e[0m"
                actual_user="www-data"
            else
                actual_user="$project_owner"
            fi
        fi
    fi
    
    echo "Project Owner: $actual_user"
    echo ""
    
    # Verify user exists
    if id "$actual_user" &>/dev/null; then
        if [ "$actual_user" != "www-data" ]; then
            echo "Setting permissions: ${actual_user}:www-data"
            sudo chown -R ${actual_user}:www-data "$project_path"
            
            # Ensure www-data can write to storage and cache
            if [ -d "$project_path/storage" ]; then
                sudo chmod -R 775 "$project_path/storage"
            fi
            if [ -d "$project_path/bootstrap/cache" ]; then
                sudo chmod -R 775 "$project_path/bootstrap/cache"
            fi
            
            echo -e "\e[32m✓ Owner: $actual_user (can edit files)\e[0m"
            echo -e "\e[32m✓ Group: www-data (web server can read/write storage)\e[0m"
        else
            echo "Setting permissions: www-data:www-data"
            sudo chown -R www-data:www-data "$project_path"
            echo -e "\e[33m⚠ Owner: www-data (use sudo to edit files)\e[0m"
        fi
        project_owner="$actual_user"
    else
        echo -e "\e[31m✗ User '$actual_user' not found\e[0m"
        echo "Falling back to www-data:www-data"
        sudo chown -R www-data:www-data "$project_path"
        project_owner="www-data"
    fi
    
    # Configure domain
    echo ""
    echo -e "\e[36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
    echo "Domain configuration:"
    current_fqdn=$(hostname -f 2>/dev/null)
    echo "Current server FQDN: $current_fqdn"
    echo ""
    echo "Enter domain name for this project:"
    echo "Examples: ${project_name}.local"
    echo "          ${project_name}.${current_fqdn}"
    echo "          ${project_name}.yourdomain.com"
    read -r domain
    domain=${domain:-"${project_name}.local"}
    
    # Configure web server
    echo ""
    echo -e "\e[36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
    echo "Web Server Configuration:"
    echo "1. Nginx (Recommended)"
    echo "2. Apache"
    echo "0. Skip (manual configuration)"
    echo ""
    read -p "Choose option: " webserver_choice
    
    case $webserver_choice in
        1)
            create_nginx_laravel_config "$domain" "$project_path"
            webserver="Nginx"
            ;;
        2)
            create_apache_laravel_config "$domain" "$project_path"
            webserver="Apache"
            ;;
        0)
            echo "Web server configuration skipped."
            webserver="Manual"
            ;;
        *)
            echo -e "\e[33mInvalid option. Skipping web server configuration.\e[0m"
            webserver="Manual"
            ;;
    esac
    
    # Show Laravel setup instructions
    show_laravel_instructions "$project_path"
    
    # Final summary
    echo ""
    echo -e "\e[32m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
    echo -e "\e[32m   ✓ Repository Cloned Successfully!\e[0m"
    echo -e "\e[32m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
    echo ""
    echo "Deployment Summary:"
    echo "  Project:    $project_name"
    echo "  Path:       $project_path"
    echo "  Owner:      $project_owner:www-data"
    echo "  Domain:     $domain"
    echo "  Web Server: $webserver"
    if [ "$webserver" != "Manual" ]; then
        # Get PHP version from config file
        local configured_php=""
        if [ -f "/etc/nginx/sites-available/${domain}" ]; then
            configured_php=$(grep "fastcgi_pass" "/etc/nginx/sites-available/${domain}" 2>/dev/null | grep -oP "php\K[0-9.]+")
        elif [ -f "/etc/apache2/sites-available/${domain}.conf" ]; then
            configured_php=$(apachectl -M 2>/dev/null | grep -oP "php\K[0-9.]+" | head -1)
        fi
        if [ -n "$configured_php" ]; then
            echo "  PHP:        $configured_php"
        else
            echo "  PHP:        $(detect_php_version)"
        fi
    else
        echo "  PHP:        $(detect_php_version) (available)"
    fi
    echo ""
    if [ "$project_owner" != "www-data" ]; then
        echo -e "\e[32m✓ You can edit files directly as '$project_owner'\e[0m"
        echo "  Example: nano $project_path/.env"
    else
        echo -e "\e[33m⚠ Files owned by www-data, use sudo to edit:\e[0m"
        echo "  Example: sudo nano $project_path/.env"
    fi
    echo ""
    echo "Access URL (after Laravel setup):"
    echo "  http://${domain}"
    echo ""
    echo "Additional Steps:"
    if [ "$webserver" != "Manual" ]; then
        echo "  1. Add '${domain}' to /etc/hosts (if local)"
        echo "     sudo nano /etc/hosts"
        echo "     Add: 127.0.0.1 ${domain}"
    else
        echo "  1. Configure your web server manually"
    fi
    echo "  2. Complete Laravel setup (see instructions above)"
    echo "  3. Optional: Setup SSL (menu options 21/22)"
    echo "  4. Optional: Setup scheduler (cron for artisan schedule:run)"
    echo "  5. Optional: Setup queue worker (supervisor for queue:work)"
    echo ""
    
    # Save deployment info
    mkdir -p "$CONFIG_DIR"
    echo "$(date '+%Y-%m-%d %H:%M:%S'): Deployed $project_name to $project_path (domain: $domain)" >> "$CONFIG_DIR/deployment_history.log"
    
    echo -e "\e[36mDeployment logged to: $CONFIG_DIR/deployment_history.log\e[0m"
}

# Function to manage GitHub SSH key
manage_github_ssh() {
    echo -e "\e[36m=== GitHub SSH Key Management ===\e[0m"
    echo ""
    echo "1. Setup/Regenerate SSH Key"
    echo "2. View SSH Key Status"
    echo "3. Show Public Key"
    echo "4. Test GitHub Connection"
    echo "5. Remove SSH Key"
    echo "0. Back"
    echo ""
    read -p "Choose option: " ssh_choice
    
    case $ssh_choice in
        1)
            setup_github_ssh_key
            ;;
        2)
            if check_ssh_key; then
                echo -e "\e[32m✓ SSH key configured\e[0m"
                echo "  Location: $SSH_KEY_FILE"
                fingerprint=$(ssh-keygen -lf "$SSH_KEY_FILE" 2>/dev/null | awk '{print $2}')
                echo "  Fingerprint: $fingerprint"
            else
                echo -e "\e[31m✗ No SSH key configured\e[0m"
            fi
            ;;
        3)
            if check_ssh_key; then
                echo ""
                echo "Public Key:"
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                cat "${SSH_KEY_FILE}.pub"
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            else
                echo -e "\e[31m✗ No SSH key found\e[0m"
            fi
            ;;
        4)
            if check_ssh_key; then
                echo "Testing GitHub connection..."
                ssh -T git@github.com 2>&1
            else
                echo -e "\e[31m✗ No SSH key configured\e[0m"
            fi
            ;;
        5)
            if check_ssh_key; then
                read -p "Remove SSH key? (y/n): " confirm_remove
                if [[ $confirm_remove =~ ^[Yy]$ ]]; then
                    rm -f "$SSH_KEY_FILE" "${SSH_KEY_FILE}.pub"
                    # Remove from SSH config
                    if [ -f "$SSH_CONFIG_FILE" ]; then
                        sed -i '/# GitHub Deploy Key/,+5d' "$SSH_CONFIG_FILE" 2>/dev/null
                    fi
                    echo -e "\e[32m✓ SSH key removed\e[0m"
                fi
            else
                echo -e "\e[33mNo SSH key to remove\e[0m"
            fi
            ;;
        0)
            return 0
            ;;
        *)
            echo -e "\e[31mInvalid option\e[0m"
            ;;
    esac
}

# Function to view deployment history
view_deployment_history() {
    local history_file="$CONFIG_DIR/deployment_history.log"
    
    echo -e "\e[36m=== Deployment History ===\e[0m"
    echo ""
    
    if [ -f "$history_file" ]; then
        cat "$history_file"
    else
        echo "No deployment history found."
    fi
    
    echo ""
    read -p "Press Enter to continue..."
}
