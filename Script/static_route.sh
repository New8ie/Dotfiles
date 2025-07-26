#!/bin/bash

# Fungsi konversi CIDR ke netmask untuk macOS
cidr_to_netmask() {
    local cidr=$1
    local i
    local mask=""

    if ! [[ $cidr =~ ^[0-9]+$ ]] || [ "$cidr" -lt 0 ] || [ "$cidr" -gt 32 ]; then
        echo "❌ CIDR tidak valid: $cidr"
        return 1
    fi

    for ((i=0; i<4; i++)); do
        if [ "$cidr" -ge 8 ]; then
            mask+="255"
            cidr=$((cidr - 8))
        else
            mask+=$(( 256 - 2 ** (8 - cidr) ))
            cidr=0
        fi

        [ "$i" -lt 3 ] && mask+="."
    done

    echo "$mask"
}

# Fungsi untuk cetak routing table dengan/ tanpa grc
print_routing_table() {
    local OS="$1"

    echo -e "\n📡 Routing table saat ini:"
    if command -v grc >/dev/null 2>&1; then
        echo "✨ Menggunakan grc untuk pewarnaan output"
        if [[ "$OS" == "Darwin" ]]; then
            grc netstat -rn -f inet
        else
            grc ip route show
        fi
    else
        echo "⚠️  grc tidak ditemukan, menampilkan output biasa"
        if [[ "$OS" == "Darwin" ]]; then
            netstat -rn -f inet
        else
            ip route show
        fi
    fi
}

# Cek root
if [ "$EUID" -ne 0 ]; then
    echo "❌ Anda harus menjalankan skrip ini dengan sudo/root."
    exit 1
fi

# Menu loop

# Warna ANSI
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
NC='\033[0m' # No Color

while true; do
    echo -e "${CYAN}=== MENU STATIC ROUTE ===${NC}"
    echo -e "${GREEN}1)${NC} Tambah static route"
    echo -e "${GREEN}2)${NC} Hapus static route"
    echo -e "${GREEN}3)${NC} Print routing table"
    echo -e "${RED}4)${NC} Exit"
    # Gunakan echo -en agar escape sequence warna tidak mengganggu input
    echo -en "${YELLOW}Pilih opsi [1/2/3/4]: ${NC}"
    read -r opsi

    case "$opsi" in
        1|2)
            echo -en "${BLUE}Masukkan subnet destination (format: IP/CIDR, contoh: 192.168.2.0/24): ${NC}"
            read -r subnet_destination
            if ! echo "$subnet_destination" | grep -E '^[0-9]{1,3}(\.[0-9]{1,3}){3}/[0-9]{1,2}$' >/dev/null; then
                echo -e "${RED}❌ Format subnet tidak valid.${NC}"
                continue
            fi

            # Deteksi OS
            OS="$(uname)"
            ip=$(echo "$subnet_destination" | cut -d'/' -f1)
            cidr=$(echo "$subnet_destination" | cut -d'/' -f2)

            if [ "$opsi" == "1" ]; then
                echo -en "${BLUE}Masukkan IP Gateway: ${NC}"
                read -r gateway
                if ! echo "$gateway" | grep -E '^[0-9]{1,3}(\.[0-9]{1,3}){3}$' >/dev/null; then
                    echo -e "${RED}❌ IP Gateway tidak valid.${NC}"
                    continue
                fi

                if [[ "$OS" == "Darwin" ]]; then
                    netmask=$(cidr_to_netmask "$cidr") || continue
                    echo -e "${YELLOW}🔧 Menambahkan route di macOS: $ip netmask $netmask via $gateway${NC}"
                    if ! sudo route -n add -net "$ip" "$gateway" "$netmask" 2>&1; then
                        echo -e "${RED}❌ Gagal menambahkan route.${NC}"
                        continue
                    fi
                elif [[ "$OS" == "Linux" ]]; then
                    echo -e "${YELLOW}🔧 Menambahkan route di Linux: $subnet_destination via $gateway${NC}"
                    if ! sudo ip route add "$subnet_destination" via "$gateway" 2>&1; then
                        echo -e "${RED}❌ Gagal menambahkan route. Mungkin route sudah ada.${NC}"
                        continue
                    fi
                fi

            elif [ "$opsi" == "2" ]; then
                if [[ "$OS" == "Darwin" ]]; then
                    netmask=$(cidr_to_netmask "$cidr") || continue
                    echo -e "${YELLOW}🗑️ Menghapus route di macOS: $ip netmask $netmask${NC}"
                    if ! sudo route -n delete -net "$ip" "$netmask" 2>&1; then
                        echo -e "${RED}❌ Gagal menghapus route.${NC}"
                        continue
                    fi
                elif [[ "$OS" == "Linux" ]]; then
                    echo -e "${YELLOW}🗑️ Menghapus route di Linux: $subnet_destination${NC}"
                    if ! sudo ip route delete "$subnet_destination" 2>&1; then
                        echo -e "${RED}❌ Gagal menghapus route. Pastikan route ada.${NC}"
                        continue
                    fi
                fi
            fi
            # print_routing_table "$OS" (dihapus sesuai permintaan)
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
