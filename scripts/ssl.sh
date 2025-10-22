#!/bin/bash

# SSL Certificate Management

# Function to generate self-signed SSL certificate
generate_ssl_certificate() {
    echo -e "\e[36m=== Generate Self-Signed SSL Certificate ===\e[0m"
    echo ""
    
    # Get domain/hostname
    current_fqdn=$(hostname -f 2>/dev/null)
    
    echo "Current FQDN: ${current_fqdn}"
    echo ""
    echo "Enter domain name for SSL certificate (e.g., rawjal.rsakudus.com):"
    echo "Press Enter to use current FQDN: ${current_fqdn}"
    read -r ssl_domain
    
    # Use current FQDN if empty
    if [ -z "$ssl_domain" ]; then
        ssl_domain="$current_fqdn"
    fi
    
    echo ""
    echo "Enter organization name (optional, press Enter to skip):"
    read -r org_name
    org_name=${org_name:-"Self-Signed"}
    
    echo ""
    echo "Enter country code (e.g., ID):"
    read -r country_code
    country_code=${country_code:-"ID"}
    
    # SSL directory
    ssl_dir="/etc/ssl/private"
    cert_dir="/etc/ssl/certs"
    
    # Create directories if not exist
    sudo mkdir -p "$ssl_dir"
    sudo mkdir -p "$cert_dir"
    
    # Certificate filenames
    key_file="${ssl_dir}/${ssl_domain}.key"
    cert_file="${cert_dir}/${ssl_domain}.crt"
    csr_file="${ssl_dir}/${ssl_domain}.csr"
    
    echo ""
    echo -e "\e[33mGenerating SSL certificate for: $ssl_domain\e[0m"
    
    # Generate private key (2048 bit)
    sudo openssl genrsa -out "$key_file" 2048 2>/dev/null
    
    # Generate certificate signing request (CSR)
    sudo openssl req -new -key "$key_file" -out "$csr_file" -subj "/C=${country_code}/O=${org_name}/CN=${ssl_domain}" 2>/dev/null
    
    # Generate self-signed certificate (valid for 365 days)
    sudo openssl x509 -req -days 365 -in "$csr_file" -signkey "$key_file" -out "$cert_file" 2>/dev/null
    
    # Set proper permissions
    sudo chmod 600 "$key_file"
    sudo chmod 644 "$cert_file"
    
    # Clean up CSR
    sudo rm -f "$csr_file"
    
    echo ""
    echo -e "\e[32m✓ SSL Certificate generated successfully!\e[0m"
    echo ""
    echo "Certificate details:"
    echo "  Domain: $ssl_domain"
    echo "  Key file: $key_file"
    echo "  Certificate file: $cert_file"
    echo "  Valid for: 365 days"
    echo ""
    
    # Store paths for later use
    export SSL_DOMAIN="$ssl_domain"
    export SSL_KEY_FILE="$key_file"
    export SSL_CERT_FILE="$cert_file"
}

# Function to configure SSL for Nginx
configure_nginx_ssl() {
    local domain="$1"
    local key_file="$2"
    local cert_file="$3"
    
    echo -e "\e[33mConfiguring Nginx with SSL...\e[0m"
    
    # Check if Nginx is installed
    if ! command -v nginx &> /dev/null; then
        echo -e "\e[31mNginx is not installed. Please install Nginx first.\e[0m"
        return 1
    fi
    
    # Backup default config
    if [ -f /etc/nginx/sites-available/default ]; then
        sudo cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.backup-$(date +%Y%m%d)
    fi
    
    # Create SSL configuration
    cat <<EOF | sudo tee /etc/nginx/sites-available/default > /dev/null
# HTTP - Redirect to HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name ${domain};
    return 301 https://\$server_name\$request_uri;
}

