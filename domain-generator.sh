#!/bin/bash

unbound() {
        echo "Adicione o abaixo no seu arquivo de configuração do unbound:
        "
        echo "include: /etc/unbound/blacklist.conf"

            echo "Quando estiver pronto para passar para proxima etapa, pressione enter"

        read

        echo "Cole todos os dominios na proxima tela, apos isso utilize ctrl+x para salvar"
        sleep 3
        nano /tmp/domain.tmp
        clear

        while read domain;
            do
                echo local-zone: "$domain" always_refuse
            done < /tmp/domain.tmp 

        echo ""

        rm -rf /tmp/domain.tmp

        echo "Cole todo o acima no arquivo /etc/unbound/blacklist.conf"
        echo "Esse arquivo voce precisará criar!"
        echo "
        
        
        
        "


}

bind9() {

    echo "Adicione o abaixo no arquivo named.conf.options:
    
    "
    echo "    // BLOQUEIO DE SITES
    response-policy {
      zone "rpz.zone" policy CNAME localhost;
    };
    
    "

    echo "Quando estiver pronto para passar para proxima etapa, pressione enter"

    read

    echo "Cole todos os dominios na proxima tela, apos isso utilize ctrl+x para salvar"
    sleep 3
    nano /tmp/domain.tmp
    clear

    echo ""
    echo "$TTL    86400
@       IN      SOA     localhost. root.localhost. (
                              1         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                          86400 )       ; Negative Cache TTL
;
@       IN      NS      localhost.

"

    while read domain;
        do
            echo "$domain     IN CNAME ."
        done < /tmp/domain.tmp 

    echo ""

    rm -rf /tmp/domain.tmp

    echo "Cole todo o acima no arquivo db.rpz.zone"
    echo "Esse arquivo voce precisará criar!"
    echo "
    
    
    
    "
}

while true; do
    echo "Escolha uma opção:"
    echo "1 - Unbound"
    echo "2 - Bind9"
    echo "voltar - Voltar"

    read -p "Digite o número da opção: " opcao

    case $opcao in
        1) unbound ;;
        2) bind9 ;;
        voltar) echo "Voltando..."
            exit 0
            ;;
        *)
            echo "Opção inválida!"
            ;;
    esac
done
