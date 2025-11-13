#!/bin/bash

# ========= util =========
RED=$'\001\033[0;31m\002'
GREEN=$'\001\033[0;32m\002'
YELLOW=$'\001\033[1;33m\002'
BLUE=$'\001\033[1;34m\002'
CYAN=$'\001\033[1;36m\002'
NC=$'\001\033[0m\002'

cidr_to_netmask() {
    local cidr=$1 i mask=""
    if ! [[ $cidr =~ ^[0-9]+$ ]] || [ "$cidr" -lt 0 ] || [ "$cidr" -gt 32 ]; then
        echo "❌ CIDR tidak valid: $cidr" >&2
        return 1
    fi
    for ((i=0;i<4;i++)); do
        if [ "$cidr" -ge 8 ]; then
            mask+="255"
            cidr=$((cidr-8))
        else
            mask+=$((256 - 2 ** (8 - cidr)))
            cidr=0
        fi
        ((i<3)) && mask+="."
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

check_and_replace_route() {
    local subnet="$1"
    local gateway="$2"
    local OS="$(uname)"

    echo -e "${CYAN}🔍 Mengecek route $subnet ...${NC}"

    if [[ "$OS" == "Darwin" ]]; then
        # Format macOS menggunakan 10.12/16
        local shortsubnet="${subnet%.*.*}/${subnet#*/}"
        if netstat -rn -f inet | grep -q "${shortsubnet%/*}"; then
            echo -e "${YELLOW}🗑️  Route ditemukan, menghapus...${NC}"
            route -n delete -net "${subnet%/*}" -netmask "$(cidr_to_netmask "${subnet#*/}")" 2>/dev/null
        fi
        echo -e "${YELLOW}➕ Menambahkan route baru: $subnet via $gateway${NC}"
        route -n add -net "${subnet%/*}" -netmask "$(cidr_to_netmask "${subnet#*/}")" "$gateway" && \
        echo -e "${GREEN}✅ Route diperbarui: $subnet via $gateway${NC}" || \
        echo -e "${RED}❌ Gagal menambahkan route.${NC}"
    else
        if ip route show | grep -q "$subnet"; then
            echo -e "${YELLOW}🗑️  Route ditemukan, menghapus...${NC}"
            ip route delete "$subnet" 2>/dev/null
        fi
        echo -e "${YELLOW}➕ Menambahkan route baru: $subnet via $gateway${NC}"
        ip route add "$subnet" via "$gateway" && \
        echo -e "${GREEN}✅ Route diperbarui: $subnet via $gateway${NC}" || \
        echo -e "${RED}❌ Gagal menambahkan route.${NC}"
    fi
}

# ========= guard =========
if [ "$EUID" -ne 0 ]; then
    echo "❌ Anda harus menjalankan skrip ini dengan sudo/root."
    exit 1
fi

# ========= main loop =========
while true; do
    echo -e "${CYAN}\n=== MENU STATIC ROUTE ===${NC}"
    echo -e "${GREEN}1)${NC} Tambah static route"
    echo -e "${GREEN}2)${NC} Hapus static route"
    echo -e "${GREEN}3)${NC} Print routing table"
    echo -e "${GREEN}4)${NC} SDD"
    echo -e "${RED}5)${NC} Exit"
    echo -e "${RED}q)${NC} Exit cepat"

    read -r -n 1 -p $' \033[1;33mPilih opsi [1-5/q]: \033[0m' opsi
    echo

    case "$opsi" in
        q|Q|5)
            echo -e "${CYAN}Keluar.${NC}"
            break
            ;;
        1|2)
            read -e -r -p $'\033[1;34mMasukkan subnet destination (format: IP/CIDR): \033[0m' subnet_destination
            if ! echo "$subnet_destination" | grep -Eq '^[0-9]{1,3}(\.[0-9]{1,3}){3}/[0-9]{1,2}$'; then
                echo -e "${RED}❌ Format subnet tidak valid.${NC}"
                continue
            fi
            OS="$(uname)"
            ip=${subnet_destination%/*}
            cidr=${subnet_destination#*/}

            if [ "$opsi" = "1" ]; then
                read -e -r -p $'\033[1;34mMasukkan IP Gateway: \033[0m' gateway
                if ! echo "$gateway" | grep -Eq '^[0-9]{1,3}(\.[0-9]{1,3}){3}$'; then
                    echo -e "${RED}❌ IP Gateway tidak valid.${NC}"
                    continue
                fi
                if [[ "$OS" == "Darwin" ]]; then
                    netmask=$(cidr_to_netmask "$cidr") || continue
                    echo -e "${YELLOW}🔧 Menambahkan route di macOS: $ip netmask $netmask via $gateway${NC}"
                    route -n add -net "$ip" -netmask "$netmask" "$gateway"
                else
                    echo -e "${YELLOW}🔧 Menambahkan route di Linux: $subnet_destination via $gateway${NC}"
                    ip route add "$subnet_destination" via "$gateway"
                fi
            else
                if [[ "$OS" == "Darwin" ]]; then
                    netmask=$(cidr_to_netmask "$cidr") || continue
                    echo -e "${YELLOW}🗑️  Menghapus route di macOS: $ip netmask $netmask${NC}"
                    route -n delete -net "$ip" -netmask "$netmask"
                else
                    echo -e "${YELLOW}🗑️  Menghapus route di Linux: $subnet_destination${NC}"
                    ip route delete "$subnet_destination"
                fi
            fi
            ;;
        3)
            OS="$(uname)"
            print_routing_table "$OS"
            ;;
        4)
            echo -e "${CYAN}=== SDD ===${NC}"
            echo -e "${GREEN}1)${NC} Lantai-2"
            echo -e "${GREEN}2)${NC} Lantai-3"
            read -r -n 1 -p $'\033[1;33mPilih opsi [1-2]: \033[0m' subopsi
            echo
            case "$subopsi" in
                1)
                    check_and_replace_route "10.12.0.0/16" "10.12.32.1"
                    ;;
                2)
                    check_and_replace_route "10.12.0.0/16" "10.12.33.1"
                    ;;
                *)
                    echo -e "${RED}❌ Opsi tidak valid.${NC}"
                    ;;
            esac
            ;;
        *)
            echo -e "${RED}❌ Opsi tidak valid.${NC}"
            ;;
    esac
done
