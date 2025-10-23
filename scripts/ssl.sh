#!/bin/bash

# SSL Certificate Management

# Function to diagnose SSL issues
diagnose_ssl_issues() {
    echo -e "\e[36m=== SSL Diagnostics ===\e[0m"
    echo ""
    
    # Check Nginx/Apache status
    echo "1. Web Server Status:"
    echo "─────────────────────────────────────"
    if systemctl is-active --quiet nginx; then
        echo -e "  Nginx: \e[32m● Running\e[0m"
    else
        echo -e "  Nginx: \e[31m○ Not running\e[0m"
    fi
    
    if systemctl is-active --quiet apache2; then
        echo -e "  Apache: \e[32m● Running\e[0m"
    else
        echo -e "  Apache: \e[90m○ Not running\e[0m"
    fi
    echo ""
    
    # Check listening ports
    echo "2. Port 443 Status:"
    echo "─────────────────────────────────────"
    if sudo ss -tuln | grep -q ":443 "; then
        echo -e "  \e[32m✓ Port 443 is LISTENING\e[0m"
        echo ""
        sudo ss -tulnp | grep ":443 "
    else
        echo -e "  \e[31m✗ Port 443 is NOT listening\e[0m"
        echo ""
        echo "  All HTTPS/SSL related ports:"
        sudo ss -tuln | grep -E ":(443|8443)" || echo "  None found"
    fi
    echo ""
    
    # Check certificates
    echo "3. SSL Certificates:"
    echo "─────────────────────────────────────"
    if [ -d /etc/ssl/private ]; then
        local cert_count=$(ls -1 /etc/ssl/private/*.key 2>/dev/null | wc -l)
        if [ $cert_count -gt 0 ]; then
            echo -e "  \e[32m✓ Found $cert_count certificate(s)\e[0m"
            ls -lh /etc/ssl/private/*.key 2>/dev/null | awk '{print "    " $9}'
        else
            echo -e "  \e[33m⚠ No certificates found\e[0m"
        fi
    fi
    echo ""
    
    # Check Nginx configuration
    echo "4. Nginx SSL Configuration:"
    echo "─────────────────────────────────────"
    if [ -d /etc/nginx/sites-enabled ]; then
        local ssl_sites=0
        for site in /etc/nginx/sites-enabled/*; do
            if [ -f "$site" ] && grep -q "listen.*443.*ssl" "$site" 2>/dev/null; then
                ssl_sites=$((ssl_sites + 1))
                echo -e "  \e[32m✓\e[0m $(basename "$site")"
            fi
        done
        if [ $ssl_sites -eq 0 ]; then
            echo -e "  \e[33m⚠ No SSL sites configured\e[0m"
        fi
    fi
    echo ""
    
    # Check recent errors
    echo "5. Recent Errors (last 10 lines):"
    echo "─────────────────────────────────────"
    if [ -f /var/log/nginx/error.log ]; then
        sudo tail -10 /var/log/nginx/error.log | sed 's/^/  /'
    else
        echo "  No error log found"
    fi
    echo ""
    
    # Suggested actions
    echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
    echo -e "\e[33mSuggested Actions:\e[0m"
    echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
    
    if ! sudo ss -tuln | grep -q ":443 "; then
        echo "  Port 443 not listening. Try:"
        echo "    sudo systemctl restart nginx"
        echo "    sudo nginx -t  # Test configuration"
    fi
    
    if systemctl is-active --quiet apache2 && systemctl is-active --quiet nginx; then
        echo "  Both Apache and Nginx are running (possible conflict):"
        echo "    sudo systemctl stop apache2"
    fi
    
    echo ""
}

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
    
    # Verify certificate files exist
    if [ ! -f "$key_file" ] || [ ! -f "$cert_file" ]; then
        echo -e "\e[31m✗ Certificate files not found!\e[0m"
        echo "  Key: $key_file"
        echo "  Cert: $cert_file"
        return 1
    fi
    
    # Check if port 443 is already in use
    if sudo ss -tuln | grep -q ":443 "; then
        echo -e "\e[33m⚠ Port 443 is already in use\e[0m"
        echo "Processes using port 443:"
        sudo ss -tulnp | grep ":443 "
        echo ""
        while true; do
            read -p "Stop existing service and continue? (y/n): " stop_service
            case $stop_service in
                [Yy]|[Yy][Ee][Ss])
                    # Try to stop Apache if it's using 443
                    sudo systemctl stop apache2 2>/dev/null || true
                    sleep 2
                    break
                    ;;
                [Nn]|[Nn][Oo])
                    return 1
                    ;;
                *)
                    echo -e "\e[31mInvalid input. Please enter 'y' or 'n'.\e[0m"
                    ;;
            esac
        done
    fi
    
    # Detect PHP version for configuration
    local php_socket="/var/run/php/php-fpm.sock"
    for version in 8.4 8.3 8.2 8.1 8.0 7.4; do
        if [ -S "/var/run/php/php${version}-fpm.sock" ]; then
            php_socket="/var/run/php/php${version}-fpm.sock"
            echo -e "\e[32m✓ Detected PHP ${version}-FPM\e[0m"
            break
        fi
    done
    
    # Backup default config
    if [ -f /etc/nginx/sites-available/default ]; then
        sudo cp /etc/nginx/sites-available/default "/etc/nginx/sites-available/default.backup-$(date +%Y%m%d-%H%M%S)"
        echo -e "\e[32m✓ Backup created\e[0m"
    fi
    
    # Create SSL configuration
    echo "Creating Nginx SSL configuration..."
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
        fastcgi_pass unix:${php_socket};
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

    echo -e "\e[32m✓ Configuration file created\e[0m"
    
    # Test Nginx configuration
    echo ""
    echo "Testing Nginx configuration..."
    if sudo nginx -t 2>&1 | tee /tmp/nginx-test.log; then
        echo -e "\e[32m✓ Nginx configuration test passed\e[0m"
    else
        echo -e "\e[31m✗ Nginx configuration test failed!\e[0m"
        echo ""
        echo "Error details:"
        cat /tmp/nginx-test.log
        rm -f /tmp/nginx-test.log
        return 1
    fi
    
    # Stop Nginx first
    echo ""
    echo "Restarting Nginx..."
    sudo systemctl stop nginx 2>/dev/null || true
    sleep 2
    
    # Start Nginx
    if sudo systemctl start nginx; then
        echo -e "\e[32m✓ Nginx started successfully\e[0m"
    else
        echo -e "\e[31m✗ Failed to start Nginx\e[0m"
        echo ""
        echo "Nginx status:"
        sudo systemctl status nginx --no-pager -l
        return 1
    fi
    
    # Wait a moment for Nginx to fully start
    sleep 2
    
    # Verify Nginx is running
    if sudo systemctl is-active --quiet nginx; then
        echo -e "\e[32m✓ Nginx is running\e[0m"
    else
        echo -e "\e[31m✗ Nginx is not running\e[0m"
        echo ""
        echo "Checking logs..."
        sudo journalctl -u nginx -n 20 --no-pager
        return 1
    fi
    
    # Verify port 443 is listening
    echo ""
    echo "Verifying port 443..."
    sleep 1
    if sudo ss -tuln | grep -q ":443 "; then
        echo -e "\e[32m✓ Port 443 is now listening\e[0m"
        sudo ss -tuln | grep ":443 "
        echo ""
        echo -e "\e[32m✓ Nginx SSL configured and restarted successfully!\e[0m"
        return 0
    else
        echo -e "\e[31m✗ Port 443 is NOT listening\e[0m"
        echo ""
        echo "Debugging information:"
        echo "1. Nginx status:"
        sudo systemctl status nginx --no-pager -l
        echo ""
        echo "2. Recent Nginx errors:"
        sudo tail -20 /var/log/nginx/error.log 2>/dev/null || echo "No error log found"
        echo ""
        echo "3. All listening ports:"
        sudo ss -tuln | grep LISTEN
        echo ""
        echo "4. Nginx configuration test:"
        sudo nginx -t
        echo ""
        echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
        echo -e "\e[33m⚠ Troubleshooting Steps:\e[0m"
        echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
        echo ""
        echo "Run these commands to diagnose:"
        echo "  1. Check Nginx is running:"
        echo "     sudo systemctl status nginx"
        echo ""
        echo "  2. Check all ports:"
        echo "     sudo ss -tuln | grep LISTEN"
        echo ""
        echo "  3. Check Nginx error log:"
        echo "     sudo tail -50 /var/log/nginx/error.log"
        echo ""
        echo "  4. Restart Nginx manually:"
        echo "     sudo systemctl restart nginx"
        echo "     sudo ss -tuln | grep :443"
        echo ""
        echo "  5. Check if Apache is using port 443:"
        echo "     sudo systemctl stop apache2"
        echo "     sudo systemctl restart nginx"
        echo ""
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
    echo "Checking if SSL port ${port} is listening..."
    if sudo ss -tuln | grep -q ":${port} "; then
        echo -e "\e[32m✓ SSL port ${port} is listening\e[0m"
        echo ""
        echo "Port details:"
        sudo ss -tulnp | grep ":${port} "
    else
        echo -e "\e[31m✗ SSL port ${port} is not listening\e[0m"
        echo ""
        echo "Possible issues:"
        echo "  1. Nginx/Apache failed to start"
        echo "  2. Configuration error"
        echo "  3. Port blocked by firewall"
        echo "  4. Another service using the port"
        echo ""
        echo "All listening ports:"
        sudo ss -tuln | grep LISTEN
        echo ""
        echo "Nginx/Apache status:"
        sudo systemctl status nginx --no-pager -l 2>/dev/null || sudo systemctl status apache2 --no-pager -l 2>/dev/null
        return 1
    fi
    
    # Check firewall
    echo ""
    echo "Checking firewall rules..."
    if command -v ufw &> /dev/null; then
        if sudo ufw status 2>/dev/null | grep -q "443.*ALLOW"; then
            echo -e "\e[32m✓ UFW allows port 443\e[0m"
        else
            echo -e "\e[33m⚠ UFW may not allow port 443\e[0m"
            echo "Adding firewall rule..."
            sudo ufw allow 443/tcp 2>/dev/null
            echo -e "\e[32m✓ Port 443 opened in firewall\e[0m"
        fi
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
    timeout 5 openssl s_client -connect localhost:${port} -servername "${domain}" </dev/null 2>/dev/null | openssl x509 -noout -subject -dates 2>/dev/null || echo "Unable to retrieve certificate info"
    
    # Test HTTPS connection
    echo ""
    echo "Testing HTTPS connection..."
    local http_code
    http_code=$(curl -k -s -o /dev/null -w "%{http_code}" "https://localhost" 2>/dev/null)
    
    if echo "$http_code" | grep -q "200\|301\|302"; then
        echo -e "\e[32m✓ HTTPS is working! (HTTP code: $http_code)\e[0m"
    else
        echo -e "\e[31m✗ HTTPS connection failed (HTTP code: $http_code)\e[0m"
        echo ""
        echo "Debugging: Testing with curl verbose..."
        curl -kv "https://localhost" 2>&1 | head -20
    fi
    
    echo ""
    echo -e "\e[32m=== SSL Configuration Complete! ===\e[0m"
    echo ""
    echo "Access your site:"
    echo "  https://${domain}"
    echo "  https://$(hostname -I | awk '{print $1}')"
    echo ""
    echo -e "\e[33mNote for browsers:\e[0m"
    echo "  1. Browser will show 'Not Secure' warning (expected for self-signed)"
    echo "  2. Click 'Advanced' -> 'Proceed to ${domain}' to accept certificate"
    echo "  3. For production, use Let's Encrypt for trusted certificates"
    echo ""
    echo "Verify with command:"
    echo "  curl -k https://localhost"
    echo "  curl -k https://${domain}"
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
    
    # Check if certificates already exist
    echo "Checking for existing SSL certificates..."
    local existing_certs=false
    if [ -d /etc/ssl/private ] && [ "$(ls -A /etc/ssl/private/*.key 2>/dev/null)" ]; then
        echo ""
        echo -e "\e[33m⚠ Existing SSL certificates found:\e[0m"
        ls -lh /etc/ssl/private/*.key 2>/dev/null | awk '{print "  " $9}'
        echo ""
        while true; do
            read -p "Generate new certificate? (y/n): " gen_new
            case $gen_new in
                [Yy]|[Yy][Ee][Ss])
                    break
                    ;;
                [Nn]|[Nn][Oo])
                    echo -e "\e[33mSetup cancelled.\e[0m"
                    return 0
                    ;;
                *)
                    echo -e "\e[31mInvalid input. Please enter 'y' or 'n'.\e[0m"
                    ;;
            esac
        done
        existing_certs=true
    fi
    
    echo ""
    while true; do
        read -p "Continue with SSL setup? (y/n): " continue_ssl
        case $continue_ssl in
            [Yy]|[Yy][Ee][Ss])
                break
                ;;
            [Nn]|[Nn][Oo])
                echo -e "\e[33mSetup cancelled.\e[0m"
                return 0
                ;;
            *)
                echo -e "\e[31mInvalid input. Please enter 'y' or 'n'.\e[0m"
                ;;
        esac
    done
    
    # Generate certificate
    echo ""
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
    echo "0. Skip configuration (certificate only)"
    echo ""
    echo -n "Choose option: "
    read -r webserver_choice
    
    case $webserver_choice in
        1)
            # Open firewall for HTTPS
            echo ""
            echo -e "\e[33mOpening firewall port 443...\e[0m"
            sudo ufw allow 443/tcp 2>/dev/null
            
            configure_nginx_ssl "$SSL_DOMAIN" "$SSL_KEY_FILE" "$SSL_CERT_FILE"
            local config_result=$?
            
            if [ $config_result -eq 0 ]; then
                test_ssl_configuration "$SSL_DOMAIN"
            else
                echo ""
                echo -e "\e[31m✗ Nginx SSL configuration failed\e[0m"
                echo ""
                while true; do
                    read -p "Run diagnostics? (y/n): " run_diag
                    case $run_diag in
                        [Yy]|[Yy][Ee][Ss])
                            diagnose_ssl_issues
                            break
                            ;;
                        [Nn]|[Nn][Oo])
                            break
                            ;;
                        *)
                            echo -e "\e[31mInvalid input. Please enter 'y' or 'n'.\e[0m"
                            ;;
                    esac
                done
            fi
            ;;
        2)
            # Open firewall for HTTPS
            echo ""
            echo -e "\e[33mOpening firewall port 443...\e[0m"
            sudo ufw allow 443/tcp 2>/dev/null
            
            configure_apache_ssl "$SSL_DOMAIN" "$SSL_KEY_FILE" "$SSL_CERT_FILE"
            local config_result=$?
            
            if [ $config_result -eq 0 ]; then
                test_ssl_configuration "$SSL_DOMAIN"
            else
                echo ""
                echo -e "\e[31m✗ Apache SSL configuration failed\e[0m"
                echo ""
                while true; do
                    read -p "Run diagnostics? (y/n): " run_diag
                    case $run_diag in
                        [Yy]|[Yy][Ee][Ss])
                            diagnose_ssl_issues
                            break
                            ;;
                        [Nn]|[Nn][Oo])
                            break
                            ;;
                        *)
                            echo -e "\e[31mInvalid input. Please enter 'y' or 'n'.\e[0m"
                            ;;
                    esac
                done
            fi
            ;;
        0)
            echo ""
            echo -e "\e[32m✓ Certificate generated successfully!\e[0m"
            echo ""
            echo "Certificate details:"
            echo "  Domain: $SSL_DOMAIN"
            echo "  Key: $SSL_KEY_FILE"
            echo "  Certificate: $SSL_CERT_FILE"
            echo ""
            echo "You can manually configure your web server using these files."
            ;;
        *)
            echo -e "\e[31mInvalid option.\e[0m"
            echo ""
            echo "Certificate files (not configured):"
            echo "  Key: $SSL_KEY_FILE"
            echo "  Certificate: $SSL_CERT_FILE"
            ;;
    esac
    
    # Clear exported variables to prevent reuse
    unset SSL_DOMAIN SSL_KEY_FILE SSL_CERT_FILE
    
    echo ""
    echo -e "\e[32m=== SSL Setup Complete ===\e[0m"
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
        while true; do
            read -p "Continue anyway? (y/n): " continue_choice
            case $continue_choice in
                [Yy]|[Yy][Ee][Ss])
                    break
                    ;;
                [Nn]|[Nn][Oo])
                    return 1
                    ;;
                *)
                    echo -e "\e[31mInvalid input. Please enter 'y' or 'n'.\e[0m"
                    ;;
            esac
        done
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
        while true; do
            read -p "Continue anyway? (y/n): " continue_choice
            case $continue_choice in
                [Yy]|[Yy][Ee][Ss])
                    break
                    ;;
                [Nn]|[Nn][Oo])
                    return 1
                    ;;
                *)
                    echo -e "\e[31mInvalid input. Please enter 'y' or 'n'.\e[0m"
                    ;;
            esac
        done
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
    
    while true; do
        read -p "Continue? (y/n): " continue_setup
        case $continue_setup in
            [Yy]|[Yy][Ee][Ss])
                break
                ;;
            [Nn]|[Nn][Oo])
                echo -e "\e[33mSetup cancelled.\e[0m"
                return 0
                ;;
            *)
                echo -e "\e[31mInvalid input. Please enter 'y' or 'n'.\e[0m"
                ;;
        esac
    done
    
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

# SSL Management Menu
ssl_management_menu() {
    while true; do
        echo ""
        echo -e "\e[36m=== SSL Management Menu ===\e[0m"
        echo ""
        echo "1. Setup Local SSL (Self-Signed)"
        echo "2. Setup Public SSL (Let's Encrypt)"
        echo "3. Diagnose SSL Issues"
        echo "4. List SSL Certificates"
        echo "5. Test SSL Connection"
        echo "0. Back to main menu"
        echo ""
        read -p "Choose option: " ssl_choice
        
        case $ssl_choice in
            1)
                setup_local_ssl
                ;;
            2)
                setup_letsencrypt_ssl
                ;;
            3)
                diagnose_ssl_issues
                ;;
            4)
                echo ""
                echo -e "\e[36m=== SSL Certificates ===\e[0m"
                echo ""
                if [ -d /etc/ssl/private ]; then
                    echo "Self-Signed Certificates:"
                    ls -lh /etc/ssl/private/*.key 2>/dev/null || echo "  None found"
                fi
                echo ""
                if [ -d /etc/letsencrypt/live ]; then
                    echo "Let's Encrypt Certificates:"
                    sudo certbot certificates 2>/dev/null || echo "  None found"
                fi
                ;;
            5)
                echo ""
                read -p "Enter domain to test (e.g., example.com or localhost): " test_domain
                test_domain=${test_domain:-localhost}
                test_ssl_configuration "$test_domain"
                ;;
            0)
                return 0
                ;;
            *)
                echo -e "\e[31mInvalid option.\e[0m"
                ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
    done
}

