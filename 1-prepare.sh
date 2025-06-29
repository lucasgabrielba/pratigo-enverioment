#!/bin/bash
# Pratigo Environment Preparation Script
# This script sets up the environment for Pratigo, including repositories and dependencies
# Versão: 1.1 - Com diagnóstico automático e correção de erros

# Color definitions for better output
BYellow='\033[1;33m'
BGreen='\033[1;32m'
BRed='\033[1;31m'
BBlue='\033[1;34m'
NC='\033[0m' # No Color

# Função para diagnosticar e corrigir problemas comuns
diagnose_and_fix() {
    local repo=$1
    echo -e "${BBlue}Diagnosticando problemas no repositório $repo...${NC}"
    
    # Verificar versão do Node.js
    echo -e "${BYellow}Verificando versão do Node.js...${NC}"
    node_version=$(node -v)
    echo -e "${BBlue}Node.js version: $node_version${NC}"
    
    # Verificar versão do NPM
    echo -e "${BYellow}Verificando versão do NPM...${NC}"
    npm_version=$(npm -v)
    echo -e "${BBlue}NPM version: $npm_version${NC}"
    
    # Verificar espaço em disco
    echo -e "${BYellow}Verificando espaço em disco...${NC}"
    disk_space=$(df -h . | tail -1 | awk '{print $4}')
    echo -e "${BBlue}Espaço disponível: $disk_space${NC}"
    
    # Verificar permissões do diretório
    echo -e "${BYellow}Verificando permissões...${NC}"
    if [ ! -w "." ]; then
        echo -e "${BRed}Erro de permissão no diretório. Corrigindo...${NC}"
        chmod -R u+w .
    fi
    
    # Verificar package.json
    echo -e "${BYellow}Verificando package.json...${NC}"
    if [ -f "package.json" ]; then
        if ! jq . package.json > /dev/null 2>&1; then
            echo -e "${BRed}package.json inválido. Tentando recuperar de backup...${NC}"
            if [ -f "package.json.bak" ]; then
                cp package.json.bak package.json
            else
                echo -e "${BRed}Não foi possível recuperar package.json${NC}"
            fi
        else
            echo -e "${BGreen}package.json válido${NC}"
            # Criar backup do package.json
            cp package.json package.json.bak
        fi
    fi
    
    # Aplicar correções específicas para cada repositório
    case "$repo" in
        "api")
            fix_api_repo
            ;;
        "gestor")
            fix_gestor_repo
            ;;
        "pwa")
            fix_pwa_repo
            ;;
        "socket")
            fix_socket_repo
            ;;
    esac
}

