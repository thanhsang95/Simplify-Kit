<!--
Spec delta for one capability.

Path: sk/changes/<change-id>/specs/<capability>/spec.md

Use only the sections you need. An unused section is omitted entirely, not left
empty. /sk:archive reads these three headings and nothing else.
-->

## ADDED Requirements

### Requirement: <Short name in the imperative>

The system SHALL <the behaviour, stated as a product contract>.

#### Scenario: <What situation this covers>

- **WHEN** <the trigger>
- **THEN** <the observable result>
- **AND** <a further observable result, if any>

#### Scenario: <A second situation>

- **GIVEN** <precondition, when one matters>
- **WHEN** <the trigger>
- **THEN** <the observable result>

## MODIFIED Requirements

<!--
RESTATE THE ENTIRE REQUIREMENT HERE — every scenario, including the ones this
change does not touch.

/sk:archive replaces the whole requirement in sk/specs/ with what it finds
here. A requirement written with only the changed scenario deletes the rest,
the names still match, and nothing reports a conflict. This is the easiest way
to lose specification in this workflow.

Copy the requirement out of sk/specs/<capability>/spec.md, then edit the copy.
-->

### Requirement: <Existing requirement name, copied exactly>

The system SHALL <the full requirement text, with your change applied>.

#### Scenario: <The scenario you are changing>

- **WHEN** <the trigger>
- **THEN** <the new observable result>

#### Scenario: <An untouched scenario — restated verbatim from sk/specs/>

- **WHEN** <the trigger>
- **THEN** <the observable result>

## REMOVED Requirements

### Requirement: <Existing requirement name, copied exactly>

<!-- One line on why it is going away. No scenarios needed. -->
