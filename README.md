Este script é utilizado para gerar rotas estáticas com o propósito de bloquear prefixos IP específicos. Foi desenvolvido para ser compatível com sistemas operacionais Linux e macOS.

## Pré-requisitos

Para que o script funcione corretamente, é necessário ter as seguintes dependências instaladas:

- **BGPQ4**
- **IPCALC**

## Lista de fabricantes e sistemas operacionais suportados

1. Cisco
2. Juniper
3. Nokia
4. Huawei
5. Mikrotik
6. VyOS
7. Linux
8. FreeBSD

**Observação:** O script foi testado nos fabricantes Cisco, Juniper e Huawei. Os demais fabricantes e sistemas operacionais listados ainda não foram testados.

## Instruções de Instalação

1. **Instale as dependências necessárias:**

   Para Linux:
   ```bash
   sudo apt update && sudo apt install git bgpq4 ipcalc -y
   ```

   Para macOS:
   ```bash
   brew update && brew install git bgpq4 ipcalc
   ```

2. **Clone o repositório do GitHub:**

   ```bash
   git clone https://github.com/andrediashexa/twitter-block.git
   ```

3. **Acesse o diretório do projeto:**

   ```bash
   cd twitter-block
   ```

4. **Conceda permissão de execução ao script:**

   ```bash
   chmod +x run.sh
   ```

5. **Execute o script:**

   ```bash
   ./run.sh
   ```

6. **Selecione o fabricante ou sistema operacional desejado da lista apresentada e siga as instruções para concluir o processo.**
