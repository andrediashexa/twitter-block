#!/bin/bash

# Função para detectar o sistema operacional
detect_os() {
    case "$(uname -s)" in
        Darwin)
            # macOS
            SED_INLINE="sed -i ''"
            ;;
        Linux)
            # Linux
            SED_INLINE="sed -i"
            ;;
        *)
            echo "Sistema operacional não suportado!"
            exit 1
            ;;
    esac
}

# Funções para gerar rotas estáticas
generate_cisco_routes() {
    while read -r prefix; do
        echo "ip route $prefix Null0" >> "$output_file"
    done < tmp_prefixes.txt
}

generate_juniper_routes() {
    while read -r prefix; do
        echo "set groups TWITTER-BLOCK routing-options static route $prefix discard" >> "$output_file"
    done < tmp_prefixes.txt
}

generate_nokia_routes() {
    while read -r prefix; do
        echo "configure router static-route $prefix blackhole" >> "$output_file"
    done < tmp_prefixes.txt
}

generate_huawei_routes() {
    while read -r prefix; do
        echo "ip route-static $prefix NULL0" >> "$output_file"
    done < tmp_prefixes.txt
    $SED_INLINE 's/\// /g' "$output_file"
}

generate_mikrotik_routes() {
    while read -r prefix; do
        echo "/ip route add dst-address=$prefix type=blackhole" >> "$output_file"
    done < tmp_prefixes.txt
}

generate_vyos_routes() {
    while read -r prefix; do
        echo "set protocols static route $prefix blackhole" >> "$output_file"
    done < tmp_prefixes.txt
}

# Funções para adicionar comandos de remoção
add_cisco_removal() {
    while read -r prefix; do
        echo "no ip route $prefix Null0" >> "$remove_file"
    done < tmp_prefixes.txt
}

add_juniper_removal() {
    echo "delete groups TWITTER-BLOCK" >> "$remove_file"
    echo "delete apply-groups TWITTER-BLOCK" >> "$remove_file"
}

add_nokia_removal() {
    while read -r prefix; do
        echo "no configure router static-route $prefix blackhole" >> "$remove_file"
    done < tmp_prefixes.txt
}

add_huawei_removal() {
    while read -r prefix; do
        echo "undo ip route-static $prefix NULL0" >> "$remove_file"
    done < tmp_prefixes.txt
}

add_mikrotik_removal() {
    while read -r prefix; do
        echo "/ip route remove dst-address=$prefix" >> "$remove_file"
    done < tmp_prefixes.txt
}

add_vyos_removal() {
    while read -r prefix; do
        echo "delete protocols static route $prefix" >> "$remove_file"
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
remove_file="remove_routes.txt"
rm -f "$output_file" "$remove_file"

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

    # Remove as linhas específicas ao ASN atual do arquivo de saída
    $SED_INLINE "s/ip prefix-list prefix_list_${asn} permit//g" "$output_file"
done

# Exibe o conteúdo do arquivo de rotas estáticas
echo "Rotas estáticas geradas em $output_file"
cat "$output_file"

# Pergunta se deseja gerar os comandos de remoção
read -p "Deseja gerar os comandos de remoção para o fabricante selecionado? (s/n): " generate_removal

if [[ $generate_removal == "s" || $generate_removal == "S" ]]; then
    # Cria o arquivo de remoção
    > "$remove_file"
    
    case $choice in
        1)
            echo "# Commands to remove Cisco routes" >> "$remove_file"
            add_cisco_removal
            ;;
        2)
            echo "# Commands to remove Juniper routes" >> "$remove_file"
            add_juniper_removal
            ;;
        3)
            echo "# Commands to remove Nokia routes" >> "$remove_file"
            add_nokia_removal
            ;;
        4)
            echo "# Commands to remove Huawei routes" >> "$remove_file"
            add_huawei_removal
            ;;
        5)
            echo "# Commands to remove Mikrotik routes" >> "$remove_file"
            add_mikrotik_removal
            ;;
        6)
            echo "# Commands to remove VyOS routes" >> "$remove_file"
            add_vyos_removal
            ;;
    esac

    echo "Comandos de remoção gerados em $remove_file"
    cat "$remove_file"
fi

# Remove o arquivo temporário apenas se os comandos de remoção não forem gerados
if [[ $generate_removal != "s" && $generate_removal != "S" ]]; then
    rm -f tmp_prefixes.txt
fi
