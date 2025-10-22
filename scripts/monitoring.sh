#!/bin/bash

# Monitoring Tools Installation (Node Exporter for Prometheus)

# Config file
CONFIG_DIR="$HOME/.ubuntu-tools"
NODE_EXPORTER_CONFIG="$CONFIG_DIR/node_exporter.conf"

# Function to install Node Exporter
install_node_exporter() {
    echo -e "\e[36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
    echo -e "\e[36m   Node Exporter Installation\e[0m"
    echo -e "\e[36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
    echo ""
    echo "Node Exporter exports hardware and OS metrics"
    echo "for Prometheus monitoring server."
    echo ""
    
    # Check if already installed
    if command -v node_exporter &> /dev/null; then
        echo -e "\e[33m⚠ Node Exporter is already installed\e[0m"
        node_exporter --version
        echo ""
        read -p "Reinstall? (y/n): " reinstall
        if [[ ! $reinstall =~ ^[Yy]$ ]]; then
            return 0
        fi
        
        # Stop service if running
        sudo systemctl stop node_exporter 2>/dev/null || true
    fi
    
    # Get latest version
    local version="1.8.2"
    echo "Installing Node Exporter v${version}..."
    echo ""
    
    # Download
    cd /tmp || return 1
    
    echo "Downloading Node Exporter..."
    wget -q --show-progress https://github.com/prometheus/node_exporter/releases/download/v${version}/node_exporter-${version}.linux-amd64.tar.gz
    
    if [ $? -ne 0 ]; then
        echo -e "\e[31m✗ Failed to download Node Exporter\e[0m"
        return 1
    fi
    
    # Extract
    echo "Extracting..."
    tar xzf node_exporter-${version}.linux-amd64.tar.gz
    
    # Move binary
    echo "Installing binary..."
    sudo mv node_exporter-${version}.linux-amd64/node_exporter /usr/local/bin/
    sudo chmod +x /usr/local/bin/node_exporter
    
    # Cleanup
    rm -rf node_exporter-${version}.linux-amd64*
    
    echo -e "\e[32m✓ Node Exporter binary installed\e[0m"
    
    # Create user
    echo ""
    echo "Creating node_exporter user..."
    if id "node_exporter" &>/dev/null; then
        echo -e "\e[33m⚠ User node_exporter already exists\e[0m"
    else
        sudo useradd --no-create-home --shell /bin/false node_exporter
        echo -e "\e[32m✓ User created\e[0m"
    fi
    
    # Set ownership
    sudo chown node_exporter:node_exporter /usr/local/bin/node_exporter
    
    # Get port configuration
    echo ""
    echo -e "\e[36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
    echo "Port Configuration"
    echo ""
    echo "Default Node Exporter port: 9100"
    local use_default_port
    read -p "Use default port 9100? (y/n): " use_default_port
    
    local node_port="9100"
    if [[ ! $use_default_port =~ ^[Yy]$ ]]; then
        read -p "Enter custom port: " custom_port
        if [[ $custom_port =~ ^[0-9]+$ ]]; then
            node_port="$custom_port"
        else
            echo -e "\e[33m⚠ Invalid port, using default 9100\e[0m"
        fi
    fi
    
    echo ""
    echo "Node Exporter will listen on port: $node_port"
    
    # Create systemd service
    echo ""
    echo "Creating systemd service..."
    cat <<EOF | sudo tee /etc/systemd/system/node_exporter.service > /dev/null
[Unit]
Description=Node Exporter
Documentation=https://github.com/prometheus/node_exporter
After=network.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter --web.listen-address=:${node_port}
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

    echo -e "\e[32m✓ Systemd service created\e[0m"
    
    # Reload systemd
    sudo systemctl daemon-reload
    
    # Enable and start service
    echo ""
    echo "Starting Node Exporter..."
    sudo systemctl enable node_exporter
    sudo systemctl start node_exporter
    
    # Check status
    sleep 2
    if systemctl is-active --quiet node_exporter; then
        echo -e "\e[32m✓ Node Exporter is running\e[0m"
    else
        echo -e "\e[31m✗ Failed to start Node Exporter\e[0m"
        sudo systemctl status node_exporter --no-pager
        return 1
    fi
    
    # Open firewall port
    echo ""
    echo -e "\e[36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
    echo "Firewall Configuration"
    echo ""
    
    if command -v ufw &> /dev/null; then
        echo "Opening port ${node_port} in UFW..."
        sudo ufw allow ${node_port}/tcp comment 'Node Exporter'
        echo -e "\e[32m✓ Port ${node_port} opened\e[0m"
    else
        echo -e "\e[33m⚠ UFW not installed, skipping firewall configuration\e[0m"
        echo "  Install UFW: sudo apt install ufw"
    fi
    
    # Configure Prometheus target
    echo ""
    echo -e "\e[36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
    echo "Prometheus Server Configuration"
    echo ""
    
    # Get current server IP
    local current_ip
    current_ip=$(hostname -I | awk '{print $1}')
    echo "Current server IP: $current_ip"
    echo ""
    
    read -p "Enter Prometheus server IP address: " prometheus_ip
    
    if [ -z "$prometheus_ip" ]; then
        echo -e "\e[33m⚠ Prometheus IP not provided\e[0m"
    else
        # Save configuration
        mkdir -p "$CONFIG_DIR"
        cat > "$NODE_EXPORTER_CONFIG" <<EOF
# Node Exporter Configuration
NODE_EXPORTER_VERSION=${version}
NODE_EXPORTER_PORT=${node_port}
PROMETHEUS_SERVER=${prometheus_ip}
CLIENT_IP=${current_ip}
INSTALL_DATE=$(date '+%Y-%m-%d %H:%M:%S')
EOF

        echo ""
        echo -e "\e[32m✓ Configuration saved\e[0m"
        echo ""
        echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
        echo -e "\e[33m   Add to Prometheus Server\e[0m"
        echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
        echo ""
        echo "On Prometheus server (${prometheus_ip}), add this to prometheus.yml:"
        echo ""
        echo "scrape_configs:"
        echo "  - job_name: \"node_exporter\""
        echo "    static_configs:"
        echo "      - targets: [\"${current_ip}:${node_port}\"]"
        echo "        labels:"
        echo "          instance: \"$(hostname)\""
        echo ""
        echo "Then restart Prometheus:"
        echo "  sudo systemctl restart prometheus"
        echo ""
    fi
    
    # Test endpoint
    echo -e "\e[36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
    echo "Testing Node Exporter endpoint..."
    echo ""
    
    if curl -s http://localhost:${node_port}/metrics | head -5 > /dev/null; then
        echo -e "\e[32m✓ Node Exporter is responding\e[0m"
        echo ""
        echo "Metrics endpoint: http://${current_ip}:${node_port}/metrics"
        echo ""
        echo "Sample metrics:"
        curl -s http://localhost:${node_port}/metrics | grep -E "node_cpu_seconds_total|node_memory_MemTotal_bytes|node_filesystem_size_bytes" | head -5
    else
        echo -e "\e[31m✗ Failed to connect to Node Exporter\e[0m"
    fi
    
    # Summary
    echo ""
    echo -e "\e[32m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
    echo -e "\e[32m   Installation Complete!\e[0m"
    echo -e "\e[32m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
    echo ""
    echo "Node Exporter Details:"
    echo "  Version:    $version"
    echo "  Port:       $node_port"
    echo "  Service:    node_exporter.service"
    echo "  User:       node_exporter"
    echo "  Endpoint:   http://${current_ip}:${node_port}/metrics"
    if [ -n "$prometheus_ip" ]; then
        echo "  Prometheus: $prometheus_ip"
    fi
    echo ""
    echo "Useful commands:"
    echo "  sudo systemctl status node_exporter"
    echo "  sudo systemctl restart node_exporter"
    echo "  curl http://localhost:${node_port}/metrics"
    echo ""
}

