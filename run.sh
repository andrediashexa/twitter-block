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

# Função para adicionar comandos de remoção para Cisco
add_cisco_removal() {
    echo "# Commands to remove Cisco routes" >> "$output_file"
    while read -r prefix; do
        echo "no ip route $prefix Null0" >> "$output_file"
    done < tmp_prefixes.txt
}

# Função para adicionar comandos de remoção para Juniper
add_juniper_removal() {
    echo "# Commands to remove Juniper routes" >> "$output_file"
    echo "delete groups TWITTER-BLOCK" >> "$output_file"
    echo "delete apply-groups TWITTER-BLOCK" >> "$output_file"
}

# Função para adicionar comandos de remoção para Nokia
add_nokia_removal() {
    echo "# Commands to remove Nokia routes" >> "$output_file"
    while read -r prefix; do
        echo "no configure router static-route $prefix blackhole" >> "$output_file"
    done < tmp_prefixes.txt
}

# Função para adicionar comandos de remoção para Huawei
add_huawei_removal() {
    echo "# Commands to remove Huawei routes" >> "$output_file"
    while read -r prefix; do
        echo "undo ip route-static $prefix NULL0" >> "$output_file"
    done < tmp_prefixes.txt
}

# Função para adicionar comandos de remoção para Mikrotik
add_mikrotik_removal() {
    echo "# Commands to remove Mikrotik routes" >> "$output_file"
    while read -r prefix; do
        echo "/ip route remove dst-address=$prefix" >> "$output_file"
    done < tmp_prefixes.txt
}

# Função para adicionar comandos de remoção para VyOS
add_vyos_removal() {
    echo "# Commands to remove VyOS routes" >> "$output_file"
    while read -r prefix; do
        echo "delete protocols static route $prefix" >> "$output_file"
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

# Define os arquivos de saída
output_file="static_routes.txt"
temp_file="juniper_temp.txt"
rm -rf "$output_file" "$temp_file"

# Limpa o arquivo de saída
> "$output_file"

for asn in "${asns[@]}"; do
    # Obtém os prefixos usando bgpq4
    bgpq4 -4 -m 24 -l prefix_list_$asn AS$asn | grep -v '^no ip prefix-list' > tmp_prefixes.txt
    
    # Gera as rotas com base na escolha
    case $choice in
        1)
            generate_cisco_routes
            add_cisco_removal
            ;;
        2)
            generate_juniper_routes
            # Adiciona o comando apply-groups ao final do arquivo no final
            ;;
        3)
            generate_nokia_routes
            add_nokia_removal
            ;;
        4)
            generate_huawei_routes
            add_huawei_removal
            ;;
        5)
            generate_mikrotik_routes
            add_mikrotik_removal
            ;;
        6)
            generate_vyos_routes
            add_vyos_removal
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

# Adiciona o apply-groups para Juniper no final do arquivo, se necessário
if [ "$choice" -eq 2 ]; then
    echo "set apply-groups TWITTER-BLOCK" >> "$output_file"
    add_juniper_removal
fi

echo "Rotas estáticas geradas em $output_file"
cat "$output_file"
