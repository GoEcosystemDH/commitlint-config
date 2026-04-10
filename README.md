# @goecosystemdh/commitlint-config

Configuracion compartida de **commitlint + husky + gitleaks** para todos los repositorios de GoEcosystemDH.

## Que hace?

Agrega 3 capas de validacion automatica al flujo de git:

1. **commitlint** — Valida que los mensajes de commit sigan [Conventional Commits](https://www.conventionalcommits.org/)
2. **husky** — Ejecuta los hooks automaticamente en cada commit
3. **gitleaks** — Detecta secrets (API keys, passwords, tokens) antes del commit

## Instalacion (one-liner)

Ejecuta este comando desde la raiz de tu repo:

```bash
bash <(curl -s https://raw.githubusercontent.com/GoEcosystemDH/commitlint-config/main/setup.sh)
```

El script automaticamente:

1. Verifica que tengas Node.js 18+
2. Instala gitleaks si no lo tienes (via brew o curl)
3. Crea `package.json` si no existe (para repos no-Node)
4. Instala commitlint, husky y config-conventional como devDependencies
5. Crea `commitlint.config.js` con las reglas estandar de la org
6. Configura el hook `commit-msg` (valida formato del mensaje)
7. Configura el hook `pre-commit` (escanea secrets con gitleaks)
8. Agrega `node_modules/` a `.gitignore`

## Despues de clonar un repo configurado

```bash
git clone https://github.com/GoEcosystemDH/tu-repo.git
cd tu-repo
npm install    # Activa husky automaticamente
```

Gitleaks debe estar instalado localmente. Si no lo tienes:

```bash
# macOS
brew install gitleaks

# Linux
curl -sSfL https://github.com/gitleaks/gitleaks/releases/download/v8.24.3/gitleaks_8.24.3_linux_x64.tar.gz | tar -xz
sudo mv gitleaks /usr/local/bin/
```

## Como funciona en el dia a dia

### Al hacer commit

```bash
git add .
git commit -m "feat: agregar endpoint de citas"
```

1. **pre-commit hook** → gitleaks escanea los archivos staged. Si detecta un secret, cancela el commit.
2. **commit-msg hook** → commitlint valida el formato del mensaje. Si no cumple, cancela el commit.
3. Si ambos pasan → el commit se guarda.

### Ejemplos

```bash
# ❌ FALLA — mensaje no cumple Conventional Commits
git commit -m "updated stuff"
# → commitlint rechaza

# ❌ FALLA — archivo con secret
echo 'AWS_KEY=AKIAIOSFODNN7EXAMPLE' > config.txt
git add config.txt
git commit -m "feat: add config"
# → gitleaks rechaza

# ✅ PASA
git commit -m "feat(auth): agregar login con SSO"
# → Ambos hooks pasan, commit guardado
```

## Bypass de emergencia

En casos criticos (hotfix urgente), puedes saltar los hooks:

```bash
git commit --no-verify -m "tu mensaje"
```

**Usa esto solo en emergencias.** Si lo necesitas frecuentemente, algo esta mal en tu flujo.

## Reglas de commitlint

Los tipos de commit permitidos son:

| Tipo | Uso |
| --- | --- |
| `feat` | Nueva funcionalidad |
| `fix` | Correccion de bug |
| `docs` | Documentacion |
| `refactor` | Refactorizacion sin cambio funcional |
| `test` | Tests |
| `chore` | Mantenimiento |
| `perf` | Mejora de rendimiento |
| `ci` | CI/CD |
| `build` | Sistema de build |
| `style` | Formato (no logica) |
| `revert` | Revertir cambio anterior |

## Configuracion de gitleaks

El hook ejecuta `gitleaks protect --staged` que:

- Escanea **solo los archivos staged** (rapido, menos de 1 segundo)
- Usa las reglas default de gitleaks + `.gitleaks.toml` del repo (si existe)
- Bloquea el commit si encuentra secrets

Si tienes falsos positivos, crea un `.gitleaks.toml` en la raiz del repo con allowlist:

```toml
[allowlist]
regexes = [
  '''ejemplo_de_falso_positivo''',
]
paths = [
  '''tests/fixtures/.*''',
]
```

## Documentacion completa

- [Guia de Commitlint + Husky en la Wiki](https://wiki.goecosystemdh.com/s/onboarding/p/commitlint-husky-validacion-automatica-de-commits-Q1CnCzeK3f)
- [Guia de Conventional Commits](https://wiki.goecosystemdh.com/s/onboarding/p/conventional-commits-guia-para-desarrolladores-O8WHML45Wd)
- [GitHub Security Scanning](https://wiki.goecosystemdh.com/s/onboarding/p/github-security-scanning-dpkj6Qb6bP)

## Contribuir

Para agregar reglas nuevas:

1. Edita `index.js` con las nuevas reglas
2. Bump version en `package.json`
3. Commit + push a main
4. El GitHub Action publicara la nueva version automaticamente

## Referencia

- [Conventional Commits Spec](https://www.conventionalcommits.org/)
- [commitlint docs](https://commitlint.js.org/)
- [husky docs](https://typicode.github.io/husky/)
- [gitleaks docs](https://github.com/gitleaks/gitleaks)
- Task AzDO: [#4084](https://dev.azure.com/goecosystem/Go-Devops/_workitems/edit/4084), [#4163](https://dev.azure.com/goecosystem/Go-Devops/_workitems/edit/4163)
