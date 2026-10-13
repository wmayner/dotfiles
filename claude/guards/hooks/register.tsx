// tool.call: an edit that adds a global random seed is refused.

import type { Register } from 'claude-code'

const GLOBAL_SEED = /\b(?:np|numpy)\.random\.seed\s*\(|(?<![\w.])random\.seed\s*\(/

export const addsGlobalSeed = (before: string, after: string) =>
  GLOBAL_SEED.test(after) && !GLOBAL_SEED.test(before)

const SEED_DENY =
  'guards: this adds a global random seed (np.random.seed or random.seed), which mutates global state. ' +
  'Take a `seed` argument and use an isolated generator instead, np.random.default_rng(seed) or ' +
  'random.Random(seed), and save the seed alongside the output.'

export const register: Register = on => {
  on('tool.call', async ($, e, next) => {
    const tool = String(e.tool)
    const input = e as Record<string, unknown>
    if (tool !== 'Edit' && tool !== 'Write' && tool !== 'NotebookEdit') {
      return next(e)
    }
    const path = String(input.file_path ?? input.notebook_path ?? '')
    if (/\.(py|ipynb)$/.test(path)) {
      const after = String(input.new_string ?? input.content ?? input.new_source ?? '')
      const before =
        tool === 'Edit'
          ? String(input.old_string ?? '')
          : tool === 'Write' && (await $.fs.exists(path))
            ? String(await $.fs.read(path).catch(() => ''))
            : ''
      if (addsGlobalSeed(before, after)) {
        return { deny: SEED_DENY }
      }
    }

    return next(e)
  })
}
