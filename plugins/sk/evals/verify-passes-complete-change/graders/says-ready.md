---
type: llm
---

The change `us-12345-field-selector` is complete. Both requirements are
implemented in `src/field-selector.ts` and `src/attribute-fields.ts`
(`listSelectableFields`, `searchFields`, the "No matching fields" message), and
`test/field-selector.test.ts` covers all three scenarios. Every task is ticked.
There is no `design.md` (the proposal says design was skipped) and no shell, so
the tests cannot be run.

PASS if the reply reports no critical issue and concludes the change is ready
for `/sk:archive`. Warnings or suggestions are fine, and so is noting that the
tests were not run or the diff was unavailable, as long as none of them claims
a requirement or scenario is missing or unimplemented.

FAIL if the reply reports any critical or blocking issue, says the change is
not ready for archive, claims a requirement, scenario or test is missing, or
says it implemented, fixed, unticked or edited anything.

Judge the substance, not the formatting or the length.
