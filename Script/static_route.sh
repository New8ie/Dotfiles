#!/bin/bash

# ========= util =========
# Warna aman untuk Readline (dibungkus \001 .. \002 agar tidak dihitung panjangnya)
RED=$'\001\033[0;31m\002'
GREEN=$'\001\033[0;32m\002'
YELLOW=$'\001\033[1;33m\002'
BLUE=$'\001\033[1;34m\002'
CYAN=$'\001\033[1;36m\002'
NC=$'\001\033[0m\002'

# Fungsi konversi CIDR ke netmask untuk macOS
cidr_to_netmask() {
    local cidr=$1 i mask=""
    if ! [[ $cidr =~ ^[0-9]+$ ]] || [ "$cidr" -lt 0 ] || [ "$cidr" -gt 32 ]; then
        echo "❌ CIDR tidak valid: $cidr"
        return 1
    fi
    for ((i=0;i<4;i++)); do
        if [ "$cidr" -ge 8 ]; then
            mask+="255"; cidr=$((cidr-8))
        else
            mask+=$((256 - 2 ** (8 - cidr))); cidr=0
        fi
        (( i<3 )) && mask+="."
    done
    echo "$mask"
}

print_routing_table() {
    local OS="$1"
    echo -e "\n📡 Routing table saat ini:"
    if command -v grc >/dev/null 2>&1; then
        echo "✨ Menggunakan grc untuk pewarnaan output"
        if [[ "$OS" == "Darwin" ]]; then grc netstat -rn -f inet; else grc ip route show; fi
    else
        echo "⚠️  grc tidak ditemukan, menampilkan output biasa"
        if [[ "$OS" == "Darwin" ]]; then netstat -rn -f inet; else ip route show; fi
    fi
}

# ========= guard =========
if [ "$EUID" -ne 0 ]; then
    echo "❌ Anda harus menjalankan skrip ini dengan sudo/root."
    exit 1
fi

# ========= main loop =========
while true; do
    echo -e "${CYAN}=== MENU STATIC ROUTE ===${NC}"
    echo -e "${GREEN}1)${NC} Tambah static route"
    echo -e "${GREEN}2)${NC} Hapus static route"
    echo -e "${GREEN}3)${NC} Print routing table"
    echo -e "${RED}4)${NC} Exit"
    echo -e "${RED}q)${NC} Exit cepat"

    # Menu 1 tombol: q keluar langsung tanpa Enter
    read -r -n 1 -p $' \001\033[1;33m\002Pilih opsi [1/2/3/4/q]: \001\033[0m\002' opsi
    echo  # newline setelah 1 tombol
    case "$opsi" in
        q|Q) echo -e "${CYAN}Keluar.${NC}"; break ;;
        1|2)
            # Input subnet (Readline aktif, backspace aman)
            read -e -r -p $'\001\033[1;34m\002Masukkan subnet destination (format: IP/CIDR, contoh: 192.168.2.0/24): \001\033[0m\002' subnet_destination
            if ! echo "$subnet_destination" | grep -Eq '^[0-9]{1,3}(\.[0-9]{1,3}){3}/[0-9]{1,2}$'; then
                echo -e "${RED}❌ Format subnet tidak valid.${NC}"
                continue
            fi

            OS="$(uname)"
            ip=${subnet_destination%/*}
            cidr=${subnet_destination#*/}

            if [ "$opsi" = "1" ]; then
                # Tambah route
                read -e -r -p $'\001\033[1;34m\002Masukkan IP Gateway: \001\033[0m\002' gateway
                if ! echo "$gateway" | grep -Eq '^[0-9]{1,3}(\.[0-9]{1,3}){3}$'; then
                    echo -e "${RED}❌ IP Gateway tidak valid.${NC}"
                    continue
                fi

                if [[ "$OS" == "Darwin" ]]; then
                    netmask=$(cidr_to_netmask "$cidr") || continue
                    echo -e "${YELLOW}🔧 Menambahkan route di macOS: $ip netmask $netmask via $gateway${NC}"
                    if ! route -n add -net "$ip" -netmask "$netmask" "$gateway"; then
                        echo -e "${RED}❌ Gagal menambahkan route.${NC}"
                        continue
                    fi
                else
                    echo -e "${YELLOW}🔧 Menambahkan route di Linux: $subnet_destination via $gateway${NC}"
                    if ! ip route add "$subnet_destination" via "$gateway"; then
                        echo -e "${RED}❌ Gagal menambahkan route. Mungkin route sudah ada.${NC}"
                        continue
                    fi
                fi

            else
                # Hapus route
                if [[ "$OS" == "Darwin" ]]; then
                    netmask=$(cidr_to_netmask "$cidr") || continue
                    echo -e "${YELLOW}🗑️  Menghapus route di macOS: $ip netmask $netmask${NC}"
                    if ! route -n delete -net "$ip" -netmask "$netmask"; then
                        echo -e "${RED}❌ Gagal menghapus route.${NC}"
                        continue
                    fi
                else
                    echo -e "${YELLOW}🗑️  Menghapus route di Linux: $subnet_destination${NC}"
                    if ! ip route delete "$subnet_destination"; then
                        echo -e "${RED}❌ Gagal menghapus route. Pastikan route ada.${NC}"
                        continue
                    fi
                fi
            fi
            ;;
        3)
            OS="$(uname)"
            print_routing_table "$OS"
            ;;
        4)
            echo -e "${CYAN}Keluar.${NC}"
            break
            ;;
        *)
            echo -e "${RED}❌ Opsi tidak valid.${NC}"
            ;;
    esac
done
