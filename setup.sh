#!/usr/bin/env bash
set -euo pipefail

echo "🔧 Configurando commitlint + husky para Conventional Commits..."
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

# Ensure .npmrc for GitHub Packages
if [ ! -f .npmrc ] || ! grep -q "@goecosystemdh" .npmrc 2>/dev/null; then
  echo "@goecosystemdh:registry=https://npm.pkg.github.com" >> .npmrc
  echo "✅ .npmrc configurado para GitHub Packages"
fi

# Initialize package.json if missing (non-Node repos)
if [ ! -f package.json ]; then
  echo '{ "private": true, "description": "Tooling only - commitlint + husky" }' > package.json
  echo "✅ package.json creado (solo para tooling, no afecta tu proyecto)"
fi

# Install dependencies
echo "📦 Instalando commitlint + husky..."
npm install --save-dev @commitlint/cli @goecosystemdh/commitlint-config husky

# Create commitlint config
cat > commitlint.config.js << 'EOF'
module.exports = { extends: ['@goecosystemdh/commitlint-config'] };
EOF
echo "✅ commitlint.config.js creado"

# Initialize husky
npx husky init 2>/dev/null || npx husky install

# Create commit-msg hook
mkdir -p .husky
cat > .husky/commit-msg << 'HOOK'
npx --no -- commitlint --edit "$1"
HOOK
chmod +x .husky/commit-msg
echo "✅ Hook commit-msg configurado"

# Remove default pre-commit if it just has 'npm test'
if [ -f .husky/pre-commit ] && grep -q "npm test" .husky/pre-commit 2>/dev/null; then
  rm .husky/pre-commit
fi

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
echo "🎉 Listo! Commitlint + Husky configurados."
echo ""
echo "Prueba con un mensaje INCORRECTO (debe fallar):"
echo "  git commit --allow-empty -m 'bad message'"
echo ""
echo "Prueba con un mensaje CORRECTO (debe pasar):"
echo "  git commit --allow-empty -m 'feat: test message'"
echo ""
echo "Formato: tipo(scope): descripcion"
echo "Tipos: feat, fix, docs, refactor, test, chore, perf, ci, build, style, revert"
