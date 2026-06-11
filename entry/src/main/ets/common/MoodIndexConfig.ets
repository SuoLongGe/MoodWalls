export function moodIndex(mood: string | null | undefined): number {
  if (mood === 'sad') return 0
  if (mood === 'anxious') return 1
  if (mood === 'lonely') return 2
  if (mood === 'tired') return 3
  if (mood === 'angry') return 4
  if (mood === 'moved') return 5
  if (mood === 'calm') return 6
  if (mood === 'happy') return 7
  return -1
}
