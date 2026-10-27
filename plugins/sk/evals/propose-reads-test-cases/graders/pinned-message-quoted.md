---
# Step 2 of AB#21301 pins the exact wording criterion 2 leaves open. It must be
# quoted word for word: /sk:continue resolves the token from this record and
# never re-fetches the test case.
type: regex
pattern: 'Name is required'
target:
  source: file
  path: sk/changes/us-21300-catalog-rename/proposal.md
---