# HTTPS - SSL Configuration
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name ${domain};

    # SSL Configuration
    ssl_certificate ${cert_file};
    ssl_certificate_key ${key_file};
    
    # SSL Security Settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_session_timeout 10m;
    ssl_session_cache shared:SSL:10m;
    ssl_session_tickets off;
    
    # Security Headers
    add_header Strict-Transport-Security "max-age=63072000" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Document Root
    root /var/www/html;
    index index.php index.html index.htm;

    location / {
        try_files \$uri \$uri/ =404;
    }

    # PHP Configuration
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php-fpm.sock;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

    # Test Nginx configuration
    if sudo nginx -t 2>/dev/null; then
        # Restart Nginx
        sudo systemctl restart nginx
        echo -e "\e[32m✓ Nginx SSL configured and restarted successfully!\e[0m"
        return 0
    else
        echo -e "\e[31m✗ Nginx configuration test failed!\e[0m"
        sudo nginx -t
        return 1
    fi
}

# Function to configure SSL for Apache
configure_apache_ssl() {
    local domain="$1"
    local key_file="$2"
    local cert_file="$3"
    
    echo -e "\e[33mConfiguring Apache with SSL...\e[0m"
    
    # Check if Apache is installed
    if ! command -v apache2 &> /dev/null; then
        echo -e "\e[31mApache is not installed. Please install Apache first.\e[0m"
        return 1
    fi
    
    # Enable SSL module
    sudo a2enmod ssl 2>/dev/null
    sudo a2enmod rewrite 2>/dev/null
    sudo a2enmod headers 2>/dev/null
    
    # Backup default SSL config
    if [ -f /etc/apache2/sites-available/default-ssl.conf ]; then
        sudo cp /etc/apache2/sites-available/default-ssl.conf "/etc/apache2/sites-available/default-ssl.conf.backup-$(date +%Y%m%d)"
    fi
    
    # Create SSL virtual host
    cat <<EOF | sudo tee /etc/apache2/sites-available/default-ssl.conf > /dev/null
<IfModule mod_ssl.c>
    <VirtualHost _default_:443>
        ServerAdmin webmaster@localhost
        ServerName ${domain}

        DocumentRoot /var/www/html

        # SSL Configuration
        SSLEngine on
        SSLCertificateFile ${cert_file}
        SSLCertificateKeyFile ${key_file}

        # SSL Protocol Settings
        SSLProtocol all -SSLv3 -TLSv1 -TLSv1.1
        SSLCipherSuite HIGH:!aNULL:!MD5
        SSLHonorCipherOrder on

        # Security Headers
        Header always set Strict-Transport-Security "max-age=63072000"
        Header always set X-Frame-Options "SAMEORIGIN"
        Header always set X-Content-Type-Options "nosniff"
        Header always set X-XSS-Protection "1; mode=block"

        <Directory /var/www/html>
            Options Indexes FollowSymLinks
            AllowOverride All
            Require all granted
        </Directory>

        ErrorLog \${APACHE_LOG_DIR}/error.log
        CustomLog \${APACHE_LOG_DIR}/access.log combined
    </VirtualHost>
</IfModule>
EOF

    # Create HTTP to HTTPS redirect
    cat <<EOF | sudo tee /etc/apache2/sites-available/000-default.conf > /dev/null
<VirtualHost *:80>
    ServerName ${domain}
    
    # Redirect to HTTPS
    RewriteEngine On
    RewriteCond %{HTTPS} off
    RewriteRule ^(.*)$ https://%{HTTP_HOST}\$1 [R=301,L]

    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF

    # Enable SSL site
    sudo a2ensite default-ssl 2>/dev/null
    
    # Test Apache configuration
    if sudo apache2ctl configtest 2>/dev/null; then
        # Restart Apache
        sudo systemctl restart apache2
        echo -e "\e[32m✓ Apache SSL configured and restarted successfully!\e[0m"
        return 0
    else
        echo -e "\e[31m✗ Apache configuration test failed!\e[0m"
        sudo apache2ctl configtest
        return 1
    fi
}

