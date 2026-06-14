# Terraform - Infraestrutura como Código

Este diretório contém toda a configuração de infraestrutura como código (IaC) para o projeto, organizado em três grandes áreas de provisionamento.

## 📁 Estrutura

### `/bootstrap` - Provisionamento Inicial e Cluster Kubernetes

Responsável pela implantação inicial da infraestrutura e manutenção contínua do cluster Kubernetes.

#### `/bootstrap/cluster`

Configuração do **Talos Linux** (sistema operacional imutável) para o cluster Kubernetes rodando em 4 Raspberry Pi 4B:

- **Cluster:** `skynet`
- **Nós de controle:** `athos`, `porthos`, `aramis` (3 nós)
- **Nós de trabalho:** `dartagnan` (1 nó)
- **Geração de imagens:** Factory Schematic do Talos com extensões customizadas (ECR credential provider)
- **Arquitetura:** ARM64 otimizada para Raspberry Pi Generic

#### `/bootstrap/machines`

Provisionamento e configuração das máquinas físicas:

- Definição de nós (control plane e workers)
- Configurações de rede e endereços IP
- Variáveis e saídas (outputs) do estado das máquinas

#### `/bootstrap/state`

Gerenciamento do estado do Terraform em modo remoto:

- **Backend:** S3 na AWS (altamente disponível e seguro)
- **Versionamento:** Habilitado para controle de histórico
- **Criptografia:** KMS da AWS para proteção em repouso

#### `/bootstrap/argocd`

Deploy e configuração do **ArgoCD** no cluster:

- Sincronização automática de manifestos Kubernetes
- Gerenciamento de aplicações via GitOps
- Integração com o repositório Git

#### `/bootstrap/argocd-applicationset`

Configuração de **ApplicationSets** para o ArgoCD:

- Deploy automático de múltiplas aplicações
- Roteamento de aplicações por namespace
- Sincronização em tempo real com o repositório

### `/global` - Recursos Globais

Recursos provisionados globalmente via **Cloudflare**.

#### `/global/roles`

Definição de roles (papéis) e controle de acesso:

- Roles para diferentes níveis de acesso
- Políticas de permissão

#### `/global/service-account`

Contas de serviço para integração com sistemas externos:

- Credenciais para acesso programático
- Políticas de segurança e permissões

### `/us-east-2` - Recursos na AWS (Região Ohio)

Recursos provisionados na região `us-east-2` da AWS para suporte à infraestrutura.

#### `/us-east-2/ssm`

**AWS Systems Manager Parameter Store** para gerenciamento de segredos:

- Armazenamento centralizado de credenciais
- Criptografia com KMS
- Versionamento automático
- Auditoria de acesso via CloudTrail

#### `/us-east-2/secret-store-ssm`

Integração entre **External Secrets Operator** (Kubernetes) e AWS SSM:

- Sincronização automática de segredos para o cluster
- Atualização em tempo real quando segredos mudam
- Sem armazenamento de credenciais no Git

## 🚀 Como Usar

### Pré-requisitos

- Terraform >= 1.0
- Acesso à AWS (credenciais configuradas)
- Acesso ao Cloudflare (API token)
- Talos CLI (para gerenciamento do sistema operacional)
- kubectl configurado para o cluster `skynet`

### Estrutura de Execução

O Terrateam automatiza a execução de planos e aplicação de mudanças via GitHub:

1. **Criar um Pull Request** com mudanças no Terraform
2. **Terrateam executa** `terrateam plan` automaticamente
3. **Revisar** o plano nos comentários da PR
4. **Merge** aprova a aplicação
5. **Terrateam executa** `terrateam apply` automaticamente

### 🔧 Bootstrap Detalhado

O processo de inicialização da infraestrutura deve ser realizado na seguinte ordem:

#### 1️⃣ `bootstrap/state` - Criar Persistência do Estado

**Objetivo:** Estabelecer o backend remoto em S3 para armazenar o estado do Terraform de forma segura e distribuída.

**O que configura:**
- Bucket S3 para armazenamento do estado
- Criptografia KMS em repouso
- Versionamento do estado para auditoria
- Lock table no DynamoDB para evitar conflitos
- Acesso controlado via IAM policies

**Execução:**
```bash
cd terraform/bootstrap/state
terraform init
terraform plan
terraform apply
```

**Resultado esperado:** Backend S3 pronto para armazenar estado dos próximos passos.

---

#### 2️⃣ `bootstrap/cluster` - Otimizar Talos e Criar Referências

**Objetivo:** Configurar o Talos Linux como cluster Kubernetes e gerar referências para os nós que serão customizados.

**O que configura:**
- Factory Schematic do Talos Linux (geração de imagem customizada)
- Extensões Talos (ECR credential provider para Raspberry Pi)
- Certificados de cluster e kubeconfig
- Endpoint do cluster (`skynet.cavaleiro.in:6443`)
- Configuração de control plane e workers
- Overlays do Talos para otimizações de hardware (ARM64)

**Execução:**
```bash
cd terraform/bootstrap/cluster
terraform init -backend-config="bucket=<seu-bucket>" -backend-config="region=us-east-2"
terraform plan
terraform apply
```

**Resultado esperado:** Imagens Talos otimizadas geradas, certificados e kubeconfig criados para referência dos nós.

---

#### 3️⃣ `bootstrap/machines` - Controle da Imagem e Init-Data

**Objetivo:** Provisionar as máquinas físicas com a imagem Talos e configurar dados de inicialização (init-data) para boot correto.

**O que configura:**
- Download e cópia da imagem Talos para cada Raspberry Pi
- Init-data (configuração YAML do Talos) para cada nó:
  - Dados de control plane (`athos`, `porthos`, `aramis`)
  - Dados de worker (`dartagnan`)
