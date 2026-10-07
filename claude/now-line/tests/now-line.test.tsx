import type { RenderPropsOf, SessionMessage } from 'claude-code'
import { expect, mock, test } from 'claude-code/testing'

import { buildDigest, isDue, newTurn, spinnerMessage } from '../hooks/logic'

const bandText = async (band: { findAll: (q: { type: 'Text' }) => Promise<{ text?: string }[]> }) =>
  (await band.findAll({ type: 'Text' })).map(t => t.text)

const user = (text: string): SessionMessage => ({ role: 'user', text, toolUses: [] })
const reply = (text: string, toolUses: SessionMessage['toolUses'] = []): SessionMessage => ({
  role: 'assistant',
  text,
  toolUses,
})
const toolResult: SessionMessage = {
  role: 'user',
  text: '',
  toolUses: [],
  toolResults: [{ tool_use_id: 'a', text: 'ok' } as never],
}

test('isDue waits 20s, then refreshes at most once a minute and only after new activity', () => {
  const t = newTurn(0)
  expect(isDue(t, 19_000)).toBe(false)
  expect(isDue(t, 20_000)).toBe(true) // turn start counts as activity
  t.summarizedActivity = t.activity
  t.summarizedAt = 20_000
  expect(isDue(t, 200_000)).toBe(false) // nothing new happened
  t.activity += 1
  expect(isDue(t, 70_000)).toBe(false)
  expect(isDue(t, 80_000)).toBe(true)
})

test('isDue gives a long turn that ended without a line one last refresh', () => {
  const short = { ...newTurn(0), running: false, endedAt: 10_000 }
  const long = { ...newTurn(0), running: false, endedAt: 30_000 }
  expect(isDue(short, 30_000)).toBe(false)
  expect(isDue(long, 30_000)).toBe(true)
  expect(isDue({ ...long, summarizedActivity: 1 }, 30_000)).toBe(false)
})

test('spinnerMessage keeps a todo message and adds the why', () => {
  expect(spinnerMessage('Editing a.ts · so b works', null)).toBe('Editing a.ts · so b works')
  expect(spinnerMessage('Editing a.ts · so b works', 'Running tests…')).toBe('Running tests · so b works')
  expect(spinnerMessage('no separator', 'Running tests…')).toBe('Running tests…')
})

test('buildDigest centres on the last typed prompt, not tool results', () => {
  const digest = buildDigest(
    [
      user('first ask'),
      reply('Plan: do X then Y'),
      user('yes do it'),
      reply('Starting.', [{ tool_use_id: 'a', tool: 'Bash', input: { command: 'make test' } }]),
      toolResult,
    ],
    'Old line · so X',
  )
  expect(digest).toContain('Earlier user request:\nfirst ask')
  expect(digest).toContain("Agent's previous reply:\nPlan: do X then Y")
  expect(digest).toContain('Current user request:\nyes do it')
  expect(digest).toContain('Bash(make test)')
  expect(buildDigest([user('x'), reply('', [{ tool_use_id: 'b', tool: 'Read', input: { file_path: 'a.ts', description: 'look' } }])], null)).toContain('Read(a.ts): look')
  expect(digest).toContain('Previous line: Old line · so X')
  expect(buildDigest([], null)).toBe('')
})

const SPINNER: RenderPropsOf['Spinner'] = { word: 'Sauteing', message: null, suffix: '…', mode: 'tool-use' }
const BAND = { hasSurvey: false, isWorking: false, maxRows: 5, bodyColumns: 80 } as RenderPropsOf['AbovePrompt']
const WHAT = 'Editing statusline.sh'
const WHY = 'so the status line shows cache warmth'
const LINE = `${WHAT} · ${WHY}`

