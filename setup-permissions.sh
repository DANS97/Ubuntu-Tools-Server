#!/bin/bash

# Make all scripts executable

echo "Setting execute permissions for all scripts..."

# Main script
chmod +x menu.sh

# All module scripts
chmod +x scripts/*.sh

echo "Done! All scripts are now executable."
echo ""
echo "You can now run the menu with:"
echo "./menu.sh"
