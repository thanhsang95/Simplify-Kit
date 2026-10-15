import { atom, read, update } from 'claude-code'
import type { ElementTable, EngineInterface, Register } from 'claude-code'

import type { Artifact, ChangeState, Scan, Step } from '../types'

// Read-only view of sk/changes/. Every rule below mirrors a SimplifyKit skill:
// the artifact order is /sk:continue Step 2, the checkbox rule is /sk:verify's,
// the [[OPEN:Q<n>]] token is reference/conventions.md. The mod never writes a
// file and never submits a prompt — buttons only fill the box, the person sends.

type $ = EngineInterface

// Mid-saturation hexes that read on both dark and light backgrounds. Each
// pipeline stage owns one hue; a glyph or word always rides with the color
// so meaning never depends on color alone.
const HUE = {
  brand: '#D97757',
  proposal: '#4F8EF7',
  spec: '#A970FF',
  design: '#2BB3A3',
  tasks: '#E0A100',
  apply: '#D97757',
  verify: '#3FB950',
  warn: '#E0A100',
  bad: '#E5534B',
  ink: '#1A1A1A',
} as const
const TONE = { dim: 'inactive' } as const
const GLYPH = { on: '●', off: '○', warn: '▲', ok: '✓', fail: '✗' } as const
type Kit = Pick<ElementTable, 'Box' | 'Text'>

/** A word on a colored background: ` IMPLEMENT `. */
function badge({ Text }: Kit, text: string, bg: string) {
  return (
    <Text backgroundColor={bg} color={HUE.ink} bold>
      {` ${text} `}
    </Text>
  )
}

function banner({ Box, Text }: Kit, glyph: string, glyphColor: string, status: string) {
  return (
    <Box gap={1}>
      <Text backgroundColor={HUE.brand} color={HUE.ink} bold>
        {' ◆ SimplifyKit '}
      </Text>
      <Text color={glyphColor}>{glyph}</Text>
      <Text bold wrap="truncate-end">
        {status}
      </Text>
    </Box>
  )
}

function cell({ Box, Text }: Kit, value: string, width: number, color?: string) {
  return (
    <Box width={width} flexShrink={0} justifyContent="flex-end">
      <Text color={color}>{value}</Text>
    </Box>
  )
}

const hex = (n: number) => Math.round(n).toString(16).padStart(2, '0')

/** Blend two #RRGGBB colors; t in [0, 1]. */
function mix(a: string, b: string, t: number) {
  const ch = (c: string, i: number) => parseInt(c.slice(1 + i * 2, 3 + i * 2), 16)
  return `#${[0, 1, 2].map(i => hex(ch(a, i) + (ch(b, i) - ch(a, i)) * t)).join('')}`
}

/** Progress bar whose filled cells run orange → green, the rest dim. */
function bar({ Box, Text }: Kit, done: number, total: number, width: number) {
  const filled = total === 0 ? 0 : Math.round((done / total) * width)
  return (
    <Box flexShrink={0}>
      {Array.from({ length: filled }, (_, i) => (
        <Text color={mix(HUE.apply, HUE.verify, width <= 1 ? 1 : i / (width - 1))}>█</Text>
      ))}
      <Text dimColor>{'░'.repeat(width - filled)}</Text>
    </Box>
  )
}

const PANE = 'sk-status'
const EMPTY: Scan = { hasSk: false, changes: [] }
const scanAtom = atom({ plugin: 'sk-status', key: 'scan' } as const, EMPTY)
const sortAtom = atom({ plugin: 'sk-status', key: 'sort' } as const, 'recent')
const selectedAtom = atom({ plugin: 'sk-status', key: 'selected' } as const, null)
const viewingAtom = atom({ plugin: 'sk-status', key: 'viewing' } as const, null)
const confirmAtom = atom({ plugin: 'sk-status', key: 'confirmArchive' } as const, null)