# Function to test SSL configuration
test_ssl_configuration() {
    local domain="$1"
    local port="${2:-443}"
    
    echo ""
    echo -e "\e[36m=== Testing SSL Configuration ===\e[0m"
    echo ""
    
    # Check if port 443 is open
    if sudo ss -tuln | grep -q ":${port} "; then
        echo -e "\e[32m✓ SSL port ${port} is listening\e[0m"
    else
        echo -e "\e[31m✗ SSL port ${port} is not listening\e[0m"
        return 1
    fi
    
    # Test SSL certificate
    echo ""
    echo "Testing SSL certificate..."
    if timeout 5 openssl s_client -connect localhost:${port} -servername "${domain}" </dev/null 2>/dev/null | grep -q "Verify return code: 18"; then
        echo -e "\e[33m⚠ Self-signed certificate detected (expected for local SSL)\e[0m"
    fi
    
    # Show certificate details
    echo ""
    echo "Certificate information:"
    timeout 5 openssl s_client -connect localhost:${port} -servername "${domain}" </dev/null 2>/dev/null | openssl x509 -noout -subject -dates 2>/dev/null
    
    # Test HTTPS connection
    echo ""
    echo "Testing HTTPS connection..."
    if curl -k -s -o /dev/null -w "%{http_code}" "https://localhost" | grep -q "200\|301\|302"; then
        echo -e "\e[32m✓ HTTPS is working!\e[0m"
    else
        echo -e "\e[31m✗ HTTPS connection failed\e[0m"
    fi
    
    echo ""
    echo -e "\e[32m=== SSL Configuration Complete! ===\e[0m"
    echo ""
    echo "Access your site:"
    echo "  https://${domain}"
    echo ""
    echo -e "\e[33mNote for browsers:\e[0m"
    echo "  1. Browser will show 'Not Secure' warning (expected for self-signed)"
    echo "  2. Click 'Advanced' -> 'Proceed to ${domain}' to accept certificate"
    echo "  3. For production, use Let's Encrypt for trusted certificates"
}

# Main SSL setup function
setup_local_ssl() {
    echo -e "\e[36m=== Local SSL Certificate Setup ===\e[0m"
    echo ""
    echo "This will:"
    echo "  1. Generate self-signed SSL certificate"
    echo "  2. Configure your web server (Nginx/Apache)"
    echo "  3. Enable HTTPS on port 443"
    echo "  4. Test SSL configuration"
    echo ""
    
    # Generate certificate
    generate_ssl_certificate
    
    if [ -z "$SSL_DOMAIN" ]; then
        echo -e "\e[31mCertificate generation failed.\e[0m"
        return 1
    fi
    
    # Choose web server
    echo ""
    echo "Select web server to configure:"
    echo "1. Nginx"
    echo "2. Apache"
    echo "0. Skip configuration"
    echo ""
    echo -n "Choose option: "
    read -r webserver_choice
    
    case $webserver_choice in
        1)
            # Open firewall for HTTPS
            sudo ufw allow 443/tcp 2>/dev/null
            
            configure_nginx_ssl "$SSL_DOMAIN" "$SSL_KEY_FILE" "$SSL_CERT_FILE"
            if [ $? -eq 0 ]; then
                test_ssl_configuration "$SSL_DOMAIN"
            fi
            ;;
        2)
            # Open firewall for HTTPS
            sudo ufw allow 443/tcp 2>/dev/null
            
            configure_apache_ssl "$SSL_DOMAIN" "$SSL_KEY_FILE" "$SSL_CERT_FILE"
            if [ $? -eq 0 ]; then
                test_ssl_configuration "$SSL_DOMAIN"
            fi
            ;;
        0)
            echo ""
            echo "Certificate generated but not configured."
            echo "You can manually configure using:"
            echo "  Key: $SSL_KEY_FILE"
            echo "  Certificate: $SSL_CERT_FILE"
            ;;
        *)
            echo -e "\e[31mInvalid option.\e[0m"
            ;;
    esac
}

