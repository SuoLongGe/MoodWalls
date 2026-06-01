export interface WeekStats {
  calmPercent: number
  anxiousPercent: number
  happyPercent: number
}

export interface ProfileOverview {
  id: number
  nickname: string
  phone: string
  avatarKey?: string
  postCount: number
  totalLikes: number
  streakDays: number
  moodClimate: string
  weekStats: WeekStats
}

export interface CalendarDay {
  date: string
  dominantMood: string
  color: string
  postCount: number
}

export interface CalendarResponse {
  month: string
  days: Array<CalendarDay>
}

export interface PostSummary {
  id: number
  userId: number
  nickname: string
  mood: string
  moodLabel: string
  text: string
  location: string
  zoneKey: string
  likes: number
  isLiked: boolean
  color: string
  createdAt: string
  timeText: string
}

export interface PostListResponse {
  list: Array<PostSummary>
  total: number
  page: number
  size: number
  hasMore: boolean
}

export interface MoodSummary {
  calm: number
  anxious: number
  happy: number
}

export interface WeeklyReport {
  report: string
  moodSummary: MoodSummary
  postCount: number
}

export interface CalendarCell {
  day: number
  isEmpty: boolean
  color: string
  hasRecord: boolean
}
