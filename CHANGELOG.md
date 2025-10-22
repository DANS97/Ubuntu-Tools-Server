# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.1.0] - 2025-10-22

### Added
- **CI/CD Pipeline with GitHub Actions**
  - ShellCheck validation on every push
  - Bash syntax checking for all scripts
  - Ubuntu 22.04 & 24.04 compatibility testing
  - Weekly scheduled compatibility tests
  - Automated release creation from tags
  - Auto-update version badges
- **PostgreSQL support** (versions 12-17) with official repository integration
- **PHP multi-version installer** - Install any version from 7.3 to 8.4
- **Node.js multi-version support** - Versions 18, 20, 22, 23 + NVM integration
- **MySQL/MariaDB alternatives** with configuration wizards
- **Docker management menu** with ctop and lazydocker tools
- Interactive configuration wizards for databases
- Version switching capabilities for PHP and PostgreSQL
- Extension selection during PHP installation (15+ extensions)
- Remote access setup for MySQL and PostgreSQL
- NVM (Node Version Manager) installation option
- `.gitignore` file for development tools
- `LICENSE` file (MIT License)

### Changed
- `scripts/php.sh` - Complete rewrite with interactive sub-menu (9 options)
- `scripts/mysql.sh` - Enhanced with MariaDB support and config wizard (7 options)
- `scripts/nodejs.sh` - Added multi-version and NVM support (8 options)
- `scripts/docker.sh` - Added management sub-menu and additional tools
- `scripts/status.sh` - Updated to check PostgreSQL, MariaDB, multiple PHP versions
- `menu.sh` - Added PostgreSQL menu item (#14), renumbered to 0-19

### Enhanced
- All database installations now include interactive setup wizards
- PHP installations prompt for extension selection
- Docker includes container management utilities
- Improved version detection and listing from repositories

## [2.0.0] - 2025-10-22

### Added
- Modular architecture with separate script files
- `scripts/` directory with 13 installation modules
- `setup-permissions.sh` for automatic permission setup
- `test.sh` for syntax validation of all scripts
- `CONTRIBUTING.md` with developer guidelines
- `QUICKSTART.md` for quick reference

### Changed
- Split monolithic `menu.sh` into modular components
- Reduced main `menu.sh` from ~580 lines to ~140 lines
- Each tool now has dedicated script file

### Removed
- Menu option #14 "Install Nginx + ODBC SQL Server 17" (install separately instead)

## [1.2.0] - 2025-10

### Added
- Show Installed Tools Status feature (menu #15)
- Setup Nginx Configuration wizard (menu #16)
- Composer installation (menu #17)
- Setup Project Folder for Nginx (menu #18)

## [1.1.0] - 2025-09

### Added
- System information dashboard
- Multiple PHP version options (7.3, 8.3, 8.4, Latest)
- ODBC SQL Server 17 installation
- Nginx + ODBC modular installation

## [1.0.0] - 2025-08

### Added
- Initial release
- Basic menu structure
- Essential tool installations (SSH, Apache, Nginx, MySQL, PHP, Docker, Node.js, Git)
- Network configuration (Static IP, Firewall)

---

## Upgrade Guide

### From v2.0 to v2.1
No breaking changes. All existing functionality preserved.

**New features available:**
- Run `./menu.sh → 7` for PHP multi-version
- Run `./menu.sh → 14` for PostgreSQL
- Run `./menu.sh → 9 → 7` for NVM installation

### From v1.x to v2.0
**Breaking:** Menu #14 removed (Nginx+ODBC). Install separately via menu #5 and #13.

**Migration steps:**
1. Pull latest changes: `git pull origin main`
2. Set permissions: `./setup-permissions.sh`
3. Test: `./test.sh`

---

[2.1.0]: https://github.com/DANS97/Ubuntu-Tools-Server/compare/v2.0.0...v2.1.0
[2.0.0]: https://github.com/DANS97/Ubuntu-Tools-Server/compare/v1.2.0...v2.0.0
[1.2.0]: https://github.com/DANS97/Ubuntu-Tools-Server/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/DANS97/Ubuntu-Tools-Server/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/DANS97/Ubuntu-Tools-Server/releases/tag/v1.0.0

### 🎯 Major Enhancements

**Multi-Version Support from Official Repositories:**

1. **PHP (scripts/php.sh)** - Complete overhaul
   - ✅ List all available PHP versions from Ondrej PPA
   - ✅ Install any PHP version (7.0 - 8.4)
   - ✅ Choose specific extensions per installation
   - ✅ Switch default PHP version easily
   - ✅ Support multiple PHP versions simultaneously
   - ✅ Automatic PHP-FPM configuration

2. **PostgreSQL (scripts/postgresql.sh)** - NEW!
   - ✅ PostgreSQL 12, 13, 14 (LTS), 15, 16, 17
   - ✅ Fetch versions from official PostgreSQL repository
   - ✅ Install PostGIS and common extensions
   - ✅ Interactive configuration (users, databases, remote access)
   - ✅ Switch between multiple PostgreSQL versions
   - ✅ Complete database setup wizard

3. **MySQL/MariaDB (scripts/mysql.sh)** - Enhanced
   - ✅ MySQL 8.0 (Ubuntu default or Official repo)
   - ✅ MariaDB as alternative option
   - ✅ Interactive configuration wizard
   - ✅ Remote access setup
   - ✅ Quick database and user creation
   - ✅ Direct MySQL shell access from menu

4. **Node.js (scripts/nodejs.sh)** - Enhanced
   - ✅ Node.js 18.x, 20.x (LTS), 22.x, 23.x
   - ✅ Install specific versions from NodeSource
   - ✅ NVM (Node Version Manager) support
   - ✅ Optional Yarn and pnpm installation
   - ✅ Build tools for native modules
   - ✅ Display all installed Node.js versions

5. **Docker (scripts/docker.sh)** - Enhanced
   - ✅ Docker CE with latest stable version
   - ✅ Docker Compose plugin included
   - ✅ Docker management menu
   - ✅ Container monitoring tools (ctop, lazydocker)
   - ✅ System cleanup utilities
   - ✅ User group management

### 📋 New Menu Structure

```
1-3:   Network & Basic Services
4-6:   Web Servers & Databases
7-9:   Programming Languages (PHP, Docker, Node.js)
10-13: Utilities & Tools
14:    PostgreSQL (NEW!)
15-19: Configuration & Status
```

### ✨ Key Features

**Interactive Installation:**
- Sub-menus for each major tool
- Version selection from official repos
- Extension/plugin selection during install
- Configuration wizards
- Real-time version listing

**Flexibility:**
- Install multiple versions side-by-side
- Easy version switching
- Choose what extensions to install
- Configure immediately or later

**Developer-Friendly:**
- NVM support for Node.js
- Multiple PHP versions for different projects
- PostgreSQL alongside MySQL
- Docker management tools
- Comprehensive status checking

### 📝 Updated Files

**Modified:**
- `scripts/php.sh` - Complete rewrite with multi-version support
- `scripts/mysql.sh` - Enhanced with MariaDB and configuration wizard
- `scripts/nodejs.sh` - Added NVM and multi-version support
- `scripts/docker.sh` - Added management menu and tools
- `scripts/status.sh` - Updated to check all new versions
- `menu.sh` - Added PostgreSQL menu option (#14)

**New:**
- `scripts/postgresql.sh` - Full PostgreSQL management

### 🔧 Technical Improvements

1. **Repository Management:**
   - Automatic PPA/repository addition
   - Version fetching from official sources
   - Smart repository detection

2. **User Experience:**
   - Color-coded output
   - Progress indicators
   - Confirmation prompts
   - Error handling

3. **Configuration:**
   - Interactive wizards
   - Secure password handling
   - Remote access setup
   - Service management

## v2.0 (October 2025) - Modular Architecture

### 🎯 Arsitektur Modular Baru

Proyek telah dipecah menjadi struktur modular untuk meningkatkan:
- **Maintainability**: Setiap modul dapat diedit secara independen
- **Scalability**: Mudah menambahkan fitur baru tanpa mengubah banyak kode
- **Readability**: Kode lebih terorganisir dan mudah dipahami
- **Reusability**: Fungsi dapat digunakan kembali di script lain

### 📁 Struktur File Baru

```
Ubuntu-Tools-Server/
├── menu.sh                     # Script utama (hanya menu & loader)
├── README.md                   # Dokumentasi utama
├── CONTRIBUTING.md             # Panduan kontribusi
├── CHANGELOG.md               # File ini
├── setup-permissions.sh        # Script untuk set permission
├── test.sh                    # Script testing
└── scripts/                   # Folder modul instalasi
    ├── network.sh             # Konfigurasi jaringan
    ├── ssh.sh                 # SSH server
    ├── apache.sh              # Apache web server
    ├── nginx.sh               # Nginx + konfigurasi
    ├── mysql.sh               # MySQL server
    ├── php.sh                 # PHP (multi-version)
    ├── docker.sh              # Docker
    ├── nodejs.sh              # Node.js
    ├── python.sh              # Python3 & Pip
    ├── git.sh                 # Git
    ├── odbc.sh                # ODBC SQL Server 17
    ├── composer.sh            # Composer
    └── status.sh              # System status checker
```

### 🔧 Perubahan Teknis

#### menu.sh
- Dikurangi dari ~580 baris menjadi ~140 baris
- Hanya berisi:
  - Script loader (`source`)
  - Fungsi display menu
  - Fungsi system info
  - Main loop
- Semua fungsi instalasi dipindahkan ke modul terpisah

#### Modul Scripts (scripts/*.sh)
- Setiap file berisi fungsi spesifik untuk satu tool/kategori
- Dapat di-maintain secara independen
- Mudah di-test secara individual
- Dapat di-reuse di script lain jika diperlukan

### ✨ Fitur Baru

1. **setup-permissions.sh**: Script otomatis untuk set executable permission pada semua file
2. **test.sh**: Script untuk testing syntax semua modul
3. **CONTRIBUTING.md**: Panduan lengkap untuk menambahkan fitur baru

### 🗑️ Perubahan Menu

- **Dihapus**: Menu #14 "Install Nginx + ODBC SQL Server 17 (modular)"
  - Masih bisa install keduanya secara terpisah (Menu #5 dan #13)
  - Nginx (Menu #5) masih menawarkan opsi install ODBC

### 📝 Dokumentasi

- README.md diupdate dengan:
  - Struktur proyek yang baru
  - Instruksi instalasi yang lebih jelas
  - Penjelasan arsitektur modular
- Ditambahkan CONTRIBUTING.md dengan panduan:
  - Cara menambahkan fungsi baru
  - Best practices
  - Testing guidelines
  - Commit message format

## Cara Upgrade

Jika Anda sudah menggunakan versi lama:

1. **Backup script lama** (opsional):
   ```bash
   cp menu.sh menu.sh.backup
   ```

2. **Pull perubahan terbaru**:
   ```bash
   git pull origin main
   ```

3. **Set permission**:
   ```bash
   chmod +x setup-permissions.sh
   ./setup-permissions.sh
   ```

4. **Test script**:
   ```bash
   chmod +x test.sh
   ./test.sh
   ```

5. **Jalankan menu**:
   ```bash
   ./menu.sh
   ```

## Compatibility

- ✅ Ubuntu 22.04 LTS
- ✅ Ubuntu 24.04 LTS
- ✅ Backward compatible dengan fungsi yang sama
- ✅ Menu tetap sama (kecuali menu #14 yang dihapus)

## Migration Notes

### Untuk Developer

Jika Anda telah memodifikasi `menu.sh` sebelumnya:

1. Identifikasi fungsi custom Anda
2. Buat file baru di `scripts/` (misal: `scripts/custom.sh`)
3. Pindahkan fungsi Anda ke file tersebut
4. Tambahkan `source "$SCRIPT_DIR/scripts/custom.sh"` di `menu.sh`
5. Tambahkan menu item dan case handler

### Untuk User

Tidak ada perubahan cara penggunaan. Semua menu dan fungsi tetap bekerja sama.

## Breaking Changes

⚠️ **Menu #14 dihapus**
- Sebelumnya: "Install Nginx + ODBC SQL Server 17"
- Sekarang: Install secara terpisah melalui menu #5 (Nginx) dan #13 (ODBC)

## Future Plans

- [ ] Tambah unit tests untuk setiap modul
- [ ] Tambah logging system
- [ ] Tambah rollback feature untuk instalasi yang gagal
- [ ] Support untuk distro Linux lain (Debian, CentOS)
- [ ] Web UI dashboard (opsional)

## Credits

**Created by**: Mahardian Ramadhani  
**Version**: 2.0  
**Date**: October 2025  
**License**: MIT (tentative)

## Support

Jika ada masalah atau pertanyaan:
1. Buka issue di GitHub
2. Sertakan output dari `./test.sh`
3. Sertakan versi Ubuntu Anda (`lsb_release -a`)

---

**Terima kasih telah menggunakan Ubuntu Tools Server Menu!** 🚀
