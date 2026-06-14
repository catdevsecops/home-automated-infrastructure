#!/bin/bash

# Pre-Commit Quick Start Script
# Execute este script para instalar e configurar pre-commit rapidamente

set -e

echo "╔════════════════════════════════════════════════════════════════════════════╗"
echo "║           PRE-COMMIT QUICK START INSTALLATION SCRIPT                      ║"
echo "╚════════════════════════════════════════════════════════════════════════════╝"
echo ""

# Verificar Python
echo "✓ Verificando Python..."
python3 --version || {
    echo "❌ Python 3 não encontrado. Instale Python 3.8+";
    exit 1;
}

# Verificar pip
echo "✓ Verificando pip..."
pip3 --version || {
    echo "❌ pip não encontrado. Instale pip3";
    exit 1;
}

# Instalar pre-commit
echo ""
echo "📦 Instalando pre-commit..."
pip3 install pre-commit

# Instalar hooks no repositório
echo ""
echo "🔧 Configurando hooks no repositório..."
pre-commit install
pre-commit install --hook-type commit-msg

# Testar pre-commit
echo ""
echo "🧪 Testando pre-commit em todos os arquivos..."
echo "   (Isso pode levar alguns minutos na primeira execução)"
echo ""

if pre-commit run --all-files; then
    echo ""
    echo "╔════════════════════════════════════════════════════════════════════════════╗"
    echo "║                    ✅ PRE-COMMIT INSTALADO COM SUCESSO!                    ║"
    echo "╚════════════════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "📝 PRÓXIMOS PASSOS:"
    echo ""
    echo "1. Editar arquivos em terraform/"
    echo ""
    echo "2. Fazer commit normalmente:"
    echo "   git add terraform/..."
    echo "   git commit -m \"feat(terraform/...): descrição\""
    echo ""
    echo "3. Pre-commit executará automaticamente!"
    echo ""
    echo "📚 DOCUMENTAÇÃO:"
    echo "   - PRE-COMMIT.md         → Guia completo"
    echo "   - .pre-commit-context.md → Contexto técnico"
    echo "   - CLAUDE.md             → Guia de colaboração"
    echo ""
else
    echo ""
    echo "⚠️  PRE-COMMIT ENCONTROU ALGUNS PROBLEMAS"
    echo ""
    echo "Erros auto-fixáveis foram corrigidos. Execute novamente:"
    echo "   pre-commit run --all-files"
    echo ""
    echo "Se persistirem, consulte:"
    echo "   - PRE-COMMIT.md"
    echo "   - .pre-commit-context.md"
fi
