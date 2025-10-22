# Quick Start Guide - Ubuntu Tools Server Menu v2.1

## 🚀 Quick Installation

```bash
# Clone repository
git clone https://github.com/DANS97/Ubuntu-Tools-Server.git
cd Ubuntu-Tools-Server

# Set permissions
chmod +x setup-permissions.sh
./setup-permissions.sh

# Run menu
./menu.sh
```

## 📋 Menu Quick Reference

| No | Menu Item | Script Module | Description |
|----|-----------|---------------|-------------|
| 1 | Set Static IP Address | `scripts/network.sh` | Configure static IP dengan netplan |
| 2 | Allow Port | `scripts/network.sh` | Buka port di UFW firewall |
| 3 | Install SSH Server | `scripts/ssh.sh` | Install OpenSSH server |
| 4 | Install Apache | `scripts/apache.sh` | Install Apache2 web server |
| 5 | Install Nginx | `scripts/nginx.sh` | Install Nginx web server |
| 6 | Install MySQL | `scripts/mysql.sh` | Install MySQL/MariaDB (multi-version) |
| 7 | Install PHP | `scripts/php.sh` | Install PHP 7.3-8.4 (multi-version) |
| 8 | Install Docker | `scripts/docker.sh` | Install Docker CE + management |
| 9 | Install Node.js | `scripts/nodejs.sh` | Install Node.js (multi-version + NVM) |
| 10 | Install Python3 & Pip | `scripts/python.sh` | Install Python3 dan pip |
| 11 | Install Git | `scripts/git.sh` | Install Git |
| 12 | Change Hostname | `scripts/network.sh` | Ganti hostname system |
| 13 | Install ODBC SQL Server 17 | `scripts/odbc.sh` | Install Microsoft ODBC Driver |
| 14 | Install PostgreSQL | `scripts/postgresql.sh` | Install PostgreSQL 12-17 (multi-version) |
| 15 | Show Installed Tools Status | `scripts/status.sh` | Tampilkan status semua tools |
| 16 | Setup Nginx Configuration | `scripts/nginx.sh` | Setup Nginx site config |
| 17 | Install Composer | `scripts/composer.sh` | Install Composer globally |
| 18 | Setup Project Folder | `scripts/nginx.sh` | Setup Nginx untuk project folder |
| 19 | Install Python3 & Pip | `scripts/python.sh` | Install Python3 dan pip |

## 🔧 Direct Script Usage

Jika Anda ingin menggunakan fungsi secara langsung di script lain:

```bash
#!/bin/bash

# Source modul yang diperlukan
source "/path/to/Ubuntu-Tools-Server/scripts/nginx.sh"
source "/path/to/Ubuntu-Tools-Server/scripts/php.sh"

# Panggil fungsi
install_nginx
install_php
setup_nginx_config
```

## 🧪 Testing

```bash
# Test syntax semua script
./test.sh

# Test individual module
bash -n scripts/nginx.sh
```

## 📝 Adding New Feature

1. **Create new script**: `scripts/newfeature.sh`
2. **Add source**: Edit `menu.sh`, add `source "$SCRIPT_DIR/scripts/newfeature.sh"`
3. **Add menu item**: Edit `display_menu()` function
4. **Add case**: Add case in main loop
5. **Test**: Run `./test.sh`

Detail lengkap: Lihat `CONTRIBUTING.md`

## 🐛 Troubleshooting

### Permission Denied
```bash
chmod +x menu.sh
chmod +x scripts/*.sh
```

### Module Not Found
```bash
# Pastikan Anda di root directory project
cd /path/to/Ubuntu-Tools-Server
./menu.sh
```

### Syntax Error
```bash
# Check syntax
bash -n menu.sh
./test.sh
```

## 📦 Project Structure

```
Ubuntu-Tools-Server/
├── menu.sh                    # Main script (140 lines)
├── setup-permissions.sh       # Permission setter
├── test.sh                   # Testing script
├── README.md                 # Full documentation
├── CONTRIBUTING.md           # Developer guide
├── CHANGELOG.md             # Version history
├── QUICKSTART.md           # This file
└── scripts/                # Modular scripts (13 files)
```

## 💡 Common Use Cases

### Setup LEMP Stack with Version Control
```
Menu 5 (Nginx) → Menu 6 (MySQL, choose version) → 
Menu 7 (PHP, choose version) → Menu 16 (Configure Nginx)
```

### Setup Laravel Development Environment
```
Menu 5 (Nginx) → Menu 6 (MySQL 8.0) → Menu 7 (PHP 8.3) → 
Menu 17 (Composer) → Menu 18 (Project Setup)
```

### Setup PostgreSQL Development
```
Menu 14 (PostgreSQL, choose version 16) → 
Configure database and users → Setup remote access
```

### Setup Node.js with Multiple Versions
```
Menu 9 (Node.js) → Option 7 (Install NVM) →
Use NVM to manage multiple Node.js versions
```

### Setup Full Stack Development
```
Menu 5 (Nginx) → Menu 6 (MySQL) → Menu 14 (PostgreSQL) →
Menu 7 (PHP 8.3) → Menu 9 (Node.js 20) → Menu 8 (Docker) →
Menu 11 (Git) → Menu 17 (Composer)
```

## 📞 Support

- **Documentation**: `README.md`
- **Contributing**: `CONTRIBUTING.md`
- **Changelog**: `CHANGELOG.md`
- **Issues**: [GitHub Issues](https://github.com/DANS97/Ubuntu-Tools-Server/issues)

## ⚡ Key Features

✅ **Modular Architecture** - Mudah di-maintain  
✅ **14 Installation Modules** - Terpisah per tools  
✅ **Multi-Version Support** - PHP, PostgreSQL, MySQL, Node.js  
✅ **Official Repositories** - Langsung dari source resmi  
✅ **Interactive Menus** - Sub-menu untuk setiap tool  
✅ **Version Selection** - Pilih versi spesifik yang dibutuhkan  
✅ **Configuration Wizards** - Setup interaktif  
✅ **System Info Dashboard** - Real-time monitoring  
✅ **Color-coded Output** - Easy to read  
✅ **Ubuntu 22.04 & 24.04** - Fully compatible  

---

**Created by**: Mahardian Ramadhani | **Version**: 2.1 | **License**: MIT