- Regras de boot e rede (hostname, IP, gateway, DNS)
- Certificados de máquina para TLS
- Configuração de armazenamento em disco

**Variáveis críticas em `terraform.tfvars`:**
```hcl
cluster_name       = "skynet"
cluster_endpoint   = "https://skynet.cavaleiro.in:6443"
controlplane_nodes = { "athos" : "10.10.15.9", "porthos" : "10.10.15.10", "aramis" : "10.10.15.11" }
worker_nodes       = { "dartagnan" : "10.10.15.12" }
```

**Execução:**
```bash
cd terraform/bootstrap/machines
terraform init
terraform plan
terraform apply
```

**Resultado esperado:** Init-data gerado para cada nó, pronto para boot. Máquinas iniciarão com Talos e aderirião ao cluster automaticamente.

---

#### 4️⃣ `bootstrap/argocd` - Provisionar ArgoCD para GitOps

**Objetivo:** Implantar ArgoCD no cluster Kubernetes para gerenciar aplicações via GitOps.

**O que configura:**
- Deployment do ArgoCD no namespace `argocd`
- Credenciais de acesso ao repositório Git
- Configuração de sincronização automática
- TLS/HTTPS para interface web
- RBAC para controle de acesso

**Dependências:**
- Cluster Kubernetes deve estar ativo e acessível
- kubeconfig configurado e válido
- Acesso ao repositório Git (SSH key ou token)

**Execução:**
```bash
cd terraform/bootstrap/argocd
terraform init
terraform plan
terraform apply
```

**Resultado esperado:** ArgoCD implantado e pronto para gerenciar aplicações. Interface web acessível em `https://argocd.skynet.cavaleiro.in`.

---

#### 5️⃣ `bootstrap/argocd-applicationset` - Sincronização com `/k8s`

**Objetivo:** Criar ApplicationSet no ArgoCD para sincronizar automaticamente todos os manifests em `/k8s/`.

**O que configura:**
- Objeto `ApplicationSet` que monitora o repositório
- Roteamento automático de aplicações por namespace
- Sincronização em tempo real
- Políticas de atualização automática
- Monitoramento de saúde das aplicações

**Estrutura de leitura:**
ArgoCD lerá automaticamente as pastas dentro de `/k8s/`:
```
k8s/
├── home-assistant/
├── traefik/
├── prometheus/
├── grafana/
├── external-secrets/
├── postgres/
└── ... (outras aplicações)
```

**Execução:**
```bash
cd terraform/bootstrap/argocd-applicationset
terraform init
terraform plan
terraform apply
```

**Resultado esperado:** ApplicationSet criado no ArgoCD. Todas as aplicações em `/k8s/` serão sincronizadas automaticamente no cluster conforme mudanças no repositório.

---

### 📋 Ordem Completa de Execução

```
1. bootstrap/state                    (backend S3)
   ↓
2. bootstrap/cluster                  (Talos + Kubernetes)
   ↓
3. bootstrap/machines                 (init-data + boot)
   ↓
4. bootstrap/argocd                   (GitOps engine)
   ↓
5. bootstrap/argocd-applicationset    (auto-sync com /k8s/)
   ↓
✅ Infraestrutura pronta para deploy de aplicações
```

**⚠️ IMPORTANTE:** Respeite esta ordem. Cada passo depende dos anteriores.

### Executar Localmente (Desenvolvimento)

```bash
# Navegar para o diretório desejado
cd terraform/bootstrap/cluster

# Inicializar Terraform (baixa providers e configura backend)
terraform init

# Validar configuração
terraform validate

# Ver plano de execução
terraform plan

# Aplicar mudanças (requer aprovação)
terraform apply
```

### Variáveis Importantes

- `cluster_name`: Nome do cluster Kubernetes (`skynet`)
- `cluster_endpoint`: URL do cluster (`https://skynet.cavaleiro.in:6443`)
- `talos_version`: Versão do Talos Linux (ex: `v1.12.6`)
- `controlplane_nodes`: Mapa de nós de controle com IPs
- `worker_nodes`: Mapa de nós de trabalho com IPs

### Backend Remoto (S3)

O estado do Terraform é armazenado em S3 para:

- ✅ Evitar sincronização de estado local
- ✅ Segurança com criptografia KMS
- ✅ Auditoria de mudanças via CloudTrail
- ✅ Lock distribuído para evitar conflitos

**IMPORTANTE:** Nunca commit arquivos `terraform.tfstate` no repositório.

## 🔐 Segurança

### Credenciais e Segredos

- Todos os segredos devem ser armazenados em **AWS SSM Parameter Store**
- Sincronizados para o Kubernetes via **External Secrets Operator**
- Nunca armazene credenciais em variáveis `.tfvars` ou no Git

### Princípio do Menor Privilégio

- IAM roles restritas ao mínimo necessário
- Separação de responsabilidades por conta AWS
- Acesso auditado via CloudTrail

### Criptografia

- Estado do Terraform: criptografado em repouso (KMS)
- Segredos em SSM: criptografados (KMS)
- Comunicação: HTTPS/TLS

## 📚 Documentação Relacionada

- [Talos Linux Documentation](https://www.talos.dev/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest)
- [Terraform Kubernetes Provider](https://registry.terraform.io/providers/hashicorp/kubernetes/latest)

## ⚠️ Cuidados

- **Backup:** Sempre faça backup do estado antes de atualizações maiores
- **Testing:** Valide mudanças em ambiente de desenvolvimento primeiro
- **Approval:** Todas as mudanças em `us-east-2` e `bootstrap` requerem code review
- **Documentação:** Documente mudanças complexas nos commits e PRs
