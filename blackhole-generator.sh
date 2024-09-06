#!/bin/bash

# Função para detectar o sistema operacional
detect_os() {
    case "$(uname -s)" in
        Darwin)
            SED_INLINE="sed ''"  # macOS
            ;;
        Linux)
            SED_INLINE="sed"     # Linux
            ;;
        *)
            echo "Sistema operacional não suportado!"
            exit 1
            ;;
    esac
}

# Função para verificar dependências necessárias
check_dependencies() {
    for cmd in bgpq4 ipcalc sipcalc; do
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
    done < $prefixes
    while read -r prefix; do
        echo "ipv6 route $prefix Null0" >> "$output_file_ipv6"
    done < $prefixesv6
}

generate_juniper_routes() {
    while read -r prefix; do
        echo "set routing-options static route $prefix discard" >> "$output_file_ipv4"
    done < $prefixes
    while read -r prefix; do
        echo "set routing-options rib inet6.0 static route $prefix discard" >> "$output_file_ipv6"
    done < $prefixesv6
}

generate_nokia_routes() {
    while read -r prefix; do
        echo "configure router static-route $prefix blackhole" >> "$output_file_ipv4"
    done < $prefixes
    while read -r prefix; do
        echo "configure router static-route ipv6 $prefix blackhole" >> "$output_file_ipv6"
    done < $prefixesv6
}

generate_huawei_routes() {
    while read -r prefix; do
        echo "ip route-static $prefix NULL0" >> "$output_file_ipv4"
    done < $prefixes
    while read -r prefix; do
        echo "ipv6 route-static $prefix NULL0" >> "$output_file_ipv6"
    done < $prefixesv6
}

generate_mikrotik_routes() {
    while read -r prefix; do
        echo "/ip route add dst-address=$prefix type=blackhole" >> "$output_file_ipv4"
    done < $prefixes
    while read -r prefix; do
        echo "/ipv6 route add dst-address=$prefix type=blackhole" >> "$output_file_ipv6"
    done < $prefixesv6
}

generate_vyos_routes() {
    while read -r prefix; do
        echo "set protocols static route $prefix blackhole" >> "$output_file_ipv4"
    done < $prefixes
    while read -r prefix; do
        echo "set protocols static route6 $prefix blackhole" >> "$output_file_ipv6"
    done < $prefixesv6
}

generate_linux_routes() {
    while read -r prefix; do
        echo "ip route add blackhole $prefix" >> "$output_file_ipv4"
    done < $prefixes
    while read -r prefix; do
        echo "ip -6 route add blackhole $prefix" >> "$output_file_ipv6"
    done < $prefixesv6
}

generate_freebsd_routes() {
    while read -r prefix; do
        echo "route add -net $prefix -blackhole" >> "$output_file_ipv4"
    done < $prefixes
    while read -r prefix; do
        echo "route add -inet6 $prefix -blackhole" >> "$output_file_ipv6"
    done < $prefixesv6
}

# Funções para adicionar comandos de remoção de rotas
add_cisco_removal() {
    while read -r prefix; do
        echo "no ip route $prefix Null0" >> "$remove_file"
    done < $prefixes
    while read -r prefix; do
        echo "no ipv6 route $prefix Null0" >> "$remove_file"
    done < $prefixesv6
}

add_juniper_removal() {
    echo "delete routing-options static" >> "$remove_file"
    echo "delete routing-options rib inet6.0 static" >> "$remove_file"
}

add_nokia_removal() {
    while read -r prefix; do
        echo "no configure router static-route $prefix blackhole" >> "$remove_file"
    done < $prefixes
    while read -r prefix; do
        echo "no configure router static-route ipv6 $prefix blackhole" >> "$remove_file"
    done < $prefixesv6
}

add_huawei_removal() {
    while read -r prefix; do
        echo "undo ip route-static $prefix NULL0" >> "$remove_file"
    done < $prefixes
    while read -r prefix; do
        echo "undo ipv6 route-static $prefix NULL0" >> "$remove_file"
    done < $prefixesv6
}

add_mikrotik_removal() {
    while read -r prefix; do
        echo "/ip route remove dst-address=$prefix" >> "$remove_file"
    done < $prefixes
    while read -r prefix; do
        echo "/ipv6 route remove dst-address=$prefix" >> "$remove_file"
    done < $prefixesv6
}

add_vyos_removal() {
    while read -r prefix; do
        echo "delete protocols static route $prefix" >> "$remove_file"
    done < $prefixes
    while read -r prefix; do
        echo "delete protocols static route6 $prefix" >> "$remove_file"
    done < $prefixesv6
}

add_linux_removal() {
    while read -r prefix; do
        echo "ip route del blackhole $prefix" >> "$remove_file"
    done < $prefixes
    while read -r prefix; do
        echo "ip -6 route del blackhole $prefix" >> "$remove_file"
    done < $prefixesv6
}

add_freebsd_removal() {
    while read -r prefix; do
        echo "route delete -net $prefix -blackhole" >> "$remove_file"
    done < $prefixes
    while read -r prefix; do
        echo "route delete -inet6 $prefix -blackhole" >> "$remove_file"
    done < $prefixesv6
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
    rm -f $prefixes $prefixesv6
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
prefixes="prefixes.txt"
prefixesv6="prefixes-v6.txt"
fullprefixesv6="full-prefixes-v6.txt"
rm -rf "$output_file_ipv4" "$output_file_ipv6" "$remove_file" "$prefixes" "$prefixesv6" "$fullprefixesv6"

# Itera sobre cada ASN para gerar os comandos de roteamento
total_asns=${#asns[@]}
for i in "${!asns[@]}"; do
    asn="${asns[$i]}"

    # Obtém os prefixos IPv4 e IPv6 e filtra para remover prefixos indesejados
    bgpq4 -4 -l "" -m 24 AS$asn | grep -v '^no ip prefix-list' | $SED_INLINE 's/ip prefix-list .* permit //g' >> $prefixes
    bgpq4 -6 -m 48 -l "" AS$asn | grep -v '^no ipv6 prefix-list' | grep -v ! | grep -v deny |sed 's/ipv6 prefix-list .* permit //g' >> $fullprefixesv6
    
    # Quebra os prefixos ipv6 recebido pelo BGPQ4 em /40
    while read prefixeslistv6;
    do
        sipcalc $prefixeslistv6 -S /40 | awk '/Network/ {print $3}' | sed 's/:0000:0000:0000:0000:0000/::/g' | sed 's/::::/::/g' | awk '{print $1"/40"}'  >> $prefixesv6
    done < $fullprefixesv6

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
rm -f $prefixes $prefixesv6
