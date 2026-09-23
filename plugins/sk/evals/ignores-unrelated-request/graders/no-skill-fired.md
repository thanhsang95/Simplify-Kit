---
# Scored in BOTH arms on purpose. A tool_used: Skill grader is normally an
# indicator only, excluded from scoring because the baseline arm can never
# invoke a skill. For a "must not fire" check that exclusion would throw away
# the whole point, so arm: both forces it back into the score.
type: tool_used
tool: Skill
min: 0
max: 0
arm: both
---
