export interface ReactionOption {
  type: string
  label: string
  emoji: string
}

export const REACTION_OPTIONS: Array<ReactionOption> = [
  { type: 'hug', label: '抱抱', emoji: '🤗' },
  { type: 'understand', label: '懂你', emoji: '💭' },
  { type: 'cheer', label: '加油', emoji: '💪' },
  { type: 'happy_for_you', label: '为你开心', emoji: '🎉' },
  { type: 'with_you', label: '陪你', emoji: '🤝' }
]

export function findReactionOption(type: string): ReactionOption | undefined {
  for (let i: number = 0; i < REACTION_OPTIONS.length; i++) {
    if (REACTION_OPTIONS[i].type === type) {
      return REACTION_OPTIONS[i]
    }
  }
  return undefined
}
