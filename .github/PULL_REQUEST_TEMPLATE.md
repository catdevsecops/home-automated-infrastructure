## 📋 Descrição

<!-- Descreva as mudanças desta PR -->

## 🎯 Tipo de Mudança

<!-- Marque com um X o tipo apropriado -->

- [ ] 🐛 **Bug Fix** - Correção de um bug existente
- [ ] ✨ **Feature** - Nova funcionalidade
- [ ] 📚 **Documentation** - Apenas mudanças de documentação
- [ ] ♻️ **Refactor** - Refatoração de código existente
- [ ] 🚀 **Performance** - Melhoria de performance
- [ ] 🔒 **Security** - Melhoria de segurança
- [ ] 🧪 **Testing** - Adição de testes

## 📝 Checklist

Antes de submeter esta PR, certifique-se que:

### Local Checks
- [ ] Executei `pre-commit run --all-files` e todos os hooks passaram
- [ ] Executei `git status` e confirmei que não há arquivos não rastreados
- [ ] Minha branch está atualizada com `main`

### Terraform
- [ ] Executei `terraform fmt -recursive` (se há mudanças em `.tf`)
- [ ] Executei `terraform validate` em cada módulo modificado
- [ ] Não incluí secrets em `terraform.tfvars` ou códigos
- [ ] Usei AWS SSM Parameter Store para dados sensíveis
- [ ] Adicionei/atualizei documentação em `README.md` do módulo (se aplicável)

### Kubernetes/Helm
- [ ] Executei `helm lint` em charts modificados (se há mudanças em `k8s/`)
- [ ] Executei `helm template` e validei os manifests
- [ ] Não hardcodei secrets em `values.yaml`
- [ ] Usei `ExternalSecret` para dados sensíveis
- [ ] Atualizei `Chart.yaml` com nova versão (se aplicável)

### Git
- [ ] Meus commits seguem Conventional Commits (`type(scope): message`)
- [ ] Minha mensagem de commit é descritiva
- [ ] Não fiz force push para `main`

### Segurança
- [ ] Não incluí credenciais, senhas ou tokens
- [ ] Executei `detect-secrets` e confirmei zero secrets detectados
- [ ] Trivy passou sem vulnerabilidades críticas

## 🔗 Referências

<!-- Vincule issues relacionadas, PRs anteriores, etc -->

Closes #
Related to #

## 📸 Screenshots (se aplicável)

<!-- Adicione screenshots para mudanças visuais -->

## 🚀 Como Testar

<!-- Descreva como testar as mudanças -->

```bash
# Exemplo:
terraform plan -out=tfplan
terraform show tfplan
```

## ⚠️ Impacto

<!-- Descreva o impacto desta mudança -->

- [ ] Breaking change
- [ ] Requer downtime
- [ ] Afeta ambiente de produção
- [ ] Requer migração de dados

Se sim, descreva:

## 📊 Métricas

<!-- Qualquer métrica relevante -->

- Build time: X segundos
- Number of lines changed: Y
- Files modified: Z

---

## ✅ Validação Automática

Este repositório utiliza GitHub Actions para validação automática. Os seguintes checks rodarão quando você fizer o push:

1. **Pre-Commit Hooks**: Verifica formatação, lint, segurança
2. **Terrateam** (se houver mudanças em terraform/): Executa `terraform plan`
3. **Status Checks**: Todos os checks devem passar

Se algum check falhar:
1. Veja os logs no GitHub Actions
2. Execute localmente: `pre-commit run --all-files`
3. Corrija os erros e faça push novamente

Para mais informações, veja [WORKFLOWS.md](.github/WORKFLOWS.md)
