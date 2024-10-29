#!/usr/bin/bash

# ==========================================================

# Colors
RED='\e[1;31m'
PINK='\e[1;35m'
GREEN='\e[1;32m'
BLUE='\e[1;34m'
YELLOW='\e[1;33m'
GRAY='\e[1;30m'
WHITE='\e[1;38m'
CYAN='\e[1;36m'
RESET='\e[0;0m'

function LOG {
  if [[ "DEBUG" =~ "$1" ]]; then
    echo -e "${GRAY}[DEBUG:L$3]${RESET} $2"
  elif [[ "INFO" =~ "$1" ]]; then
    echo -e "${GREEN}[INFO:L$3]${RESET} $2"
  elif [[ "WARN" =~ "$1" ]]; then
    echo -e "${YELLOW}[WARN:L$3]${RESET} $2"
  elif [[ "ERROR" =~ "$1" ]]; then
    echo -e "${RED}[ERRO:L$3]${RESET} $2"
  elif [[ "FATAL" =~ "$1" ]]; then
    echo -e "${CYAN}[FATAL:L$3]${RESET} $2"
  fi
}

function LEITURA() {
  read -rp $''"$1"$'\E\n\e[1;36m[\e[1;33m>\e[1;36m]\e[0;0m ' INPUT
  echo -e "$INPUT\n"
}

# ==========================================================
# ==== ALTERE AQUI ===== ALTERE AQUI ===== ALTERE AQUI =====

# Exemplo para testes oi simulação (Windows com gitbash) FUCK MICROSOFT!:
# > Caso em linux basta utilizar a variável $PWD ao inves desta gambiarra
# diretorio_base_fullpath="$(cygpath.exe -m $PWD)/alunos"
# git_config_padrao_fullpath="$(cygpath.exe -m $PWD)/.gitconfig"
# ssh_pasta_padrao_fullpath="$(cygpath.exe -m $PWD)/.ssh"

# Exemplo para ambiente de produção (Windows com gitbash) FUCK MICROSOFT!:
# > Caso em linux basta utilizar a variável $HOME ao inves desta gambiarra
diretorio_base_fullpath="$(cygpath.exe -m $USERPROFILE)/documents/alunos"
git_config_padrao_fullpath="$(cygpath.exe -m $USERPROFILE)/.gitconfig"
ssh_pasta_padrao_fullpath="$(cygpath.exe -m $USERPROFILE)/.ssh"

# ==========================================================

git_config_padrao_template="
[http]
  proxy = \"http://Incode:2VD29%40inc@proxy.ceuma.edu.br:3128\"

[credential \"http://proxy.ceuma.edu.br:3128\"]
  provider = generic

[safe]
  directory = *
"
ssh_config_padrao_template="
AddKeysToAgent yes
"

ssh_config_padrao_fullpath="$ssh_pasta_padrao_fullpath/config"

# ==========================================================

while true; do
  primeiro_nome=$(LEITURA "Digite o seu primeiro nome (Nome)")
  [[ -z ${primeiro_nome} ]] && LOG "ERRO" "A entrada não pode ser vazia\n" $LINENO || break;
done

while true; do
  segundo_nome=$(LEITURA "Digite o seu segundo nome (Sobrenome)")
  [[ -z ${segundo_nome} ]] && LOG "ERRO" "A entrada não pode ser vazia\n" $LINENO || break;
done

while true; do
  usuario_github=$(LEITURA "Digite o seu username no GitHub (usuario)")
  [[ -z ${usuario_github} ]] && LOG "ERRO" "A entrada não pode ser vazia\n" $LINENO || break;
done

while true; do
  regex="^(([A-Za-z0-9]+((\.|\-|\_|\+)?[A-Za-z0-9]?)*[A-Za-z0-9]+)|[A-Za-z0-9]+)@(([A-Za-z0-9]+)+((\.|\-|\_)?([A-Za-z0-9]+)+)*)+\.([A-Za-z]{2,})+$"
  email_github=$(LEITURA "Digite o seu e-mail usado no GitHub (email@dominio.prefixo)")
  [[ ${email_github} =~ ${regex} ]] && break ||
  [[ -z ${email_github} ]] && LOG "ERRO" "A entrada não pode ser vazia\n" $LINENO ||
  LOG "ERRO" "O formato do e-mail é inválido\n" $LINENO || break;
done

while true; do
  senha_chave_ssh=$(LEITURA "Digite uma senha para sua chave SSH: ")
  [[ ${#senha_chave_ssh} -gt 6 || ${#senha_chave_ssh} -eq 6 ]] && break ||
  [[ -z ${senha_chave_ssh} ]] && LOG "ERRO" "A entrada não pode ser vazia\n" ||
  LOG "ERRO" "A entrada deve ter mais de 6 caracteres\n"
done

echo -en """[1] Manhã
[2] Tarde
[3] Noite
"""

while true; do
  case $(LEITURA "Escolha um turno: ") in
    1)
      turno="Matutino";
      break;
      ;;
    2)
      turno="Vespertino";
      break;
      ;;
    3)
      turno="Noturno";
      break;
      ;;
    *)
      LOG "ERRO" "Entrada inválida\n"
      ;;
  esac
