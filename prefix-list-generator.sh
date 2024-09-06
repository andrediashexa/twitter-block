#!/bin/bash

reverseGrep="(undo|deny)"

generate(){
        #v4
        while read asns;
            do
                bgpq4 $vendor 32 -l PREFIX_LIST_X-$asns AS$asns | grep -i -v -E $reverseGrep
            done < twitter-asns.txt

    echo ""

        #v6
        #while read asns;
        #    do
        #        bgpq4 -6 -A -U -R 128 -l PREFIX_LIST_X AS$asns | grep -i -v -E "$reverseGrep"
        #    done < twitter-asns.txt
}

while true; do
    echo "Escolha para qual vendor voce quer gerar a prefix-list:"
    echo "1 - Huawei"
    echo "2 - Huawei (XPL)"
    echo "3 - Cisco IOS-XE"
    echo "4 - Cisco IOS-XR"
    echo "5 - Juniper (Route-Filter)"
    echo "6 - Mikrotik v6"
    echo "7 - Mikrotik v7"
    echo "8 - Nokia MD-CLI"
    echo "9 - Nokia SR-LINUX"
    echo "10 - Nokia SROS Classic"
    echo "11 - OpenBGPD"
    echo "12 - BIRD"
    echo "13 - Arista"
    echo "99 - JSON Format"
    echo "voltar - Voltar"

    read -p "Digite o número da opção: " opcao

    case $opcao in
        1) vendor="-A -U -R" ; generate ;; #Huawei
        2) vendor="-A -u -R" ; generate ;; #Huawei XPL
        3) vendor="-A -R" ; generate ;; #Cisco IOS-XE
        4) vendor="-A -X -R" ; generate ;; #Cisco IOS-XR
        5) vendor="-J -m" ; generate ;; #Juniper
        6) vendor="-A -K -R" ; generate ;; #Mikrotik v6
        7) vendor=-"-A -K7 -R" ; generate ;; #Mikrotik v7
        8) vendor="-A -n -R" ; generate ;; #Nokia MD-CLI
        9) vendor=-"-A -n2 -R" ; generate ;; #Nokia SR-LINUX
        10) vendor=-"-A -N -R" ; generate ;; #Nokia SROS Classic
        11) vendor=-"-A -B -R" ; generate ;; #OpenBGPD
        12) vendor=-"-A -b -R" ; generate ;; #BIRD
        13) vendor=-"-A -e -R" ; generate ;; #Arista
        99) vendor=-"-A -j -R" ; generate ;; #JSON Format
        voltar) echo "Voltando..."
            exit 0
            ;;
        *)
            echo "Opção inválida!"
            ;;
    esac
done