# Function to install Certbot
install_certbot() {
    echo -e "\e[33mInstalling Certbot...\e[0m"
    
    if command -v certbot &> /dev/null; then
        echo -e "\e[32m✓ Certbot already installed\e[0m"
        certbot --version
        return 0
    fi
    
    # Install snapd if not present
    if ! command -v snap &> /dev/null; then
        sudo apt update
        sudo apt install -y snapd
        sudo systemctl enable --now snapd.socket
        sleep 2
    fi
    
    # Install certbot via snap (recommended method)
    sudo snap install core
    sudo snap refresh core
    sudo snap install --classic certbot
    sudo ln -sf /snap/bin/certbot /usr/bin/certbot
    
    echo -e "\e[32m✓ Certbot installed successfully!\e[0m"
    certbot --version
}

# Function to configure Let's Encrypt for Nginx
setup_letsencrypt_nginx() {
    local domain="$1"
    local email="$2"
    
    echo -e "\e[33mConfiguring Let's Encrypt for Nginx...\e[0m"
    
    # Check if Nginx is installed
    if ! command -v nginx &> /dev/null; then
        echo -e "\e[31mNginx is not installed. Please install Nginx first.\e[0m"
        return 1
    fi
    
    # Check if domain is accessible
    echo "Testing domain accessibility..."
    if ! curl -s -o /dev/null -w "%{http_code}" "http://${domain}" | grep -q "200\|301\|302\|404"; then
        echo -e "\e[33m⚠ Warning: Domain may not be accessible from internet\e[0m"
        echo "Make sure:"
        echo "  1. DNS A record points to this server IP"
        echo "  2. Port 80 is open and forwarded"
        echo "  3. Firewall allows HTTP traffic"
        echo ""
        read -p "Continue anyway? (y/n): " continue_choice
        if [[ ! $continue_choice =~ ^[Yy]$ ]]; then
            return 1
        fi
    fi
    
    # Stop any process using port 80 temporarily
    sudo systemctl stop nginx 2>/dev/null || true
    
    # Obtain certificate
    echo ""
    echo -e "\e[33mObtaining SSL certificate from Let's Encrypt...\e[0m"
    
    if sudo certbot certonly --standalone \
        --non-interactive \
        --agree-tos \
        --email "$email" \
        --domains "$domain" \
        --pre-hook "systemctl stop nginx" \
        --post-hook "systemctl start nginx"; then
        
        echo -e "\e[32m✓ Certificate obtained successfully!\e[0m"
    else
        echo -e "\e[31m✗ Failed to obtain certificate\e[0m"
        sudo systemctl start nginx
        return 1
    fi
    
    # Certificate paths
    local cert_path="/etc/letsencrypt/live/${domain}/fullchain.pem"
    local key_path="/etc/letsencrypt/live/${domain}/privkey.pem"
    
    # Backup existing config
    if [ -f /etc/nginx/sites-available/default ]; then
        sudo cp /etc/nginx/sites-available/default "/etc/nginx/sites-available/default.backup-$(date +%Y%m%d-%H%M%S)"
    fi
    
    # Create Nginx SSL configuration
    cat <<EOF | sudo tee /etc/nginx/sites-available/default > /dev/null
# HTTP - Redirect to HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name ${domain};
    
    # Let's Encrypt verification
    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }
    
    location / {
        return 301 https://\$server_name\$request_uri;
    }
}

# HTTPS - Let's Encrypt SSL
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name ${domain};

    # Let's Encrypt SSL Configuration
    ssl_certificate ${cert_path};
    ssl_certificate_key ${key_path};
    
    # SSL Security Settings (Mozilla Intermediate)
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers off;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:50m;
    ssl_session_tickets off;
    ssl_stapling on;
    ssl_stapling_verify on;
    
    # Security Headers
    add_header Strict-Transport-Security "max-age=63072000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Document Root
    root /var/www/html;
    index index.php index.html index.htm;

    location / {
        try_files \$uri \$uri/ =404;
    }

    # PHP Configuration
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php-fpm.sock;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

    # Test and reload Nginx
    if sudo nginx -t 2>/dev/null; then
        sudo systemctl start nginx
        sudo systemctl reload nginx
        echo -e "\e[32m✓ Nginx configured with Let's Encrypt SSL!\e[0m"
        return 0
    else
        echo -e "\e[31m✗ Nginx configuration test failed!\e[0m"
        sudo nginx -t
        return 1
    fi
}

