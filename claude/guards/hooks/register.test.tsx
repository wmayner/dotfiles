import { expect, test } from 'claude-code/testing'

import { addsGlobalSeed, classify } from './register'

test('global seeds', async () => {
  expect(addsGlobalSeed('', 'np.random.seed(0)')).toBe(true)
  expect(addsGlobalSeed('', 'import random\nrandom.seed(seed)')).toBe(true)
  expect(addsGlobalSeed('', 'rng = np.random.default_rng(seed)')).toBe(false)
  expect(addsGlobalSeed('', 'rng = random.Random(seed)')).toBe(false)
  expect(addsGlobalSeed('np.random.seed(0)', 'np.random.seed(1)')).toBe(false)
})

test('which commands are held', async () => {
  expect(classify('git status && ls')).toBe(null)
  expect(classify('git checkout main')).toEqual({ kind: 'git', label: 'git checkout', dir: null, paths: ['main'] })
  expect(classify('cd sub && git checkout -- a.py b.py')).toEqual({ kind: 'git', label: 'git checkout', dir: 'sub', paths: ['a.py', 'b.py'] })
  expect(classify('git -C /repo reset --hard HEAD')).toEqual({ kind: 'git', label: 'git reset --hard', dir: '/repo', paths: null })
  expect(classify('git restore --staged a.py')).toBe(null)
  expect(classify('git stash')?.label).toBe('git stash')
  expect(classify('git stash pop')).toBe(null)
  expect(classify('vastai create instance 123 --image x')?.kind).toBe('spend')
  expect(classify('vastai show instances')).toBe(null)
  expect(classify('vastai stop instance 5')).toBe(null)
})

test('an edit adding a global seed is refused, an isolated generator is not', async ($, on) => {
  on('tool.call', () => ({ result: {}, text: 'ok' }))
  const bad = await $.tool.call({ tool: 'Edit', file_path: '/tmp/x.py', old_string: 'a', new_string: 'np.random.seed(0)' })
  expect(bad.deny).toContain('global random seed')
  const good = await $.tool.call({ tool: 'Edit', file_path: '/tmp/x.py', old_string: 'a', new_string: 'rng = np.random.default_rng(seed)' })
  expect(good.deny).toBe(undefined)
})
