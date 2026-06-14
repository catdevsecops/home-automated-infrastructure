# 📚 Exemplos de PRs com Pre-Commit Validation

Este arquivo mostra exemplos de como as PRs funcionam com a validação automática.

## Cenário 1: PR que Passa ✅

### Mudança: Adicionar novo arquivo Terraform

```bash
git checkout -b feature/add-new-resource
cat > terraform/us-east-2/example/main.tf << 'EOF'
resource "aws_s3_bucket" "example" {
  bucket = "my-bucket-${data.aws_caller_identity.current.account_id}"
  tags = {
    Name = "example"
  }
}
EOF

git add terraform/us-east-2/example/main.tf
pre-commit run --all-files
# ✅ Todos os hooks passam
git commit -m "feat(terraform/us-east-2): add s3 bucket resource"
git push origin feature/add-new-resource
```

### Resultado na PR

```
✅ Pre-Commit Validation Passed

All checks passed! ✨
```

Workflow roda:
- ✅ Terraform fmt (nada a formatar)
- ✅ Terraform validate (válido)
- ✅ Terraform tflint (segue padrões)
- ✅ Trivy (sem vulnerabilidades)
- ✅ Detect-secrets (sem secrets)

---

## Cenário 2: PR que Falha por Formatação ❌

### Mudança: Arquivo Terraform mal formatado

```bash
git checkout -b feature/malformatted
cat > terraform/us-east-2/example/bad.tf << 'EOF'
resource "aws_s3_bucket" "bad" {
bucket = "my-bucket"
 tags = {
   Name = "bad"
 }
}
EOF

git add terraform/us-east-2/example/bad.tf
pre-commit run --all-files
# ❌ terraform_fmt falha (indentação errada)
```

### O que Acontece

1. **Localmente:**
   ```
   terraform_fmt......................................................Failed
   - hook id: terraform_fmt
   - files were modified by this hook

   Warning: 1 issue(s) found by Terraform fmt
   ```

2. **Pre-commit auto-fixa:**
   ```bash
   git diff terraform/us-east-2/example/bad.tf
   # Mostra que foi reformatado
   ```

3. **Developer faz commit novamente:**
   ```bash
   git add terraform/us-east-2/example/bad.tf
   git commit -m "fix: terraform fmt auto-fix"
   pre-commit run --all-files
   # ✅ Passa agora
   git push
   ```

4. **Na PR:**
   Quando faz push, GitHub Actions roda novamente e passa.

---

## Cenário 3: PR com Secret Detectado ❌

### Mudança: Developer acidentalmente comita API key

```bash
git checkout -b feature/acidental-secret
cat > terraform/bootstrap/variables.tf << 'EOF'
variable "api_key" {
  default = "sk_live_abc123xyz456"  # ❌ SECRET!
}
EOF

git add terraform/bootstrap/variables.tf
pre-commit run --all-files
# ❌ detect-secrets falha
```

### Resultado

```
Detected secrets in staged files
File: terraform/bootstrap/variables.tf
Secret pattern: AWS_ACCESS_KEY_ID detected
```

### Solução Correta

```bash
# ❌ ERRADO - Remover secret do arquivo
# ✅ CORRETO - Usar AWS SSM Parameter Store
cat > terraform/bootstrap/variables.tf << 'EOF'
data "aws_ssm_parameter" "api_key" {
  name = "/prod/api-key"
}
EOF

git add terraform/bootstrap/variables.tf
pre-commit run --all-files
# ✅ Passa agora
git commit -m "chore: use ssm parameter for api key"
git push
```

---

## Cenário 4: PR com Problemas de Segurança (Trivy) ❌

### Mudança: S3 bucket sem criptografia

```bash
git checkout -b feature/insecure-s3
cat > terraform/us-east-2/example/bucket.tf << 'EOF'
resource "aws_s3_bucket" "logs" {
  bucket = "app-logs-bucket"
  # ❌ Sem server_side_encryption_configuration
  # ❌ Sem versioning
  # ❌ Sem block_public_access
}
EOF

git add terraform/us-east-2/example/bucket.tf
pre-commit run --all-files
# ❌ trivy-terraform falha (vulnerabilidades de segurança)
```

### Resultado

```
trivy - Terraform security scan.............................Failed
- hook id: trivy-terraform

Detected misconfigurations:
[HIGH] S3 bucket not encrypted
  Resource: aws_s3_bucket.logs
  File: terraform/us-east-2/example/bucket.tf:1-4

[MEDIUM] S3 bucket versioning not enabled
  Resource: aws_s3_bucket.logs
```

### Solução

