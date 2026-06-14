# GitHub Actions Workflows

Este projeto utiliza GitHub Actions para automatizar validações e testes. Este documento descreve os workflows disponíveis.

## 📋 Workflows Disponíveis

### 1. Pre-Commit Validation (`pre-commit.yml`)

Executa validações do pre-commit em todas as PRs que modificam arquivos relevantes.

**Triggers:**
- `pull_request` no branch `main`
- Tipos: opened, synchronize, reopened

**O que faz:**
1. Faz checkout do código
2. Instala dependências:
   - Python 3.11
   - Terraform 1.14.8
   - TFLint
   - Trivy
   - Pre-commit
3. Executa pre-commit nos arquivos modificados
4. Comenta na PR com resultado (sucesso ou falha)

**Hooks Executados:**
- `terraform_fmt` - Formata Terraform
- `terraform_validate` - Valida sintaxe
- `terraform_tflint` - Lint de boas práticas
- `trivy-terraform` - Segurança (Terraform)
- `trivy-kubernetes` - Segurança (Kubernetes)
- `detect-secrets` - Detecta secrets acidentais
- Validações padrão (YAML, JSON, trailing whitespace, etc)

**Resultados:**
- ✅ Se tudo passar: Nenhum comentário (ou comentário removido)
- ❌ Se falhar: Comenta com detalhes do erro e instruções de correção

### 2. Pre-Commit with Reviewdog (`pre-commit-reviewdog.yml`)

Workflow avançado que fornece feedback mais detalhado nas PRs.

**Triggers:**
- `pull_request` no branch `main`
- Apenas quando há mudanças em:
  - `terraform/**/*.tf`
  - `k8s/**/*.yaml`
  - `k8s/**/*.yml`
  - `.pre-commit-config.yaml`
  - `.tflint.hcl`
  - `.github/workflows/**`

**Diferenças do primeiro workflow:**
- Mais eficiente (roda apenas quando necessário)
- Comentários mais detalhados com exemplos de output
- Instruções step-by-step para correção local

**Resultados:**
- ✅ Sucesso: "All checks passed! ✨"
- ❌ Falha: Mostra output dos hooks + instruções de correção

### 3. Release (`release.yml`)

Publicada com release tags (v*.*.*)

**O que faz:**
- Faz setup do Terraform
- Configura credenciais AWS
- Gera release artifacts
- Faz upload no GitHub Releases

## 🚀 Como Usar

### Executar Localmente

Antes de fazer uma PR, execute localmente:

```bash
# Instalar dependências
pre-commit install
pip install pre-commit

# Rodar em todos os arquivos
pre-commit run --all-files

# Ou apenas nos arquivos modificados
pre-commit run --files terraform/bootstrap/cluster/main.tf
```

### Entender Erros na PR

Quando o workflow falhar, você verá um comentário como:

```
❌ Pre-Commit Validation Failed

Please check the workflow logs for details: [123456789](...)

Common Issues:
- Run `pre-commit run --all-files` locally to fix formatting issues
- Check for trailing whitespace and line endings
...
```

**Para resolver:**

1. Clique no link do workflow para ver detalhes completos
2. Revise os erros na saída
3. Execute localmente: `pre-commit run --all-files`
4. Corrija os erros (muitos são automáticos)
5. Commit e push novamente

### Configurar Proteção de Branch

Para forçar que todas as PRs passem pelo pre-commit:

1. Vá para: **Settings → Branches → Branch protection rules**
2. Selecione `main`
3. Ative: **"Require status checks to pass before merging"**
4. Procure por: `Pre-Commit Validation` e `Pre-Commit Checks with Reviewdog`
5. Selecione ambos
6. Salve

## 🔧 Customizações

### Modificar Triggers

Para rodar em branches específicos, edite o workflow:

```yaml
on:
  pull_request:
    branches:
      - main
      - develop  # Adicionar outro branch
```

### Adicionar Mais Dependências

Se precisar instalar algo além do padrão, adicione no step "Install [Tool]":

```yaml
- name: Install Custom Tool
  run: |
    curl -fsSL https://example.com/install.sh | bash
```

### Ignorar Certos Arquivos

Se houver arquivos que não devem passar por pre-commit, adicione em `.pre-commit-config.yaml`:

```yaml
- id: terraform_fmt
  exclude: ^terraform/old-stuff/
```

### Configurar Severidade Trivy

Para apenas falhar em vulnerabilidades críticas:

```yaml
- id: trivy-terraform
  name: trivy - Terraform security scan
  entry: trivy config --severity CRITICAL terraform/
```

## 📊 Monitoramento

### Ver Status de Workflows

1. Vá para: **Actions** no repositório GitHub
2. Selecione o workflow desejado
3. Veja a história de execuções

### Debug de Falhas

1. Clique no workflow que falhou
2. Expanda os steps para ver logs completos
3. Procure por mensagens de erro específicas

### Métricas

- **Tempo de execução:** Geralmente 2-3 minutos
- **Taxa de sucesso:** Deve ser alta se configuração está correta
- **Custos:** GitHub Actions é gratuito para repositórios públicos

## 🆘 Troubleshooting

### Erro: "command not found: terraform"

Verifique se o step "Install Terraform" rodou corretamente.

### Erro: "Trivy not found"

Trivy requer instalação do apt. Verifique se está no ubuntu-latest:

```yaml
runs-on: ubuntu-latest  # ✅ Correto
```

### Workflow não dispara em PR

Verifique:
1. PR está no branch `main`?
2. Arquivos modificados correspondem ao `paths:` no workflow?
3. PR tipo é um de: opened, synchronize, reopened?

### Comentário duplicado na PR

Isso pode acontecer se múltiplos workflows rodam. Solução:
- Use apenas um dos workflows (recomendado: `pre-commit-reviewdog.yml`)
- Delete o outro ou use `if: false` para desabilitar

## 📚 Referências

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Pre-Commit Framework](https://pre-commit.com/)
- [Terraform Best Practices](https://www.terraform.io/)
- [Trivy Documentation](https://aquasecurity.github.io/trivy/)
