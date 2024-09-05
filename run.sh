#!/bin/bash

chmod +x ./*

while true; do
    echo "Escolha uma opção:"
    echo "1 - Gerar rotas de Blackhole"
    echo "2 - Gerar lista de dominios para bloquear em DNS Recursivo (Bind e Unbound)"
    echo "sair - Sair"

    read -p "Digite o número da opção: " opcao

    case $opcao in
        1)./blackhole-generator.sh ;;
        2)./domain-generator.sh ;;
        sair) echo "Saindo..."
            exit 0
            ;;
        *)
            echo "Opção inválida!"
            ;;
    esac
done
