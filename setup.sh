#!/usr/bin/env bash
set -euo pipefail

echo "🔧 Configurando commitlint + husky + gitleaks..."
echo ""

# Verify node/npm
if ! command -v node &>/dev/null; then
  echo "❌ Node.js no encontrado. Instala Node.js 18+ antes de continuar."
  echo "   https://nodejs.org/ o: brew install node"
  exit 1
fi

# Verify we're in a git repo
if ! git rev-parse --is-inside-work-tree &>/dev/null; then
  echo "❌ No estas dentro de un repositorio git."
  exit 1
fi

REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT"

# ============================================================================
# GITLEAKS: Install if missing
# ============================================================================
if ! command -v gitleaks &>/dev/null; then
  echo "⚠️  gitleaks no encontrado. Intentando instalar..."

  if command -v brew &>/dev/null; then
    brew install gitleaks
  elif command -v apt-get &>/dev/null; then
    GITLEAKS_VERSION="8.24.3"
    curl -sSfL "https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS_VERSION}/gitleaks_${GITLEAKS_VERSION}_linux_x64.tar.gz" | tar -xz
    sudo mv gitleaks /usr/local/bin/
  else
    echo "❌ No se pudo instalar gitleaks automaticamente."
    echo "   Instalalo manualmente: https://github.com/gitleaks/gitleaks#installing"
    echo "   macOS: brew install gitleaks"
    echo "   Linux: curl -sSfL ... | tar -xz && sudo mv gitleaks /usr/local/bin/"
    exit 1
  fi
fi
echo "✅ gitleaks instalado: $(gitleaks version 2>&1 || echo 'disponible')"

# Ensure .npmrc for GitHub Packages
if [ ! -f .npmrc ] || ! grep -q "@goecosystemdh" .npmrc 2>/dev/null; then
  echo "@goecosystemdh:registry=https://npm.pkg.github.com" >> .npmrc
  echo "✅ .npmrc configurado para GitHub Packages"
fi

# Initialize package.json if missing (non-Node repos)
if [ ! -f package.json ]; then
  echo '{ "private": true, "description": "Tooling only - commitlint + husky + gitleaks" }' > package.json
  echo "✅ package.json creado (solo para tooling, no afecta tu proyecto)"
fi

# Install dependencies
echo "📦 Instalando commitlint + husky..."
npm install --save-dev @commitlint/cli @commitlint/config-conventional husky

# Create commitlint config
cat > commitlint.config.js << 'EOF'
module.exports = {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'type-enum': [2, 'always', [
      'feat', 'fix', 'refactor', 'docs', 'test',
      'chore', 'perf', 'ci', 'build', 'style', 'revert'
    ]],
    'subject-empty': [2, 'never'],
    'type-empty': [2, 'never'],
    'subject-max-length': [2, 'always', 100]
  }
};
EOF
echo "✅ commitlint.config.js creado"

# Initialize husky
npx husky init 2>/dev/null || npx husky install

# ============================================================================
# HOOK: commit-msg (commitlint)
# ============================================================================
mkdir -p .husky
cat > .husky/commit-msg << 'HOOK'
npx --no -- commitlint --edit "$1"
HOOK
chmod +x .husky/commit-msg
echo "✅ Hook commit-msg configurado (valida formato Conventional Commits)"

# ============================================================================
# HOOK: pre-commit (gitleaks)
# ============================================================================
cat > .husky/pre-commit << 'HOOK'
# Gitleaks pre-commit hook — previene commits con secrets
# Escanea SOLO los archivos staged (rapido)

if ! command -v gitleaks &>/dev/null; then
  echo "⚠️  gitleaks no esta instalado — saltando escaneo de secrets"
  echo "   Instalalo: brew install gitleaks"
  exit 0
fi

echo "🔍 Escaneando secrets en archivos staged..."
gitleaks protect --staged --verbose --redact --no-banner

if [ $? -ne 0 ]; then
  echo ""
  echo "❌ Secrets detectados en los archivos staged."
  echo "   Remueve los secrets antes de hacer commit."
  echo "   Si es un falso positivo, agrega el patron a .gitleaks.toml (allowlist)"
  echo "   En emergencias: git commit --no-verify"
  exit 1
fi

echo "✅ Sin secrets detectados"
HOOK
chmod +x .husky/pre-commit
echo "✅ Hook pre-commit configurado (escanea secrets con gitleaks)"

# Ensure node_modules in .gitignore
if [ -f .gitignore ]; then
  if ! grep -q "node_modules" .gitignore 2>/dev/null; then
    echo "node_modules/" >> .gitignore
    echo "✅ node_modules/ agregado a .gitignore"
  fi
else
  echo "node_modules/" > .gitignore
  echo "✅ .gitignore creado con node_modules/"
fi

echo ""
echo "🎉 Listo! Commitlint + Husky + Gitleaks configurados."
echo ""
echo "PRUEBA 1 — Mensaje de commit incorrecto (debe FALLAR):"
echo "  git commit --allow-empty -m 'bad message'"
echo ""
echo "PRUEBA 2 — Mensaje de commit correcto (debe PASAR):"
echo "  git commit --allow-empty -m 'feat: test message'"
echo ""
echo "PRUEBA 3 — Archivo con secret simulado (debe FALLAR el commit):"
echo "  echo 'AWS_SECRET=AKIAIOSFODNN7EXAMPLE' > /tmp/test.txt"
echo "  git add /tmp/test.txt && git commit -m 'test: fake secret'"
echo ""
echo "Formato de commit: tipo(scope): descripcion"
echo "Tipos validos: feat, fix, docs, refactor, test, chore, perf, ci, build, style, revert"
