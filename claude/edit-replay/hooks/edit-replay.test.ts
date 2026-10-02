import { expect, test } from 'claude-code/testing'

test('records a turn\'s edits and /replay shows the first', async ($, on) => {
  on('tool.call', () => ({ result: {}, text: 'ok' }))
  on('session.cwd', () => ({ value: '/repo' }))
  on('ui.open', () => ({ value: { isPlaced: true as const } }))
  on('turn.complete', () => ({ text: 'done' }))
  await $.tool.call({ tool: 'Edit', file_path: '/repo/a.py', old_string: 'x = 1', new_string: 'x = 2' })
  await $.turn.complete({ turnId: 't1', answer: 'done' } as never)
  const ui = await $.ui.mount({ plugin: 'edit-replay', surface: 'terminal', component: 'Pane', requestId: 'replay-theater', props: { title: 'Replay' } as never })
  expect(await ui.find({ type: 'Text', text: 'a.py' })).toBeDefined()
  expect(await ui.find({ type: 'Text', text: 'step 1 of 1' })).toBeDefined()
  expect(await ui.find({ type: 'Text', text: '+ x = 2' })).toBeDefined()
  await ui.unmount()
})
