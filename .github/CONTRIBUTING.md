# Guia de Contribuição

Obrigado por querer contribuir com este projeto! Este documento descreve o fluxo de contribuição.

## 🚀 Quick Start

### 1. Setup Local

```bash
# Clone o repositório
git clone https://github.com/catdevsecops/home-automated-infrastructure.git
cd home-automated-infrastructure

# Instale as dependências
pip3 install pre-commit
pre-commit install
pre-commit install --hook-type commit-msg

# Teste a instalação
pre-commit run --all-files
```

### 2. Crie uma Branch

```bash
# Use padrão: feature/descrição ou fix/descrição
git checkout -b feature/minha-feature

# Faça suas mudanças
# ...
```

### 3. Validate Localmente

```bash
# Rodar pre-commit (faz auto-fix onde possível)
pre-commit run --all-files

# Se tiver mudanças em Terraform
cd terraform/seu-modulo
terraform init
terraform fmt
terraform validate

# Se tiver mudanças em Kubernetes
helm lint k8s/seu-app
helm template seu-app k8s/seu-app -n namespace
```

### 4. Faça Commit

```bash
# Use Conventional Commits
git add .
git commit -m "feat(scope): descrição curta"

# Tipos válidos:
# feat:     nova funcionalidade
# fix:      correção de bug
# docs:     mudança de documentação
# style:    formatação
# refactor: refatoração de código
# test:     adição de testes
# chore:    tarefas de manutenção
```

### 5. Abra uma PR

```bash
# Push para seu fork
git push origin feature/minha-feature

# Abra PR via GitHub UI
# Preencha o template de PR
# Aguarde os checks automáticos
```

## ✅ Checklist Pré-PR

### Terraform
- [ ] `terraform fmt -recursive` rodou
- [ ] `terraform validate` passou
- [ ] `terraform plan` mostra apenas mudanças esperadas
- [ ] Nenhum secret em `tfvars`
- [ ] Usou AWS SSM Parameter Store para dados sensíveis

### Kubernetes
- [ ] `helm lint` passou
- [ ] `helm template` renderizou corretamente
- [ ] Nenhum secret hardcoded
- [ ] Usou `ExternalSecret` para dados sensíveis

### Geral
- [ ] Executei `pre-commit run --all-files` ✅
- [ ] Meus commits seguem Conventional Commits
- [ ] Descrição da PR está clara
- [ ] PR está contra `main`

## 🔍 O que Roda Automaticamente na PR

1. **Pre-Commit Validation**
   - terraform_fmt
   - terraform_validate
   - terraform_tflint
   - trivy (Terraform)
   - trivy (Kubernetes)
   - detect-secrets
   - Validações padrão (YAML, JSON, etc)

2. **Terrateam** (se terraform alterado)
   - Executa `terraform plan`
   - Comenta resultado na PR

3. **Branch Protection Rules**
   - Todos os checks devem passar
   - Pelo menos 1 approval necessário (se configurado)

## 🐛 Encontrou um Bug?

1. Verifique se já existe uma issue
2. Se não, crie uma nova issue com:
   - Descrição clara do problema
   - Passos para reproduzir
   - Comportamento esperado vs atual
   - Seu ambiente (SO, versões, etc)

## 💡 Sugestões de Feature?

1. Abra uma discussion ou issue
2. Descreva o caso de uso
3. Aguarde feedback da comunidade

## 📚 Estrutura do Projeto

```
.
├── terraform/          # IaC com Terraform
│   ├── bootstrap/      # Setup inicial (roda uma vez)
│   ├── global/         # Recursos globais
│   └── us-east-2/      # Recursos regionais
├── k8s/                # Manifests Kubernetes (Helm)
│   ├── home-assistant/
│   ├── prometheus/
│   └── ...
├── .github/
│   ├── workflows/      # GitHub Actions
│   └── scripts/        # Scripts auxiliares
└── docs/               # Documentação
```

## 🎓 Aprendendo o Projeto

1. **README.md** - Visão geral do projeto
2. **CLAUDE.md** - Padrões de desenvolvimento
3. **PRE-COMMIT.md** - Detalhes de validação
4. **terraform/README.md** - Guia Terraform específico
5. **Issues/Discussions** - Contexto de decisões passadas

## 🆘 Precisa de Ajuda?

1. Veja a documentação no README
2. Procure issues/discussions similares
3. Abra uma discussion com sua dúvida
4. Procure em commits recentes por padrões similares

## 📋 Guia de Estilo

### Commit Messages

```bash
# ✅ Bom
git commit -m "feat(terraform/bootstrap): add talos configuration"
git commit -m "fix(k8s/home-assistant): scale replicas to 2"
git commit -m "docs(terraform): update README with examples"

# ❌ Ruim
git commit -m "update files"
git commit -m "alterações"
git commit -m "WIP: stuff"
```

### Nomes de Branch

```bash
# ✅ Bom
git checkout -b feature/add-talos-config
git checkout -b fix/ha-replica-scaling
git checkout -b docs/update-terraform-readme

# ❌ Ruim
git checkout -b feature
git checkout -b my-changes
git checkout -b test123
```

### PR Descriptions

```markdown
## Descrição
Breve descrição do que muda.

## Mudanças
- Mudança 1
- Mudança 2

## Impacto
- Afeta produção? Sim/Não
- Downtime necessário? Sim/Não
- Breaking change? Sim/Não

## Como Testar
Passos para testar as mudanças.
```

## 🔐 Segurança

### NUNCA commite:
- Senhas
- API keys
- Certificados privados
- AWS credentials
- Tokens de qualquer tipo

### Sempre use:
- AWS SSM Parameter Store para dados sensíveis
- ExternalSecret para sincronizar em Kubernetes
- IAM roles/policies restritas ao mínimo

## 📖 Recursos Úteis

- [Conventional Commits](https://www.conventionalcommits.org/)
- [Terraform Best Practices](https://www.terraform.io/docs/)
- [Kubernetes](https://kubernetes.io/docs/)
- [ArgoCD Best Practices](https://argo-cd.readthedocs.io/)
- [Pre-Commit Framework](https://pre-commit.com/)

## 🙏 Agradecimentos

Obrigado por contribuir! Sua contribuição faz diferença.

---

**Última atualização:** 2026-06-14
