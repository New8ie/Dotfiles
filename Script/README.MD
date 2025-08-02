# 🛠️ Koleksi Script Pribadi

Kumpulan bash script utilitas untuk keperluan jaringan dan manajemen server pribadi.

---

## 📦 Daftar Script & Cara Penggunaan

### 1. `mylocalip.sh`
🔍 Menampilkan IP lokal aktif pada semua interface jaringan Anda (bukan hanya `eth0` atau `wlan0`).

**Cara pakai:**
```bash
bash mylocalip.sh
```

---

### 2. `sshcpid.sh`
📂 Copy file dari remote host ke lokal menggunakan SCP. Script ini menggunakan `sshpass` jika diperlukan.

**Cara pakai:**
```bash
bash sshcpid.sh <remote_user>@<remote_host>:/path/to/file /local/destination/
```

Contoh:
```bash
bash sshcpid.sh user@192.168.1.10:/etc/nginx/nginx.conf /tmp/
```

> Pastikan `sshpass` telah terinstall jika password-based login digunakan.

---

### 3. `static_route.sh`
🌐 Menambahkan static route ke tabel routing sistem.

**Cara pakai:**
```bash
sudo bash static_route.sh <destination_network> <gateway_ip> <interface>
```

Contoh:
```bash
sudo bash static_route.sh 192.168.50.0/24 192.168.1.1 eth0
```

> Berguna untuk konfigurasi jaringan manual di VM atau server dengan banyak interface.

---

### 4. `zabbix-install.sh`
📈 Script instalasi otomatis Zabbix agent di sistem Linux (Debian/Ubuntu/CentOS).

**Cara pakai:**
```bash
sudo bash zabbix-install.sh
```

Script akan:
- Mendeteksi OS
- Menambahkan repository Zabbix sesuai distro
- Install dan konfigurasi Zabbix agent
- Mengaktifkan dan menjalankan servicenya

---

## 📝 Prasyarat Umum

Pastikan Anda memiliki:
- Akses root (`sudo`)
- Koneksi internet
- Bash shell
- Paket `curl`, `git`, `sshpass` jika diperlukan

---

## 📂 Struktur Direktori

```bash
📁 scripts/
├── mylocalip.sh
├── sshcpid.sh
├── static_route.sh
└── zabbix-install.sh
```

---

## 🧾 Lisensi

Proyek ini menggunakan lisensi MIT — silakan gunakan, modifikasi, dan distribusikan.

---

## 🙌 Kontribusi

Pull request dan saran sangat diterima! Jangan ragu untuk fork dan ubah sesuai kebutuhan Anda.