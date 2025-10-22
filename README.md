# Ubuntu Tools Server Menu# Ubuntu Tools Server Menu# Ubuntu Tools Server Menu



[![Ubuntu](https://img.shields.io/badge/Ubuntu-22.04%20%7C%2024.04-orange?logo=ubuntu)](https://ubuntu.com)

[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

[![Version](https://img.shields.io/badge/Version-2.1-green.svg)](CHANGELOG.md)[![Ubuntu](https://img.shields.io/badge/Ubuntu-22.04%20%7C%2024.04-orange?logo=ubuntu)](https://ubuntu.com)Menu interaktif untuk mengelola server Ubuntu dengan mudah. Dibuat oleh Mahardian Ramadhani.

[![ShellCheck](https://github.com/DANS97/Ubuntu-Tools-Server/actions/workflows/test.yml/badge.svg)](https://github.com/DANS97/Ubuntu-Tools-Server/actions/workflows/test.yml)

[![Compatibility](https://github.com/DANS97/Ubuntu-Tools-Server/actions/workflows/compatibility.yml/badge.svg)](https://github.com/DANS97/Ubuntu-Tools-Server/actions/workflows/compatibility.yml)[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)



Automated server management tool untuk Ubuntu dengan support multi-version installation dari repository resmi.[![Version](https://img.shields.io/badge/Version-2.1-green.svg)](CHANGELOG.md)## Deskripsi



## Features



**Core Capabilities:**Automated server management tool untuk Ubuntu dengan support multi-version installation dari repository resmi.Skrip bash ini menyediakan menu interaktif untuk melakukan berbagai tugas konfigurasi dan instalasi pada server Ubuntu 22.04 dan 24.04. Menu menampilkan spesifikasi server dan opsi untuk setting IP, allow port, install berbagai tools seperti SSH, Apache, Nginx, MySQL, PHP, Docker, dll.

- Multi-version support: PHP (7.3-8.4), PostgreSQL (12-17), Node.js (18-23)

- Official repositories integration

- Easy version switching

- Interactive configuration wizards## Features## Fitur

- Real-time system dashboard

- **CI/CD ready** with GitHub Actions



**Available Tools:****Core Capabilities:**- **Dashboard Sistem**: Menampilkan informasi spesifikasi server (OS, Kernel, Hostname, CPU, RAM, Disk Usage)



| Category | Tools |- Multi-version support: PHP (7.3-8.4), PostgreSQL (12-17), Node.js (18-23)- **Konfigurasi Jaringan**:

|----------|-------|

| Web Servers | Apache, Nginx + config wizard |- Official repositories integration  - Set Static IP Address

| Databases | MySQL/MariaDB, PostgreSQL (12-17) |

| Languages | PHP (7.3-8.4), Python3, Node.js + NVM |- Easy version switching  - Allow Port (menggunakan ufw)

| DevOps | Docker + Compose, Git, Composer |

| Network | Static IP, UFW, SSH, ODBC |- Interactive configuration wizards- **Instalasi Tools**:



## Quick Start- Real-time system dashboard  - SSH Server



```bash  - Apache Web Server

# Clone

git clone https://github.com/DANS97/Ubuntu-Tools-Server.git**Available Tools:**  - Nginx Web Server

cd Ubuntu-Tools-Server

  - **MySQL Server (Multi-Version + MariaDB)**

# Run

chmod +x setup-permissions.sh| Category | Tools |  - **PostgreSQL Server (Multi-Version 12-17)**

./setup-permissions.sh

./menu.sh|----------|-------|  - **PHP (Multi-Version 7.3-8.4 + Extensions)**

```

| Web Servers | Apache, Nginx + config wizard |  - **Docker CE (with management tools)**

## Usage Examples

| Databases | MySQL/MariaDB, PostgreSQL (12-17) |  - **Node.js (Multi-Version + NVM support)**

**LEMP Stack:**

```bash| Languages | PHP (7.3-8.4), Python3, Node.js + NVM |  - Python3 dan Pip

./menu.sh -> 5 (Nginx) -> 6 (MySQL) -> 7 (PHP+extensions) -> 16 (Configure)

```| DevOps | Docker + Compose, Git, Composer |  - Git



**Multiple PHP Versions:**| Network | Static IP, UFW, SSH, ODBC |  - ODBC SQL Server 17

```bash

./menu.sh -> 7 -> 2 (8.1) -> 2 (8.3) -> 8 (switch to 8.3)  - Composer

```

## Quick Start- **Utilitas**:

See [QUICKSTART.md](QUICKSTART.md) for more examples.

  - Change Hostname

## Architecture

```bash  - Show Installed Tools Status

Modular design dengan 14 independent scripts di `scripts/` directory:

- Main orchestrator: `menu.sh` (140 lines)# Clone  - Setup Nginx Configuration

- Modules: network, ssh, apache, nginx, mysql, postgresql, php, docker, nodejs, python, git, odbc, composer, status

git clone https://github.com/DANS97/Ubuntu-Tools-Server.git

## CI/CD Pipeline

cd Ubuntu-Tools-Server## Prerequisites

✅ **Automated Quality Control:**

- ShellCheck validation on every push

- Syntax checking for all bash scripts

- Ubuntu 22.04 & 24.04 compatibility testing# Run- Ubuntu 22.04 atau 24.04

- Weekly scheduled compatibility tests

chmod +x setup-permissions.sh- Akses sudo

✅ **Release Automation:**

- Auto-create GitHub releases from tags./setup-permissions.sh- Koneksi internet untuk instalasi paket

- Generate release archives

- Update version badges automatically./menu.sh



## Documentation```## 🚀 Quick Start



- [QUICKSTART.md](QUICKSTART.md) - Menu reference

- [CHANGELOG.md](CHANGELOG.md) - Version history

- [CONTRIBUTING.md](CONTRIBUTING.md) - Development guide## Usage Examples```bash



## Requirements# Clone repository



- Ubuntu 22.04 or 24.04**LEMP Stack:**git clone https://github.com/DANS97/Ubuntu-Tools-Server.git

- Root or sudo access

- Internet connection```bashcd Ubuntu-Tools-Server



## Contributing./menu.sh -> 5 (Nginx) -> 6 (MySQL) -> 7 (PHP+extensions) -> 16 (Configure)



All pull requests are automatically validated with CI/CD pipeline. Please ensure:```# Set permissions and run

- Scripts pass ShellCheck validation

- Bash syntax is correctchmod +x setup-permissions.sh && ./setup-permissions.sh

- Changes are tested on Ubuntu 22.04 & 24.04

**Multiple PHP Versions:**./menu.sh

## License

```bash```

MIT - Created by Mahardian Ramadhani ([@DANS97](https://github.com/DANS97))

./menu.sh -> 7 -> 2 (8.1) -> 2 (8.3) -> 8 (switch to 8.3)

```## 📖 Usage Examples



See [QUICKSTART.md](QUICKSTART.md) for more examples.### LEMP Stack with Version Control

```bash

## Architecture./menu.sh

→ 5 (Nginx) → 6 (MySQL, choose version) → 7 (PHP, choose version + extensions)

Modular design dengan 14 independent scripts di `scripts/` directory:→ 16 (Configure Nginx) → 17 (Composer)

- Main orchestrator: `menu.sh` (140 lines)```

- Modules: network, ssh, apache, nginx, mysql, postgresql, php, docker, nodejs, python, git, odbc, composer, status

### Install Multiple PHP Versions

## Documentation```bash

./menu.sh → 7 → 2 (Custom) → 8.1 → y

- [QUICKSTART.md](QUICKSTART.md) - Menu reference./menu.sh → 7 → 2 (Custom) → 8.3 → y

- [CHANGELOG.md](CHANGELOG.md) - Version history./menu.sh → 7 → 8 (Switch to 8.3 as default)

- [CONTRIBUTING.md](CONTRIBUTING.md) - Development guide```



## Requirements### PostgreSQL Development

```bash

- Ubuntu 22.04 or 24.04./menu.sh → 14 → 5 (PostgreSQL 16) → y (extensions) → y (configure)

- Root or sudo access```

- Internet connection

See [QUICKSTART.md](QUICKSTART.md) for more examples.

## License

## Troubleshooting

MIT - Created by Mahardian Ramadhani ([@DANS97](https://github.com/DANS97))

- Jika instalasi gagal, periksa log error dan pastikan repository tersedia.
- Untuk PHP versi lama, PPA ondrej/php ditambahkan otomatis.
- Jika interface tidak muncul, pastikan interface benar (gunakan `ip link show`).

## Kontribusi

Silakan buat issue atau pull request untuk improvement.

## Lisensi

Dibuat oleh Mahardian Ramadhani. Gunakan dengan bijak.

## Versi

- v1.0: Menu dasar dengan instalasi tools
- v1.1: Tambah dashboard sistem, PHP versi, ODBC
- v1.2: Tambah fitur Show Installed Tools Status, Setup Nginx Configuration, Composer, dan Setup Project Folder for Nginx
- v2.0: **Modular architecture** - Memecah fungsi instalasi ke file-file terpisah untuk maintenance yang lebih mudah
- v2.1: **Overpowered version selection** - PHP (7.3-8.4), PostgreSQL (12-17), MySQL/MariaDB, Node.js (multi-version + NVM), Docker management