done

# ==========================================================

aluno_pasta_nome="${primeiro_nome}_${segundo_nome}_${turno:0:3}"
aluno_pasta_nome="${aluno_pasta_nome^^}"
aluno_pasta_fullpath="$diretorio_base_fullpath/$aluno_pasta_nome"

git_config_usuario_fullpath="$aluno_pasta_fullpath/.gitconfig"
git_config_usuario_template="
[user]
  name = \"$usuario_github\"
  email = $email_github

[url \"$usuario_github.github.com:\"]
  insteadOf = git@github.com:

[url \"$usuario_github.github.com:\"]
  insteadOf = https://github.com:"

git_diretiva_template="
[includeIf \"gitdir:$aluno_pasta_nome/**/\"]
  path = $git_config_usuario_fullpath
"

ssh_usuario_fullpath="$aluno_pasta_fullpath/.ssh"
ssh_usuario_config_fullpath="$ssh_usuario_fullpath/config"
ssh_usuario_chave_name="SSH_${aluno_pasta_nome}_ED25519_16"
ssh_usuario_chave_fullpath="$ssh_usuario_fullpath/$ssh_usuario_chave_name"

# ==========================================================

# 1.1
if [[ ! -f "$git_config_padrao_fullpath" ]]; then
  {
    ERR=$( echo -e "$git_config_padrao_template" > "$git_config_padrao_fullpath" 2>&1 )
    [[ -z $ERR ]] &&
    LOG "INFO" "Criado arquivo de configuração padrão git em $git_config_padrao_fullpath" $LINENO
  } || {
    LOG "FATAL" "Falha ao criar arquivo de configuração padrão git em $git_config_padrao_fullpath" $LINENO "$ERR"
    LOG "FATAL" "$ERR" $LINENO
    exit 1
  }
else
  LOG "WARN" "Arquivo de configuração padrão git já existe em $git_config_padrao_fullpath" $LINENO
fi

# 1.2
if [[ ! -d "$ssh_pasta_padrao_fullpath" ]]; then
  {
    ERR=$( mkdir -p "$ssh_pasta_padrao_fullpath" 2>&1 )
    [[ -z $ERR ]] &&
    LOG "INFO" "Pasta padrão do ssh criada em $ssh_pasta_padrao_fullpath" $LINENO
  } || {
    LOG "FATAL" "Não foi possível criar a pasta padrão do ssh em $ssh_pasta_padrao_fullpath" $LINENO "$ERR"
    LOG "FATAL" "$ERR" $LINENO
    exit 1
  }
else
  LOG "WARN" "Pasta padrão do ssh já existe em $ssh_pasta_padrao_fullpath" $LINENO
fi

# 1.3
if [[ ! -f "$ssh_config_padrao_fullpath" ]]; then
  {
    ERR=$( echo -e "$ssh_config_padrao_template" > "$ssh_config_padrao_fullpath" 2>&1 )
    [[ -z $ERR ]] &&
    LOG "INFO" "Criado arquivo de configuração padrão ssh em $ssh_config_padrao_fullpath" $LINENO
  } || {
    LOG "FATAL" "Falha ao criar arquivo de configuração padrão ssh em $ssh_config_padrao_fullpath" $LINENO "$ERR"
    LOG "FATAL" "$ERR" $LINENO
    exit 1
  }
else
  LOG "WARN" "Arquivo de configuração padrão ssh já existe em $ssh_config_padrao_fullpath" $LINENO
fi

# 1.4
if ! grep -qF "$ssh_config_padrao_template" "$ssh_config_padrao_fullpath"; then
  {
    ERR=$( echo -e "$ssh_config_padrao_template" >> "$ssh_config_padrao_fullpath" 2>&1 )
    [[ -z $ERR ]] &&
    LOG "INFO" "Adicionado configuração template ssh na configuração padrão" $LINENO
  } || {
    LOG "FATAL" "Falha ao adicionar o template ssh na configuração ssh padrão" $LINENO "$ERR"
    LOG "FATAL" "$ERR" $LINENO
    exit 1
  }
else
  LOG "WARN" "Configuração template ssh já existente na configuração padrão" $LINENO
fi

# 2.1
if [[ ! -d "$diretorio_base_fullpath" ]]; then
  {
    ERR=$( mkdir -p "$diretorio_base_fullpath" 2>&1 )
    [[ -z $ERR ]] &&
    LOG "INFO" "Pasta dos alunos criada em $diretorio_base_fullpath" $LINENO
  } || {
    LOG "FATAL" "Não foi possível criar a pasta dos alunos em $diretorio_base_fullpath" $LINENO "$ERR"
    LOG "FATAL" "$ERR" $LINENO
    exit 1
  }
else
  LOG "WARN" "Pasta dos alunos já existe em $diretorio_base_fullpath" $LINENO
fi

# 2.2
if [[ ! -d "$aluno_pasta_fullpath" ]]; then
  {
    ERR=$( mkdir -p "$aluno_pasta_fullpath" 2>&1 )
    [[ -z $ERR ]] &&
    LOG "INFO" "Pasta do aluno $primeiro_nome $segundo_nome criada em $aluno_pasta_fullpath" $LINENO
  } || {
    LOG "FATAL" "Não foi possível criar a pasta do aluno $primeiro_nome $segundo_nome em $aluno_pasta_fullpath" $LINENO "$ERR"
    LOG "FATAL" "$ERR" $LINENO
    exit 1
  }
else
  LOG "WARN" "Pasta do aluno $primeiro_nome $segundo_nome já existe em $aluno_pasta_fullpath" $LINENO
fi

# 3.1
if [[ ! -f "$git_config_usuario_fullpath" ]]; then
  {
    ERR=$( echo -e "$git_config_usuario_template" > "$git_config_usuario_fullpath" 2>&1 )
    [[ -z $ERR ]] &&
    LOG "INFO" "Arquivo de configuração git para o aluno $primeiro_nome $segundo_nome criado em $git_config_usuario_fullpath" $LINENO
  } || {
    LOG "FATAL" "Não foi possível criar o arquivo de configuração git para o aluno $primeiro_nome $segundo_nome em $git_config_usuario_fullpath" $LINENO "$ERR"
    LOG "FATAL" "$ERR" $LINENO
    exit 1
  }
else
  LOG "WARN" "Arquivo de configuração git para o aluno $primeiro_nome $segundo_nome já existe em $git_config_usuario_fullpath" $LINENO
fi

# 3.1
if ! grep -qF "$aluno_pasta_fullpath" "$git_config_padrao_fullpath"; then
  {
    ERR=$( echo -e "$git_diretiva_template" >> "$git_config_padrao_fullpath" 2>&1 )
    [[ -z $ERR ]] &&
    LOG "INFO" "Adicionado diretiva da configuração do aluno $primeiro_nome $segundo_nome na configuração padrão" $LINENO
  } || {
    LOG "FATAL" "Falha ao adicionar a diretiva de configuração do aluno $primeiro_nome $segundo_nome na configuração padrão" $LINENO "$ERR"
    LOG "FATAL" "$ERR" $LINENO
    exit 1
  }
else
  LOG "WARN" "Diretiva da configuração do aluno $primeiro_nome $segundo_nome já existente na configuração padrão" $LINENO
fi

# 4.1
if [[ ! -d "$ssh_usuario_fullpath" ]]; then
  {
    ERR=$( mkdir -p "$ssh_usuario_fullpath" 2>&1 )
    [[ -z $ERR ]] &&
    LOG "INFO" "Pasta ssh do aluno $primeiro_nome $segundo_nome criada em $ssh_usuario_fullpath" $LINENO
  } || {
    LOG "FATAL" "Não foi possível criar a pasta ssh do aluno $primeiro_nome $segundo_nome em $ssh_usuario_fullpath" $LINENO "$ERR"
    LOG "FATAL" "$ERR" $LINENO
    exit 1
  }
else
  LOG "WARN" "Pasta ssh do aluno $primeiro_nome $segundo_nome já existe em $ssh_usuario_fullpath" $LINENO
fi

# 4.2
if [[ ! -f "$ssh_usuario_config_fullpath" ]]; then
  {
    ERR=$( echo -e "" > "$ssh_usuario_config_fullpath" 2>&1 )
    [[ -z $ERR ]] &&
    LOG "INFO" "Criado arquivo de configuração base ssh para o aluno $primeiro_nome $segundo_nome em $ssh_usuario_config_fullpath" $LINENO
  } || {
    LOG "FATAL" "Não foi possível criar o arquivo de configuração base ssh para o aluno $primeiro_nome $segundo_nome em $ssh_usuario_config_fullpath" $LINENO "$ERR"
    LOG "FATAL" "$ERR" $LINENO
    exit 1
  }
else
  LOG "WARN" "Arquivo de configuração base ssh para o aluno $primeiro_nome $segundo_nome já existe em $ssh_usuario_config_fullpath" $LINENO
fi

# 4.3
if [[ ! -f "$ssh_usuario_chave_fullpath" ]]; then
  {
    ERR=$(
      ssh-keygen -a 16 -t ed25519 -C "$usuario_github <$email_github> <$primeiro_nome $segundo_nome INCODE ${turno}>" -N $senha_chave_ssh -f $ssh_usuario_chave_fullpath -q 2>&1
    )
    [[ -z $ERR ]] &&
    LOG "INFO" "Chave ssh para o aluno $primeiro_nome $segundo_nome gerada com sucesso em $ssh_usuario_chave_fullpath" $LINENO
  } || {
    LOG "FATAL" "Não foi possível gerar a chave ssh para o aluno $primeiro_nome $segundo_nome em $ssh_usuario_chave_fullpath" $LILENO "$ERR"
    LOG "FATAL" "$ERR" $LILENO
    exit 1
  }
else
  LOG "WARN" "Chave ssh do aluno $primeiro_nome $segundo_nome já existente em $ssh_usuario_chave_fullpath" $LINENO
fi

#
ssh_usuario_config_template="
Host $usuario_github.github.com
  Hostname github.com
  User git
  IdentitiesOnly yes
  IdentityFile $ssh_usuario_chave_fullpath
"

ssh_diretiva_inclusao="Include $ssh_usuario_config_fullpath"

# 5.1
if ! grep -qF "$ssh_usuario_chave_fullpath" "$ssh_usuario_config_fullpath"; then
  {
    ERR=$( echo -e "$ssh_usuario_config_template" >> "$ssh_usuario_config_fullpath" 2>&1 )
    [[ -z $ERR ]] &&
    LOG "INFO" "Adicionado configuração template ssh na configuração do aluno $primeiro_nome $segundo_nome" $LINENO
  } || {
    LOG "FATAL" "Falha ao adicionar o template ssh na configuração ssh do aluno $primeiro_nome $segundo_nome" $LINENO "$ERR"
    LOG "FATAL" "$ERR" $LINENO
    exit 1
  }
else
  LOG "WARN" "Configuração template ssh já existente na configuração do aluno $primeiro_nome $segundo_nome" $LINENO
fi

# 5.2
if ! grep -qF "$ssh_diretiva_inclusao" "$ssh_config_padrao_fullpath"; then
  {
    ERR=$( echo -e "$ssh_diretiva_inclusao" >> "$ssh_config_padrao_fullpath" 2>&1 )
    [[ -z $ERR ]] &&
    LOG "INFO" "Adicionado diretiva de configuração ssh do aluno $primeiro_nome $segundo_nome na configuração ssh padrão" $LINENO
  } || {
    LOG "FATAL" "Falha ao adicionar a diretiva de configuração ssh do aluno $primeiro_nome $segundo_nome na configuração ssh padrão" $LINENO "$ERR"
    LOG "FATAL" "$ERR" $LINENO
    exit 1
  }
else
  LOG "WARN" "Diretiva da configuração ssh do aluno $primeiro_nome $segundo_nome já existente na configuração ssh padrão" $LINENO
fi

# ==========================================================

# 6.1
if [[ ! -f "${ssh_usuario_chave_fullpath}.pass" ]]; then
  {
    ERR=$( echo "$senha_chave_ssh" > "${ssh_usuario_chave_fullpath}.pass" 2>&1 )
    [[ -z $ERR ]]
  }
fi

echo -e ""
LOG "FATAL" """
\e[7;33m
A pasta para seu perfil foi criada em $aluno_pasta_fullpath.
Para garantir uma melhor organização e que todas as suas configurações personalizadas sejam aplicadas
corretamente, recomenda-se mover seus repositórios e projetos para esta pasta. Dessa forma, todos os seus
projetos utilizarão as configurações específicas que você atribuir para o Git.

Foi gerada uma par de chaves (publica e privada) SSH em $ssh_usuario_fullpath.
Esta chave será utilizada para autenticar as suas operações Git no GitHub. Por segurança, é recomendado que você guarde
uma cópia segura dessa chave e, em seguida, remova o arquivo original.

Também é possível definir outra senha para a proteção da sua chave. Para saber como adicionar ou alterar
uma frase secreta, consulte o link abaixo:
https://docs.github.com/pt/authentication/connecting-to-github-with-ssh/working-with-ssh-key-passphrases#adding-or-changing-a-passphrase

Para adicionar essa chave SSH à sua conta do GitHub, siga as instruções no link:
https://docs.github.com/pt/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account${RESET}""" $LINENO
