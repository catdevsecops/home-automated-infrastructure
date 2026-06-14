#!/bin/bash
set -e

# Script para rodar pre-commit e capturar erros detalhados
# Usado pelo GitHub Actions workflow

echo "🔍 Running Pre-Commit Validation..."
echo "===================================="

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Arquivo temporário para capturar output
OUTPUT_FILE=$(mktemp)
trap "rm -f $OUTPUT_FILE" EXIT

# Rodar pre-commit e capturar saída
if pre-commit run --all-files > "$OUTPUT_FILE" 2>&1; then
    echo -e "${GREEN}✅ All Pre-Commit Hooks Passed!${NC}"
    cat "$OUTPUT_FILE"
    exit 0
else
    echo -e "${RED}❌ Pre-Commit Validation Failed${NC}"
    echo ""
    echo "Failed Hooks Output:"
    echo "===================="
    cat "$OUTPUT_FILE"
    echo ""
    echo -e "${YELLOW}To fix locally, run:${NC}"
    echo "  pre-commit run --all-files"
    echo ""
    exit 1
fi
