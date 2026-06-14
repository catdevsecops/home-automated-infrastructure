# CLAUDE.md - Guia de Colaboração

Este arquivo documenta boas práticas, padrões e orientações para implementação de features e correções neste projeto usando **ArgoCD** e **Terraform**.

## 🎯 Princípios Gerais

### GitOps First
- Todas as mudanças de infraestrutura e aplicações devem ser tratadas como código
- Nenhuma mudança manual diretamente no cluster via `kubectl` ou AWS Console
- Código é a única fonte de verdade (SSOT - Single Source of Truth)
- ArgoCD sincroniza automaticamente `/k8s/` com o cluster
- Terrateam automatiza execução de Terraform via GitHub PRs

### Imutabilidade
- **Talos Linux** oferece sistema operacional imutável - nunca editar máquinas diretamente
- Cluster Kubernetes em **4 Raspberry Pi 4B** com nomes específicos (athos, porthos, aramis, dartagnan)
- Configurações devem ser versionadas no Git
- Mudanças requerem novo deploy, nunca patches in-place

### Menor Privilégio
- IAM roles restritas ao mínimo necessário
- Secrets sempre em **AWS SSM Parameter Store** (nunca em Git)
- Integração via **External Secrets Operator** para sincronização automática
- Acesso auditável via CloudTrail e CloudWatch

### Infraestrutura de Referência
- **Cluster:** `skynet` com endpoint `https://skynet.cavaleiro.in:6443`
- **DNS:** Gerenciado via Cloudflare (global)
- **Traefik:** Reverse proxy com TLS válido para rede interna
- **Ubiquiti:** Hardware de controle para mesh WiFi e segurança
- **Home Assistant Cloud:** Replicação gerenciada da central de automação

---

## 🏗️ Padrões Terraform

### Organização de Módulos

```
terraform/
├── bootstrap/     # Provisionamento inicial (deve rodar uma vez)
├── global/        # Recursos compartilhados globalmente
└── us-east-2/     # Recursos regionais
```

**Regra:** Cada diretório é um "stack" independente com seu próprio `terraform.tfstate`.

### Estrutura de Arquivo

Cada diretório deve seguir:
```
├── main.tf          # Recursos principais
├── variables.tf     # Variáveis de entrada
├── outputs.tf       # Saídas exportadas
├── provider.tf      # Provider configuration
├── data.tf          # Data sources
├── locals.tf        # Variáveis locais (optional)
└── terraform.tfvars # Valores concretos (NUNCA commit secrets)
```

### Nomeação

- **Recursos:** snake_case em lowercase (ex: `aws_s3_bucket`, `kubernetes_namespace`)
- **Variáveis:** snake_case em lowercase
- **Outputs:** snake_case em lowercase
- **Locais:** snake_case em lowercase
- **Data sources:** snake_case em lowercase

Exemplo correto:
```hcl
resource "aws_s3_bucket" "terraform_state" {
  bucket = "my-terraform-state-bucket"
}

variable "cluster_name" {
  description = "Nome do cluster Kubernetes"
  type        = string
}

output "cluster_endpoint" {
  value = kubernetes_cluster.main.endpoint
}
```

### State Management

**Regras rígidas:**
- ✅ State armazenado em S3 com backend remoto
- ✅ Versionamento e lock habilitados
- ✅ Criptografia KMS em repouso
- ❌ NUNCA fazer commit de `terraform.tfstate`
- ❌ NUNCA usar state local em produção
- ❌ NUNCA compartilhar state via email ou repositório

### Providers e Versioning

Sempre fixe versões de providers:
```hcl
terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.20"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "~> 0.10"
    }
  }
}
```

### Variáveis Sensíveis

**NUNCA coloque em `terraform.tfvars`:**
- AWS access keys
- Senhas de banco de dados
- Tokens de API
- Certificados privados

**Solução:** Use AWS SSM Parameter Store + External Secrets Operator

