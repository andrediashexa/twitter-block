#!/bin/bash

# Função para detectar o sistema operacional
detect_os() {
    case "$(uname -s)" in
        Darwin)
            SED_INLINE="sed -i ''"  # macOS
            ;;
        Linux)
            SED_INLINE="sed -i"     # Linux
            ;;
        *)
            echo "Sistema operacional não suportado!"
            exit 1
            ;;
    esac
}

# Função para verificar dependências necessárias
check_dependencies() {
    for cmd in bgpq4 ipcalc; do
        if ! command -v $cmd &> /dev/null; then
            echo "Erro: O comando '$cmd' não está instalado."
            exit 1
        fi
    done
}

# Funções para gerar rotas estáticas para diferentes fabricantes
generate_cisco_routes() {
    while read -r prefix; do
        echo "ip route $prefix Null0" >> "$output_file_ipv4"
    done < tmp_prefixes_ipv4.txt
    while read -r prefix; do
        echo "ipv6 route $prefix Null0" >> "$output_file_ipv6"
    done < tmp_prefixes_ipv6.txt
}

generate_juniper_routes() {
    while read -r prefix; do
        echo "set routing-options static route $prefix discard" >> "$output_file_ipv4"
    done < tmp_prefixes_ipv4.txt
    while read -r prefix; do
        echo "set routing-options rib inet6.0 static route $prefix discard" >> "$output_file_ipv6"
    done < tmp_prefixes_ipv6.txt
}

generate_nokia_routes() {
    while read -r prefix; do
        echo "configure router static-route $prefix blackhole" >> "$output_file_ipv4"
    done < tmp_prefixes_ipv4.txt
    while read -r prefix; do
        echo "configure router static-route ipv6 $prefix blackhole" >> "$output_file_ipv6"
    done < tmp_prefixes_ipv6.txt
}

generate_huawei_routes() {
    while read -r prefix; do
        echo "ip route-static $prefix NULL0" >> "$output_file_ipv4"
    done < tmp_prefixes_ipv4.txt
    while read -r prefix; do
        echo "ipv6 route-static $prefix NULL0" >> "$output_file_ipv6"
    done < tmp_prefixes_ipv6.txt
}

generate_mikrotik_routes() {
    while read -r prefix; do
        echo "/ip route add dst-address=$prefix type=blackhole" >> "$output_file_ipv4"
    done < tmp_prefixes_ipv4.txt
    while read -r prefix; do
        echo "/ipv6 route add dst-address=$prefix type=blackhole" >> "$output_file_ipv6"
    done < tmp_prefixes_ipv6.txt
}

generate_vyos_routes() {
    while read -r prefix; do
        echo "set protocols static route $prefix blackhole" >> "$output_file_ipv4"
    done < tmp_prefixes_ipv4.txt
    while read -r prefix; do
        echo "set protocols static route6 $prefix blackhole" >> "$output_file_ipv6"
    done < tmp_prefixes_ipv6.txt
}

generate_linux_routes() {
    while read -r prefix; do
        echo "ip route add blackhole $prefix" >> "$output_file_ipv4"
    done < tmp_prefixes_ipv4.txt
    while read -r prefix; do
        echo "ip -6 route add blackhole $prefix" >> "$output_file_ipv6"
    done < tmp_prefixes_ipv6.txt
}

generate_freebsd_routes() {
    while read -r prefix; do
        echo "route add -net $prefix -blackhole" >> "$output_file_ipv4"
    done < tmp_prefixes_ipv4.txt
    while read -r prefix; do
        echo "route add -inet6 $prefix -blackhole" >> "$output_file_ipv6"
    done < tmp_prefixes_ipv6.txt
}

# Funções para adicionar comandos de remoção de rotas
add_cisco_removal() {
    while read -r prefix; do
        echo "no ip route $prefix Null0" >> "$remove_file"
    done < tmp_prefixes_ipv4.txt
    while read -r prefix; do
        echo "no ipv6 route $prefix Null0" >> "$remove_file"
    done < tmp_prefixes_ipv6.txt
}

add_juniper_removal() {
    echo "delete routing-options static" >> "$remove_file"
    echo "delete routing-options rib inet6.0 static" >> "$remove_file"
}

add_nokia_removal() {
    while read -r prefix; do
        echo "no configure router static-route $prefix blackhole" >> "$remove_file"
    done < tmp_prefixes_ipv4.txt
    while read -r prefix; do
        echo "no configure router static-route ipv6 $prefix blackhole" >> "$remove_file"
    done < tmp_prefixes_ipv6.txt
}

add_huawei_removal() {
    while read -r prefix; do
        echo "undo ip route-static $prefix NULL0" >> "$remove_file"
    done < tmp_prefixes_ipv4.txt
    while read -r prefix; do
        echo "undo ipv6 route-static $prefix NULL0" >> "$remove_file"
    done < tmp_prefixes_ipv6.txt
}

add_mikrotik_removal() {
    while read -r prefix; do
        echo "/ip route remove dst-address=$prefix" >> "$remove_file"
    done < tmp_prefixes_ipv4.txt
    while read -r prefix; do
        echo "/ipv6 route remove dst-address=$prefix" >> "$remove_file"
    done < tmp_prefixes_ipv6.txt
}

