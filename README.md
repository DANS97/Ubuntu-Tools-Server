# Ubuntu Tools Server Menu# Ubuntu Tools Server Menu



[![Ubuntu](https://img.shields.io/badge/Ubuntu-22.04%20%7C%2024.04-orange?logo=ubuntu)](https://ubuntu.com)Menu interaktif untuk mengelola server Ubuntu dengan mudah. Dibuat oleh Mahardian Ramadhani.

[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

[![Version](https://img.shields.io/badge/Version-2.1-green.svg)](CHANGELOG.md)## Deskripsi



Automated server management tool untuk Ubuntu dengan support multi-version installation dari repository resmi.Skrip bash ini menyediakan menu interaktif untuk melakukan berbagai tugas konfigurasi dan instalasi pada server Ubuntu 22.04 dan 24.04. Menu menampilkan spesifikasi server dan opsi untuk setting IP, allow port, install berbagai tools seperti SSH, Apache, Nginx, MySQL, PHP, Docker, dll.



## Features## Fitur



**Core Capabilities:**- **Dashboard Sistem**: Menampilkan informasi spesifikasi server (OS, Kernel, Hostname, CPU, RAM, Disk Usage)

- Multi-version support: PHP (7.3-8.4), PostgreSQL (12-17), Node.js (18-23)- **Konfigurasi Jaringan**:

- Official repositories integration  - Set Static IP Address

- Easy version switching  - Allow Port (menggunakan ufw)

- Interactive configuration wizards- **Instalasi Tools**:

- Real-time system dashboard  - SSH Server

  - Apache Web Server

**Available Tools:**  - Nginx Web Server

  - **MySQL Server (Multi-Version + MariaDB)**

| Category | Tools |  - **PostgreSQL Server (Multi-Version 12-17)**

|----------|-------|  - **PHP (Multi-Version 7.3-8.4 + Extensions)**

| Web Servers | Apache, Nginx + config wizard |  - **Docker CE (with management tools)**

| Databases | MySQL/MariaDB, PostgreSQL (12-17) |  - **Node.js (Multi-Version + NVM support)**

| Languages | PHP (7.3-8.4), Python3, Node.js + NVM |  - Python3 dan Pip

| DevOps | Docker + Compose, Git, Composer |  - Git

| Network | Static IP, UFW, SSH, ODBC |  - ODBC SQL Server 17

  - Composer

## Quick Start- **Utilitas**:

  - Change Hostname

```bash  - Show Installed Tools Status

# Clone  - Setup Nginx Configuration

git clone https://github.com/DANS97/Ubuntu-Tools-Server.git

cd Ubuntu-Tools-Server## Prerequisites



# Run- Ubuntu 22.04 atau 24.04

chmod +x setup-permissions.sh- Akses sudo

./setup-permissions.sh- Koneksi internet untuk instalasi paket

./menu.sh

```## 🚀 Quick Start



## Usage Examples```bash

# Clone repository

**LEMP Stack:**git clone https://github.com/DANS97/Ubuntu-Tools-Server.git

```bashcd Ubuntu-Tools-Server

./menu.sh -> 5 (Nginx) -> 6 (MySQL) -> 7 (PHP+extensions) -> 16 (Configure)

```# Set permissions and run

chmod +x setup-permissions.sh && ./setup-permissions.sh

**Multiple PHP Versions:**./menu.sh

```bash```

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