const STEP_LABEL: Record<Step, string> = {
  gaps: 'AC missing',
  spec: 'spec delta',
  design: 'design',
  tasks: 'tasks',
  apply: 'implement',
  verify: 'verify',
}
const ORDER: Step[] = ['gaps', 'spec', 'design', 'tasks', 'apply', 'verify']

async function readText($: $, path: string): Promise<string | null> {
  try {
    return await $.fs.read(path)
  } catch {
    return null
  }
}

async function listSafe($: $, path: string) {
  try {
    return await $.fs.list(path)
  } catch {
    return []
  }
}

async function findSpecs($: $, dir: string, depth = 0): Promise<string[]> {
  if (depth > 4) return []
  const found: string[] = []
  for (const entry of await listSafe($, dir)) {
    const path = `${dir}/${entry.name}`
    if (entry.kind === 'dir') found.push(...(await findSpecs($, path, depth + 1)))
    else if (entry.kind === 'file' && entry.name === 'spec.md') found.push(path)
  }
  return found
}

function countTasks(text: string) {
  let done = 0
  let total = 0
  for (const match of text.matchAll(/^\s*[-*]\s*\[([^\]]*)\]/gm)) {
    total += 1
    if (/^\s*[xX]\s*$/.test(match[1] ?? "")) done += 1
  }
  return { done, total }
}

async function scanChange($: $, id: string): Promise<ChangeState | null> {
  const root = `sk/changes/${id}`
  const proposal = await readText($, `${root}/proposal.md`)
  if (proposal === null) return null

  let mtimeMs = 0
  for (const entry of await listSafe($, root)) mtimeMs = Math.max(mtimeMs, entry.mtimeMs)

  const specPaths = await findSpecs($, `${root}/specs`)
  const open = new Set<string>()
  for (const path of specPaths) {
    const text = (await readText($, path)) ?? ''
    for (const m of text.matchAll(/\[\[OPEN:(Q\d+)\]\]/g)) open.add(m[1] ?? "")
    try {
      mtimeMs = Math.max(mtimeMs, (await $.fs.stat(path)).mtimeMs)
    } catch {}
  }

  const design = (await $.fs.exists(`${root}/design.md`))
    ? 'file'
    : /^##\s+Design\b/m.test(proposal)
      ? 'skipped'
      : 'none'
  const tasksText = await readText($, `${root}/tasks.md`)
  const { done, total } = tasksText === null ? { done: 0, total: 0 } : countTasks(tasksText)

  let step: Step
  let next: string
  if (/\*\*AC source:\*\*\s*none yet/i.test(proposal)) {
    step = 'gaps'
    next = `/sk:propose ${id}`
  } else if (specPaths.length === 0) {
    step = 'spec'
    next = `/sk:continue ${id}`
  } else if (design === 'none') {
    step = 'design'
    next = `/sk:continue ${id}`
  } else if (tasksText === null) {
    step = 'tasks'
    next = `/sk:continue ${id}`
  } else if (done < total || total === 0) {
    step = 'apply'
    next = `/sk:apply ${id}`
  } else {
    step = 'verify'
    next = `/sk:verify ${id}`
  }

  return {
    id,
    step,
    next,
    specCount: specPaths.length,
    specPaths,
    design,
    hasTasks: tasksText !== null,
    tasksDone: done,
    tasksTotal: total,
    openQuestions: [...open].sort(),
    mtimeMs,
  }
}

async function scan($: $): Promise<Scan> {
  if (!(await $.fs.exists('sk'))) return EMPTY
  const changes: ChangeState[] = []
  for (const entry of await listSafe($, 'sk/changes')) {
    if (entry.kind !== 'dir' || entry.name === 'archive') continue
    try {
      const change = await scanChange($, entry.name)
      if (change) changes.push(change)
    } catch {}
  }
  changes.sort((a, b) => b.mtimeMs - a.mtimeMs)
  return { hasSk: true, changes }
}