# Funções específicas para cada repositório
fix_api_repo() {
    echo -e "${BBlue}Aplicando correções específicas para o repositório api...${NC}"
    
    # Verificar se é um projeto Laravel
    if [ -f "artisan" ]; then
        # Tentar instalar o Composer se não estiver instalado
        if ! command -v composer >/dev/null 2>&1; then
            echo -e "${BYellow}Tentando instalar o Composer automaticamente...${NC}"
            
            # Verificar se o PHP está instalado
            if command -v php >/dev/null 2>&1; then
                # Instalar Composer
                EXPECTED_CHECKSUM="$(curl -s https://composer.github.io/installer.sig)"
                php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
                ACTUAL_CHECKSUM="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"
                
                if [ "$EXPECTED_CHECKSUM" != "$ACTUAL_CHECKSUM" ]; then
                    echo -e "${BRed}Falha na verificação do instalador do Composer${NC}"
                    rm composer-setup.php
                else
                    php composer-setup.php --quiet
                    rm composer-setup.php
                    
                    # Mover para um local no PATH
                    if [ -d "/usr/local/bin" ] && [ -w "/usr/local/bin" ]; then
                        sudo mv composer.phar /usr/local/bin/composer
                    else
                        chmod +x composer.phar
                        sudo mv composer.phar /usr/bin/composer 2>/dev/null || mv composer.phar ./composer && alias composer="./composer"
                    fi
                fi
            else
                echo -e "${BRed}PHP não está instalado. Tentando instalar...${NC}"
                if command -v brew >/dev/null 2>&1; then
                    brew install php
                elif command -v apt-get >/dev/null 2>&1; then
                    sudo apt-get update && sudo apt-get install -y php php-cli php-common php-json php-mbstring php-zip unzip
                elif command -v yum >/dev/null 2>&1; then
                    sudo yum install -y php php-cli php-common php-json php-mbstring php-zip unzip
                else
                    echo -e "${BRed}Não foi possível instalar o PHP automaticamente.${NC}"
                fi
            fi
        fi
        
        # Verificar novamente se o Composer está disponível
        if command -v composer >/dev/null 2>&1 || [ -f "./composer" ]; then
            # Verificar se as dependências do Composer já foram instaladas
            if [ ! -d "vendor" ]; then
                echo -e "${BYellow}Instalando dependências do Composer...${NC}"
                if [ -f "./composer" ]; then
                    chmod +x ./composer
                    ./composer install --no-interaction
                else
                    composer install --no-interaction
                fi
                
                # Verificar se a instalação foi bem-sucedida
                if [ $? -ne 0 ]; then
                    echo -e "${BYellow}Tentando instalar com --ignore-platform-reqs...${NC}"
                    if [ -f "./composer" ]; then
                        chmod +x ./composer
                        ./composer install --no-interaction --ignore-platform-reqs
                    else
                        composer install --no-interaction --ignore-platform-reqs
                    fi
                fi
            else
                echo -e "${BGreen}Dependências do Composer já instaladas${NC}"
            fi
            
            # Criar arquivo .env se não existir
            if [ ! -f ".env" ] && [ -f ".env.example" ]; then
                echo -e "${BYellow}Criando arquivo .env a partir do .env.example...${NC}"
                cp .env.example .env
                
                # Configurar banco de dados SQLite para desenvolvimento local
                if command -v sed >/dev/null 2>&1; then
                    echo -e "${BYellow}Configurando banco de dados SQLite para desenvolvimento local...${NC}"
                    sed -i 's/DB_CONNECTION=mysql/DB_CONNECTION=sqlite/g' .env 2>/dev/null || sed -i '' 's/DB_CONNECTION=mysql/DB_CONNECTION=sqlite/g' .env
                    touch database/database.sqlite
                fi
                
                # Gerar chave de aplicação Laravel
                if [ -f "vendor/autoload.php" ] && command -v php >/dev/null 2>&1; then
                    echo -e "${BYellow}Gerando chave de aplicação Laravel...${NC}"
                    php artisan key:generate --force
                    
                    # Executar migrações se o banco de dados for SQLite
                    if grep -q "DB_CONNECTION=sqlite" .env; then
                        echo -e "${BYellow}Executando migrações do banco de dados...${NC}"
                        php artisan migrate --force
                    fi
                fi
            fi
        else
            echo -e "${BRed}Composer não está disponível. Não é possível instalar dependências do Laravel.${NC}"
        fi
    fi
}

fix_gestor_repo() {
    echo -e "${BBlue}Aplicando correções específicas para o repositório gestor...${NC}"
    
    # Verificar e corrigir problemas comuns em projetos Angular/React
    if [ -f "package.json" ]; then
        # Verificar se é um projeto Angular
        if grep -q "@angular/core" package.json; then
            echo -e "${BYellow}Detectado projeto Angular. Verificando configurações...${NC}"
            
            # Verificar se o @angular-devkit/build-angular está presente
            if ! grep -q "@angular-devkit/build-angular" package.json; then
                echo -e "${BYellow}Adicionando @angular-devkit/build-angular...${NC}"
                npm install --save-dev @angular-devkit/build-angular
            fi
        fi
    fi
}

