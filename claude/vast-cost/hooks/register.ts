// Shows running vast.ai instances and their hourly cost on the status line
// under the prompt. Nothing is shown when there are no instances.

import type { EngineInterface, Register } from 'claude-code'

const POLL_MS = 5 * 60 * 1000

type Instance = { actual_status?: string; dph_total?: number }

/** "vast.ai: 2 running · $1.24/h · 1 stopped", or undefined with no instances. */
export const summarize = (instances: Instance[]) => {
  const running = instances.filter(i => i.actual_status === 'running')
  const idle = instances.length - running.length
  if (instances.length === 0) {
    return undefined
  }
  const rate = running.reduce((sum, i) => sum + (i.dph_total ?? 0), 0)
  const parts = [`${running.length} running`]
  if (running.length > 0) {
    parts.push(`$${rate.toFixed(2)}/h`)
  }
  if (idle > 0) {
    // A stopped instance still bills for its disk
    parts.push(`${idle} not running`)
  }

  return `vast.ai: ${parts.join(' · ')}`
}

async function poll($: EngineInterface) {
  const run = await $.process.run(['vastai', 'show', 'instances', '--raw'], { timeoutMs: 20000 }).catch(() => null)
  if (run === null || run.exitCode !== 0) {
    return // vastai missing or offline: leave the line as it was
  }
  try {
    $.ui.status(summarize(JSON.parse(run.stdout) as Instance[]))
  } catch {
    // not JSON (a login prompt, say)
  }
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    const result = await next(e)
    $.clock.every(POLL_MS, () => {
      void poll($)
    })
    void poll($)

    return result
  })

  // A vastai command probably changed what is running
  on('tool.call', { tool: 'Bash' }, async ($, e, next) => {
    const ran = await next(e)
    if (/\bvastai\b/.test(e.command)) {
      void poll($)
    }

    return ran
  })
}
