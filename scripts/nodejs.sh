#!/bin/bash

# Node.js installation with version selection from official repository

# Function to get available Node.js versions
get_nodejs_versions() {
    echo -e "\e[36mAvailable Node.js versions from official repository:\e[0m"
    echo ""
    echo -e "\e[33m======================================\e[0m"
    echo -e "\e[33m    Node.js Version Categories\e[0m"
    echo -e "\e[33m======================================\e[0m"
    echo -e "\e[32mLTS (Long Term Support) - Recommended for production\e[0m"
    echo "  • Node.js 18.x (LTS) - Active LTS until April 2025"
    echo "  • Node.js 20.x (LTS) - Active LTS until April 2026"
    echo "  • Node.js 22.x (LTS) - Active LTS"
    echo ""
    echo -e "\e[36mCurrent (Latest features) - For development\e[0m"
    echo "  • Node.js 21.x (Current)"
    echo "  • Node.js 23.x (Current)"
    echo ""
    echo -e "\e[33mLegacy (Older versions)\e[0m"
    echo "  • Node.js 16.x (Maintenance)"
    echo -e "\e[33m======================================\e[0m"
}

# Function to install Node.js with specific version
install_nodejs_version() {
    local node_version=$1
    
    echo -e "\e[36mInstalling Node.js ${node_version}.x...\e[0m"
    
    # Remove existing Node.js if present
    if command -v node &> /dev/null; then
        echo -e "\e[33mExisting Node.js found. Removing...\e[0m"
        sudo apt remove -y nodejs
        sudo apt autoremove -y
    fi
    
    # Setup NodeSource repository
    echo "Setting up NodeSource repository for Node.js ${node_version}.x..."
    curl -fsSL https://deb.nodesource.com/setup_${node_version}.x | sudo -E bash -
    
    # Install Node.js and npm
    sudo apt install -y nodejs
    
    # Verify installation
    if command -v node &> /dev/null; then
        echo -e "\e[32m✓ Node.js installed successfully!\e[0m"
        echo "  Node.js: $(node -v)"
        echo "  npm: $(npm -v)"
        
        # Ask to install build tools
        echo ""
        read -p "Install build tools for native modules? (y/n): " install_build
        if [[ $install_build =~ ^[Yy]$ ]]; then
            sudo apt install -y build-essential
            echo -e "\e[32m✓ Build tools installed.\e[0m"
        fi
        
        # Ask to install yarn
        echo ""
        read -p "Install Yarn package manager? (y/n): " install_yarn
        if [[ $install_yarn =~ ^[Yy]$ ]]; then
            sudo npm install -g yarn
            echo -e "\e[32m✓ Yarn installed: $(yarn -v)\e[0m"
        fi
        
        # Ask to install pnpm
        echo ""
        read -p "Install pnpm package manager? (y/n): " install_pnpm
        if [[ $install_pnpm =~ ^[Yy]$ ]]; then
            sudo npm install -g pnpm
            echo -e "\e[32m✓ pnpm installed: $(pnpm -v)\e[0m"
        fi
        
    else
        echo -e "\e[31m✗ Installation failed.\e[0m"
        return 1
    fi
}

# Function to install NVM (Node Version Manager)
install_nvm() {
    echo -e "\e[36mInstalling NVM (Node Version Manager)...\e[0m"
    
    # Download and install NVM
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    
    # Load NVM
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    if command -v nvm &> /dev/null; then
        echo -e "\e[32m✓ NVM installed successfully!\e[0m"
        echo ""
        echo -e "\e[33mNVM Usage:\e[0m"
        echo "  nvm install node          # Install latest version"
        echo "  nvm install 20            # Install Node.js 20"
        echo "  nvm install --lts         # Install latest LTS"
        echo "  nvm use 20                # Switch to Node.js 20"
        echo "  nvm list                  # List installed versions"
        echo ""
        echo -e "\e[33mReload your shell or run:\e[0m"
        echo "  source ~/.bashrc          # or ~/.zshrc"
    else
        echo -e "\e[31m✗ NVM installation failed.\e[0m"
        return 1
    fi
}

# Main Node.js installation function
install_nodejs() {
    while true; do
        echo ""
        echo -e "\e[33m======================================\e[0m"
        echo -e "\e[33m    Node.js Installation Menu\e[0m"
        echo -e "\e[33m======================================\e[0m"
        echo "1. Show available Node.js versions"
        echo "2. Install Node.js (choose version manually)"
        echo "3. Install Node.js 18.x (LTS)"
        echo "4. Install Node.js 20.x (LTS - Recommended)"
        echo "5. Install Node.js 22.x (Latest LTS)"
        echo "6. Install Node.js 23.x (Current/Latest)"
        echo "7. Install NVM (Node Version Manager)"
        echo "8. Show current Node.js version"
        echo "0. Back to main menu"
        echo -e "\e[33m======================================\e[0m"
        read -p "Choose an option: " node_choice

        case $node_choice in
            1)
                get_nodejs_versions
                ;;
            2)
                echo ""
                read -p "Enter Node.js major version to install (e.g., 20, 18): " custom_version
                if [[ $custom_version =~ ^[0-9]+$ ]]; then
                    install_nodejs_version $custom_version
                else
                    echo -e "\e[31mInvalid version format. Use format: 20 or 18\e[0m"
                fi
                ;;
            3)
                install_nodejs_version "18"
                ;;
            4)
                install_nodejs_version "20"
                ;;
            5)
                install_nodejs_version "22"
                ;;
            6)
                install_nodejs_version "23"
                ;;
            7)
                install_nvm
                ;;
            8)
                if command -v node &> /dev/null; then
                    echo -e "\e[32m✓ Node.js is installed:\e[0m"
                    echo "  Node.js: $(node -v)"
                    echo "  npm: $(npm -v)"
                    
                    if command -v yarn &> /dev/null; then
                        echo "  Yarn: $(yarn -v)"
                    fi
                    
                    if command -v pnpm &> /dev/null; then
                        echo "  pnpm: $(pnpm -v)"
                    fi
                    
                    if command -v nvm &> /dev/null; then
                        echo ""
                        echo -e "\e[36mNVM versions:\e[0m"
                        nvm list
                    fi
                else
                    echo -e "\e[31m✗ Node.js is not installed.\e[0m"
                fi
                ;;
            0)
                return
                ;;
            *)
                echo -e "\e[31mInvalid option.\e[0m"
                ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
    done
}
