import { expect, test } from 'claude-code/testing'

import { addsGlobalSeed } from './register'

test('global seeds', async () => {
  expect(addsGlobalSeed('', 'np.random.seed(0)')).toBe(true)
  expect(addsGlobalSeed('', 'import random\nrandom.seed(seed)')).toBe(true)
  expect(addsGlobalSeed('', 'rng = np.random.default_rng(seed)')).toBe(false)
  expect(addsGlobalSeed('', 'rng = random.Random(seed)')).toBe(false)
  expect(addsGlobalSeed('np.random.seed(0)', 'np.random.seed(1)')).toBe(false)
})

test('an edit adding a global seed is refused, an isolated generator is not', async ($, on) => {
  on('tool.call', () => ({ result: {}, text: 'ok' }))
  const bad = await $.tool.call({ tool: 'Edit', file_path: '/tmp/x.py', old_string: 'a', new_string: 'np.random.seed(0)' })
  expect(bad.deny).toContain('global random seed')
  const good = await $.tool.call({ tool: 'Edit', file_path: '/tmp/x.py', old_string: 'a', new_string: 'rng = np.random.default_rng(seed)' })
  expect(good.deny).toBe(undefined)
})
