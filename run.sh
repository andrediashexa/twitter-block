#!/bin/bash

# Função para detectar o sistema operacional
detect_os() {
    case "$(uname -s)" in
        Darwin)
            # macOS
            SED_INLINE="sed -i '' -e"
            ;;
        Linux)
            # Linux
            SED_INLINE="sed -i -e"
            ;;
        *)
            echo "Sistema operacional não suportado!"
            exit 1
            ;;
    esac
}

# Função para gerar rotas estáticas para Cisco
generate_cisco_routes() {
    while read -r prefix; do
        echo "ip route $prefix Null0" >> "$output_file"
    done < tmp_prefixes.txt
}

# Função para gerar rotas estáticas para Juniper
generate_juniper_routes() {
    while read -r prefix; do
        echo "set groups TWITTER-BLOCK routing-options static route $prefix discard" >> "$output_file"
    done < tmp_prefixes.txt
    echo "set apply-groups TWITTER-BLOCK" >> "$output_file"
}

# Função para gerar rotas estáticas para Nokia
generate_nokia_routes() {
    while read -r prefix; do
        echo "configure router static-route $prefix blackhole" >> "$output_file"
    done < tmp_prefixes.txt
}

# Função para gerar rotas estáticas para Huawei
generate_huawei_routes() {
    while read -r prefix; do
        echo "ip route-static $prefix NULL0" >> "$output_file"
    done < tmp_prefixes.txt
    $SED_INLINE 's/\// /g' "$output_file"
}

# Função para gerar rotas estáticas para Mikrotik
generate_mikrotik_routes() {
    while read -r prefix; do
        echo "/ip route add dst-address=$prefix type=blackhole" >> "$output_file"
    done < tmp_prefixes.txt
}

# Função para gerar rotas estáticas para VyOS
generate_vyos_routes() {
    while read -r prefix; do
        echo "set protocols static route $prefix blackhole" >> "$output_file"
    done < tmp_prefixes.txt
}

# Lista de ASNs
asns=("63179" "54888" "35995" "13414")

# Detecta o sistema operacional
detect_os

# Solicita o tipo de dispositivo
echo "Selecione o fabricante para gerar as rotas estáticas:"
echo "1 - Cisco"
echo "2 - Juniper"
echo "3 - Nokia"
echo "4 - Huawei"
echo "5 - Mikrotik"
echo "6 - VyOS"
read -p "Escolha uma opção (1-6): " choice

# Define o arquivo de saída
output_file="static_routes.txt"
rm -rf "$output_file"

# Limpa o arquivo de saída
> "$output_file"

for asn in "${asns[@]}"; do
    # Obtém os prefixos usando bgpq4
    bgpq4 -4 -m 24 -l prefix_list_$asn AS$asn | grep -v '^no ip prefix-list' > tmp_prefixes.txt
    
    # Gera as rotas com base na escolha
    case $choice in
        1)
            generate_cisco_routes
            ;;
        2)
            generate_juniper_routes
            ;;
        3)
            generate_nokia_routes
            ;;
        4)
            generate_huawei_routes
            ;;
        5)
            generate_mikrotik_routes
            ;;
        6)
            generate_vyos_routes
            ;;
        *)
            echo "Opção inválida!"
            rm -f tmp_prefixes.txt
            exit 1
            ;;
    esac

    # Executa o sed para remover as linhas específicas ao ASN atual
    $SED_INLINE "s/ip prefix-list prefix_list_${asn} permit//g" "$output_file"
    
    # Remove o arquivo temporário
    rm -f tmp_prefixes.txt
done

echo "Rotas estáticas geradas em $output_file"
cat "$output_file"
