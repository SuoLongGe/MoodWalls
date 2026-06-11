export interface WeekStats {
  calmPercent: number
  anxiousPercent: number
  happyPercent: number
}

export interface ProfileOverview {
  id: number
  nickname: string
  phone: string
  email?: string
  avatarKey?: string
  avatarUrl?: string
  postCount: number
  totalLikes: number
  streakDays: number
  activeDays: number
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
  imageUrl?: string
  location: string
  zoneKey: string
  likes: number
  liked: boolean
  color: string
  createdAt: string
  timeText: string
  avatarKey?: string
  avatarUrl?: string
  isMine?: boolean
  commentCount?: number
  visibility?: string
  canDelete?: boolean
  cloudCount?: number
}

export interface PostListResponse {
  list: Array<PostSummary>
  total: number
  page: number
  size: number
  hasMore: boolean
}

export interface WeeklyReport {
  report: string
  moodSummary: Record<string, number>
  postCount: number
}

export interface CalendarCell {
  day: number
  isEmpty: boolean
  color: string
  hasRecord: boolean
}
