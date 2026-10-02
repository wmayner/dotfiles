import { expect, test } from 'claude-code/testing'

import { largest, thresholdFor, tokens } from './register'

test('thresholds, ordering and token estimates', async () => {
  expect(thresholdFor(79)).toBe(0)
  expect(thresholdFor(80)).toBe(80)
  expect(thresholdFor(95)).toBe(90)
  expect(largest([{ tool: 'a', detail: '', chars: 1 }, { tool: 'b', detail: '', chars: 9 }])[0]?.tool).toBe('b')
  expect(tokens(400)).toBe('100')
  expect(tokens(48000)).toBe('12.0k')
})

test('records a tool result and lists it in the pane', async ($, on) => {
  on('tool.call', () => ({ result: {}, text: 'x'.repeat(8000) }))
  on('ui.open', () => ({ value: { isPlaced: true as const } }))
  await $.tool.call({ tool: 'Read', file_path: '/tmp/big.txt' })
  for (const surface of ['terminal', 'desktop'] as const) {
    const ui = await $.ui.mount({ plugin: 'context-watch', surface, component: 'Pane', requestId: 'context-top', props: { title: 'Context' } as never })
    expect(await ui.find({ type: 'Text', text: '/tmp/big.txt' })).toBeDefined()
    expect(await ui.find({ type: 'Text', text: '2.0k' })).toBeDefined()
    await ui.unmount()
  }
})
