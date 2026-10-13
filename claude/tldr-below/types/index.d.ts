declare module 'claude-code' {
  interface PluginState {
    'tldr-below': {
      /** TL;DRs on (mirrors $.store 'enabled', which persists across sessions). */
      isOn: boolean
      /** By message id: the TL;DR, '' while none. */
      line: StateFamily<string>
      /** By message id: its row was stored, so the drawn text is whole. */
      isFinal: StateFamily<boolean>
    }
  }
}
