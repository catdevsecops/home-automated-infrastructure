# Home Automated Infrastructure

Uma infraestrutura de código aberto que automatiza completamente o controle de uma casa residencial usando GitOps, Kubernetes em edge computing e home automation.

## 📁 Estrutura de Pastas

```
home-automated-infrastructure/
├── k8s/                          # Manifests Kubernetes (GitOps - ArgoCD)
│   ├── home-assistant/           # Central de automação residencial
│   ├── traefik/                  # Ingress controller e balanceador de rotas
│   ├── prometheus/               # Coleta de métricas
│   ├── grafana/                  # Dashboards e visualizações
│   ├── external-secrets/         # Integração com AWS SSM
│   ├── postgres/                 # Banco de dados relacional
│   ├── default/                  # Aplicações genéricas
│   ├── cloudflare/               # Integração DNS Cloudflare
│   ├── arc-systems/              # GitHub Actions Runners self-hosted
│   └── kube-system/              # Componentes do Kubernetes
│
├── terraform/                    # Infraestrutura como Código
│   ├── bootstrap/                # Provisionamento inicial do cluster
│   │   ├── state/                # Backend S3 para estado do Terraform
│   │   ├── cluster/              # Configuração do Talos Linux
│   │   ├── machines/             # Init-data e boot das máquinas
│   │   ├── argocd/               # Deploy do ArgoCD
│   │   └── argocd-applicationset/# Sincronização automática com /k8s/
│   ├── global/                   # Recursos globais (Cloudflare)
│   │   ├── roles/                # Definição de roles de acesso
│   │   └── service-account/      # Contas de serviço
│   └── us-east-2/                # Recursos na AWS (Ohio)
│       ├── ssm/                  # AWS Systems Manager Parameter Store
│       └── secret-store-ssm/     # External Secrets para Kubernetes
│
└── README.md                     # Este arquivo
```

## 📋 Estrutura do Projeto

### `/k8s` - Kubernetes com GitOps (ArgoCD)

Manifests Kubernetes organizados por namespace e aplicação, gerenciados automaticamente pelo ArgoCD.

**Estrutura de taxonomia:** `namespace/nome-aplicação/helm-chart/`

Principais componentes:

- **home-assistant** - Central de automação residencial
- **traefik** - Ingress controller com balanceamento de rotas
- **prometheus** - Coleta de métricas
- **grafana** - Visualização de métricas e dashboards
- **external-secrets** - Integração com AWS SSM Parameter Store
- **postgres** - Banco de dados relacional
- **kube-system** - Componentes do Kubernetes
- **default** - Aplicações genéricas
- **cloudflare** - Integração com DNS Cloudflare
- **arc-systems** - GitHub Actions Runners self-hosted

### `/terraform` - Infraestrutura como Código

Infraestrutura provisionada com Terraform, gerenciada pelo Terrateam para execução automática em PRs.

#### `/terraform/bootstrap`

Implantação inicial do cluster e manutenção via Terrateam:

- Configuração do Talos Linux (sistema operacional imutável)
- Provisionamento do cluster Kubernetes
- Estados do Terraform armazenados em S3 da AWS

#### `/terraform/bootstrap/cluster`

Configuração específica do cluster Talos Linux em 4 Raspberry Pi 4B:

- Sistema operacional imutável e à prova de falhas
- Configurações de rede e boot

#### `/terraform/global`

Recursos globais provisionados via Cloudflare:

- DNS records
- Configurações de rede pública

#### `/terraform/us-east-2`

Recursos provisionados na região Ohio da AWS:

- Armazenamento de estado do Terraform (S3)
- Integração com SSM Parameter Store para segredos

## 🏗️ Características da Infraestrutura

### Home Automation

- **Home Assistant** como central de controle inteligente
- Replicação gerenciada via Home Assistant Cloud
- Controle completo de dispositivos residenciais

### Computação

- **Kubernetes** implantado em cluster edge com 4 Raspberry Pi 4B
- **Talos Linux** - sistema operacional imutável, seguro e à prova de falhas
- Controle de hardware Ubiquiti para mesh WiFi e segurança perimetral

### Observabilidade

- **Prometheus** - coleta de métricas de infraestrutura e aplicações
- **Grafana** - dashboards e visualizações de dados em tempo real

### Rede & Segurança

- **Traefik** - reverse proxy com balanceamento de carga
- Certificados válidos para uso dentro da rede interna
- **GitHub Actions Runners** self-hosted para CI/CD seguro
- **External Secrets** com AWS SSM Parameter Store para gerenciamento seguro de credenciais

### Automação & CI/CD

- **ArgoCD** - GitOps para sincronização automática do Kubernetes
- **Terrateam** - automação de Terraform via GitHub PR
- **GitHub Actions** - runners próprios rodando na infraestrutura
- Eliminação de necessidade de credenciais em plataformas terceirizadas

### Segurança

- Todos os segredos gerenciados via AWS SSM Parameter Store
- Criptografia em repouso (KMS da AWS)
- Sem credenciais armazenadas no repositório
- Execução de pipelines dentro da própria infraestrutura

## 🚀 Como Usar

### Pré-requisitos

- Acesso ao repositório Git
- Conhecimento básico de Kubernetes, Terraform e GitOps
- Acesso à AWS (para SSM Parameter Store)
- Acesso ao Cloudflare (para gerenciamento de DNS)

### Deploy de Alterações

**Para aplicações Kubernetes:**

1. Modifique os manifests em `/k8s`
2. Faça commit na branch `main`
3. ArgoCD sincronizará automaticamente as mudanças

**Para infraestrutura:**

1. Modifique os arquivos Terraform em `/terraform`
2. Crie um Pull Request
3. Terrateam executará o `terrateam plan`
4. Após aprovação, Terrateam executará o `terrateam apply`

## 📝 Documentação Adicional

Consulte o arquivo `terraform/README.md` para detalhes específicos sobre a configuração do Terraform.

## 🔐 Segurança

- Nenhum segredo é versionado no repositório
- Todos os segredos utilizam AWS SSM Parameter Store com criptografia
- Certificados SSL válidos para comunicação interna
- Execução de workflows dentro da própria infraestrutura
- Acesso controlado via Home Assistant Cloud

## 📄 Licença

Este projeto está aberto para consulta e aprendizado. Consulte o repositório para informações de licença específicas.
