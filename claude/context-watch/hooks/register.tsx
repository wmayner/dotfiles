// Warns as the context window fills, and keeps a tally of what each tool
// result added to it: /context-top lists the largest in a pane.
//
// The per-turn tracking follows Anthropic's Token Weather example mod
// (github.com/anthropics/claude-code-playground, Apache-2.0).

import type { Register } from 'claude-code'

const PANE_ID = 'context-top'
const THRESHOLDS = [80, 90]
const TOP = 15
// ponytail: a rough rule of thumb; the engine's own count needs an API call per result
const CHARS_PER_TOKEN = 4

type Entry = { tool: string; detail: string; chars: number }

// ponytail: module variables, so a hot reload forgets the tally so far
let entries: Entry[] = []
let warnedAt = 0

/** The highest threshold `percent` has reached, or 0. */
export const thresholdFor = (percent: number) => Math.max(0, ...THRESHOLDS.filter(t => percent >= t))

export const largest = (all: Entry[]) => [...all].sort((a, b) => b.chars - a.chars).slice(0, TOP)

export const tokens = (chars: number) => {
  const n = chars / CHARS_PER_TOKEN

  return n >= 1000 ? `${(n / 1000).toFixed(1)}k` : String(Math.round(n))
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    const result = await next(e)
    await $.command.register({ name: 'context-top', description: 'List the tool results that took the most context this session' })

    return result
  })

  on('session.measure', ($, e, next) => {
    const reached = thresholdFor(e.context.percent ?? 0)
    if (reached > warnedAt) {
      $.ui.toast(`Context is at ${e.context.percent}%. Consider /prepare-compact, or /context-top to see what filled it.`, {
        timeoutMs: 15000,
      })
    }
    // Falls back after a compaction, so the next climb warns again
    warnedAt = reached

    return next(e)
  })

  on('session.compact', async ($, e, next) => {
    const result = await next(e)
    entries = []

    return result
  })

  on('tool.call', async ($, e, next) => {
    const ran = await next(e)
    // A subagent's results stay in its own context
    if (e.agentId === undefined && ran.deny === undefined) {
      const input = e as Record<string, unknown>
      const detail = String(input.file_path ?? input.command ?? input.pattern ?? input.url ?? input.description ?? '')
      entries.push({
        tool: String(e.tool),
        detail: detail.replace(/\s+/g, ' ').slice(0, 80),
        chars: (ran.text ?? JSON.stringify(ran.result) ?? '').length,
      })
    }

    return ran
  })

  on('command.run', { command: 'context-top' }, async $ => {
    if (entries.length === 0) {
      return { text: 'context-top: no tool results recorded yet.' }
    }
    await $.ui.open({ id: PANE_ID, title: 'Context', focus: true, closeOnEscape: true, rows: Math.min(entries.length, TOP) + 6 })

    return { text: `context-top: ${entries.length} tool results recorded.` }
  })

  on('ui.render', { component: 'Pane' }, ($, e, next) => {
    if (e.requestId !== PANE_ID) {
      return next(e)
    }
    const { Box, Text, Button } = $.ui.resolve(e)
    const total = entries.reduce((sum, entry) => sum + entry.chars, 0)

    return (
      <Box flexDirection="column" borderStyle="round" borderColor="green" paddingX={1}>
        <Text bold color="green">
          Largest tool results · about {tokens(total)} tokens from {entries.length} results
        </Text>
        <Box flexDirection="column" marginTop={1}>
          {largest(entries).map(entry => (
            <Box gap={2}>
              <Box width={7} justifyContent="flex-end">
                <Text bold>{tokens(entry.chars)}</Text>
              </Box>
              <Box width={10}>
                <Text color="cyan" wrap="truncate-end">
                  {entry.tool}
                </Text>
              </Box>
              <Text dimColor wrap="truncate-end">
                {entry.detail}
              </Text>
            </Box>
          ))}
        </Box>
        <Box marginTop={1} gap={2}>
          <Button key="close" label="Close" hotkey="c" autoFocus onPress={() => $.ui.close({ id: PANE_ID })} />
          <Text dimColor>Estimated at {CHARS_PER_TOKEN} characters per token</Text>
        </Box>
      </Box>
    )
  })
}