function statusLine(change: ChangeState) {
  const tasks = change.step === 'apply' ? ` ${change.tasksDone}/${change.tasksTotal}` : ''
  const qs = change.openQuestions.length > 0 ? ` · ${GLYPH.warn} ${change.openQuestions.join(',')}` : ''
  return `sk ${change.id} · ${STEP_LABEL[change.step]}${tasks}${qs} · ⇥ ${change.next}`
}

async function refresh($: $): Promise<Scan> {
  const result = await scan($)
  // Skip the write when nothing on disk moved, so the timer never redraws idly.
  const before = JSON.stringify(await read($, scanAtom))
  if (JSON.stringify(result) !== before) await update($, scanAtom, () => result)
  const active = result.changes[0]
  $.ui.status(active ? statusLine(active) : undefined)
  return result
}

/**
 * Runs an sk skill as if the person typed it. A press is the person's own
 * explicit request, the same as typing the command — this never runs on its
 * own. Falls back to filling the prompt when the command cannot be found.
 */
async function runSk($: $, skill: string, id: string) {
  try {
    const commands = await $.command.list()
    const found =
      commands.find(c => c.name === `sk:${skill}`) ??
      commands.find(c => c.plugin === 'sk' && (c.name === skill || c.name.endsWith(`:${skill}`)))
    if (found === undefined) throw new Error('not found')
    await $.command.run({ command: found.name, args: id })
  } catch {
    await $.prompt.fill({ text: `/sk:${skill} ${id}` })
  }
}

/** The files behind one artifact, relative to the working directory. */
function artifactPaths(change: ChangeState, artifact: Artifact): string[] {
  const root = `sk/changes/${change.id}`
  if (artifact === 'spec') return change.specPaths
  if (artifact === 'design' && change.design === 'skipped') return [`${root}/proposal.md`]
  return [`${root}/${artifact}.md`]
}

async function readArtifact($: $, change: ChangeState, artifact: Artifact) {
  const parts: string[] = []
  for (const path of artifactPaths(change, artifact)) {
    const text = (await readText($, path)) ?? '_(could not read this file)_'
    parts.push(artifact === 'spec' ? `\`${path}\`\n\n${text}` : text)
  }
  return parts.join('\n\n---\n\n')
}

// Each stage owns a hue, used only where the stage itself is named (the
// badge, the list's step column) so the color always means "this stage".
const STAGE_HUE: Record<Step, string> = {
  gaps: HUE.warn,
  spec: HUE.spec,
  design: HUE.design,
  tasks: HUE.tasks,
  apply: HUE.apply,
  verify: HUE.verify,
}

// One row of the pipeline checklist. Color carries state only:
// done = green ✓, now = orange ●, to do = dim ○, blocked = amber ▲.
type Row = { step: Step; glyph: string; label: string; detail: string; state: 'done' | 'now' | 'todo' | 'warn' }
const STATE_COLOR = { done: HUE.verify, now: HUE.brand, todo: TONE.dim, warn: HUE.warn } as const

function pipeline(change: ChangeState): Row[] {
  const at = ORDER.indexOf(change.step)
  const row = (step: Step, label: string, doneDetail: string, nowDetail: string): Row => {
    const i = ORDER.indexOf(step)
    if (i < at) return { step, glyph: GLYPH.ok, label, detail: doneDetail, state: 'done' }
    if (i === at) return { step, glyph: GLYPH.on, label, detail: nowDetail, state: 'now' }
    return { step, glyph: GLYPH.off, label, detail: '', state: 'todo' }
  }
  const specs = `${change.specCount} capabilit${change.specCount === 1 ? 'y' : 'ies'}`
  const proposal: Row =
    change.step === 'gaps'
      ? { step: 'gaps', glyph: GLYPH.warn, label: 'Proposal', detail: 'acceptance criteria missing', state: 'warn' }
      : { step: 'gaps', glyph: GLYPH.ok, label: 'Proposal', detail: 'proposal.md', state: 'done' }
  return [
    proposal,
    row('spec', 'Spec delta', specs, 'next to write'),
    row('design', 'Design', change.design === 'skipped' ? 'skipped' : 'design.md', 'next to write'),
    row('tasks', 'Tasks', 'tasks.md', 'next to write'),
    row('apply', 'Implement', `${change.tasksTotal}/${change.tasksTotal} tasks`, `${change.tasksDone}/${change.tasksTotal}`),
    row('verify', 'Verify & archive', '', 'ready: verify, then archive'),
  ]
}

