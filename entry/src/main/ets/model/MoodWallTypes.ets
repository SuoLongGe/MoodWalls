export interface NoteItem {
  id: number
  mood: string
  moodLabel: string
  text: string
  location: string
  timeText: string
  likes: number
  color: string
}

export interface MoodOption {
  key: string
  label: string
  color: string
  hint: string
}

export interface ZoneCard {
  key: string
  title: string
  subtitle: string
  summary: string
  accent: string
}