test('a long turn gets a line in the spinner, then in the band once it ends', async ($, on) => {
  const clock = mock.clock(on)
  const asks: string[] = []
  let spinnerProps: RenderPropsOf['Spinner'] | undefined

  on('session.start', ($, e) => ({ cwd: e.cwd }))
  on('session.id', () => ({ value: 'main' }))
  on('turn.start', ($, e) => ({ turnId: e.turnId }))
  on('turn.complete', ($, e) => ({ text: e.answer }))
  on('tool.call', () => ({ result: {}, text: '' }) as never)
  on('session.messages', () => ({ value: [user('show cache warmth'), reply('On it.')] }))
  on('model.complete', ($, e) => {
    asks.push(e.prompt)
    return {
      value: {
        isAnswered: true as const,
        text: `"${LINE}"\nextra`,
        usage: { input_tokens: 0, output_tokens: 0, cache_creation_input_tokens: 0, cache_read_input_tokens: 0 },
      },
    }
  })
  on('ui.render', { component: 'Spinner' }, ($, e) => {
    spinnerProps = e.props
    const { Text } = $.ui.resolve(e)
    return <Text>spinner</Text>
  })
  on('ui.render', { component: 'AbovePrompt' }, ($, e) => {
    const { Text } = $.ui.resolve(e)
    return <Text>engine</Text>
  })

  await $.session.start({ cwd: '/', surface: 'terminal', isInteractive: true })
  await $.turn.start({ text: 'show cache warmth', turnId: 't1' })

  await clock.advance(15_000)
  expect(asks).toHaveLength(0) // under 20s

  await clock.advance(15_000)
  expect(asks).toHaveLength(1)
  expect(asks[0]).toContain('Current user request:\nshow cache warmth')

  const sub = await $.ui.mount({ plugin: 'now-line', surface: 'terminal', component: 'Spinner', props: SPINNER, requestId: 'agent-1' })
  expect(spinnerProps?.message).toBe(null) // a subagent's spinner is left alone
  await sub.unmount()
  const spinner = await $.ui.mount({ plugin: 'now-line', surface: 'terminal', component: 'Spinner', props: SPINNER, requestId: 'main' })
  expect(spinnerProps?.message).toBe(LINE) // first line only, quotes stripped

  await clock.advance(60_000)
  expect(asks).toHaveLength(1) // no tool calls since, so no refresh

  await $.tool.call({ tool: 'Bash', command: 'ls' })
  await clock.advance(15_000)
  expect(asks).toHaveLength(2)

  await $.turn.complete({ answer: 'done', durationMs: 120_000, isAborted: false, turnId: 't1', reason: 'answer' })
  for (const surface of ['terminal', 'desktop'] as const) {
    const band = await $.ui.mount({ plugin: 'now-line', surface, component: 'AbovePrompt', props: BAND })
    expect(await bandText(band)).toEqual(expect.arrayContaining([`Why ${WHY}`, `Last step ${WHAT}`]))
    await band.unmount()
  }

  await clock.advance(120_000)
  expect(asks).toHaveLength(2) // nothing after the turn ended

  await $.turn.start({ text: 'quick question', turnId: 't2' })
  await spinner.redraw()
  expect(spinnerProps?.message).toBe(null) // engine's own word again
  const band = await $.ui.mount({ plugin: 'now-line', surface: 'terminal', component: 'AbovePrompt', props: BAND })
  expect((await band.find({ type: 'Text' }))?.text).toBe('engine')
})

test('a failing model is retried at the normal pace, and an ended turn is not retried', async ($, on) => {
  const clock = mock.clock(on)
  let asks = 0
  on('session.start', ($, e) => ({ cwd: e.cwd }))
  on('session.id', () => ({ value: 'main' }))
  on('turn.start', ($, e) => ({ turnId: e.turnId }))
  on('turn.complete', ($, e) => ({ text: e.answer }))
  on('tool.call', () => ({ result: {}, text: '' }) as never)
  on('fs.write', () => ({ value: undefined }))
  on('ui.log', () => ({ value: undefined }))
  on('session.messages', () => ({ value: [user('do it')] }))
  on('model.complete', () => {
    asks += 1
    return {
      value: {
        isAnswered: false as const,
        reason: 'empty-reply' as const,
        usage: { input_tokens: 0, output_tokens: 0, cache_creation_input_tokens: 0, cache_read_input_tokens: 0 },
      },
    }
  })

  await $.session.start({ cwd: '/', surface: 'terminal', isInteractive: true })
  await $.turn.start({ text: 'do it', turnId: 't1' })
  await clock.advance(30_000)
  expect(asks).toBe(1)
  await $.tool.call({ tool: 'Bash', command: 'ls' })
  await clock.advance(30_000)
  expect(asks).toBe(1) // not every 15s
  await clock.advance(30_000)
  expect(asks).toBe(2)
  await $.turn.complete({ answer: '', durationMs: 90_000, isAborted: false, turnId: 't1', reason: 'answer' })
  await clock.advance(120_000)
  expect(asks).toBe(2)
})

test('a turn with no typed prompt continues the previous one and keeps its line', async ($, on) => {
  const clock = mock.clock(on)
  on('session.start', ($, e) => ({ cwd: e.cwd }))
  on('session.id', () => ({ value: 'main' }))
  on('turn.start', ($, e) => ({ turnId: e.turnId }))
  on('turn.complete', ($, e) => ({ text: e.answer }))
  on('fs.write', () => ({ value: undefined }))
  on('session.messages', () => ({ value: [user('do it')] }))
  on('model.complete', () => ({
    value: {
      isAnswered: true as const,
      text: LINE,
      usage: { input_tokens: 0, output_tokens: 0, cache_creation_input_tokens: 0, cache_read_input_tokens: 0 },
    },
  }))
  on('ui.render', { component: 'AbovePrompt' }, ($, e) => {
    const { Text } = $.ui.resolve(e)
    return <Text>engine</Text>
  })

  await $.session.start({ cwd: '/', surface: 'terminal', isInteractive: true })
  await $.turn.start({ text: 'do it', turnId: 't1' })
  await clock.advance(30_000)
  await $.turn.complete({ answer: '', durationMs: 30_000, isAborted: false, turnId: 't1', reason: 'answer' })
  await $.turn.start({ text: '', turnId: 't2' })
  await $.turn.complete({ answer: '', durationMs: 1_000, isAborted: false, turnId: 't2', reason: 'answer' })
  const band = await $.ui.mount({ plugin: 'now-line', surface: 'terminal', component: 'AbovePrompt', props: BAND })
  expect(await bandText(band)).toEqual(expect.arrayContaining([`Why ${WHY}`, `Last step ${WHAT}`]))
})
