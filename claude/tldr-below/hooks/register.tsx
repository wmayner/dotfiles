// A one-sentence Haiku TL;DR drawn under each long reply, which stays in full.
// Adapted from the tldr plugin in alignment-hive (github.com/Crazytieguy/alignment-hive),
// which collapses the reply to the TL;DR instead. Only the drawing changes; the
// stored transcript and the model's context are untouched. /tldr toggles it.
import { atom, read, update, memberOf } from 'claude-code'
import type { EngineInterface, Register } from 'claude-code'

const GUIDELINES = `You write the one-sentence TL;DR shown under a long message from an AI assistant. The reader asked the assistant for something, maybe hours of work ago, and wants to know how it went.

- One plain sentence, under 30 words, no prefix. Write as the assistant, to the reader: its "I" stays "I", the reader is "you".
- Lead with the outcome: the answer, result or finding, keeping the message's hedges, tense and who did what.
- Mention a question or request only if the message actually puts one to the reader, in its own words. Never comment on the message or on what it doesn't ask.

Reply with the sentence only.`

const FAIL = '!fail:'
const KEEP_SESSIONS = 20

const isOn = atom({ plugin: 'tldr-below', key: 'isOn' } as const, true)
const line = atom({ plugin: 'tldr-below', key: 'line' } as const, '')
const isFinal = atom({ plugin: 'tldr-below', key: 'isFinal' } as const, false)

/** Long enough for a TL;DR: over 100 words and more than one non-blank line. */
export const isLong = (text: string) =>
  text.split(/\s+/).filter(Boolean).length > 100 && text.split('\n').filter(l => l.trim()).length > 1

// Ids summarized or in flight this load. ponytail: no retry and no concurrency
// cap; a failed summary says so under the reply. Add both if Haiku flakes often.
const started = new Set<string>()
let saving: Promise<void> = Promise.resolve()

async function save($: EngineInterface, id: string, t: string) {
  const sid = await $.session.id() // looked up per save: /clear starts a new session
  const saved = ((await $.store.get('s/' + sid)) ?? {}) as Record<string, string>
  saved[id] = t
  await $.store.set('s/' + sid, saved)
  const index = ((await $.store.get('sessions')) ?? []) as string[]
  if (!index.includes(sid)) {
    index.push(sid)
    while (index.length > KEEP_SESSIONS) await $.store.delete('s/' + index.shift())
    await $.store.set('sessions', index)
  }
}

async function summarize($: EngineInterface, id: string, text: string) {
  let t: string
  try {
    const r = await $.model.complete({
      model: 'haiku',
      system: GUIDELINES,
      prompt: '<message>\n' + text + '\n</message>',
      effort: 'low',
      timeoutMs: 30000,
    })
    t = r.isAnswered ? r.text.trim().replace(/^tl;?dr\s*:\s*/i, '').replace(/\s*\n+\s*/g, ' ') : FAIL + (r.reason ?? 'no answer')
  } catch (err) {
    t = FAIL + String(err)
  }
  await update($, memberOf(line, { requestId: id }), () => t)
  if (!t.startsWith(FAIL)) {
    // Serialized read-modify-writes; a failed save must not stall the ones after it.
    saving = saving.then(() => save($, id, t)).catch(() => {})
    await saving
  }
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    const enabled = (await $.store.get('enabled')) !== false
    await update($, isOn, () => enabled)
    await $.command.register({ name: 'tldr', description: 'One-sentence TL;DR under long replies: /tldr toggles; on, off' })
    const saved = ((await $.store.get('s/' + (await $.session.id()))) ?? {}) as Record<string, string>
    for (const [id, t] of Object.entries(saved)) await update($, memberOf(line, { requestId: id }), () => t)
    return next(e)
  })

  on('session.append', { door: 'response' }, async ($, e, next) => {
    const r = await next(e)
    // The row is stored, so its text is whole; marking it redraws the block, which starts the summary.
    if (!e.agentId && r.uuid && r.message?.type === 'assistant') {
      await update($, memberOf(isFinal, { requestId: r.uuid }), () => true)
    }
    return r
  })

  on('command.run', { command: 'tldr' }, async ($, e) => {
    const a = e.args.trim().toLowerCase()
    if (a !== '' && a !== 'on' && a !== 'off') return { text: 'Usage: /tldr (toggle), /tldr on, /tldr off' }
    const value = a === '' ? !(await read($, isOn)) : a === 'on'
    await $.store.set('enabled', value)
    await update($, isOn, () => value)
    return { text: value ? 'tl;dr on: long replies get a one-sentence summary underneath.' : 'tl;dr off.' }
  })

  on('ui.render', { component: 'AssistantMessage' }, async ($, e, next) => {
    const text = e.props.text
    if (!isLong(text) || !(await read($, isOn))) return next(e)
    const id = e.requestId
    const t = await read($, memberOf(line, e))
    const fin = await read($, memberOf(isFinal, e))
    if (fin && !t && !started.has(id)) {
      started.add(id)
      summarize($, id, text).catch(() => {})
    }
    // Still streaming, or stored before this mod started: the engine's own drawing.
    if (!t && !fin) return next(e)

    const { Box, Text } = $.ui.resolve(e)
    const indent = e.surface === 'terminal' ? 2 : 0 // under the message text, past the bullet
    return (
      <Box flexDirection="column">
        {await next(e)}
        <Box marginTop={1} paddingLeft={indent}>
          {!t ? (
            <Text dimColor italic>tl;dr: summarizing…</Text>
          ) : t.startsWith(FAIL) ? (
            <Text dimColor>tl;dr unavailable: {t.slice(FAIL.length)}</Text>
          ) : (
            <Text>
              <Text bold>tl;dr </Text>
              {t}
            </Text>
          )}
        </Box>
      </Box>
    )
  })
}