```bash
cat > terraform/us-east-2/example/bucket.tf << 'EOF'
resource "aws_s3_bucket" "logs" {
  bucket = "app-logs-bucket"

  tags = {
    Name = "application-logs"
  }
}

# Enable versioning
resource "aws_s3_bucket_versioning" "logs" {
  bucket = aws_s3_bucket.logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "logs" {
  bucket = aws_s3_bucket.logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
EOF

git add terraform/us-east-2/example/bucket.tf
pre-commit run --all-files
# ✅ Passa agora
git commit -m "fix: implement s3 security best practices"
git push
```

---

## Cenário 5: PR com Múltiplos Arquivos

### Mudança: Adicionar nova aplicação Kubernetes

```bash
git checkout -b feature/add-monitoring

# Adicionar chart Helm
mkdir -p k8s/monitoring/templates
cat > k8s/monitoring/Chart.yaml << 'EOF'
apiVersion: v2
name: monitoring
version: 1.0.0
EOF

cat > k8s/monitoring/values.yaml << 'EOF'
namespace: monitoring
replicaCount: 1
image:
  repository: prom/prometheus
  tag: latest
EOF

cat > k8s/monitoring/templates/deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: prometheus
spec:
  replicas: {{ .Values.replicaCount }}
  template:
    spec:
      containers:
      - name: prometheus
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
EOF

# Adicionar Terraform
mkdir -p terraform/us-east-2/monitoring
cat > terraform/us-east-2/monitoring/main.tf << 'EOF'
resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
}
EOF

git add k8s/monitoring/ terraform/us-east-2/monitoring/
pre-commit run --all-files
```

### Resultado

Se tudo passar:
```
trailing-whitespace.............................................Passed
check-yaml......................................................Passed
check-json......................................................Passed
Terraform fmt...................................................Passed
Terraform validate..............................................Passed
Terraform tflint................................................Passed
trivy - Terraform security scan..................................Passed
trivy - Kubernetes security scan.................................Passed
```

PR comentário:
```
✅ Pre-Commit Validation Passed

All checks passed! ✨
```

---

## Cenário 6: GitHub Actions Comment Example

Quando PR falha, vê algo assim:

### ❌ Falha

```markdown
## ❌ Pre-Commit Validation Failed

### Issues Found

```
terraform_fmt: Bad request
  File: terraform/bootstrap/cluster/main.tf:45
  Issue: Mixed tabs and spaces
```

### How to Fix

1. Run locally: `pre-commit run --all-files`
2. Commit the fixes: `git add . && git commit -m "chore(pre-commit): auto fixes"`
3. Push: `git push`

See [PRE-COMMIT.md](link) for more info.
```

### ✅ Sucesso

```markdown
✅ Pre-Commit Validation Passed

All checks passed! ✨
```

---

## Cenário 7: Iteração com Feedback

```
Passo 1: Developer abre PR com erro
         → GitHub Actions comenta com erro

Passo 2: Developer vê comentário
         → Executa: pre-commit run --all-files

Passo 3: Auto-fix corrige os arquivos
         → Faz commit: "chore(pre-commit): auto fixes"
         → Faz push

Passo 4: GitHub Actions roda novamente
         → ✅ Passa
         → Comentário anterior é removido

Passo 5: PR está pronta para review de código
         → Outros reviewers podem aprovar
         → Merge pode acontecer
```

---

## 📊 Tempo de Execução

```
Atividade                    Tempo
─────────────────────────────────────
Setup (checkout + deps)      ~45s
Terraform fmt               ~10s
Terraform validate          ~15s
Terraform tflint            ~20s
Trivy (terraform/)          ~30s
Trivy (k8s/)                ~20s
Detect-secrets              ~5s
Comment on PR               ~5s
─────────────────────────────────────
Total                       ~2-3 min
```

---

## 🎓 O que Aprender com Exemplos

1. **Sempre rodar localmente primeiro:** `pre-commit run --all-files`
2. **Deixar pre-commit auto-corrigir:** Muitos erros são corrigidos automaticamente
3. **Entender mensagens de erro:** Leia a saída para entender o problema
4. **Usar templates corretos:** Siga as convenções do projeto
5. **Security first:** Trivy detecta problemas de segurança comuns

---

## 🔗 Recursos Úteis

- [PRE-COMMIT.md](../PRE-COMMIT.md) - Detalhes dos hooks
- [CONTRIBUTING.md](CONTRIBUTING.md) - Guia de contribuição
- [WORKFLOWS.md](WORKFLOWS.md) - Detalhes dos workflows
- [CLAUDE.md](../CLAUDE.md) - Padrões do projeto