// The files the Read row offers, and the key that opens each.
const HOTKEY_OF: Record<Artifact, string> = { proposal: 'p', spec: 's', design: 'd', tasks: 't' }
const ARTIFACTS: Artifact[] = ['proposal', 'spec', 'design', 'tasks']
const FILE_LABEL: Record<Artifact, string> = { proposal: 'proposal', spec: 'spec delta', design: 'design', tasks: 'tasks' }

/** Furthest along first; ties broken by most recent edit. */
function byProgress(a: ChangeState, b: ChangeState) {
  const stage = ORDER.indexOf(b.step) - ORDER.indexOf(a.step)
  if (stage !== 0) return stage
  const ratio = (c: ChangeState) => (c.tasksTotal === 0 ? 0 : c.tasksDone / c.tasksTotal)
  return ratio(b) - ratio(a) || b.mtimeMs - a.mtimeMs
}

function stepText(change: ChangeState) {
  return change.step === 'apply' && change.tasksTotal > 0
    ? `${STEP_LABEL[change.step]} ${change.tasksDone}/${change.tasksTotal}`
    : STEP_LABEL[change.step]
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    await $.command.register({
      name: 'sk-status',
      description: 'Where each SimplifyKit change stands, with the next /sk command one key away',
    })
    await refresh($)
    // Picks up edits made outside Claude (an editor, git pull); refresh() only
    // writes state when something changed, so an idle tick redraws nothing.
    $.clock.every(4000, () => void refresh($))
    return next(e)
  })

  on('command.run', { command: 'sk-status' }, async $ => {
    await refresh($)
    await $.ui.open({ id: PANE, title: 'SimplifyKit', focus: true, closeOnEscape: true })
    return {}
  })

  on('turn.complete', async ($, e, next) => {
    const result = await next(e)
    if (e.agentId !== undefined) return result
    const { changes } = await refresh($)
    if (changes[0]) void $.prompt.suggest({ text: changes[0].next })
    return result
  })

  on('ui.render', { component: 'Pane', requestId: PANE }, async ($, e) => {
    const { Box, Text, Button, Markdown } = $.ui.resolve(e)
    const kit = { Box, Text }
    const { hasSk, changes } = await read($, scanAtom)
    const sort = await read($, sortAtom)
    const selectedId = await read($, selectedAtom)
    const viewing = await read($, viewingAtom)
    const confirming = await read($, confirmAtom)
    const fill = (text: string) => () => void $.prompt.fill({ text })
    const cols = e.props.bodyColumns ?? 40

    if (!hasSk) {
      return (
        <Box flexDirection="column" gap={1}>
          {banner(kit, GLYPH.off, TONE.dim, 'not set up here')}
          <Text>
            No <Text color={HUE.proposal}>sk/</Text> folder in this repository.{' '}
            <Text color={HUE.brand} bold>
              /sk:init
            </Text>{' '}
            sets it up; changes you start with{' '}
            <Text color={HUE.spec} bold>
              /sk:propose
            </Text>{' '}
            show up here.
          </Text>
          <Box>
            <Button key="init" hotkey="1" variant="primary" label="1: Run /sk:init" onPress={() => void runSk($, 'init', '')} />
          </Box>
        </Box>
      )
    }

    if (changes.length === 0) {
      return (
        <Box flexDirection="column" gap={1}>
          {banner(kit, GLYPH.off, TONE.dim, 'no open change')}
          <Text>
            Nothing under <Text color={HUE.proposal}>sk/changes/</Text>. Start one from a work item:{' '}
            <Text color={HUE.spec} bold>
              /sk:propose AB#&lt;id&gt;
            </Text>
          </Text>
          <Box>
            <Button key="propose" hotkey="1" variant="primary" label="1: /sk:propose AB#…" onPress={fill('/sk:propose AB#')} />
          </Box>
        </Box>
      )
    }

    // scan() already orders by most recent edit; the other order is opt-in.
    const list = (sort === 'progress' ? [...changes].sort(byProgress) : changes).slice(0, 9)
    const active = list.find(c => c.id === selectedId) ?? (list[0] as ChangeState)
    const hue = STAGE_HUE[active.step]

    // Reading one artifact: the file itself, read fresh, with a way back.
    if (viewing !== null) {
      const text = await readArtifact($, active, viewing)
      const title = viewing === 'spec' ? 'spec delta' : `${viewing}.md`
      return (
        <Box flexDirection="column" gap={1}>
          <Box gap={2}>
            <Text color={hue} bold wrap="truncate-end">
              {`▍${title} · ${active.id}`}
            </Text>
            <Button key="back" hotkey="b" label="Back" plain autoFocus onPress={() => void update($, viewingAtom, () => null)} />
          </Box>
          <Markdown text={text} />
          <Box>
            <Button key="back-bottom" hotkey="b" label="Back" plain onPress={() => void update($, viewingAtom, () => null)} />
          </Box>
        </Box>
      )
    }

    const blocked = active.openQuestions.length > 0
    const anyBlocked = changes.some(c => c.openQuestions.length > 0 || c.step === 'gaps')
    const status = `${changes.length} open change${changes.length === 1 ? '' : 's'}`
    const barWidth = Math.max(6, Math.min(16, cols - 32))
    const nextSkill = active.next.split(/\s+/)[0]?.replace('/sk:', '') ?? 'continue'
    const isConfirming = confirming === active.id
    const files = ARTIFACTS.filter(
      f =>
        f === 'proposal' ||
        (f === 'spec' && active.specCount > 0) ||
        (f === 'design' && active.design !== 'none') ||
        (f === 'tasks' && active.hasTasks),
    )

    return (
      <Box flexDirection="column" gap={1}>
        {banner(kit, anyBlocked ? GLYPH.warn : GLYPH.on, anyBlocked ? HUE.warn : HUE.verify, status)}

        {changes.length > 1 && (
          <Box flexDirection="column">
            <Box gap={1}>
              <Text color={HUE.proposal} bold>
                ▍Changes
              </Text>
              <Text dimColor>· {sort === 'progress' ? 'furthest along first' : 'last edited first'} ·</Text>
              <Button
                key="sort"
                hotkey="o"
                label={sort === 'progress' ? 'order by last edit' : 'order by progress'}
                plain
                onPress={() => void update($, sortAtom, s => (s === 'progress' ? 'recent' : 'progress'))}
              />
            </Box>
            {list.map((change, i) => {
              const isActive = change.id === active.id
              const warn = change.openQuestions.length > 0 || change.step === 'gaps'
              return (
                <Box gap={1}>
                  <Text color={HUE.brand} bold>
                    {isActive ? '▸' : ' '}
                  </Text>
                  <Box flexGrow={1} flexShrink={1}>
                    <Button
                      key={`pick-${change.id}`}
                      hotkey={String(i + 1)}
                      label={change.id}
                      plain
                      onPress={() => {
                        void update($, selectedAtom, () => change.id)
                        void update($, confirmAtom, () => null)
                      }}
                    />
                  </Box>
                  <Text color={HUE.warn}>{warn ? GLYPH.warn : ' '}</Text>
                  {cell(kit, stepText(change), 14, STAGE_HUE[change.step])}
                </Box>
              )
            })}
          </Box>
        )}

        <Box flexDirection="column">
          <Box gap={1}>
            <Text color={HUE.brand} bold wrap="truncate-end">
              {`▍${active.id}`}
            </Text>
            {badge(kit, STEP_LABEL[active.step].toUpperCase(), HUE.brand)}
          </Box>
          {pipeline(active).map(r => (
            <Box gap={1} paddingLeft={1}>
              <Box width={1} flexShrink={0}>
                <Text color={STATE_COLOR[r.state]} bold>
                  {r.glyph}
                </Text>
              </Box>
              <Box width={17} flexShrink={0}>
                <Text
                  color={r.state === 'now' || r.state === 'warn' ? STATE_COLOR[r.state] : undefined}
                  dimColor={r.state === 'todo'}
                  bold={r.state === 'now' || r.state === 'warn'}
                >
                  {r.label}
                </Text>
              </Box>
              {r.step === 'apply' && r.state === 'now' && active.tasksTotal > 0
                ? bar(kit, active.tasksDone, active.tasksTotal, barWidth)
                : null}
              {r.state === 'warn' ? (
                <Text color={HUE.warn} wrap="truncate-end">
                  {r.detail}
                </Text>
              ) : (
                <Text dimColor wrap="truncate-end">
                  {r.detail}
                </Text>
              )}
            </Box>
          ))}
        </Box>

        {blocked && (
          <Box flexDirection="column" borderStyle="round" borderColor={HUE.warn} paddingX={1}>
            <Box gap={1}>
              {badge(kit, `${GLYPH.warn} OPEN`, HUE.warn)}
              <Text color={HUE.warn} bold>
                {active.openQuestions.join(', ')}
              </Text>
            </Box>
            <Text dimColor>/sk:archive stops until these are answered in the spec delta.</Text>
          </Box>
        )}

        {files.length > 0 && (
          <Box flexDirection="column">
            <Text color={HUE.proposal} bold>
              ▍Read
            </Text>
            <Box gap={3} paddingLeft={1} flexWrap="wrap">
              {files.map(f => (
                <Button
                  key={`view-${f}`}
                  hotkey={HOTKEY_OF[f]}
                  label={FILE_LABEL[f]}
                  plain
                  onPress={() => void update($, viewingAtom, () => f)}
                />
              ))}
            </Box>
          </Box>
        )}

        {isConfirming ? (
          <Box flexDirection="column" borderStyle="round" borderColor={HUE.warn} paddingX={1}>
            <Text color={HUE.warn} bold>
              {GLYPH.warn} Archive {active.id}?
            </Text>
            <Text dimColor>Merges the spec delta into sk/specs/ and moves the change out of sk/changes/.</Text>
            <Box gap={3}>
              <Button
                key="archive-yes"
                hotkey="a"
                label="Yes, archive"
                plain
                onPress={() => {
                  void update($, confirmAtom, () => null)
                  void runSk($, 'archive', active.id)
                }}
              />
              <Button key="cancel" hotkey="c" label="Cancel" plain autoFocus onPress={() => void update($, confirmAtom, () => null)} />
            </Box>
          </Box>
        ) : (
          <Box flexDirection="column">
            <Text color={HUE.verify} bold>
              ▍Next
            </Text>
            <Box gap={3} paddingLeft={1} flexWrap="wrap">
              <Button
                key="next"
                hotkey="n"
                variant="primary"
                label={`n: Run /sk:${nextSkill}`}
                onPress={() => void runSk($, nextSkill, active.id)}
              />
              {/* /sk:ff is never the default next step: the mod cannot tell a small item
                  from a large one, so it is offered next to /sk:continue, not instead of it. */}
              {(active.step === 'spec' || active.step === 'design' || active.step === 'tasks') && (
                <Button key="ff" hotkey="f" label="f: Run /sk:ff" plain onPress={() => void runSk($, 'ff', active.id)} />
              )}
              {active.step === 'verify' && (
                <Button key="archive" hotkey="a" label="Archive…" plain onPress={() => void update($, confirmAtom, () => active.id)} />
              )}
              <Button key="edit" hotkey="e" label="Edit in prompt" plain onPress={fill(active.next)} />
            </Box>
          </Box>
        )}
      </Box>
    )
  })
}
