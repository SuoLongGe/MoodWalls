export interface TopReactionItem {
  type: string
  label: string
  count: number
}

export interface ReactionResponse {
  totalReactions: number
  myReaction?: string | null
  reactionStats?: Record<string, number>
  topReactions?: Array<TopReactionItem>
}

export interface NoteItem {
  id: number
  userId?: number
  nickname?: string
  mood: string
  moodLabel: string
  text: string
  imageUrl?: string
  location: string
  zoneKey?: string
  timeText: string
  likes: number
  liked?: boolean
  color: string
  createdAt?: string
  avatarKey?: string
  avatarUrl?: string
  isMine?: boolean
  mine?: boolean
  commentCount?: number
  visibility?: string
  canDelete?: boolean
  totalReactions?: number
  myReaction?: string | null
  topReactions?: Array<TopReactionItem>
  reactionStats?: Record<string, number>
  whisperCount?: number
  cloudCount?: number
}

export interface CloudGiftResponse {
  cloudCount: number
  sent: boolean
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
  imageUrl?: string
  location: string
  zoneKey?: string
  timeText: string
  likes: number
  liked?: boolean
  isLiked?: boolean
  color: string
  createdAt?: string
  avatarKey?: string
  avatarUrl?: string
  isMine?: boolean
  mine?: boolean
  commentCount?: number
  visibility?: string
  canDelete?: boolean
  totalReactions?: number
  myReaction?: string | null
  topReactions?: Array<TopReactionItem>
  reactionStats?: Record<string, number>
  whisperCount?: number
  cloudCount?: number
}

export interface LikeResponseFromApi {
  likes: number
  liked?: boolean
  isLiked?: boolean
}

export interface PublishPostResponse {
  post: NoteItem
  aiResponse: string
  riskLevel: number
  comfortNote: string
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

export interface MoodBreakdownItem {
  mood: string
  label: string
  percent: number
  count: number
}

export interface ZoneStoryResponse {
  zoneKey: string
  title: string
  subtitle: string
  accent: string
  postCount: number
  dominantMood?: string | null
  dominantMoodLabel?: string | null
  moodBreakdown: Array<MoodBreakdownItem>
  story: string
  encouragement: string
}

export interface MoodCurvePoint {
  date: string
  weekday: string
  dominantMood?: string | null
  label?: string | null
  color?: string | null
  postCount: number
}

export interface MoodCurveResponse {
  days: number
  points: Array<MoodCurvePoint>
  summary: string
}

export interface SupportResponse {
  response: string
  riskLevel: number
  isCrisis: boolean
  comfortNote: string
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
  authorAvatarUrl?: string
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
  authorAvatarUrl?: string
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
  whisperCount?: number
}

export interface CreateCommentBody {
  content: string
  commentType?: string
  parentId?: number | null
  replyToUserId?: number | null
}

export interface InspirationDrawResponse {
  alreadyDrawn?: boolean
  content?: string
  mood?: string
  moodLabel?: string
  moodColor?: string
  source?: string
  drawnAt?: string
  remainingToday?: number
}

export interface CreateEncouragementNoteBody {
  content: string
  mood: string
}

export interface EncouragementNoteResponse {
  id: number
  content: string
  mood: string
  moodLabel: string
  moodColor: string
  createdAt: string
  timeText: string
}
