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
  liked?: boolean
  color: string
  createdAt?: string
  avatarKey?: string
  isMine?: boolean
  mine?: boolean
  commentCount?: number
  visibility?: string
  canDelete?: boolean
}

export interface PostDetailResponse extends NoteItem {
}

export interface PostListResponse {
  list: NoteItem[]
  total: number
  page: number
  size: number
  hasMore: boolean
}

export interface LikeResponse {
  likes: number
  liked: boolean
}

/** 后端 JSON 可能使用 isLiked 字段名 */
export interface NoteItemFromApi {
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
  liked?: boolean
  isLiked?: boolean
  color: string
  createdAt?: string
  avatarKey?: string
  isMine?: boolean
  mine?: boolean
  commentCount?: number
  visibility?: string
  canDelete?: boolean
}

export interface LikeResponseFromApi {
  likes: number
  liked?: boolean
  isLiked?: boolean
}

export interface PublishPostResponse {
  post: NoteItem
  aiResponse: string
}

export interface TodayStatsResponse {
  anxiousPercent: number
  calmPercent: number
  happyPercent: number
  totalPosts: number
}

export interface MoodStatItem {
  mood: string
  label: string
  color: string
  percent: number
  count: number
}

export interface MoodStatsResponse {
  period: string
  totalPosts: number
  items: Array<MoodStatItem>
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

export interface CommentReplyItem {
  id: number
  postId: number
  userId: number
  parentId: number
  authorNickname: string
  authorAvatarKey?: string
  content: string
  commentType: string
  replyToNickname?: string
  isMine?: boolean
  canDelete?: boolean
  createdAt: string
  timeText: string
}

export interface CommentItem {
  id: number
  postId: number
  userId: number
  authorNickname: string
  authorAvatarKey?: string
  content: string
  commentType: string
  parentId?: number | null
  replyToNickname?: string
  isMine?: boolean
  canDelete?: boolean
  createdAt: string
  timeText: string
  replies: Array<CommentReplyItem>
}

export interface CommentListResponse {
  list: Array<CommentItem>
  total: number
  page: number
  size: number
  hasMore: boolean
}

export interface CreateCommentBody {
  content: string
  commentType?: string
  parentId?: number | null
  replyToUserId?: number | null
}
