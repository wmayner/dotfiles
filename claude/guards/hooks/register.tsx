// The hold-and-confirm pane follows Anthropic's Blast Radius example mod
// (github.com/anthropics/claude-code-playground, Apache-2.0).
//
// tool.call: a command that would discard uncommitted changes this session
// did not make, or that starts cloud billing, is held behind a pane with
// Proceed and Cancel. An edit that adds a global random seed is refused.

import type { Elements, EngineInterface, Register } from 'claude-code'

const PANE_ID = 'guards'
const POLL_SECONDS = '0.25'
const HOLD_LIMIT_MS = 10 * 60 * 1000
const LIST_MAX = 12

// ---- Global random seeds ---------------------------------------------------

const GLOBAL_SEED = /\b(?:np|numpy)\.random\.seed\s*\(|(?<![\w.])random\.seed\s*\(/

export const addsGlobalSeed = (before: string, after: string) =>
  GLOBAL_SEED.test(after) && !GLOBAL_SEED.test(before)

const SEED_DENY =
  'guards: this adds a global random seed (np.random.seed or random.seed), which mutates global state. ' +
  'Take a `seed` argument and use an isolated generator instead, np.random.default_rng(seed) or ' +
  'random.Random(seed), and save the seed alongside the output.'

// ---- What gets held --------------------------------------------------------

export type Risk =
  | { kind: 'git'; label: string; dir: string | null; paths: string[] | null }
  | { kind: 'spend'; label: string; note: string }

const SPEND_TOOLS: Record<string, string> = {
  'mcp__plugin_remote-kernels_remote-kernels__start': 'start a cloud GPU machine',
  'mcp__plugin_remote-kernels_remote-kernels__attach': 'resume a cloud GPU machine',
  'mcp__runpod__create-pod': 'create a RunPod pod',
  'mcp__runpod__create-endpoint': 'create a RunPod endpoint',
  'mcp__runpod__create-cluster': 'create a RunPod cluster',
}

/** Splits one segment into words, honouring quotes. */
const tokenize = (text: string) =>
  [...text.matchAll(/"((?:[^"\\]|\\.)*)"|'([^']*)'|(\S+)/g)].map(m => m[1] ?? m[2] ?? m[3] ?? '')

const joinDir = (dir: string | null, arg: string) => (dir === null || arg.startsWith('/') ? arg : `${dir}/${arg}`)

/** The first held segment of a shell command, or null. */
export const classify = (command: string): Risk | null => {
  // ponytail: tracks a plain `cd dir` and `git -C dir`; subshells, pushd and
  // `..` are not followed. Blast Radius has the full version if this misses.
  let dir: string | null = null
  for (const segment of command.split(/&&|\|\||;|\||\n/)) {
    const words = tokenize(segment.trim())
    while (words.length > 0 && /^[A-Za-z_][A-Za-z0-9_]*=/.test(words[0] ?? '')) {
      words.shift()
    }
    const [cmd, ...args] = words
    if (cmd === 'cd' && args[0] !== undefined) {
      dir = joinDir(dir, args[0])
    } else if (cmd === 'vastai' && args[1] === 'instance' && ['create', 'launch', 'start'].includes(args[0] ?? '')) {
      return { kind: 'spend', label: `vastai ${args[0]} instance`, note: 'This starts hourly billing on vast.ai.' }
    } else if (cmd === 'vastai' && args[0] === 'destroy') {
      return { kind: 'spend', label: 'vastai destroy', note: "This deletes the instance and its disk. It can't be undone." }
    } else if (cmd === 'git') {
      let gitDir = dir
      let i = 0
      while (i < args.length && (args[i] ?? '').startsWith('-')) {
        if (args[i] === '-C' && args[i + 1] !== undefined) {
          gitDir = joinDir(gitDir, args[i + 1] ?? '')
        }
        i += args[i] === '-C' || args[i] === '-c' ? 2 : 1
      }
      const sub = args[i]
      const rest = args.slice(i + 1)
      const positional = rest.filter(a => !a.startsWith('-'))
      const afterDashes = rest.includes('--') ? rest.slice(rest.indexOf('--') + 1) : null
      if (sub === 'reset' && rest.includes('--hard')) {
        return { kind: 'git', label: 'git reset --hard', dir: gitDir, paths: null }
      }
      if (sub === 'stash' && (rest[0] === undefined || rest[0] === 'push' || rest[0] === 'save' || rest[0].startsWith('-'))) {
        return { kind: 'git', label: 'git stash', dir: gitDir, paths: null }
      }
      if (sub === 'checkout' && (rest.includes('-f') || rest.includes('--force')) && afterDashes === null) {
        return { kind: 'git', label: 'git checkout --force', dir: gitDir, paths: null }
      }
      const isStagedOnly = rest.includes('--staged') && !rest.includes('--worktree') && !rest.includes('-W')
      if ((sub === 'checkout' || (sub === 'restore' && !isStagedOnly)) && (afterDashes ?? positional).length > 0) {
        // `git checkout some-branch` lands here too: it is only held if
        // "some-branch" also names a changed path, which measuring decides.
        return { kind: 'git', label: `git ${sub}`, dir: gitDir, paths: afterDashes ?? positional }
      }
    }
  }

  return null
}

// ---- Measuring -------------------------------------------------------------

type Report = { summary: string; lines: string[]; note: string }

// Files this session's Edit and Write calls changed, absolute.
// ponytail: forgotten on a hot reload, and edits made through Bash are never
// seen, so those files are reported as not this session's. The pane says so.
const touched = new Set<string>()

/** Changed tracked files under `targets` that this session did not edit; null when not in a repo. */
async function unrelatedChanges($: EngineInterface, risk: Risk & { kind: 'git' }) {
  const sessionCwd = await $.session.cwd()
  const cwd = risk.dir === null ? sessionCwd : joinDir(sessionCwd, risk.dir)
  const top = await $.process.run(['git', 'rev-parse', '--show-toplevel'], { cwd, timeoutMs: 10000 }).catch(() => null)
  const status = await $.process.run(['git', 'status', '--porcelain'], { cwd, timeoutMs: 15000 }).catch(() => null)
  if (top === null || status === null || top.exitCode !== 0 || status.exitCode !== 0) {
    return null
  }
  const root = top.stdout.trim()
  const targets = risk.paths?.map(p => (p === '.' ? cwd : joinDir(cwd, p)).replace(/\/+$/, '')) ?? null

  return status.stdout
    .split('\n')
    .filter(row => row.length > 3 && !row.startsWith('??'))
    .map(row => `${root}/${row.slice(3).split(' -> ').pop()}`)
    .filter(file => !touched.has(file))
    .filter(file => targets === null || targets.some(t => file === t || file.startsWith(`${t}/`)))
    .map(file => file.slice(root.length + 1))
}

// ---- Holding ---------------------------------------------------------------

type Held = { command: string; label: string; report: Report; decision: string | null; where: 'pane' | 'band' }

// The call being held, or null. One at a time.
let held: Held | null = null

/** Opens the pane and waits for a button; resolves 'proceed' or the reason it was not run. */
async function hold($: EngineInterface, signal: AbortSignal, mine: Held) {
  while (held !== null) {
    if (signal.aborted) {
      return 'the turn was interrupted'
    }
    await $.process.run(['sleep', POLL_SECONDS], { timeoutMs: 5000 })
  }
  held = mine
  let isPlaced = false
  try {
    const opened = await $.ui.open({ id: PANE_ID, title: 'Confirm', focus: true, rows: 9 + mine.report.lines.length })
    isPlaced = opened.isPlaced
    // No room for a pane (a narrow terminal): the band above the prompt draws it
    if (!isPlaced) {
      mine.where = 'band'
    }
    $.ui.invalidate('ui.render')
    const startedAt = await $.clock.now()
    while (mine.decision === null) {
      if (signal.aborted) {
        return 'the turn was interrupted'
      }
      if ((await $.clock.now()) - startedAt > HOLD_LIMIT_MS) {
        return 'no answer within 10 minutes'
      }
      await $.process.run(['sleep', POLL_SECONDS], { timeoutMs: 5000 })
    }

    return mine.decision === 'proceed' ? 'proceed' : 'the user pressed Cancel'
  } catch {
    return 'guards hit an error while holding it'
  } finally {
    if (isPlaced) {
      await $.ui.close({ id: PANE_ID }).catch(() => undefined)
    }
    if (held === mine) {
      held = null
    }
    $.ui.invalidate('ui.render')
  }
}

// ---- Drawing ---------------------------------------------------------------

function draw({ Box, Text, Button }: Pick<Elements['terminal'], 'Box' | 'Text' | 'Button'>, state: Held) {
  // The buttons answer the call this pane was drawn for, never whichever is held now.
  const decide = (choice: string) => () => {
    state.decision ??= choice
  }

  return (
    <Box flexDirection="column" borderStyle="round" borderColor="yellow" paddingX={1}>
      <Text bold color="yellow">
        ⚠ {state.label}
      </Text>
      <Text wrap="truncate-end">
        <Text dimColor>Command  </Text>
        <Text bold>{state.command}</Text>
      </Text>
      <Text>
        <Text dimColor>Would    </Text>
        <Text bold color="red">
          {state.report.summary}
        </Text>
      </Text>
      <Box flexDirection="column" marginTop={1}>
        {state.report.lines.map(line => (
          <Text wrap="truncate-end">  {line}</Text>
        ))}
      </Box>
      <Text dimColor italic wrap="wrap">
        {state.report.note}
      </Text>
      <Box marginTop={1} gap={2}>
        <Button key="proceed" label="Proceed" hotkey="1" plain onPress={decide('proceed')} />
        <Button key="cancel" label="Cancel" hotkey="2" plain autoFocus onPress={decide('cancel')} />
        <Text dimColor>Claude is waiting on your answer</Text>
      </Box>
    </Box>
  )
}

export const register: Register = on => {
  on('tool.call', async ($, e, next) => {
    const tool = String(e.tool)
    const input = e as Record<string, unknown>

    if (tool === 'Edit' || tool === 'Write' || tool === 'NotebookEdit') {
      const path = String(input.file_path ?? input.notebook_path ?? '')
      if (/\.(py|ipynb)$/.test(path)) {
        const after = String(input.new_string ?? input.content ?? input.new_source ?? '')
        const before =
          tool === 'Edit'
            ? String(input.old_string ?? '')
            : tool === 'Write' && (await $.fs.exists(path))
              ? String(await $.fs.read(path).catch(() => ''))
              : ''
        if (addsGlobalSeed(before, after)) {
          return { deny: SEED_DENY }
        }
      }
      const ran = await next(e)
      if (ran.deny === undefined && ran.isError !== true) {
        touched.add(path)
      }

      return ran
    }

    let mine: Held | null = null
    if (tool === 'Bash') {
      const command = String(input.command ?? '')
      const risk = classify(command)
      if (risk?.kind === 'spend') {
        mine = { command, label: risk.label, report: { summary: risk.label, lines: [], note: risk.note }, decision: null, where: 'pane' }
      } else if (risk?.kind === 'git') {
        const files = await unrelatedChanges($, risk)
        if (files !== null && files.length > 0) {
          const summary = `discard changes in ${files.length} ${files.length === 1 ? 'file' : 'files'} this session did not edit`
          const lines = files.slice(0, LIST_MAX)
          if (files.length > LIST_MAX) {
            lines.push(`+ ${files.length - LIST_MAX} more`)
          }
          const note = 'Listed: changed files not written by this session’s Edit or Write. Edits made through Bash count as not this session’s.'
          mine = { command, label: risk.label, report: { summary, lines, note }, decision: null, where: 'pane' }
        }
      }
    } else if (SPEND_TOOLS[tool] !== undefined) {
      const { tool: _tool, tool_use_id: _id, ...args } = input
      const summary = SPEND_TOOLS[tool] ?? tool
      mine = { command: `${tool} ${JSON.stringify(args)}`, label: summary, report: { summary, lines: [], note: 'This starts billing.' }, decision: null, where: 'pane' }
    }

    if (mine === null) {
      return next(e)
    }
    const outcome = await hold($, next.signal, mine)
    if (outcome === 'proceed') {
      return next(e)
    }

    return {
      deny: `guards held this and did not run it: ${outcome}. It would have: ${mine.report.summary}. Do not retry it or work around it unless the user asks you to.`,
    }
  })

  on('ui.render', { component: 'Pane' }, ($, e, next) =>
    e.requestId !== PANE_ID || held === null ? next(e) : draw($.ui.resolve(e), held),
  )

  on('ui.render', { component: 'AbovePrompt' }, async ($, e, next) => {
    if (held === null || held.where !== 'band') {
      return next(e)
    }
    const { Box } = $.ui.resolve(e)
    const mine = draw($.ui.resolve(e), held)
    const below = await next(e).catch(() => null)

    return below === null || below === undefined ? mine : (
      <Box flexDirection="column">
        {mine}
        {below}
      </Box>
    )
  })
}