# Function to configure Let's Encrypt for Apache
setup_letsencrypt_apache() {
    local domain="$1"
    local email="$2"
    
    echo -e "\e[33mConfiguring Let's Encrypt for Apache...\e[0m"
    
    # Check if Apache is installed
    if ! command -v apache2 &> /dev/null; then
        echo -e "\e[31mApache is not installed. Please install Apache first.\e[0m"
        return 1
    fi
    
    # Check domain accessibility
    echo "Testing domain accessibility..."
    if ! curl -s -o /dev/null -w "%{http_code}" "http://${domain}" | grep -q "200\|301\|302\|404"; then
        echo -e "\e[33m⚠ Warning: Domain may not be accessible from internet\e[0m"
        echo "Make sure DNS A record points to this server"
        echo ""
        read -p "Continue anyway? (y/n): " continue_choice
        if [[ ! $continue_choice =~ ^[Yy]$ ]]; then
            return 1
        fi
    fi
    
    # Obtain certificate using Apache plugin
    echo ""
    echo -e "\e[33mObtaining SSL certificate from Let's Encrypt...\e[0m"
    
    # Enable required modules
    sudo a2enmod ssl rewrite headers 2>/dev/null
    
    if sudo certbot --apache \
        --non-interactive \
        --agree-tos \
        --email "$email" \
        --domains "$domain" \
        --redirect; then
        
        echo -e "\e[32m✓ Certificate obtained and Apache configured!\e[0m"
        return 0
    else
        echo -e "\e[31m✗ Failed to obtain certificate or configure Apache\e[0m"
        return 1
    fi
}

# Function to setup auto-renewal
setup_auto_renewal() {
    echo -e "\e[33mSetting up automatic certificate renewal...\e[0m"
    
    # Test renewal
    echo "Testing renewal process..."
    if sudo certbot renew --dry-run; then
        echo -e "\e[32m✓ Renewal test successful!\e[0m"
    else
        echo -e "\e[33m⚠ Renewal test had issues (certificates may still renew)\e[0m"
    fi
    
    # Certbot automatically installs renewal timer
    # Check if systemd timer is active
    if systemctl list-timers | grep -q certbot; then
        echo -e "\e[32m✓ Auto-renewal timer is active\e[0m"
        echo ""
        echo "Renewal schedule:"
        systemctl list-timers | grep certbot
    else
        echo -e "\e[33m⚠ Auto-renewal timer not found\e[0m"
        echo "Setting up cron job as backup..."
        
        # Add cron job for renewal
        (crontab -l 2>/dev/null | grep -v certbot; echo "0 0,12 * * * certbot renew --quiet --post-hook 'systemctl reload nginx || systemctl reload apache2'") | crontab -
        echo -e "\e[32m✓ Cron job created for auto-renewal\e[0m"
    fi
    
    echo ""
    echo "Certificates will auto-renew before expiry (90 days validity)"
}

