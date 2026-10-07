import type { SessionMessage } from 'claude-code'

export const MIN_MS = 20_000 // turns shorter than this never get a line
export const EVERY_MS = 60_000 // at most one refresh a minute
export const TICK_MS = 15_000

export type Turn = {
  running: boolean
  startedAt: number
  endedAt: number
  activity: number // bumped by each tool call; starts at 1 so a tool-less turn still gets a line
  summarizedActivity: number
  summarizedAt: number
}

export const newTurn = (now: number): Turn => ({
  running: true,
  startedAt: now,
  endedAt: 0,
  activity: 1,
  summarizedActivity: 0,
  summarizedAt: -Infinity,
})

export function isDue(t: Turn, now: number): boolean {
  if (!t.running) {
    // A turn that ran long but ended before its first line still gets one, for the band.
    return t.endedAt - t.startedAt >= MIN_MS && t.summarizedActivity === 0
  }
  return (
    now - t.startedAt >= MIN_MS &&
    t.activity > t.summarizedActivity &&
    now - t.summarizedAt >= EVERY_MS
  )
}

export const SYSTEM = `You write the one-line status shown while a coding agent works on a user's request.
Reply with exactly one line and nothing else, in the form:
<what the agent is doing right now> · <why: the user's goal>
At most 90 characters. Be concrete: name files, commands or components. Start the first half with a present participle.
Example: Editing statusline.sh to parse cache stats · so the status line shows cache warmth
Only use file names and commands that appear in the input; never guess a file's extension.
If a previous line is given, keep its second half unless the goal clearly changed.`

const head = (s: string, n: number) => (s.length > n ? s.slice(0, n) + '…' : s)
const tail = (s: string, n: number) => (s.length > n ? '…' + s.slice(-n) : s)

const isPrompt = (m: SessionMessage) =>
  m.role === 'user' && m.text.trim() !== '' && !m.toolResults?.length

const ARG_KEYS = ['file_path', 'command', 'pattern', 'url', 'query', 'prompt', 'skill']

function describeCall(tool: string, input: Record<string, unknown>): string {
  const key = ARG_KEYS.find(k => typeof input[k] === 'string')
  const arg = key ? String(input[key]) : JSON.stringify(input)
  const call = `${tool}(${head(arg.replace(/\s+/g, ' '), 100)})`
  return typeof input.description === 'string' ? `${call}: ${input.description}` : call
}

/** The text Haiku summarizes: the turn's prompt, the exchange before it, and what the turn has done so far. */
export function buildDigest(messages: readonly SessionMessage[], previousLine: string | null): string {
  const at = messages.findLastIndex(isPrompt)
  if (at === -1) return ''

  const before = messages.slice(0, at)
  const priorReply = before.findLast(m => m.role === 'assistant' && m.text.trim() !== '')
  const priorPrompt = before.findLast(isPrompt)

  const during = messages.slice(at + 1)
  const said = during.filter(m => m.role === 'assistant' && m.text.trim() !== '').slice(-3)
  const calls = during.flatMap(m => m.toolUses).slice(-10)

  const parts: string[] = []
  if (priorPrompt) parts.push(`Earlier user request:\n${head(priorPrompt.text, 500)}`)
  if (priorReply) parts.push(`Agent's previous reply:\n${tail(priorReply.text, 1200)}`)
  parts.push(`Current user request:\n${head(messages[at]?.text ?? '', 1500)}`)
  if (said.length) parts.push(`What the agent has said this turn:\n${said.map(m => tail(m.text, 400)).join('\n---\n')}`)
  if (calls.length) parts.push(`Its latest tool calls, oldest first:\n${calls.map(c => describeCall(c.tool, c.input)).join('\n')}`)
  if (previousLine) parts.push(`Previous line: ${previousLine}`)
  return parts.join('\n\n')
}

/** First line of the reply, without quotes, capped. */
export function cleanLine(text: string): string {
  const first = (text.trim().split('\n')[0] ?? '').trim().replace(/^["'`]|["'`]$/g, '')
  return head(first, 120)
}

/** The line's two halves; `why` is empty when the model left out the separator. */
export function splitLine(line: string): { what: string; why: string } {
  const [what = line, why = ''] = line.split(' · ')
  return { what, why }
}

/** What the spinner shows: our line, or the engine's own message (a todo's text) plus our why. */
export function spinnerMessage(line: string, engineMessage: string | null): string {
  if (!engineMessage) return line
  const { why } = splitLine(line)
  return why ? `${engineMessage.replace(/…$/, '')} · ${why}` : engineMessage
}
