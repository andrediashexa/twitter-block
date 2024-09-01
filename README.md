Necessário rodar em Linux ou MacOS.

Utiliza BGPQ4 e IPCALC para o funcionamento.

Suporta os seguintes vendors:

--Huawei
--Juniper
--Cisco
--VyOS
--RouterOS (Mikrotik)
--Nokia

Testado para Juniper, Huawei e Cisco. Outros vendors nao estão testados.

apt update ; apt install git bgpq4 ipcalc -y

git clone https://github.com/andrediashexa/twitter-block.git

cd twitter-block

chmod +x run.sh

./run.sh


Escolha o vendor e pronto.