```hcl
# ❌ ERRADO
variable "db_password" {
  default = "senha123"
}

# ✅ CORRETO - referência a SSM
data "aws_ssm_parameter" "db_password" {
  name = "/prod/database/password"
}
```

### Outputs Sensíveis

Marque outputs sensíveis como `sensitive = true`:
```hcl
output "kubeconfig_content" {
  value     = data.talos_client_configuration.this.kubeconfig_raw
  sensitive = true
}
```

### Plan e Apply

Sempre revisar `terraform plan` antes de `terraform apply`:
```bash
# Ver mudanças propostas
terraform plan -out=tfplan

# Revisar o plano em detalhes
terraform show tfplan

# Aplicar apenas se estiver correto
terraform apply tfplan
```

---

## 🚀 Padrões ArgoCD

### Estrutura de Charts Helm

```
k8s/
├── namespace/
│   ├── app-name/
│   │   ├── Chart.yaml
│   │   ├── values.yaml
│   │   ├── values-prod.yaml (opcional)
│   │   └── templates/
│   │       ├── deployment.yaml
│   │       ├── service.yaml
│   │       ├── configmap.yaml
│   │       ├── externalsecret.yaml
│   │       └── _helpers.tpl
│   └── ...
├── home-assistant/
├── traefik/
└── ...
```

**Regra:** Uma pasta por namespace, uma subpasta por aplicação com chart Helm completo.

### Usando Helm para Provisionamento

Todos os manifests Kubernetes devem ser provisionados via **Helm**. Use Helm para:
- Gerenciar valores por ambiente (values.yaml, values-prod.yaml)
- Template reusável de componentes
- Versionamento de releases
- Rollback simplificado via ArgoCD

Exemplo de `Chart.yaml`:
```yaml
apiVersion: v2
name: home-assistant
description: A Helm chart for Home Assistant
type: application
version: 1.0.0
appVersion: "2024.01.0"

dependencies: []
```

Exemplo de `values.yaml`:
```yaml
namespace: home-assistant

replicaCount: 2

image:
  repository: homeassistant/home-assistant
  pullPolicy: IfNotPresent
  tag: "2024.01.0"

service:
  type: ClusterIP
  port: 8123

resources:
  requests:
    cpu: 500m
    memory: 512Mi
  limits:
    cpu: 1000m
    memory: 1024Mi

livenessProbe:
  httpGet:
    path: /
    port: 8123
  initialDelaySeconds: 30
  periodSeconds: 10

readinessProbe:
  httpGet:
    path: /
    port: 8123
  initialDelaySeconds: 5
  periodSeconds: 5

labels:
  app: home-assistant
  version: "2024.01.0"
  managed-by: argocd
```

### Secrets com External Secrets Operator

**NUNCA coloque secrets em YAML:**
```yaml
# ❌ ERRADO - Nunca fazer isso
apiVersion: v1
kind: Secret
metadata:
  name: db-password
type: Opaque
data:
  password: cGFzc3dvcmQxMjM=  # base64 não é criptografia!
```

**✅ CORRETO - Use ExternalSecret:**
```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: db-password
  namespace: default
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: aws-ssm
    kind: SecretStore
  target:
    name: db-password
    creationPolicy: Owner
  data:
    - secretKey: password
      remoteRef:
        key: /prod/database/password
```

### Estrutura de Application

Cada aplicação deve ter uma Application ou ApplicationSet no ArgoCD:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: home-assistant
  namespace: argocd
spec:
  project: default

  source:
    repoURL: https://github.com/catdevsecops/home-automated-infrastructure.git
    targetRevision: main
    path: k8s/home-assistant

  destination:
    server: https://kubernetes.default.svc
    namespace: home-assistant

  syncPolicy:
    automated:
      prune: true     # Remove recursos deletados do Git
      selfHeal: true  # Sincronize automaticamente se detectar drift
    syncOptions:
      - CreateNamespace=true
