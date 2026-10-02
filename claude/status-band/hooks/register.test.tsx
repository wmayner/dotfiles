import { expect, test } from 'claude-code/testing'

import { filledCells, formatDelta, lastCodeBlock, level, modelName } from './register'

test('bar and colour thresholds', async () => {
  expect(filledCells(0)).toBe(0)
  expect(filledCells(50)).toBe(6)
  expect(filledCells(140)).toBe(12)
  expect(level(69, 'blue')).toBe('blue')
  expect(level(70, 'blue')).toBe('yellow')
  expect(level(85, 'blue')).toBe('red')
})

test('change since last turn', async () => {
  expect(formatDelta(98300)).toBe('▲ +98.3k')
  expect(formatDelta(0)).toBe('▲ +0.0k')
  expect(formatDelta(-12000)).toBe('▼ 12.0k')
})

test('last code block', async () => {
  expect(lastCodeBlock('a\n```sh\nls -la\n```\nb\n```\nsecond\n```')).toBe('second')
  expect(lastCodeBlock('no code here')).toBe(null)
})

test('model names', async () => {
  expect(modelName('claude-opus-5-5', 'medium')).toBe('Opus 5.5 (Medium)')
  expect(modelName('claude-haiku-4-5-20251001', '')).toBe('Haiku 4.5')
  expect(modelName('claude-opus-5-5[1m]', 'xhigh')).toBe('Opus 5.5 (Xhigh)')
  expect(modelName('opus', '')).toBe('opus')
})

test('draws directory, context bar and rate limits in the band', async ($, on) => {
  on('session.root', () => ({ value: '/Users/me/dotfiles' }))
  on('session.model', () => ({ value: 'claude-opus-5-5' }))
  on('session.usage', () => ({ value: {
    startedAt: 0,
    context: { window: 200000, tokens: 150000, percent: 75 },
    rateLimits: [{ kind: 'five_hour', percentUsed: 23.5 }],
  } }))

  on('session.messages', () => ({ value: [{ role: 'assistant', text: 'run\n```sh\nmake test\n```', toolUses: [] }] }))
  let copied = ''
  on('ui.copy', (_$, c) => {
    copied = c.text

    return { value: { isCopied: true as const } }
  })
  on('ui.toast', () => ({ value: undefined }))

  const ui = await $.ui.mount({
    plugin: 'status-band',
    surface: 'terminal',
    component: 'AbovePrompt',
    props: { hasSurvey: false, isWorking: false, maxRows: 10, bodyColumns: 100, scroll: { offset: 0, bodyRows: 10 } } as never,
  })
  expect(await ui.find({ type: 'Text', text: 'dotfiles' })).toBeDefined()
  expect((await ui.find({ type: 'Text', text: /75%/ }))?.props.color).toBe('yellow')
  expect((await ui.find({ type: 'Text', text: '24%' }))?.props.color).toBe('blue')
  expect(await ui.find({ type: 'Text', text: 'Opus 5.5' })).toBeDefined()
  await ui.press({ key: 'copy' })
  expect(copied).toBe('make test')
  await ui.unmount()
})
