#!/bin/bash

# Python3 and Pip installation

install_python() {
    echo "Installing Python3 and Pip..."
    sudo apt update
    sudo apt install -y python3 python3-pip
    echo "Python3 and Pip installed."
}