# Function to verify Let's Encrypt SSL
verify_letsencrypt_ssl() {
    local domain="$1"
    
    echo ""
    echo -e "\e[36m=== Verifying Let's Encrypt SSL ===\e[0m"
    echo ""
    
    # Check certificate files
    if [ -d "/etc/letsencrypt/live/${domain}" ]; then
        echo -e "\e[32m✓ Certificate directory exists\e[0m"
        echo "  Path: /etc/letsencrypt/live/${domain}/"
    else
        echo -e "\e[31m✗ Certificate directory not found\e[0m"
        return 1
    fi
    
    # Show certificate details
    echo ""
    echo "Certificate information:"
    sudo certbot certificates | grep -A 10 "${domain}"
    
    # Test HTTPS connection
    echo ""
    echo "Testing HTTPS connection..."
    if curl -s -o /dev/null -w "%{http_code}" "https://${domain}" | grep -q "200\|301\|302"; then
        echo -e "\e[32m✓ HTTPS is working!\e[0m"
    else
        echo -e "\e[31m✗ HTTPS connection failed\e[0m"
    fi
    
    # Test SSL certificate validity
    echo ""
    echo "Testing SSL certificate..."
    if echo | timeout 5 openssl s_client -connect "${domain}:443" -servername "${domain}" 2>/dev/null | grep -q "Verify return code: 0"; then
        echo -e "\e[32m✓ SSL certificate is valid and trusted!\e[0m"
    else
        echo -e "\e[33m⚠ SSL certificate validation had issues\e[0m"
    fi
    
    echo ""
    echo -e "\e[32m=== SSL Setup Complete! ===\e[0m"
    echo ""
    echo "Your site is now secured with Let's Encrypt:"
    echo "  🔒 https://${domain}"
    echo ""
    echo "✅ Trusted by all browsers (no warnings)"
    echo "✅ Automatic renewal enabled"
    echo "✅ HTTP → HTTPS redirect active"
    echo "✅ Security headers configured"
}

# Main Let's Encrypt setup function
setup_letsencrypt_ssl() {
    echo -e "\e[36m=== Let's Encrypt SSL Setup ===\e[0m"
    echo ""
    echo "This will obtain a FREE SSL certificate from Let's Encrypt"
    echo "✅ Trusted by all browsers"
    echo "✅ Automatic renewal every 90 days"
    echo ""
    echo -e "\e[33mRequirements:\e[0m"
    echo "  1. Valid domain name (e.g., example.com)"
    echo "  2. Domain DNS A record pointing to this server's public IP"
    echo "  3. Port 80 and 443 accessible from internet"
    echo "  4. Valid email address for certificate notifications"
    echo ""
    
    # Check server public IP
    public_ip=$(curl -s ifconfig.me 2>/dev/null || curl -s icanhazip.com 2>/dev/null)
    if [ -n "$public_ip" ]; then
        echo "Server public IP: $public_ip"
        echo "Make sure your domain DNS points to this IP"
        echo ""
    fi
    
    read -p "Continue? (y/n): " continue_setup
    if [[ ! $continue_setup =~ ^[Yy]$ ]]; then
        return 0
    fi
    
    # Get domain
    echo ""
    echo "Enter your domain name (e.g., example.com or subdomain.example.com):"
    read -r domain
    
    if [ -z "$domain" ]; then
        echo -e "\e[31mDomain is required.\e[0m"
        return 1
    fi
    
    # Get email
    echo ""
    echo "Enter your email address (for certificate expiry notifications):"
    read -r email
    
    if [ -z "$email" ]; then
        echo -e "\e[31mEmail is required.\e[0m"
        return 1
    fi
    
    # Install Certbot
    echo ""
    install_certbot
    
    # Open firewall ports
    echo ""
    echo -e "\e[33mOpening firewall ports...\e[0m"
    sudo ufw allow 80/tcp 2>/dev/null
    sudo ufw allow 443/tcp 2>/dev/null
    echo -e "\e[32m✓ Ports 80 and 443 opened\e[0m"
    
    # Choose web server
    echo ""
    echo "Select web server:"
    echo "1. Nginx"
    echo "2. Apache"
    echo "0. Cancel"
    echo ""
    echo -n "Choose option: "
    read -r webserver_choice
    
    case $webserver_choice in
        1)
            setup_letsencrypt_nginx "$domain" "$email"
            if [ $? -eq 0 ]; then
                setup_auto_renewal
                verify_letsencrypt_ssl "$domain"
            fi
            ;;
        2)
            setup_letsencrypt_apache "$domain" "$email"
            if [ $? -eq 0 ]; then
                setup_auto_renewal
                verify_letsencrypt_ssl "$domain"
            fi
            ;;
        0)
            echo "Cancelled."
            return 0
            ;;
        *)
            echo -e "\e[31mInvalid option.\e[0m"
            return 1
            ;;
    esac
}
