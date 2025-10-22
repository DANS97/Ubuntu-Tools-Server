#!/bin/bash

# Apache Web Server installation

install_apache() {
    echo "Installing Apache Web Server..."
    sudo apt update
    sudo apt install -y apache2
    sudo systemctl enable apache2
    sudo systemctl start apache2
    echo "Apache installed and started. Default port 80."
}
