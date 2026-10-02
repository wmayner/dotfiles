import type { EngineInterface, Register, RenderSurface } from 'claude-code'

const BAR_CELLS = 12
// The engine draws its `[-]` collapse mark over the band's right edge
const COLLAPSE_MARK = 4

// Each meter keeps its own colour until it needs attention: yellow from 70,
// red from 85
export const level = (percent: number, calm: string) =>
  percent >= 85 ? 'red' : percent >= 70 ? 'yellow' : calm

const CONTEXT_COLOR = 'green'
const LIMIT_COLORS: Record<string, string> = { five_hour: 'blue', seven_day: 'magenta' }

// "claude-opus-5-5" and "claude-haiku-4-5-20251001" read as "Opus 5.5" and
// "Haiku 4.5"; anything else (an alias, another provider's id) is shown as is.
export const modelName = (id: string, effort: string) => {
  const [, family, major, minor] = /^claude-([a-z]+)-(\d+)(?:-(\d{1,2}))?(?![\d])/.exec(id) ?? []
  const name =
    family === undefined || major === undefined
      ? id
      : `${family[0]?.toUpperCase()}${family.slice(1)} ${major}${minor === undefined ? '' : `.${minor}`}`

  return effort === '' ? name : `${name} (${effort[0]?.toUpperCase()}${effort.slice(1)})`
}

export const filledCells = (percent: number) =>
  Math.round((Math.min(100, Math.max(0, percent)) / 100) * BAR_CELLS)

// "▲ +98.3k" for growth since the last turn, "▼ 12.0k" after a compaction
export const formatDelta = (delta: number) =>
  `${delta < 0 ? '▼ ' : '▲ +'}${(Math.abs(delta) / 1000).toFixed(1)}k`

/** The last fenced code block in `text`, or null. */
export const lastCodeBlock = (text: string) =>
  [...text.matchAll(/```[^\n]*\n([\s\S]*?)```/g)].pop()?.[1]?.replace(/\n$/, '') ?? null

const WINDOWS: Record<string, string> = { five_hour: '5h', seven_day: '7d', spend_limit: 'spend' }

// ponytail: module variables, refilled by session.start on every reload;
// move to $.state if anything else needs to read them.
let branch = ''
let title = ''
// ponytail: effort only arrives with tool calls and turn ends, so it is
// missing until the first of either in a session.
let effort = ''
// Context tokens at the end of the previous turn, and the change over the last one
let lastTokens: number | undefined
let delta: number | undefined

// Reads the branch, sets the iTerm2 window/tab title, and redraws
const refresh = async ($: EngineInterface) => {
  const git = await $.process.run(['git', 'branch', '--show-current'], { timeoutMs: 2000 }).catch(() => null)
  branch = git?.exitCode === 0 ? git.stdout.trim() : ''
  const dir = (await $.session.root()).split('/').pop() ?? ''
  const tab = title === '' ? `${dir}: CC` : `${dir}: CC: ${title}`
  await $.process
    .run(['sh', '-c', 'printf "\\033]0;%s\\007" "$1" > /dev/tty', 'sh', tab], { timeoutMs: 2000 })
    .catch(() => null)
  $.ui.invalidate('ui.render')
}

// Copies the last code block of Claude's last reply, or the whole reply
// when it has none, so long strings never pass through terminal wrapping
async function copyLast($: EngineInterface, surface: RenderSurface) {
  const messages = await $.session.messages()
  const reply = 'deny' in messages ? undefined : messages.findLast(m => m.role === 'assistant' && m.text.trim() !== '')
  if (reply === undefined) {
    $.ui.toast('Nothing to copy yet')

    return
  }
  const block = lastCodeBlock(reply.text)
  const { isCopied } = await $.ui.copy({ text: block ?? reply.text, surface })
  $.ui.toast(isCopied ? (block === null ? 'Copied the last reply' : 'Copied the last code block') : 'Could not reach the clipboard')
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    const result = await next(e)
    lastTokens = (await $.session.usage()).context.tokens
    await refresh($)

    return result
  })

  on('turn.complete', async ($, e, next) => {
    const result = await next(e)
    // A subagent's turn does not move the main context window
    if (e.agentId !== undefined) {
      return result
    }

    const { tokens } = (await $.session.usage()).context
    delta = tokens === undefined || lastTokens === undefined ? undefined : tokens - lastTokens
    lastTokens = tokens ?? lastTokens
    await refresh($)

    return result
  })

  on('session.measure', ($, e, next) => {
    $.ui.invalidate('ui.render')

    return next(e)
  })

  // ponytail: the title only arrives with these two events, so a new
  // AI-generated title shows one prompt late.
  on('classic.PostToolUse', ($, e, next) => {
    if (e.agent_id === undefined && e.effort !== undefined && e.effort.level !== effort) {
      effort = e.effort.level
      $.ui.invalidate('ui.render')
    }

    return next(e)
  })

  on('classic.Stop', ($, e, next) => {
    effort = e.effort?.level ?? effort

    return next(e)
  })

  on('classic.SessionStart', ($, e, next) => {
    title = e.session_title ?? title

    return next(e)
  })

  on('classic.UserPromptSubmit', ($, e, next) => {
    title = e.session_title ?? title

    return next(e)
  })

  on('ui.render', { component: 'AbovePrompt' }, async ($, e, next) => {
    if (e.props.hasSurvey) {
      return next(e)
    }

    const [root, model, usage] = await Promise.all([$.session.root(), $.session.model(), $.session.usage()])
    const { Box, Text, Button } = $.ui.resolve(e)
    const dir = root.split('/').pop() ?? root
    const percent = usage.context.percent

    return (
      <Box width={e.props.bodyColumns - COLLAPSE_MARK} gap={2}>
        <Text bold>{dir}</Text>
        {branch === '' ? null : <Text color="cyan">{branch}</Text>}
        <Text dimColor>{modelName(model, effort)}</Text>
        <Box flexGrow={1} flexShrink={1}>
          <Text dimColor italic wrap="truncate-end">
            {title}
          </Text>
        </Box>
        {percent === undefined ? null : (
          <Box>
            <Text color={level(percent, CONTEXT_COLOR)}>{'━'.repeat(filledCells(percent))}</Text>
            <Text dimColor>{'━'.repeat(BAR_CELLS - filledCells(percent))}</Text>
            <Text color={level(percent, CONTEXT_COLOR)}> {percent}%</Text>
            {delta === undefined ? null : <Text dimColor> {formatDelta(delta)}</Text>}
          </Box>
        )}
        {usage.rateLimits.map(limit => (
          <Box>
            <Text dimColor>{WINDOWS[limit.kind] ?? limit.kind} </Text>
            <Text color={level(limit.percentUsed, LIMIT_COLORS[limit.kind] ?? 'cyan')}>
              {Math.round(limit.percentUsed)}%
            </Text>
          </Box>
        ))}
        <Button key="copy" label="⧉" hotkey="c" plain dimColor onPress={() => copyLast($, e.surface)} />
      </Box>
    )
  })
}
