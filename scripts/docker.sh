#!/bin/bash

# Docker installation with version options

# Function to show Docker versions
get_docker_versions() {
    echo -e "\e[33m======================================\e[0m"
    echo -e "\e[33m      Docker Installation Options\e[0m"
    echo -e "\e[33m======================================\e[0m"
    echo -e "\e[32mDocker CE (Community Edition):\e[0m"
    echo "  • Latest stable version"
    echo "  • Updated regularly"
    echo "  • Free and open source"
    echo ""
    echo -e "\e[36mDocker Compose:\e[0m"
    echo "  • Multi-container orchestration"
    echo "  • Version 2.x (latest)"
    echo ""
    echo -e "\e[35mAdditional Tools:\e[0m"
    echo "  • Docker Buildx (advanced builds)"
    echo "  • Docker Scan (security scanning)"
    echo "  • ctop (container monitoring)"
    echo -e "\e[33m======================================\e[0m"
}

# Function to install Docker
install_docker_full() {
    echo -e "\e[36mInstalling Docker CE...\e[0m"
    
    # Remove old versions
    echo "Removing old Docker versions if present..."
    sudo apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null
    
    # Install dependencies
    sudo apt update
    sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release
    
    # Add Docker GPG key
    echo "Adding Docker GPG key..."
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    
    # Add Docker repository
    echo "Adding Docker repository..."
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Update package index
    sudo apt update
    
    # Install Docker Engine
    echo "Installing Docker Engine, containerd, and Docker Compose..."
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # Start and enable Docker
    sudo systemctl enable docker
    sudo systemctl start docker
    
    # Verify installation
    if command -v docker &> /dev/null; then
        echo -e "\e[32m✓ Docker installed successfully!\e[0m"
        docker --version
        docker compose version
        
        # Add current user to docker group
        echo ""
        read -p "Add current user ($USER) to docker group? (y/n): " add_user
        if [[ $add_user =~ ^[Yy]$ ]]; then
            sudo usermod -aG docker $USER
            echo -e "\e[32m✓ User added to docker group.\e[0m"
            echo -e "\e[33m⚠ Log out and back in for changes to take effect.\e[0m"
        fi
        
        # Install additional tools
        echo ""
        read -p "Install ctop (container monitoring tool)? (y/n): " install_ctop
        if [[ $install_ctop =~ ^[Yy]$ ]]; then
            echo "Installing ctop..."
            sudo wget https://github.com/bcicen/ctop/releases/download/v0.7.7/ctop-0.7.7-linux-amd64 -O /usr/local/bin/ctop
            sudo chmod +x /usr/local/bin/ctop
            echo -e "\e[32m✓ ctop installed. Run 'ctop' to monitor containers.\e[0m"
        fi
        
        # Install lazydocker
        echo ""
        read -p "Install lazydocker (TUI for Docker)? (y/n): " install_lazy
        if [[ $install_lazy =~ ^[Yy]$ ]]; then
            echo "Installing lazydocker..."
            curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash
            echo -e "\e[32m✓ lazydocker installed. Run 'lazydocker' to use.\e[0m"
        fi
        
        # Test Docker
        echo ""
        read -p "Test Docker with hello-world container? (y/n): " test_docker
        if [[ $test_docker =~ ^[Yy]$ ]]; then
            echo "Running Docker hello-world..."
            sudo docker run hello-world
        fi
        
    else
        echo -e "\e[31m✗ Docker installation failed.\e[0m"
        return 1
    fi
}

# Function to manage Docker
manage_docker() {
    while true; do
        echo ""
        echo -e "\e[33m======================================\e[0m"
        echo -e "\e[33m       Docker Management Menu\e[0m"
        echo -e "\e[33m======================================\e[0m"
        echo "1. Show Docker status"
        echo "2. List running containers"
        echo "3. List all containers"
        echo "4. List Docker images"
        echo "5. Docker system info"
        echo "6. Clean up Docker (remove unused data)"
        echo "7. Start Docker service"
        echo "8. Stop Docker service"
        echo "9. Restart Docker service"
        echo "0. Back"
        echo -e "\e[33m======================================\e[0m"
        read -p "Choose an option: " manage_choice

        case $manage_choice in
            1)
                systemctl status docker --no-pager
                ;;
            2)
                docker ps
                ;;
            3)
                docker ps -a
                ;;
            4)
                docker images
                ;;
            5)
                docker info
                ;;
            6)
                echo "Docker cleanup options:"
                echo "1. Remove stopped containers"
                echo "2. Remove unused images"
                echo "3. Remove unused volumes"
                echo "4. Remove everything unused (prune all)"
                read -p "Choose cleanup option: " cleanup_choice
                case $cleanup_choice in
                    1) docker container prune -f ;;
                    2) docker image prune -a -f ;;
                    3) docker volume prune -f ;;
                    4) docker system prune -a --volumes -f ;;
                esac
                ;;
            7)
                sudo systemctl start docker
                echo "Docker service started"
                ;;
            8)
                sudo systemctl stop docker
                echo "Docker service stopped"
                ;;
            9)
                sudo systemctl restart docker
                echo "Docker service restarted"
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

# Main Docker installation function
install_docker() {
    while true; do
        echo ""
        echo -e "\e[33m======================================\e[0m"
        echo -e "\e[33m       Docker Installation Menu\e[0m"
        echo -e "\e[33m======================================\e[0m"
        echo "1. Show Docker installation info"
        echo "2. Install Docker CE (Full installation)"
        echo "3. Manage Docker (if already installed)"
        echo "4. Uninstall Docker"
        echo "0. Back to main menu"
        echo -e "\e[33m======================================\e[0m"
        read -p "Choose an option: " docker_choice

        case $docker_choice in
            1)
                get_docker_versions
                ;;
            2)
                install_docker_full
                ;;
            3)
                if command -v docker &> /dev/null; then
                    manage_docker
                else
                    echo -e "\e[31mDocker is not installed.\e[0m"
                fi
                ;;
            4)
                read -p "Are you sure you want to uninstall Docker? (y/n): " confirm
                if [[ $confirm =~ ^[Yy]$ ]]; then
                    echo "Uninstalling Docker..."
                    sudo apt remove -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
                    sudo apt autoremove -y
                    echo -e "\e[32m✓ Docker uninstalled.\e[0m"
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