fix_pwa_repo() {
    echo -e "${BBlue}Aplicando correções específicas para o repositório pwa...${NC}"
    
    if [ -f "package.json" ]; then
        # IMPORTANTE: PWA precisa do Node.js versão 12
        echo -e "${BYellow}Verificando versão do Node.js para o PWA (precisa ser v12)...${NC}"
        current_node_version=$(node -v | cut -d 'v' -f2 | cut -d '.' -f1)
        
        # Verificar versão do Node.js para o PWA (requer Node.js 12)
        if [ "$current_node_version" != "12" ]; then
            echo -e "${BYellow}O repositório PWA requer Node.js 12, mas está usando a versão $current_node_version.${NC}"
            
            # Verificar se o NVM está instalado
            if command -v nvm >/dev/null 2>&1; then
                echo -e "${BYellow}Tentando mudar para Node.js 12 usando NVM...${NC}"
                nvm use 12 || nvm install 12
            else
                # Tentar instalar o NVM automaticamente
                echo -e "${BYellow}NVM não está instalado. Tentando instalar automaticamente...${NC}"
                curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
                
                # Carregar NVM
                export NVM_DIR="$HOME/.nvm"
                [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
                [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
                
                # Verificar se NVM foi instalado corretamente
                if command -v nvm >/dev/null 2>&1; then
                    echo -e "${BGreen}NVM instalado com sucesso!${NC}"
                    echo -e "${BYellow}Instalando Node.js 12...${NC}"
                    nvm install 12
                    nvm use 12
                else
                    echo -e "${BRed}Falha ao instalar NVM. Tentando usar n como alternativa...${NC}"
                    
                    # Tentar usar 'n' como alternativa
                    if command -v npm >/dev/null 2>&1; then
                        echo -e "${BYellow}Tentando instalar 'n' para gerenciar versões do Node.js...${NC}"
                        npm install -g n
                        n 12
                    else
                        echo -e "${BRed}Não foi possível instalar NVM ou 'n'. O PWA pode não funcionar corretamente.${NC}"
                    fi
                fi
            fi
        fi
        
        # Verificar e ajustar dependências problemáticas para Node.js 12
        if command -v jq >/dev/null 2>&1; then
            # Verificar node-sass
            if jq -e '.dependencies["node-sass"] or .devDependencies["node-sass"]' package.json >/dev/null; then
                echo -e "${BYellow}Ajustando versão do node-sass para compatibilidade com Node.js 12...${NC}"
                # Atualizar para versão compatível com Node.js 12
                sed -i 's/"node-sass": "[^"]*"/"node-sass": "^4.14.1"/g' package.json 2>/dev/null || \
                sed -i '' 's/"node-sass": "[^"]*"/"node-sass": "^4.14.1"/g' package.json
            fi
            
            # Verificar grpc
            if jq -e '.dependencies["grpc"] or .devDependencies["grpc"]' package.json >/dev/null; then
                echo -e "${BYellow}Ajustando versão do grpc para compatibilidade com Node.js 12...${NC}"
                # Atualizar para versão compatível com Node.js 12
                sed -i 's/"grpc": "[^"]*"/"grpc": "^1.24.4"/g' package.json 2>/dev/null || \
                sed -i '' 's/"grpc": "[^"]*"/"grpc": "^1.24.4"/g' package.json
            fi
            
            # Verificar e ajustar outras dependências problemáticas
            if jq -e '.dependencies["node-gyp"] or .devDependencies["node-gyp"]' package.json >/dev/null; then
                echo -e "${BYellow}Ajustando versão do node-gyp para compatibilidade com Node.js 12...${NC}"
                sed -i 's/"node-gyp": "[^"]*"/"node-gyp": "^7.1.2"/g' package.json 2>/dev/null || \
                sed -i '' 's/"node-gyp": "[^"]*"/"node-gyp": "^7.1.2"/g' package.json
            fi
            
            # Verificar e ajustar versão do webpack se necessário
            if jq -e '.dependencies["webpack"] or .devDependencies["webpack"]' package.json >/dev/null; then
                echo -e "${BYellow}Verificando compatibilidade do webpack com Node.js 12...${NC}"
                webpack_version=$(jq -r '.dependencies["webpack"] // .devDependencies["webpack"]' package.json | sed 's/[^0-9.]//g' | cut -d'.' -f1)
                if [ "$webpack_version" -gt "4" ]; then
                    echo -e "${BYellow}Ajustando versão do webpack para compatibilidade com Node.js 12...${NC}"
                    sed -i 's/"webpack": "[^"]*"/"webpack": "^4.46.0"/g' package.json 2>/dev/null || \
                    sed -i '' 's/"webpack": "[^"]*"/"webpack": "^4.46.0"/g' package.json
                fi
            fi
        else
            echo -e "${BYellow}jq não está instalado. Tentando instalar...${NC}"
            if command -v brew >/dev/null 2>&1; then
                brew install jq
            elif command -v apt-get >/dev/null 2>&1; then
                sudo apt-get update && sudo apt-get install -y jq
            elif command -v yum >/dev/null 2>&1; then
                sudo yum install -y jq
            else
                echo -e "${BRed}Não foi possível instalar jq automaticamente.${NC}"
            fi
        fi
        
        # Verificar se há um arquivo .npmrc e adicionar configurações para evitar erros de build nativos
        echo -e "${BYellow}Configurando .npmrc para evitar problemas com módulos nativos...${NC}"
        echo "unsafe-perm=true" > .npmrc
        echo "node-gyp=7.1.2" >> .npmrc
        echo "python=python2" >> .npmrc
    fi
}

fix_socket_repo() {
    echo -e "${BBlue}Aplicando correções específicas para o repositório socket...${NC}"
    
    # Verificar e corrigir problemas comuns em projetos Node.js/Socket.io
    if [ -f "package.json" ]; then
        # Verificar se tem socket.io
        if grep -q "socket.io" package.json; then
            echo -e "${BYellow}Verificando dependências de socket.io...${NC}"
            
            # Verificar se tem dotenv, adicionar se não tiver
            if ! grep -q "dotenv" package.json; then
                echo -e "${BYellow}Adicionando dotenv...${NC}"
                npm install --save dotenv
            fi
        fi
    fi
}

# Directory definitions
ROOTDIR=$(cd `dirname $0` && pwd -P)
REPODIR="$ROOTDIR/repositories"
BASEDIR="$ROOTDIR"
NETWORK="pratigo_net"

# Check if config.env exists
if [ ! -f "$ROOTDIR/config.env" ]; then
    echo -e "${BYellow}Config file not found. Please create config.env file to start.${NC}"
    exit 1
fi

# Clean up services directory if it exists
if [ -d "$ROOTDIR/services" ]; then 
    echo -e "${BYellow}Cleaning up services directory...${NC}"
    rm -Rf $ROOTDIR/services
fi

# Função para instalar dependências do sistema
install_system_dependencies() {
    echo -e "${BYellow}Verificando e instalando dependências do sistema...${NC}"
    
    # Verificar se o Homebrew está instalado (macOS)
    if [[ "$(uname)" == "Darwin" ]] && ! command -v brew >/dev/null 2>&1; then
        echo -e "${BYellow}Instalando Homebrew...${NC}"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    
    # Instalar jq
    if ! command -v jq >/dev/null 2>&1; then
        echo -e "${BYellow}jq não está instalado. Tentando instalar...${NC}"
        if command -v brew >/dev/null 2>&1; then
            brew install jq
        elif command -v apt-get >/dev/null 2>&1; then
            sudo apt-get update && sudo apt-get install -y jq
        elif command -v yum >/dev/null 2>&1; then
            sudo yum install -y jq
        else
            echo -e "${BRed}Não foi possível instalar jq automaticamente.${NC}"
        fi
    fi
    
    # Instalar NVM se não estiver instalado
    if ! command -v nvm >/dev/null 2>&1; then
        echo -e "${BYellow}NVM não está instalado. Tentando instalar...${NC}"
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
        
        # Carregar NVM
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
        [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
        
        # Verificar se NVM foi instalado corretamente
        if ! command -v nvm >/dev/null 2>&1; then
            echo -e "${BRed}Falha ao instalar NVM. Você precisará instalá-lo manualmente.${NC}"
            echo -e "${BYellow}Visite https://github.com/nvm-sh/nvm para instruções.${NC}"
        else
            echo -e "${BGreen}NVM instalado com sucesso!${NC}"
        fi
    fi
    
    # Instalar Node.js 12 se não estiver instalado
    if command -v nvm >/dev/null 2>&1; then
        if ! nvm ls 12 | grep -q "v12"; then
            echo -e "${BYellow}Instalando Node.js 12 para o repositório PWA...${NC}"
            nvm install 12
        fi
    fi
    
    # Instalar Composer se não estiver instalado
    if ! command -v composer >/dev/null 2>&1; then
        echo -e "${BYellow}Composer não está instalado. Tentando instalar...${NC}"
        
        if command -v php >/dev/null 2>&1; then
            # Verificar se o PHP está instalado
            php_version=$(php -v | head -n 1 | cut -d' ' -f2 | cut -d'.' -f1)
            
            # Instalar Composer
            EXPECTED_CHECKSUM="$(curl -s https://composer.github.io/installer.sig)"
            php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
            ACTUAL_CHECKSUM="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"
            
            if [ "$EXPECTED_CHECKSUM" != "$ACTUAL_CHECKSUM" ]; then
                echo -e "${BRed}Falha na verificação do instalador do Composer: Checksums inválidos${NC}"
                rm composer-setup.php
            else
                php composer-setup.php --quiet
                rm composer-setup.php
                
                # Mover para um local no PATH
                if [ -d "/usr/local/bin" ] && [ -w "/usr/local/bin" ]; then
                    mv composer.phar /usr/local/bin/composer
                elif [ -d "$HOME/.local/bin" ]; then
                    mkdir -p "$HOME/.local/bin"
                    mv composer.phar "$HOME/.local/bin/composer"
                    export PATH="$HOME/.local/bin:$PATH"
                else
                    # Mover para o diretório atual e criar um alias
                    chmod +x composer.phar
                    alias composer="./composer.phar"
                fi
                
                echo -e "${BGreen}Composer instalado com sucesso!${NC}"
            fi
        else
            echo -e "${BRed}PHP não está instalado. Não é possível instalar o Composer.${NC}"
            echo -e "${BYellow}Por favor, instale o PHP primeiro: https://www.php.net/downloads${NC}"
        fi
    fi
}

# Verificar e instalar dependências necessárias
echo -e "${BYellow}Verificando dependências necessárias...${NC}"
install_system_dependencies

# Create Docker network if it doesn't exist
echo -e "${BYellow}Setting up Docker network...${NC}"
NetworkExternalExist=$(docker network inspect $(docker network ls -q) | grep "$NETWORK") 
if [[ -z ${NetworkExternalExist} ]]; then
    docker network create $NETWORK &>/dev/null
    echo -e "${BGreen}Network "$NETWORK" created${NC}"
else
    echo -e "${BGreen}Network "$NETWORK" already exists${NC}"
fi

# Check if network gateway is available
NETWORK_GATEWAY=$(docker network inspect --format='{{(index .IPAM.Config 0).Gateway}}' "$NETWORK")
if [[ -z ${NETWORK_GATEWAY} ]]; then
    echo -e "${BRed}Gateway not detected${NC}"
    exit 1
fi

# Load environment variables
echo -e "${BYellow}Loading environment variables...${NC}"
set -o nounset -o pipefail -o errexit
set -o allexport
source "$ROOTDIR/config.env"
[ -z "$BASEDIR" ] && BASEDIR="$ROOTDIR" && echo "BASEDIR=$BASEDIR" >> "$ROOTDIR/config.env"
[ -z "$REPODIR" ] && REPODIR="$ROOTDIR/repositories" && echo "REPODIR=$REPODIR" >> "$ROOTDIR/config.env"
set +o allexport

# Create repositories directory if it doesn't exist
if [ ! -d "$REPODIR" ]; then
    echo -e "${BYellow}Creating repositories directory...${NC}"
    mkdir -p "$REPODIR"
fi

# Configure git safe directories
echo -e "${BYellow}Configuring git safe directories...${NC}"
git config --global --add safe.directory $REPODIR/api
git config --global --add safe.directory $REPODIR/gestor
git config --global --add safe.directory $REPODIR/pwa
git config --global --add safe.directory $REPODIR/socket

# Limpar modificações locais nos repositórios se existirem
# API
if [ -d "$REPODIR/api" ] && [ -d "$REPODIR/api/.git" ]; then
    echo -e "${BYellow}Cleaning local modifications in API repository...${NC}"
    cd "$REPODIR/api"
    git reset --hard HEAD
    git clean -fd
    cd "$ROOTDIR"
fi

# Socket
if [ -d "$REPODIR/socket" ] && [ -d "$REPODIR/socket/.git" ]; then
    echo -e "${BYellow}Cleaning local modifications in Socket repository...${NC}"
    cd "$REPODIR/socket"
    git reset --hard HEAD
    git clean -fd
    cd "$ROOTDIR"
fi

# Run Ansible to clone/update repositories
echo -e "${BYellow}Running Ansible to clone/update repositories...${NC}"
ansible-playbook "$(dirname $0)/ansible/playbook.yml"

# Variável para armazenar a versão original do Node.js
ORIGINAL_NODE_VERSION=""

# Função para salvar a versão atual do Node.js
save_node_version() {
    if command -v node >/dev/null 2>&1; then
        ORIGINAL_NODE_VERSION=$(node -v)
        echo -e "${BBlue}Versão atual do Node.js: $ORIGINAL_NODE_VERSION${NC}"
    fi
}

# Função para restaurar a versão original do Node.js
restore_node_version() {
    if [ -n "$ORIGINAL_NODE_VERSION" ] && command -v nvm >/dev/null 2>&1; then
        echo -e "${BYellow}Restaurando Node.js para a versão original: $ORIGINAL_NODE_VERSION${NC}"
        nvm use $(echo $ORIGINAL_NODE_VERSION | sed 's/v//')
    fi
}

# Salvar a versão atual do Node.js antes de começar
save_node_version

# Função para instalar dependências de um repositório
install_dependencies_for_repo() {
    local repo=$1
    local repo_dir="$REPODIR/$repo"
    
    echo -e "${BYellow}Installing dependencies for $repo...${NC}"
    
    if [ ! -d "$repo_dir" ]; then
        echo -e "${BRed}Repository directory $repo_dir does not exist. Skipping...${NC}"
        return 1
    fi
    
    cd "$repo_dir" || return 1
    
    # Executar diagnóstico e correções específicas para o repositório
    diagnose_and_fix "$repo"
    
    # Para o repositório PWA, usar Node.js 12
    if [ "$repo" = "pwa" ]; then
        # Verificar se o NVM está disponível
        if command -v nvm >/dev/null 2>&1 || [ -s "$HOME/.nvm/nvm.sh" ]; then
            # Se NVM existe mas não está carregado, carregá-lo
            if ! command -v nvm >/dev/null 2>&1 && [ -s "$HOME/.nvm/nvm.sh" ]; then
                echo -e "${BYellow}Carregando NVM...${NC}"
                export NVM_DIR="$HOME/.nvm"
                [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
                [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
            fi
            
            # Salvar a versão atual do Node.js
            original_node_version=$(node -v 2>/dev/null || echo "v0.0.0")
            echo -e "${BYellow}Versão atual do Node.js: $original_node_version${NC}"
            echo -e "${BYellow}Mudando temporariamente para Node.js v12...${NC}"
            
            # Verificar se Node.js 12 está instalado
            if ! nvm ls 12 | grep -q "v12"; then
                echo -e "${BYellow}Node.js 12 não está instalado. Instalando...${NC}"
                nvm install 12
            fi
            
            # Usar Node.js 12
            nvm use 12
            
            # Continuar com a instalação
            echo -e "${BYellow}Usando Node.js $(node -v) para instalar dependências do PWA...${NC}"
            
            # Lembrar de voltar para a versão original depois
            RETURN_TO_NODE_VERSION="$original_node_version"
        fi
    fi
    
    # Verificar se o package.json existe antes de tentar instalar
    if [ -f "package.json" ]; then
        # Fazer backup do package.json antes de qualquer modificação
        cp package.json package.json.bak 2>/dev/null
        
        # Limpar cache do npm
        echo -e "${BYellow}Cleaning npm cache...${NC}"
        npm cache clean --force
        
        # Instalar dependências
        echo -e "${BYellow}Installing npm dependencies...${NC}"
        npm install --legacy-peer-deps --force
        INSTALL_STATUS=$?
        
        # Verificar se a instalação foi bem-sucedida
        if [ $INSTALL_STATUS -eq 0 ]; then
            echo -e "${BGreen}Successfully installed dependencies for $repo${NC}"
        else
            echo -e "${BYellow}First attempt failed. Trying fixes...${NC}"
            
            # Tentativa de correção 1: Remover node_modules e package-lock.json
            echo -e "${BYellow}Removing node_modules and package-lock.json...${NC}"
            rm -rf node_modules package-lock.json
            
            # Tentativa de correção 2: Limpar cache do npm novamente
            echo -e "${BYellow}Cleaning npm cache again...${NC}"
            npm cache clean -f
            npm cache verify
            
            # Tentativa de correção 3: Reinstalar com --no-package-lock
            echo -e "${BYellow}Reinstalling dependencies with --no-package-lock...${NC}"
            npm install --legacy-peer-deps --force --no-package-lock
            INSTALL_STATUS=$?
            
            if [ $INSTALL_STATUS -eq 0 ]; then
                echo -e "${BGreen}Successfully installed dependencies for $repo after fixes${NC}"
            else
                # Tentativa de correção 4: Usar yarn se disponível
                if command -v yarn >/dev/null 2>&1; then
                    echo -e "${BYellow}Trying with yarn instead...${NC}"
                    yarn install --force
                    INSTALL_STATUS=$?
                    
                    if [ $INSTALL_STATUS -eq 0 ]; then
                        echo -e "${BGreen}Successfully installed dependencies using yarn for $repo${NC}"
                    else
                        echo -e "${BRed}Failed to install dependencies for $repo with yarn${NC}"
                    fi
                else
                    echo -e "${BRed}Failed to install dependencies for $repo after multiple attempts${NC}"
                fi
                
                if [ $INSTALL_STATUS -ne 0 ]; then
                    echo -e "${BYellow}You may need to fix this repository manually${NC}"
                    
                    # Registrar o erro em um arquivo de log com detalhes
                    echo "[$(date)] Failed to install dependencies for $repo" >> "$ROOTDIR/install-errors.log"
                    echo "Node version: $(node -v)" >> "$ROOTDIR/install-errors.log"
                    echo "NPM version: $(npm -v)" >> "$ROOTDIR/install-errors.log"
                    
                    # Salvar o último erro em um arquivo separado para referência
                    echo -e "${BYellow}Saving last error log to $ROOTDIR/errors-$repo.log${NC}"
                    npm install --legacy-peer-deps --force 2> "$ROOTDIR/errors-$repo.log"
                fi
            fi
        fi
    else
        echo -e "${BYellow}No package.json found in $repo, skipping npm install${NC}"
    fi
    
    # Se for o PWA, restaurar a versão original do Node.js
    if [ "$repo" = "pwa" ] && [ -n "$RETURN_TO_NODE_VERSION" ] && command -v nvm >/dev/null 2>&1; then
        echo -e "${BYellow}Restaurando Node.js para a versão original: $RETURN_TO_NODE_VERSION${NC}"
        nvm use "$(echo $RETURN_TO_NODE_VERSION | sed 's/v//')" || nvm use default
    fi
    
    # Voltar para o diretório raiz
    cd "$ROOTDIR"
}

# Install dependencies for each repository
repositories=("api" "gestor" "pwa" "socket")
echo -e "${BYellow}Installing dependencies for repositories...${NC}"

for repo in "${repositories[@]}"; do
    # Usar a nova função para instalar dependências
    install_dependencies_for_repo "$repo"
done

# Garantir que estamos usando a versão original do Node.js no final
restore_node_version

# Verificar se houve erros durante a instalação
if [ -f "$ROOTDIR/install-errors.log" ]; then
    echo -e "${BYellow}Foram encontrados alguns erros durante a instalação. Verifique o arquivo $ROOTDIR/install-errors.log para mais detalhes.${NC}"
    echo -e "${BYellow}Você pode precisar corrigir manualmente alguns repositórios.${NC}"
fi

echo -e "${BGreen}Preparation complete!${NC}"
echo -e "${BYellow}Next step: Run '2-install-base.sh' to install base services${NC}"

# Exibir resumo da instalação
echo -e "\n${BBlue}=== Resumo da Instalação ===${NC}"
echo -e "${BYellow}Repositórios processados:${NC}"
for repo in "${repositories[@]}"; do
    if [ -d "$REPODIR/$repo" ]; then
        if [ -f "$ROOTDIR/errors-$repo.log" ]; then
            echo -e "  - $repo: ${BRed}Com erros${NC}"
        else
            echo -e "  - $repo: ${BGreen}OK${NC}"
        fi
    else
        echo -e "  - $repo: ${BYellow}Não encontrado${NC}"
    fi
done
