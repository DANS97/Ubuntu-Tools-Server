#!/bin/bash

# SSH Server installation

install_ssh_server() {
    echo "Installing SSH Server..."
    sudo apt update
    sudo apt install -y openssh-server
    sudo systemctl enable ssh
    sudo systemctl start ssh
    echo -e "\e[32mSSH Server installed and started.\e[0m"
    echo -e "\e[33mDefault SSH port is 22. Make sure to allow it in firewall if needed.\e[0m"
}