```

### ApplicationSet para Multi-App

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: main-apps
  namespace: argocd
spec:
  generators:
    - list:
        elements:
          - name: home-assistant
            namespace: home-assistant
          - name: traefik
            namespace: traefik
          - name: prometheus
            namespace: prometheus

  template:
    metadata:
      name: '{{ name }}'
    spec:
      project: default
      source:
        repoURL: https://github.com/catdevsecops/home-automated-infrastructure.git
        targetRevision: main
        path: k8s/{{ name }}
      destination:
        server: https://kubernetes.default.svc
        namespace: '{{ namespace }}'
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
          - CreateNamespace=true
```

### Auto-Sync vs Manual Sync

**Recomendação:** Use `automated.prune: true` e `automated.selfHeal: true` para ambiente de produção.

```yaml
# ✅ RECOMENDADO - Auto-sync em produção
syncPolicy:
  automated:
    prune: true      # Remove recursos não rastreados
    selfHeal: true   # Sincroniza se detectar drift
    allowEmpty: false
```

### Namespace Management

Sempre crie namespaces como recursos Git:
```yaml
# k8s/home-assistant/namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: home-assistant
  labels:
    app: home-assistant
```

### Image Updates

Use ArgoCD Image Updater para updates automáticos:
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: image-updater-config
  namespace: argocd
data:
  registries.conf: |
    - name: docker
      api_version: v2
      type: docker
      default: true
```

---

## 🔒 Segurança

### Secrets Management

**Pipeline completo:**
1. Crie secret em AWS SSM Parameter Store
2. External Secrets Operator sincroniza para Kubernetes
3. Pod referencia o Kubernetes Secret
4. Nunca fazer commit de secrets no Git

```bash
# Criar secret em SSM
aws ssm put-parameter \
  --name /prod/home-assistant/api-key \
  --value "sua-chave-secreta" \
  --type SecureString \
  --key-id alias/aws/ssm
```

### RBAC

Use RBAC restritivo para cada aplicação:
```yaml
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: home-assistant
  namespace: home-assistant

---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: home-assistant
  namespace: home-assistant
rules:
  - apiGroups: [""]
    resources: ["configmaps", "secrets"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "list"]

---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: home-assistant
  namespace: home-assistant
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: home-assistant
subjects:
  - kind: ServiceAccount
    name: home-assistant
    namespace: home-assistant
```

### Network Policies

Implemente network policies para segurança de rede:
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: home-assistant-policy
  namespace: home-assistant
spec:
  podSelector:
    matchLabels:
      app: home-assistant
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              name: traefik
      ports:
        - protocol: TCP
          port: 8123
  egress:
    - to:
        - namespaceSelector: {}
      ports:
        - protocol: TCP
          port: 443
```

---

## ✅ Setup Inicial

Antes de começar a trabalhar no projeto, execute:

```bash
# 1. Instalar pre-commit
pip3 install pre-commit

# 2. Instalar os hooks no repositório
pre-commit install
pre-commit install --hook-type commit-msg

# 3. Verificar que está funcionando
pre-commit run --all-files
```

Consulte `PRE-COMMIT.md` para detalhes completos sobre as validações automatizadas.

## 📝 Fluxo de Desenvolvimento

### Bootstrap Inicial (Primeira Execução)

⚠️ **Executar nesta ordem obrigatoriamente:**

1. **`terraform/bootstrap/state`** - Backend S3 para persistência
2. **`terraform/bootstrap/cluster`** - Talos Linux otimizado para ARM64
3. **`terraform/bootstrap/machines`** - Init-data e boot (nós: athos, porthos, aramis, dartagnan)
4. **`terraform/bootstrap/argocd`** - GitOps engine
5. **`terraform/bootstrap/argocd-applicationset`** - Auto-sincronização com `/k8s/`

Cada etapa depende da anterior. Consulte `terraform/README.md` para detalhes completos.

