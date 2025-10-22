#!/bin/bash

# ODBC SQL Server 17 installation

install_odbc_sqlserver() {
    echo "Installing ODBC Driver for SQL Server 17..."
    sudo apt update
    sudo apt install -y curl apt-transport-https
    curl https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://packages.microsoft.com/ubuntu/$(lsb_release -rs)/prod $(lsb_release -cs) main"
    sudo apt update
    sudo apt install -y msodbcsql17
    echo "ODBC SQL Server 17 installed."
}
