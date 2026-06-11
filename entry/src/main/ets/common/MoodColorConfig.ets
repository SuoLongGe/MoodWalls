export function moodColor(mood: string | null | undefined): string {
  if (mood === 'happy') return '#F6C445'
  if (mood === 'calm') return '#73C088'
  if (mood === 'moved') return '#B786F7'
  if (mood === 'tired') return '#92A0B0'
  if (mood === 'anxious') return '#F08C62'
  if (mood === 'sad') return '#6CB1F0'
  if (mood === 'angry') return '#E17272'
  if (mood === 'lonely') return '#8B7AD6'
  return '#D8DEDC'
}