add_vyos_removal() {
    while read -r prefix; do
        echo "delete protocols static route $prefix" >> "$remove_file"
    done < tmp_prefixes_ipv4.txt
    while read -r prefix; do
        echo "delete protocols static route6 $prefix" >> "$remove_file"
    done < tmp_prefixes_ipv6.txt
}

add_linux_removal() {
    while read -r prefix; do
        echo "ip route del blackhole $prefix" >> "$remove_file"
    done < tmp_prefixes_ipv4.txt
    while read -r prefix; do
        echo "ip -6 route del blackhole $prefix" >> "$remove_file"
    done < tmp_prefixes_ipv6.txt
}

add_freebsd_removal() {
    while read -r prefix; do
        echo "route delete -net $prefix -blackhole" >> "$remove_file"
    done < tmp_prefixes_ipv4.txt
    while read -r prefix; do
        echo "route delete -inet6 $prefix -blackhole" >> "$remove_file"
    done < tmp_prefixes_ipv6.txt
}

# Função para exibir a barra de progresso
show_progress() {
    local current="$1"
    local total="$2"
    local progress=$((current * 100 / total))
    local bar_width=50
    local filled=$((progress * bar_width / 100))
    local empty=$((bar_width - filled))
    local bar=$(printf "%0.s#" $(seq 1 $filled))
    local spaces=$(printf "%0.s " $(seq 1 $empty))
    printf "\r[%s%s] %d%%" "$bar" "$spaces" "$progress"
}

# Configuração de limpeza com trap
cleanup() {
    rm -f tmp_prefixes_ipv4.txt tmp_prefixes_ipv6.txt
}
trap cleanup EXIT

# Verifica dependências
check_dependencies

# Detecta o sistema operacional
detect_os

# Lista de ASNs para consulta
asns=("63179" "54888" "35995" "13414")

# Solicita o tipo de dispositivo ou sistema operacional para gerar as rotas
echo "Selecione o fabricante ou sistema operacional para gerar as rotas estáticas:"
echo "1 - Cisco"
echo "2 - Juniper"
echo "3 - Nokia"
echo "4 - Huawei"
echo "5 - Mikrotik"
echo "6 - VyOS"
echo "7 - Linux"
echo "8 - FreeBSD"
echo "voltar - Volta ao menu anterior"
read -p "Escolha uma opção (1-8): " choice

# Define os arquivos de saída e limpa qualquer arquivo anterior
output_file_ipv4="static_routes_ipv4.txt"
output_file_ipv6="static_routes_ipv6.txt"
remove_file="remove_routes.txt"
rm -f "$output_file_ipv4" "$output_file_ipv6" "$remove_file"

# Itera sobre cada ASN para gerar os comandos de roteamento
total_asns=${#asns[@]}
for i in "${!asns[@]}"; do
    asn="${asns[$i]}"

    # Obtém os prefixos IPv4 e IPv6 e filtra para remover prefixos indesejados
    bgpq4 -4 -m 24 -l prefix_list_$asn AS$asn | grep -v '^no ip prefix-list' > tmp_prefixes_ipv4.txt
    bgpq4 -6 -m 48 -l prefix_list_$asn AS$asn | grep -v '^no ipv6 prefix-list' > tmp_prefixes_ipv6.txt

    # Gera as rotas com base na escolha
    case $choice in
        1) generate_cisco_routes ;;
        2) generate_juniper_routes ;;
        3) generate_nokia_routes ;;
        4) generate_huawei_routes ;;
        5) generate_mikrotik_routes ;;
        6) generate_vyos_routes ;;
        7) generate_linux_routes ;;
        8) generate_freebsd_routes ;;
        voltar) exit 1 ;;
        *) echo "Opção inválida!" && exit 1 ;;
    esac

    # Remove as linhas específicas ao ASN atual do arquivo de saída
    $SED_INLINE "s/ip prefix-list prefix_list_${asn} permit//g" "$output_file_ipv4"
    $SED_INLINE "s/ipv6 prefix-list prefix_list_${asn} permit//g" "$output_file_ipv6"

    # Atualiza a barra de progresso
    show_progress $((i + 1)) $total_asns
done

echo -e "\nRotas estáticas IPv4 geradas em $output_file_ipv4"
cat "$output_file_ipv4"
echo -e "\nRotas estáticas IPv6 geradas em $output_file_ipv6"
cat "$output_file_ipv6"

# Pergunta se deseja gerar os comandos de remoção
read -p "Deseja gerar os comandos de remoção para o fabricante selecionado? (s/n): " generate_removal

if [[ $generate_removal == "s" || $generate_removal == "S" ]]; then
    > "$remove_file"
    case $choice in
        1) add_cisco_removal ;;
        2) add_juniper_removal ;;
        3) add_nokia_removal ;;
        4) add_huawei_removal ;;
        5) add_mikrotik_removal ;;
        6) add_vyos_removal ;;
        7) add_linux_removal ;;
        8) add_freebsd_removal ;;
    esac
    echo "Comandos de remoção gerados em $remove_file"
    cat "$remove_file"
fi

# Remove o arquivo temporário
rm -f tmp_prefixes_ipv4.txt tmp_prefixes_ipv6.txt
