#!/bin/bash

# Composer installation

install_composer() {
    echo "Installing Composer..."
    # Check if PHP is installed
    if ! command -v php &> /dev/null; then
        echo "PHP not found. Installing PHP Latest first..."
        source "$(dirname "$0")/scripts/php.sh"
        install_php
    fi

    # Download and install Composer
    curl -sS https://getcomposer.org/installer | php
    sudo mv composer.phar /usr/local/bin/composer
    sudo chmod +x /usr/local/bin/composer
    echo "Composer installed globally. Version: $(composer --version)"
}
