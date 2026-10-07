import { atom, read, update } from 'claude-code'
import type { Register } from 'claude-code'

import { buildDigest, cleanLine, isDue, newTurn, spinnerMessage, splitLine, SYSTEM, TICK_MS } from './logic'
import type { Turn } from './logic'
import type { Line } from '../types'

const line = atom({ plugin: 'now-line', key: 'line' } as const, null as Line)

export const register: Register = on => {
  // ponytail: module state, lost on hot reload; the next turn.start rebuilds it
  let turn: Turn | null = null
  let isBusy = false
  let hasLoggedFailure = false

  on('session.start', async ($, e, next) => {
    $.clock.every(TICK_MS, async () => {
      if (turn === null || isBusy || !isDue(turn, await $.clock.now())) return
      const t = turn
      isBusy = true
      // Count the attempt whether or not it succeeds, so a failing model is retried
      // at the normal pace and an ended turn is not retried at all.
      t.summarizedActivity = t.activity
      t.summarizedAt = await $.clock.now()
      try {
        const messages = await $.session.messages()
        if (!Array.isArray(messages)) return
        const previous = await read($, line)
        const digest = buildDigest(messages, previous)
        if (digest === '') return
        const reply = await $.model.complete({
          model: 'haiku',
          system: SYSTEM,
          prompt: digest,
          effort: 'low',
          maxTokens: 100,
          timeoutMs: 8000,
        })
        if (!reply.isAnswered) throw new Error(reply.reason)
        if (turn !== t) return // a new turn started while Haiku was answering
        await update($, line, () => cleanLine(reply.text))
      } catch (error) {
        if (!hasLoggedFailure) $.ui.log(`now-line: no summary (${error instanceof Error ? error.message : error})`)
        hasLoggedFailure = true
      } finally {
        isBusy = false
      }
    })
    return next(e)
  })

  on('turn.start', async ($, e, next) => {
    // A turn started without a typed prompt continues the work before it.
    if (e.text === '' && turn !== null) {
      turn.running = true
      return next(e)
    }
    turn = newTurn(await $.clock.now())
    await update($, line, () => null)
    return next(e)
  })

  on('tool.call', ($, e, next) => {
    if (turn?.running) turn.activity += 1
    return next(e)
  }).catch(($, e, next) => next(e))

  on('turn.complete', async ($, e, next) => {
    if (e.agentId === undefined && turn !== null) {
      turn.running = false
      turn.endedAt = await $.clock.now()
    }
    return next(e)
  })

  on('ui.render', { component: 'Spinner' }, async ($, e, next) => {
    // The main thread's spinner carries the session id; a subagent's carries its own.
    if (e.requestId !== (await $.session.id())) return next(e)
    const text = await read($, line)
    if (text === null) return next(e)
    return next({ ...e, props: { ...e.props, message: spinnerMessage(text, e.props.message) } })
  })

  on('ui.render', { component: 'AbovePrompt' }, async ($, e, next) => {
    if (e.props.hasSurvey || e.props.isWorking) return next(e)
    const text = await read($, line)
    if (text === null) return next(e)
    const { what, why } = splitLine(text)
    const { Box, Text } = $.ui.resolve(e)
    return (
      <Box flexDirection="column">
        {why !== '' && (
          <Text dimColor wrap="truncate-end">
            <Text bold>Why</Text> {why}
          </Text>
        )}
        <Text dimColor wrap="truncate-end">
          <Text bold>Last step</Text> {what}
        </Text>
      </Box>
    )
  })
}
