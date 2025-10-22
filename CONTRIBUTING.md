# Contributing Guide

## Menambahkan Fungsi Instalasi Baru

Struktur modular memudahkan penambahan fungsi instalasi baru. Ikuti langkah berikut:

### 1. Buat File Script Baru

Buat file baru di folder `scripts/` dengan nama yang sesuai, misalnya `scripts/redis.sh`:

```bash
#!/bin/bash

# Redis installation

install_redis() {
    echo "Installing Redis Server..."
    sudo apt update
    sudo apt install -y redis-server
    sudo systemctl enable redis-server
    sudo systemctl start redis-server
    echo "Redis Server installed and started."
}
```

### 2. Load Script di menu.sh

Tambahkan baris source di bagian atas `menu.sh` setelah script modules lainnya:

```bash
source "$SCRIPT_DIR/scripts/redis.sh"
```

### 3. Tambahkan Menu Item

Edit fungsi `display_menu()` di `menu.sh` untuk menambahkan menu item baru:

```bash
printf "\e[32m%-40s %s\e[0m\n" "19. Install Redis Server" ""
```

### 4. Tambahkan Case Handler

Tambahkan case di switch statement di main loop:

```bash
19)
    install_redis
    ;;
```

### 5. Update Documentation

Jangan lupa update `README.md` untuk mendokumentasikan fitur baru:
- Tambahkan di daftar Fitur
- Update struktur proyek jika perlu
- Update versi

## Best Practices

### Struktur Fungsi

```bash
#!/bin/bash

# Deskripsi singkat file

function_name() {
    echo "Starting installation/configuration..."
    
    # Update package list
    sudo apt update
    
    # Install package
    sudo apt install -y package-name
    
    # Enable and start service (jika ada)
    sudo systemctl enable service-name
    sudo systemctl start service-name
    
    echo "Installation completed successfully."
}
```

### Error Handling

Tambahkan error handling untuk instalasi yang lebih robust:

```bash
install_package() {
    echo "Installing Package..."
    
    if ! sudo apt update; then
        echo -e "\e[31mFailed to update package list.\e[0m"
        return 1
    fi
    
    if ! sudo apt install -y package-name; then
        echo -e "\e[31mFailed to install package.\e[0m"
        return 1
    fi
    
    echo -e "\e[32mPackage installed successfully.\e[0m"
}
```

### Interactive Prompts

Gunakan `read` untuk input user:

```bash
configure_service() {
    echo "Enter configuration value:"
    read -r config_value
    
    echo "Confirm configuration (y/n):"
    read -r confirm
    
    if [[ $confirm =~ ^[Yy]$ ]]; then
        # Apply configuration
        echo "Configuration applied."
    else
        echo "Configuration cancelled."
        return 0
    fi
}
```

### Color Codes

Gunakan color codes untuk output yang lebih jelas:

```bash
echo -e "\e[32mSuccess message\e[0m"    # Green
echo -e "\e[33mWarning message\e[0m"    # Yellow
echo -e "\e[31mError message\e[0m"      # Red
echo -e "\e[36mInfo message\e[0m"       # Cyan
echo -e "\e[35mHighlight message\e[0m"  # Magenta
```

## Testing

Sebelum commit, test script Anda:

1. **Syntax Check**:
   ```bash
   bash -n menu.sh
   bash -n scripts/your-script.sh
   ```

2. **Dry Run**: Jalankan di environment test terlebih dahulu

3. **Verification**: Pastikan fungsi dapat dipanggil dengan benar dari menu

## Kompatibilitas

Pastikan script kompatibel dengan:
- Ubuntu 22.04 LTS
- Ubuntu 24.04 LTS

Test di kedua versi jika memungkinkan.

## Commit Guidelines

Format commit message:

```
[Category] Brief description

Detailed description jika diperlukan
```

Contoh:
```
[Feature] Add Redis server installation

- Add scripts/redis.sh with installation function
- Update menu.sh to load redis script
- Add menu item #19 for Redis installation
- Update README.md documentation
```

Categories:
- `[Feature]` - Fitur baru
- `[Fix]` - Bug fix
- `[Update]` - Update existing feature
- `[Docs]` - Documentation only
- `[Refactor]` - Code refactoring

## Questions?

Jika ada pertanyaan atau butuh bantuan, buat issue di repository.
