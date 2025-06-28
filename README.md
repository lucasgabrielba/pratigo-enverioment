# Pratigo Environment

Este repositório prepara um ambiente de desenvolvimento para o conjunto de aplicações Pratigo utilizando Docker. Os scripts automatizam a criação da rede, o clone dos projetos e a inicialização dos serviços.

## Pré-requisitos

- Docker e Docker Compose instalados;
- Token de acesso ao GitLab (necessário para clonar os repositórios privados);
- Node.js com npm ou pnpm para instalação das dependências.

## Configuração do ambiente

1. Clone este repositório.
2. Copie o arquivo `.env` para `config.env` e edite os valores conforme o seu ambiente:

```dotenv
NETWORK=agileos_net
NETWORK_GATEWAY=172.27.0.1
GITLAB_TOKEN=<SEU_TOKEN_DO_GITLAB>
GITLAB_API_AUTH=<TOKEN_API_OPCIONAL>
BASEDIR=/caminho/para/o/diretorio/base
REPODIR=/caminho/para/o/diretorio/repositories
```

- `NETWORK` e `NETWORK_GATEWAY` definem a rede Docker usada pelos contêineres.
- `GITLAB_TOKEN` é utilizado pelo Ansible para clonar os projetos do Pratigo.
- `GITLAB_API_AUTH` é repassado ao container da API.
- `BASEDIR` representa o diretório raiz do ambiente.
- `REPODIR` indica onde os repositórios clonados serão armazenados.

## Utilização dos scripts

1. **Preparar o ambiente**

   ```bash
   ./1-prepare.sh
   ```

   Este script cria a rede, clona os repositórios (API, Gestor, PWA e Socket) e instala as dependências de cada projeto.

2. **Subir os serviços**

   ```bash
   ./2-install-base.sh
   ```

   Inicializa todos os contêineres definidos em `compose/docker-compose.yml`.

3. **Parar os serviços**

   ```bash
   ./5-stop-base-containers.sh
   ```

4. **Remover os serviços**

   ```bash
   ./7-remove-base-containers.sh
   ```

Execute os scripts na ordem necessária para subir ou desmontar o ambiente.

## Estrutura do repositório

- `dockers/` contém as definições de cada serviço.
- `compose/docker-compose.yml` orquestra os serviços.
- `ansible/playbook.yml` automatiza o clone dos repositórios do Pratigo.
- Scripts `*.sh` controlam a criação, inicialização, parada e remoção dos contêineres.

Com essas etapas você terá o ambiente de desenvolvimento do Pratigo pronto para uso.