### Adicionar Nova Aplicação

1. **Criar estrutura Helm no Git:**
```bash
mkdir -p k8s/nova-app/templates/
touch k8s/nova-app/{Chart.yaml,values.yaml}
touch k8s/nova-app/templates/{deployment.yaml,service.yaml,externalsecret.yaml,_helpers.tpl}
```

2. **Estrutura recomendada:**
```
k8s/nova-app/
├── Chart.yaml                  # Metadados do chart
├── values.yaml                 # Valores padrão
├── values-prod.yaml            # Valores para produção (opcional)
└── templates/
    ├── deployment.yaml         # Deployment principal
    ├── service.yaml            # Service (ClusterIP/NodePort/LoadBalancer)
    ├── externalsecret.yaml     # Secrets via AWS SSM (se necessário)
    ├── ingress.yaml            # Ingress (se necessário)
    ├── configmap.yaml          # ConfigMap (se necessário)
    ├── hpa.yaml                # HorizontalPodAutoscaler (se necessário)
    └── _helpers.tpl            # Templates reusáveis
```

3. **Exemplo de `Chart.yaml`:**
```yaml
apiVersion: v2
name: nova-app
description: Descrição da aplicação
type: application
version: 1.0.0
appVersion: "1.0.0"
```

4. **Exemplo de `values.yaml`:**
```yaml
namespace: default

replicaCount: 2

image:
  repository: meu-registry/nova-app
  tag: "1.0.0"
  pullPolicy: IfNotPresent

service:
  type: ClusterIP
  port: 8080

resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 512Mi

livenessProbe:
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 30
  periodSeconds: 10

readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 5
```

