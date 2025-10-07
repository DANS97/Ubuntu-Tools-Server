# Ubuntu Tools Server Menu

Menu interaktif untuk mengelola server Ubuntu dengan mudah. Dibuat oleh Mahardian Ramadhani.

## Deskripsi

Skrip bash ini menyediakan menu interaktif untuk melakukan berbagai tugas konfigurasi dan instalasi pada server Ubuntu 22.04 dan 24.04. Menu menampilkan spesifikasi server dan opsi untuk setting IP, allow port, install berbagai tools seperti SSH, Apache, Nginx, MySQL, PHP, Docker, dll.

## Fitur

- **Dashboard Sistem**: Menampilkan informasi spesifikasi server (OS, Kernel, Hostname, CPU, RAM, Disk Usage)
- **Konfigurasi Jaringan**:
  - Set Static IP Address
  - Allow Port (menggunakan ufw)
- **Instalasi Tools**:
  - SSH Server
  - Apache Web Server
  - Nginx Web Server
  - MySQL Server
  - PHP (versi 7.3, 8.3, 8.4, atau Latest)
  - Docker
  - Node.js
  - Python3 dan Pip
  - Git
  - ODBC SQL Server 17
  - Nginx + ODBC SQL Server 17 (modular)
- **Utilitas**:
  - Change Hostname

## Prerequisites

- Ubuntu 22.04 atau 24.04
- Akses sudo
- Koneksi internet untuk instalasi paket

## Instalasi

1. Clone atau download repository ini.
2. Berikan permission executable pada skrip:

   ```bash
   chmod +x menu.sh
   ```

3. Jalankan skrip:

   ```bash
   ./menu.sh
   ```

## Penggunaan

Setelah menjalankan `./menu.sh`, Anda akan melihat dashboard dengan informasi sistem dan menu opsi. Pilih nomor opsi yang diinginkan:

- Masukkan nomor opsi (1-15)
- Ikuti instruksi interaktif
- Setelah selesai, pilih kembali ke menu utama atau exit

### Contoh Penggunaan

1. **Set Static IP**:
   - Pilih 1
   - Masukkan interface (e.g., enp0s3)
   - Masukkan IP, Gateway, DNS

2. **Install PHP**:
   - Pilih 7
   - Pilih versi PHP (1-5)

3. **Install Nginx + ODBC**:
   - Pilih 14

## Catatan

- Pastikan menjalankan sebagai root atau dengan `sudo` jika diperlukan.
- Beberapa instalasi memerlukan koneksi internet untuk menambah repository eksternal (e.g., Microsoft ODBC).
- Perubahan hostname memerlukan reboot untuk fully applied.
- Backup konfigurasi Netplan dibuat otomatis sebelum mengubah IP.

## Troubleshooting

- Jika instalasi gagal, periksa log error dan pastikan repository tersedia.
- Untuk PHP versi lama, PPA ondrej/php ditambahkan otomatis.
- Jika interface tidak muncul, pastikan interface benar (gunakan `ip link show`).

## Kontribusi

Silakan buat issue atau pull request untuk improvement.

## Lisensi

Dibuat oleh Mahardian Ramadhani. Gunakan dengan bijak.

## Versi

- v1.0: Menu dasar dengan instalasi tools
- v1.1: Tambah dashboard sistem, PHP versi, ODBC, modular Nginx+ODBC
