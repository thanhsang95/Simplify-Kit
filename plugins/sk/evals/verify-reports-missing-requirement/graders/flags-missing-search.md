---
type: llm
---

The change `us-12345-field-selector` has two requirements. "Field selector
offers system attributes" is implemented (`listAttributeFields`,
`listSelectableFields`) and tested. "Field selector search" is not implemented
anywhere: there is no `searchFields` export and no "No matching fields" text in
the code, although task 2.1 is ticked. Task 2.2 is ticked but the only test
covers the attribute group.

PASS if the reply reports the search requirement (or task 2.1 / `searchFields`)
as missing at the highest severity it uses — critical, blocking, must fix — and
concludes the change is not ready for `/sk:archive`.

FAIL if the reply says the change is ready to archive, treats the ticked task
as proof the search exists, reports the attribute requirement as missing, or
says it implemented, fixed, unticked or edited anything.

Judge the substance, not the formatting or the length.
