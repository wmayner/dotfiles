import { expect, test } from 'claude-code/testing'

import { summarize } from './register'

test('summary line', async () => {
  expect(summarize([])).toBe(undefined)
  expect(summarize([{ actual_status: 'running', dph_total: 0.5 }, { actual_status: 'running', dph_total: 0.74 }])).toBe(
    'vast.ai: 2 running · $1.24/h',
  )
  expect(summarize([{ actual_status: 'running', dph_total: 0.5 }, { actual_status: 'exited' }])).toBe(
    'vast.ai: 1 running · $0.50/h · 1 not running',
  )
  expect(summarize([{ actual_status: 'exited' }])).toBe('vast.ai: 0 running · 1 not running')
})