5. **Exemplo de template (`deployment.yaml`):**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "nova-app.fullname" . }}
  namespace: {{ .Values.namespace }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: {{ include "nova-app.name" . }}
  template:
    metadata:
      labels:
        app: {{ include "nova-app.name" . }}
    spec:
      containers:
      - name: {{ include "nova-app.name" . }}
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
        ports:
        - containerPort: 8080
        livenessProbe:
          {{- toYaml .Values.livenessProbe | nindent 10 }}
        readinessProbe:
          {{- toYaml .Values.readinessProbe | nindent 10 }}
        resources:
          {{- toYaml .Values.resources | nindent 10 }}
```

6. **Criar Terraform (se precisar de infra em AWS/Cloudflare):**
```bash
mkdir -p terraform/us-east-2/nova-app/
touch terraform/us-east-2/nova-app/{main.tf,variables.tf,outputs.tf,provider.tf}
```

7. **Commit com mensagem descritiva:**
```bash
git add k8s/nova-app/ terraform/us-east-2/nova-app/
git commit -m "feat(k8s/nova-app): add nova-app helm chart

- Deployment com 2 replicas
- Integração com SSM Parameter Store via ExternalSecret
- TLS via Traefik Ingress
- Prometheus metrics exposta em :8080/metrics
- Health checks configurados (liveness + readiness)"
git push origin main
```

8. **ArgoCD sincronizará automaticamente** (ApplicationSet monitora `/k8s/`)

### Modificar Configuração Kubernetes (Helm)

1. **Editar `values.yaml` em `/k8s/app-name/`**
2. **Validar sintaxe e renderização:**
```bash
# Validar chart Helm
helm lint k8s/home-assistant/

# Ver manifests renderizados
helm template home-assistant k8s/home-assistant/ -n home-assistant

# Validar manifests final
helm template home-assistant k8s/home-assistant/ -n home-assistant | kubectl --dry-run=client apply -f -
```

3. **Commit com contexto:**
```bash
git commit -m "fix(k8s/home-assistant): scale replicas to 2 in values.yaml

Motivo: aumentar disponibilidade durante atualizações
Validado localmente com: helm template + kubectl --dry-run"
git push origin main
```

4. **ArgoCD sincronizará automaticamente** em poucos segundos
5. **Verificar sincronização:** `argocd app get home-assistant` ou UI

### Atualizar Infraestrutura Terraform

**Para mudanças em `/terraform/bootstrap/`:**
1. **Editar arquivos** (main.tf, variables.tf, etc)
2. **Plan local (teste):**
```bash
cd terraform/bootstrap/cluster
terraform init
terraform plan -out=tfplan
terraform show tfplan  # revisar cuidadosamente
```

3. **Commit com explicação clara:**
```bash
git commit -m "fix(terraform/bootstrap/cluster): update talos version to v1.13.0

BREAKING: Requires cluster restart
Recomendação: fazer durante manutenção programada
Impacto: ~5 minutos de downtime dos nós"
git push -u origin feature/talos-upgrade
```

4. **Criar Pull Request no GitHub**
5. **Terrateam executa `terrateam plan` automaticamente**
6. **Revisar plan nos comentários da PR**
7. **Após aprovação, fazer merge**
8. **Terrateam executa `terrateam apply` automaticamente**

**Para mudanças em `/terraform/us-east-2/` e `/terraform/global/`:**
Mesmo fluxo acima - Terrateam gerencia todas as mudanças.

### Fluxo com Terrateam

```
1. Criar PR com mudanças
   ↓
2. Terrateam detecta mudança em /terraform/
   ↓
3. Terrateam executa: terrateam plan
   ↓
4. Comenta com resultado do plan
   ↓
5. Aprovar a PR (code review)
   ↓
6. Fazer merge na main
   ↓
7. Terrateam executa: terrateam apply
   ↓
✅ Infraestrutura atualizada
```

---

## ✅ Checklist para PRs

### Antes de Commitar

- [ ] Sem secrets em código (usar AWS SSM Parameter Store)
- [ ] Sem `.tfstate` ou arquivos temporários
- [ ] Formatação correta

### Terraform - Antes de fazer PR

**Pre-commit automatiza muitas dessas verificações!**

- [ ] `pre-commit run --all-files` passou
  - `terraform_fmt` ✅ (código formatado automaticamente)
  - `terraform_validate` ✅ (sintaxe correta automaticamente)
  - `terraform_tflint` ✅ (estilo e boas práticas)
  - `trivy` ✅ (segurança e vulnerabilidades)
  - `detect-secrets` ✅ (sem secrets commitados)
- [ ] `terraform plan -out=tfplan` revisado manualmente
- [ ] `terraform show tfplan` mostra apenas mudanças esperadas
- [ ] Nenhum secret em variables, outputs ou `.tfvars`
  - Use AWS SSM Parameter Store + External Secrets
- [ ] State backend configurado corretamente
- [ ] Versões de providers fixas (usar `~>` ou `=`)
- [ ] Comentários explicam lógica complexa
- [ ] Outputs sensíveis marcados com `sensitive = true`
- [ ] Mensagem de commit segue Conventional Commits
  - Formato: `type(scope): message`
  - Exemplo: `feat(terraform/bootstrap): add talos configuration`

### Kubernetes/ArgoCD (Helm) - Antes de fazer PR

- [ ] `helm lint k8s/app-name/` passou
- [ ] `helm template app-name k8s/app-name/ -n namespace | kubectl --dry-run=client apply -f -` passou
- [ ] `values.yaml` contém todos os valores necessários
- [ ] Namespace definido em `values.yaml` (nunca assumir default)
- [ ] Secrets usam **ExternalSecret** nos templates (nunca hardcoded em values)
- [ ] RBAC definido em templates (ServiceAccount + Role/RoleBinding)
- [ ] Labels e annotations corretos em templates via `_helpers.tpl`
  - `app: {{ include "app-name.name" . }}`
  - `version: {{ .Chart.AppVersion }}`
  - `managed-by: argocd`
- [ ] Resource limits definidos em `values.yaml` (cpu/memory)
- [ ] Probes de health configurados em `values.yaml` e templates
  - `livenessProbe` para detectar travamentos
  - `readinessProbe` para tráfego
- [ ] Application/ApplicationSet criado no ArgoCD (ou será criado automaticamente)

### GitOps - Antes de fazer PR

- [ ] Estrutura segue padrão: `/k8s/namespace/app-name/`
- [ ] Arquivo `namespace.yaml` presente se criar novo namespace
- [ ] Nenhuma mudança feita manualmente no cluster
- [ ] Alterações refletem 100% no Git

### Geral - Antes de fazer PR

- [ ] Commit message clara e descritiva
  - Formato: `type(scope): message`
  - Exemplos:
    - `feat(k8s/home-assistant): add prometheus scraper`
    - `fix(terraform/bootstrap/cluster): update talos to v1.13.0`
    - `docs(terraform): add bootstrap instructions`
- [ ] Descrição da PR explica:
  - O que muda
  - Por que muda
  - Impacto (downtime, breaking changes, etc)
- [ ] Nenhum arquivo sensível ou temporário
- [ ] Terrateam terá oportunidade de rodar plan (para Terraform)
- [ ] Code review será solicitado

### Durante Code Review

- [ ] Revisor valida `terrateam plan` (para Terraform)
- [ ] Revisor valida manifests visuais (para Kubernetes)
- [ ] Discussão de impactos e riscos
- [ ] Aprovação de pelo menos 1 revisor

### Antes de Merge

- [ ] Todas as verificações passaram
- [ ] Nenhuma mudança manual no cluster desde o commit
- [ ] PR está atualizada com main (sem conflitos)

---

## 🚨 Cuidados Importantes

### NUNCA Faça

- ❌ Commit de `.tfstate`, `*.tfstate*` ou `terraform.tfstate`
- ❌ Commit de credenciais, tokens, senhas ou certificados privados
- ❌ Editar recursos diretamente no AWS Console
- ❌ Fazer `kubectl apply` manual no cluster (sempre via Git + ArgoCD)
- ❌ SSH nas máquinas Talos para editar configuração (reeditar em Terraform e redeploy)
- ❌ Hardcode secrets em manifests Kubernetes
- ❌ Force push para main (`git push --force`)
- ❌ Deletar bucket S3 ou DynamoDB sem backup
- ❌ Mudar versão de provider sem testar
- ❌ Desabilitar auto-sync do ArgoCD sem motivo
- ❌ Modificar `terraform.tfvars` com dados sensíveis
- ❌ Commit de arquivo `.terraform/` ou `.terraform.lock.hcl` (usar `.gitignore`)

### Talos Linux Específico

- ❌ Nunca SSH diretamente nas máquinas para editar
  - Mudanças são perdidas no reboot
  - Usar Terraform para todas as configurações
- ❌ Nunca usar `talosctl machineconfig patch` em produção
  - Sempre versionar em Terraform + redeploy
- ❌ Nunca resetar máquinas Talos sem backup de kubeconfig

### ArgoCD Específico

- ❌ Nunca editar Application/ApplicationSet diretamente via kubectl
  - Versionar em Terraform (`bootstrap/argocd-applicationset`)
- ❌ Nunca fazer `argocd app sync --force-refresh` sem entender impacto
- ❌ Nunca desabilitar health assessment de uma aplicação crítica
- ❌ Nunca commitar credenciais do repositório em ArgoCD

### AWS Específico

- ❌ Nunca deletar secrets de SSM Parameter Store sem backup
- ❌ Nunca compartilhar AWS access keys
- ❌ Nunca desabilitar criptografia KMS de dados em repouso
- ❌ Nunca fazer destroy de bucket S3 ou DynamoDB sem confirmar uso

### Antes de Deletar Recursos

Sempre verificar impacto:
```bash
# Ver o que será deletado
terraform plan -destroy

# Revisar cuidadosamente antes de apply
terraform apply -destroy
```

### Backup do State

Antes de mudanças maiores:
```bash
# Fazer backup local
aws s3 cp s3://seu-bucket/terraform.tfstate ./backup-$(date +%Y%m%d).tfstate

# Ou habilitar versionamento em S3
aws s3api put-bucket-versioning \
  --bucket seu-bucket \
  --versioning-configuration Status=Enabled
```

---

## 🔍 Referências do Projeto

### Documentação Interna

- **`README.md`** - Visão geral do projeto, estrutura de pastas
- **`terraform/README.md`** - Detalhes de Terraform, ordem de bootstrap
- **`PRE-COMMIT.md`** - Validações automatizadas e setup
- **`CLAUDE.md`** - Este arquivo, guia de colaboração

### Cluster e Hardware

- **Cluster:** `skynet`
- **Endpoint:** `https://skynet.cavaleiro.in:6443`
- **Nós:**
  - Control Plane: `athos` (10.10.15.9), `porthos` (10.10.15.10), `aramis` (10.10.15.11)
  - Worker: `dartagnan` (10.10.15.12)
- **Hardware:** 4x Raspberry Pi 4B
- **SO:** Talos Linux (ARM64)
- **Kubernetes:** Implantado automaticamente pelo Talos

### Componentes Principais

- **Talos Linux:** Sistema operacional imutável para Kubernetes
- **ArgoCD:** GitOps engine para sincronização automática
- **Traefik:** Reverse proxy com TLS para rede interna
- **Prometheus:** Coleta de métricas
- **Grafana:** Visualização de métricas
- **Home Assistant:** Automação residencial (com replicação via Cloud)
- **External Secrets:** Sincronização AWS SSM → Kubernetes
- **GitHub Actions Runners:** Runners self-hosted no cluster

### Tecnologias

- **IaC:** Terraform 1.0+ com providers: AWS, Kubernetes, Talos, Cloudflare
- **Orquestração Kubernetes:** Helm charts para todas as aplicações
- **Gitops:** ArgoCD + ApplicationSet para auto-sync
- **Automação:** Terrateam (Terraform via PR) + GitHub Actions
- **Segurança:** AWS IAM, KMS, SSM Parameter Store, RBAC Kubernetes
- **DNS:** Cloudflare (global)

## 📚 Recursos Úteis

### Documentação Oficial

- [Talos Linux Documentation](https://www.talos.dev/)
- [ArgoCD Best Practices](https://argo-cd.readthedocs.io/en/stable/user-guide/best-practices/)
- [Kubernetes Security](https://kubernetes.io/docs/concepts/security/)
- [Terraform Best Practices](https://www.terraform.io/docs/language/state/purposes.html)
- [External Secrets Operator](https://external-secrets.io/)
- [Terrateam Docs](https://www.terrateam.io/)

### Padrões Específicos

- **Home Assistant:** Consultar `/k8s/home-assistant/`
- **Traefik:** Consultar `/k8s/traefik/`
- **Prometheus/Grafana:** Consultar `/k8s/prometheus/` e `/k8s/grafana/`
- **GitHub Actions Runners:** Consultar `/k8s/arc-systems/`

## 💬 Fluxo de Ajuda

**Para dúvidas sobre implementação:**

1. **Padrões gerais:** Consulte este arquivo (CLAUDE.md)
2. **Estrutura de pastas:** Consulte `README.md` principal
3. **Terraform específico:** Consulte `terraform/README.md`
4. **Exemplo prático:** Procure em commits anteriores com padrão similar
5. **Funcionalidade específica:** Consulte documentação oficial

**Para problemas:**

1. Reproduzir localmente com `terraform plan` ou `helm template`
2. Consultar logs no cluster: `kubectl logs -n namespace pod-name`
3. Revisar últimos commits: `git log --oneline -20`
4. Verificar ArgoCD UI: estado da aplicação, últimas sincronizações
5. Consultar documentação oficial da ferramenta
