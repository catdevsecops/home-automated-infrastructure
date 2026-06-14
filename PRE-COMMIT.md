# Pre-Commit Hooks

Este projeto utiliza **pre-commit** para automatizar validações antes de fazer commit no Git. Todas as validações são executadas no repositório local antes do commit ser criado.

## 🎯 O que é Validado

### Terraform

#### 1. **terraform_validate**
- Valida sintaxe de todos os arquivos `.tf`
- Verifica se os recursos são válidos
- Executa em: `terraform/`

#### 2. **terraform_fmt**
- Formata automaticamente arquivos Terraform
- Aplica estilo consistente
- Formata recursivamente todo o diretório `terraform/`
- **Modifica arquivos automaticamente**

#### 3. **terraform_docs**
- Gera documentação automática dos módulos Terraform
- Atualiza `README.md` em cada módulo
- Executa em: `terraform/`

#### 4. **terraform_tflint**
- Lint de Terraform com regras avançadas
- Detecta erros de estilo e boas práticas
- Usa arquivo `.tflint.hcl` para configuração
- Verifica:
  - Nomeação de variáveis (snake_case)
  - Declarações não utilizadas
  - Documentação de variáveis e outputs
  - Comprimento máximo de linhas (120 caracteres)
  - Tags obrigatórias em recursos

#### 5. **tflint (explícito)**
- Ferramenta TFLint para linting avançado
- Configurado via `.tflint.hcl`
- Executa em todos os arquivos `.tf`

### Segurança

#### 6. **trivy**
- Escaneamento de segurança com Trivy
- Detecta vulnerabilidades em Infrastructure as Code:
  - Configurações inseguras de IAM
  - S3 buckets públicos
  - Banco de dados sem criptografia
  - Falta de tags obrigatórias
  - Acesso não restringido
  - Vulnerabilidades conhecidas em dependências
- Executa em: `terraform/` e `k8s/` (YAML)

### Validação Geral

#### 8. **yamllint**
- Valida sintaxe YAML
- Aplica estilo consistente
- Configurado via `.yamllint.yaml`
- Exclui: `.terraform/`, arquivos ocultos

#### 8. **detect-secrets**
- Detecta secrets acidentalmente commitados
- Procura por padrões: API keys, tokens, passwords
- Usa baseline `.secrets.baseline`

#### 9. **Hooks Padrão**
- `trailing-whitespace` - Remove espaços em branco no final de linhas
- `end-of-file-fixer` - Adiciona newline no final de arquivos
- `check-yaml` - Valida YAML
- `check-json` - Valida JSON
- `check-added-large-files` - Bloqueia arquivos > 1MB
- `check-merge-conflict` - Detecta conflitos de merge não resolvidos
- `check-case-conflict` - Detecta conflitos de case em nomes de arquivo

### Commits

#### 10. **commitizen**
- Valida mensagem de commit
- Força uso de Conventional Commits
- Formato: `type(scope): message`
- Tipos: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `chore`

## 📦 Instalação

### Pré-requisitos

```bash
# Python 3.8+ e pip
python3 --version
pip3 --version

# Git
git --version
```

### Setup Inicial

```bash
# 1. Instalar pre-commit
pip3 install pre-commit

# 2. Instalar os hooks
pre-commit install
pre-commit install --hook-type commit-msg

# 3. (Opcional) Rodar em todos os arquivos
pre-commit run --all-files
```

## 🚀 Uso

### Executar Automaticamente (ao fazer commit)

```bash
git add .
git commit -m "feat(terraform): add new resource"
# Pre-commit executará automaticamente
```

### Executar Manualmente

```bash
# Rodar em todos os arquivos
pre-commit run --all-files

# Rodar apenas no Terraform
pre-commit run --all-files -- terraform/

# Rodar um hook específico
pre-commit run terraform_fmt --all-files
pre-commit run trivy --all-files
pre-commit run tflint --all-files
```

### Skip de Hooks (use com cuidado)

```bash
# Pular um hook específico (não recomendado)
SKIP=trivy git commit -m "feat: commit sem trivy"

# Pular todos os hooks (não recomendado)
git commit --no-verify -m "feat: bypass all hooks"
```

## 📋 Fluxo Típico

```
1. Editar arquivos em terraform/
   ↓
2. git add .
   ↓
3. git commit -m "feat(terraform/...): descrição"
   ↓
4. Pre-commit hooks executam:
   - terraform_fmt (formata automaticamente)
   - terraform_validate (valida sintaxe)
   - terraform_tflint (verifica estilo)
   - trivy (verifica segurança)
   - detect-secrets (detecta secrets)
   - commitizen (valida mensagem)
   ↓
5. Se houver erros:
   - Fix automático (terraform_fmt, trailing-whitespace)
   - Erros que precisam correção manual (checkov, tflint)
   - Re-run: git add . && git commit
   ↓
6. Se tudo passar:
   ✅ Commit criado com sucesso
```

## 🔍 Exemplos de Erros Comuns

### Erro: Trivy detectou security issue

