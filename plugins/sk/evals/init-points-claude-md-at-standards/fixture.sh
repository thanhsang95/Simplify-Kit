#!/usr/bin/env bash
# The init-sets-up-sk repository plus a root CLAUDE.md carrying a sentinel
# line. /sk:init must append its section to ./CLAUDE.md (the first of
# ./CLAUDE.md and ./.claude/CLAUDE.md that exists), end it with
# `Code standards: docs/code-standards.md` so reviews that read only CLAUDE.md
# judge by the same doc /sk:verify uses, and leave the existing text alone.
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

cat > CLAUDE.md <<'EOF'
# catalog-service

Release notes go in CHANGES.txt, newest entry first, one line per merged PR.
EOF
