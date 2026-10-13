import { expect, test } from 'claude-code/testing'

import { isLong } from './register'

test('only long, multi-line replies get a TL;DR', async () => {
  const words = Array(101).fill('word').join(' ')
  expect(isLong(words + '\nmore')).toBe(true)
  expect(isLong(words)).toBe(false)
  expect(isLong('short\nreply')).toBe(false)
})
