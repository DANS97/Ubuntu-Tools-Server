#!/bin/bash

# Git installation

install_git() {
    echo "Installing Git..."
    sudo apt update
    sudo apt install -y git
    echo "Git installed."
}
