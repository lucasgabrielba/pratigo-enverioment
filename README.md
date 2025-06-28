# Configuração do Repositório AgileOS Environment

Este guia irá orientá-lo na configuração do repositório `agileos-environment` para o ambiente AgileOS. O repositório `agileos-environment` é usado para configurar o ambiente de desenvolvimento e inclui informações sensíveis que não devem ser compartilhadas publicamente, como tokens de acesso e informações de rede.

## Pré-requisitos

Antes de começar, certifique-se de ter as seguintes informações e ferramentas disponíveis:

1. Uma conta no GitHub.

2. Um token pessoal do GitHub para autenticação.

3. Possui Docker e Docker Compose instalados.

## Passos para Configuração

Siga estas etapas para configurar o repositório `agileos-environment`:

### 1. Clone o Repositório

Clone o repositório `agileos-environment` em seu sistema local:

```bash
git clone https://github.com/lucasgabrielba/agileos-environment.git
```

### 2. Configure o arquivo `config.env`

No diretório do repositório `agileos-environment`, você encontrará um arquivo chamado `config.example.txt`. Este arquivo contém configurações de exemplo que você deve personalizar para o seu ambiente. Renomeie o arquivo `config.example.txt` para `config.env`:

```bash
mv config.example.txt config.env
```

Agora, edite o arquivo `config.env` com um editor de texto para adicionar as informações corretas.

### 3. Adicione as Informações da Env

No arquivo `config.env`, você deve adicionar as seguintes informações:

```dotenv
NETWORK=agileos_net
NETWORK_GATEWAY=172.27.0.1
GITHUB_TOKEN=<SEU_TOKEN_DO_GITHUB>
BASEDIR=/caminho/para/o/diretorio/base
REPODIR=/caminho/para/o/diretorio/do/repo
```

Substitua `<SEU_TOKEN_DO_GITHUB>` pelo seu token pessoal do GitHub.

- `NETWORK`: O nome da rede utilizada pelo ambiente AgileOS no docker.
- `NETWORK_GATEWAY`: O endereço IP da gateway da rede docker.
- `GITHUB_TOKEN`: Seu token pessoal do GitHub usado para autenticação.
- `BASEDIR`: O caminho para o diretório base em seu sistema local.
- `REPODIR`: O caminho para o diretório do repositório `agileos-environment` em seu sistema local.

Certifique-se de que todas as informações estão corretas e que você não compartilhe o arquivo `config.env` publicamente, pois ele contém informações sensíveis.

### 4. Salve e Feche o Arquivo `config.env`

Depois de adicionar todas as informações necessárias, salve e feche o arquivo `config.env`.

Agora, o repositório `agileos-environment` está configurado corretamente para o seu ambiente AgileOS.

Lembre-se de nunca compartilhar seu token do GitHub ou informações sensíveis publicamente. Mantenha o arquivo `config.env` seguro e restrito apenas ao ambiente de desenvolvimento.

Claro, vou adicionar as instruções para os comandos que o usuário deve executar após configurar o arquivo `config.env`. Aqui estão os comandos completos e uma explicação de cada um:

### 5. Prepare o Ambiente

O primeiro comando é responsável por preparar o ambiente para a execução do AgileOS. Ele configura a rede Docker e cria alguns diretórios necessários. Execute o seguinte comando:

```bash
./1-prepare.sh
```

### 6. Suba os Contêineres

Este comando inicializa todos os contêineres necessários para o ambiente de desenvolvimento:

```bash
./2-install-base.sh
```

### 7. Pare os Contêineres

Para interromper os contêineres em execução, utilize:

```bash
./5-stop-base-containers.sh
```

### 8. Remova os Contêineres

Caso deseje remover completamente os contêineres criados, execute:

```bash
./7-remove-base-containers.sh
```

Lembre-se de executar esses comandos na ordem apropriada, dependendo do que você deseja fazer com o ambiente AgileOS. Certifique-se de que o arquivo `config.env` esteja configurado corretamente antes de executar esses comandos, pois eles dependem das informações especificadas no arquivo de configuração.

## Considerações Finais

A configuração do repositório `agileos-environment` é uma etapa importante para configurar um ambiente de desenvolvimento adequado para o AgileOS. Certifique-se de seguir este guia com cuidado e proteger suas informações sensíveis.
# pratigo-enverioment