# Function to change Prometheus server IP
change_prometheus_ip() {
    echo -e "\e[36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
    echo -e "\e[36m   Change Prometheus Server IP\e[0m"
    echo -e "\e[36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
    echo ""
    
    # Check if Node Exporter is installed
    if ! systemctl is-active --quiet node_exporter; then
        echo -e "\e[31m✗ Node Exporter is not running\e[0m"
        echo "Install Node Exporter first (Menu option)."
        return 1
    fi
    
    # Get current configuration
    local current_ip current_port current_prometheus
    current_ip=$(hostname -I | awk '{print $1}')
    current_port="9100"
    current_prometheus=""
    
    if [ -f "$NODE_EXPORTER_CONFIG" ]; then
        # shellcheck source=/dev/null
        source "$NODE_EXPORTER_CONFIG"
        current_port="$NODE_EXPORTER_PORT"
        current_prometheus="$PROMETHEUS_SERVER"
    fi
    
    echo "Current Configuration:"
    echo "  Client IP:       $current_ip"
    echo "  Client Port:     $current_port"
    if [ -n "$current_prometheus" ]; then
        echo "  Prometheus IP:   $current_prometheus"
    else
        echo "  Prometheus IP:   (not configured)"
    fi
    echo ""
    
    local new_prometheus_ip
    read -p "Enter new Prometheus server IP: " new_prometheus_ip
    
    if [ -z "$new_prometheus_ip" ]; then
        echo -e "\e[31mIP address required.\e[0m"
        return 1
    fi
    
    # Validate IP format (basic)
    if [[ ! $new_prometheus_ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        echo -e "\e[31mInvalid IP address format.\e[0m"
        return 1
    fi
    
    # Update configuration file
    mkdir -p "$CONFIG_DIR"
    
    if [ -f "$NODE_EXPORTER_CONFIG" ]; then
        sed -i "s/^PROMETHEUS_SERVER=.*/PROMETHEUS_SERVER=${new_prometheus_ip}/" "$NODE_EXPORTER_CONFIG"
    else
        cat > "$NODE_EXPORTER_CONFIG" <<EOF
# Node Exporter Configuration
NODE_EXPORTER_PORT=${current_port}
PROMETHEUS_SERVER=${new_prometheus_ip}
CLIENT_IP=${current_ip}
UPDATED_DATE=$(date '+%Y-%m-%d %H:%M:%S')
EOF
    fi
    
    echo ""
    echo -e "\e[32m✓ Configuration updated\e[0m"
    echo ""
    echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
    echo -e "\e[33m   Update Prometheus Server Configuration\e[0m"
    echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
    echo ""
    echo "On Prometheus server (${new_prometheus_ip}), update prometheus.yml:"
    echo ""
    echo "scrape_configs:"
    echo "  - job_name: \"node_exporter\""
    echo "    static_configs:"
    echo "      - targets: [\"${current_ip}:${current_port}\"]"
    echo "        labels:"
    echo "          instance: \"$(hostname)\""
    echo ""
    echo "Then restart Prometheus:"
    echo "  sudo systemctl restart prometheus"
    echo ""
}

# Function to show Node Exporter status
show_node_exporter_status() {
    echo -e "\e[36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
    echo -e "\e[36m   Node Exporter Status\e[0m"
    echo -e "\e[36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
    echo ""
    
    # Check if installed
    if ! command -v node_exporter &> /dev/null; then
        echo -e "\e[31m✗ Node Exporter not installed\e[0m"
        return 1
    fi
    
    # Version
    echo "Version:"
    node_exporter --version 2>&1 | head -2
    echo ""
    
    # Service status
    echo "Service Status:"
    if systemctl is-active --quiet node_exporter; then
        echo -e "  \e[32m✓ Running\e[0m"
    else
        echo -e "  \e[31m✗ Not running\e[0m"
    fi
    
    if systemctl is-enabled --quiet node_exporter; then
        echo -e "  \e[32m✓ Enabled (auto-start)\e[0m"
    else
        echo -e "  \e[33m⚠ Disabled\e[0m"
    fi
    echo ""
    
    # Configuration
    if [ -f "$NODE_EXPORTER_CONFIG" ]; then
        echo "Configuration:"
        # shellcheck source=/dev/null
        source "$NODE_EXPORTER_CONFIG"
        echo "  Port:            $NODE_EXPORTER_PORT"
        echo "  Client IP:       $CLIENT_IP"
        echo "  Prometheus:      $PROMETHEUS_SERVER"
        echo "  Install Date:    ${INSTALL_DATE:-N/A}"
        echo ""
    fi
    
    # Port check
    local port
    port=$(sudo netstat -tlnp 2>/dev/null | grep node_exporter | awk '{print $4}' | cut -d: -f2)
    if [ -n "$port" ]; then
        echo "Listening on port: $port"
    fi
    
    # Metrics test
    echo ""
    echo "Testing metrics endpoint..."
    if curl -s http://localhost:${NODE_EXPORTER_PORT:-9100}/metrics > /dev/null; then
        echo -e "\e[32m✓ Metrics endpoint responding\e[0m"
        echo ""
        echo "Available metrics count:"
        curl -s http://localhost:${NODE_EXPORTER_PORT:-9100}/metrics | grep -c "^node_"
    else
        echo -e "\e[31m✗ Metrics endpoint not responding\e[0m"
    fi
    
    echo ""
    read -p "Press Enter to continue..."
}

# Function to uninstall Node Exporter
uninstall_node_exporter() {
    echo -e "\e[36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
    echo -e "\e[36m   Uninstall Node Exporter\e[0m"
    echo -e "\e[36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
    echo ""
    
    if ! command -v node_exporter &> /dev/null; then
        echo -e "\e[33m⚠ Node Exporter is not installed\e[0m"
        return 0
    fi
    
    echo -e "\e[31mThis will remove:\e[0m"
    echo "  - Node Exporter binary"
    echo "  - Systemd service"
    echo "  - User and group"
    echo ""
    read -p "Continue with uninstall? (y/n): " confirm
    
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        echo "Uninstall cancelled."
        return 0
    fi
    
    echo ""
    echo "Stopping and disabling service..."
    sudo systemctl stop node_exporter 2>/dev/null || true
    sudo systemctl disable node_exporter 2>/dev/null || true
    
    echo "Removing systemd service..."
    sudo rm -f /etc/systemd/system/node_exporter.service
    sudo systemctl daemon-reload
    
    echo "Removing binary..."
    sudo rm -f /usr/local/bin/node_exporter
    
    echo "Removing user..."
    sudo userdel node_exporter 2>/dev/null || true
    
    echo "Removing configuration..."
    rm -f "$NODE_EXPORTER_CONFIG"
    
    echo ""
    echo -e "\e[32m✓ Node Exporter uninstalled\e[0m"
    echo ""
    echo "Note: Firewall rules were not removed automatically."
    echo "To remove port manually: sudo ufw delete allow 9100/tcp"
    echo ""
}

# Main monitoring menu
monitoring_menu() {
    while true; do
        echo ""
        echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
        echo -e "\e[33m   Monitoring Tools Menu\e[0m"
        echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
        echo "1. Install Node Exporter (for Prometheus)"
        echo "2. Change Prometheus Server IP"
        echo "3. Show Node Exporter Status"
        echo "4. Uninstall Node Exporter"
        echo "0. Back to main menu"
        echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
        read -p "Choose option: " monitoring_choice
        
        case $monitoring_choice in
            1)
                install_node_exporter
                ;;
            2)
                change_prometheus_ip
                ;;
            3)
                show_node_exporter_status
                ;;
            4)
                uninstall_node_exporter
                ;;
            0)
                return 0
                ;;
            *)
                echo -e "\e[31mInvalid option\e[0m"
                ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
    done
}
