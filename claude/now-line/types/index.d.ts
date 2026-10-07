export type Line = string | null

declare module 'claude-code' {
  interface PluginState {
    'now-line': { line: Line }
  }
}
