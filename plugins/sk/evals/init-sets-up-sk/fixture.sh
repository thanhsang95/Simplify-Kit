#!/usr/bin/env bash
# Seeds a small, ordinary repository: enough for /sk:init to have something
# real to read, with no sk/ workspace yet.
set -eu

mkdir -p src docs .claude/rules

cat > package.json <<'EOF'
{
  "name": "catalog-service",
  "version": "1.4.0",
  "scripts": {
    "build": "tsc -p tsconfig.json",
    "test": "vitest run"
  },
  "devDependencies": {
    "typescript": "^5.6.0",
    "vitest": "^2.1.0"
  }
}
EOF

cat > src/catalog.ts <<'EOF'
export interface CatalogItem {
  id: string;
  title: string;
  archived: boolean;
}

export function listActive(items: CatalogItem[]): CatalogItem[] {
  return items.filter((item) => !item.archived);
}
EOF

cat > docs/code-standards.md <<'EOF'
# Code standards

- Named exports only; no default exports.
- Every exported function has a vitest case next to it.
- Errors carry the catalog id in the message.
EOF

cat > README.md <<'EOF'
# catalog-service

TypeScript service for catalog listings. Build with `npm run build`, test with
`npm test`. Conventions live in `docs/code-standards.md`.
EOF

cat > .claude/rules/backend-conventions.md <<'EOF'
---
paths: ["src/**"]
---

# Backend conventions

- Named exports only; no default exports.
EOF

cat > .claude/CLAUDE.md <<'EOF'
# catalog-service

Path-scoped rules live under `.claude/rules/` — see `backend-conventions.md`
for anything under `src/`.
EOF