```
Trivy found security issues:
  AVD-AZU-0001: Ensure IAM policies are not too permissive
  File: terraform/us-east-2/ssm/main.tf:15-25
  Severity: HIGH
```

**Solução:** Restringir permissões no arquivo Terraform:
```hcl
# ❌ ERRADO
statement {
  actions   = ["*"]
  resources = ["*"]
}

# ✅ CORRETO
statement {
  actions   = ["ssm:GetParameter", "ssm:GetParameters"]
  resources = ["arn:aws:ssm:*:*:parameter/prod/*"]
}
```

### Erro: TFLint detectou violation

```
Error: terraform_naming_convention: variable `var_name` should be `var_name` (snake_case)
  on terraform/bootstrap/cluster/variables.tf:5
```

**Solução:** Renomear variável para snake_case:
```hcl
# ❌ ERRADO
variable "varName" { }

# ✅ CORRETO
variable "var_name" { }
```

### Erro: Detectado secret

```
Detected secrets in staged files
File: terraform/bootstrap/machines/terraform.tfvars
Secret pattern: AWS_ACCESS_KEY_ID detected
```

**Solução:** Remover secret e usar AWS SSM Parameter Store:
```hcl
# ❌ ERRADO
access_key = "AKIAIOSFODNN7EXAMPLE"

# ✅ CORRETO
data "aws_ssm_parameter" "api_key" {
  name = "/prod/api-key"
}
```

### Erro: Mensagem de commit inválida

```
Error: commit message doesn't follow Conventional Commits format
Expected format: type(scope): message
Got: "update terraform files"
```

**Solução:** Usar formato correto:
```bash
# ❌ ERRADO
git commit -m "update terraform files"

# ✅ CORRETO
git commit -m "feat(terraform/bootstrap): add talos configuration"
git commit -m "fix(terraform/us-east-2): restrict IAM permissions"
git commit -m "docs(terraform): update README"
```

## ⚙️ Configuração

### Modificar Regras TFLint

Editar `.tflint.hcl`:
```hcl
# Desabilitar uma regra
rule "terraform_workspace_remote" {
  enabled = false
}

# Modificar comportamento
rule "terraform_max_line_length" {
  enabled = true
  length  = 150  # aumentar de 120 para 150
}
```

### Configurar Trivy

Trivy pode ser configurado via arquivo `.trivy.yaml` na raiz do projeto:
```yaml
# .trivy.yaml
severity:
  - HIGH
  - CRITICAL
exit-code: 1
ignore-file: .trivyignore
```

Ou adicionar flags customizadas no `.pre-commit-config.yaml` editando o `entry`:
```yaml
- id: trivy-terraform
  name: trivy - Terraform security scan
  entry: trivy config --severity HIGH,CRITICAL terraform/
  language: system
  always_run: true
  pass_filenames: false
  stages: [commit]
```

Para ignorar certos problemas, crie um arquivo `.trivyignore`:
```
# .trivyignore
AVD-AZU-0001  # Ignorar specific vulnerability
```

### Modificar Regras YAML

Editar `.yamllint.yaml`:
```yaml
rules:
  line-length:
    max: 120
    level: error
```

## 🔄 Atualizar Hooks

```bash
# Atualizar para versões mais recentes
pre-commit autoupdate

# Verificar versões instaladas
pre-commit --version
pre-commit-terraform --version
```

## 📚 Recursos Úteis

- [Pre-commit Framework](https://pre-commit.com/)
- [Pre-commit Terraform by antonbabenko](https://github.com/antonbabenko/pre-commit-terraform)
- [TFLint Documentation](https://github.com/terraform-linters/tflint)
- [Trivy Documentation](https://aquasecurity.github.io/trivy/)
- [Conventional Commits](https://www.conventionalcommits.org/)

## 🚨 Troubleshooting

### Pre-commit não está rodando

```bash
# Verificar se está instalado
pre-commit --version

# Reinstalar hooks
pre-commit install
pre-commit install --hook-type commit-msg

# Verificar arquivo .git/hooks/
ls -la .git/hooks/
```

### Erro: "command not found: terraform"

```bash
# Instalar Terraform
brew install terraform  # macOS
apt-get install terraform  # Linux
choco install terraform  # Windows
```

### Erro: "command not found: tflint"

```bash
# Instalar TFLint
brew install tflint  # macOS
# Ou via pre-commit (automático)
pre-commit run tflint --all-files
```

### Erro: "command not found: trivy"

```bash
# Instalar Trivy (recomendado)
# macOS
brew install trivy

# Linux
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | apt-key add -
echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/trivy.list
apt-get update && apt-get install trivy

# Ou deixar pre-commit instalar via sistema
pre-commit run trivy --all-files
```

## 💡 Dicas

1. **Rodar pre-commit em CI/CD:** Adicionar no GitHub Actions
2. **Ignorar um arquivo:** Adicionar em `excluded-paths` nos configs
3. **Desabilitar temporariamente:** `git commit --no-verify` (use com cuidado)
4. **Entender erros:** Ler mensagens com atenção, elas indicam exatamente o problema
5. **Auto-fix quando possível:** Deixar pre-commit corrigir automaticamente (terraform_fmt, etc)
