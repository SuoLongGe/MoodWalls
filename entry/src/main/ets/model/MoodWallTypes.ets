export interface NoteItem {
  id: number
  userId?: number
  nickname?: string
  mood: string
  moodLabel: string
  text: string
  location: string
  zoneKey?: string
  timeText: string
  likes: number
  isLiked?: boolean
  color: string
  createdAt?: string
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
  postCount?: number
  dominantMood?: string
}

export interface MapZonesResponse {
  summary: string
  zones: ZoneCard[]
}

export interface ZonePostItem {
  id: number
  mood: string
  content: string
  location: string
  likeCount: number
  createdAt: string
}

export interface ZonePostsResponse {
  list: ZonePostItem[]
  total: number
  page: number
  size: number
  hasMore: boolean
}

export interface SupportResponse {
  response: string
  isCrisis: boolean
}

export interface WeeklyReportResponse {
  report: string
  moodSummary: Record<string, number>
  postCount: number
}

export interface NotificationItem {
  id: number
  type: string
  title: string
  content: string
  refType: string | null
  refId: number | null
  isRead: boolean
  createdAt: string
}

export interface UnreadCountResponse {
  count: number
}

export interface NotificationListResponse {
  list: NotificationItem[]
  total: number
  page: number
  size: number
  hasMore: boolean
}
