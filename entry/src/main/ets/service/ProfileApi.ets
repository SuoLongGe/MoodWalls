import { AuthSession } from '../common/AuthSession'
import { MediaUrl } from '../common/MediaUrl'
import { HttpClient } from './HttpClient'
import {
  CalendarDay,
  CalendarResponse,
  PostListResponse,
  PostSummary,
  ProfileOverview,
  WeekStats,
  WeeklyReport
} from '../model/ProfileApiTypes'
import { MoodCurvePoint, MoodCurveResponse } from '../model/MoodWallTypes'

interface ProfileOverviewJson {
  id?: number | string
  nickname?: string
  phone?: string
  email?: string
  avatarKey?: string
  avatarUrl?: string
  postCount?: number | string
  totalLikes?: number | string
  streakDays?: number | string
  activeDays?: number | string
  moodClimate?: string
  weekStats?: WeekStatsJson
}

interface WeekStatsJson {
  calmPercent?: number | string
  anxiousPercent?: number | string
  happyPercent?: number | string
}

interface CalendarDayJson {
  date?: string
  dominantMood?: string
  color?: string
  postCount?: number | string
}

interface CalendarResponseJson {
  month?: string
  days?: Array<CalendarDayJson>
}

interface MoodCurvePointJson {
  date?: string
  weekday?: string
  dominantMood?: string | null
  label?: string | null
  color?: string | null
  postCount?: number | string
}

interface MoodCurveResponseJson {
  days?: number | string
  points?: Array<MoodCurvePointJson>
  summary?: string
}

interface PostSummaryJson {
  id?: number | string
  userId?: number | string
  nickname?: string | null
  mood?: string | null
  moodLabel?: string | null
  text?: string | null
  imageUrl?: string | null
  location?: string | null
  zoneKey?: string | null
  likes?: number | string
  liked?: boolean
  isLiked?: boolean
  color?: string | null
  createdAt?: string | null
  timeText?: string | null
  avatarKey?: string | null
  avatarUrl?: string | null
  isMine?: boolean
  commentCount?: number | string
  visibility?: string | null
  canDelete?: boolean
  cloudCount?: number | string
}

interface PostListResponseJson {
  list?: Array<PostSummaryJson>
  total?: number | string
  page?: number | string
  size?: number | string
  hasMore?: boolean
}

export class ProfileApi {

  static getOverview(): Promise<ProfileOverview> {
    return HttpClient.get<object>('/profile', AuthSession.getToken())
      .then((payload: object) => ProfileApi.mapOverviewPayload(payload))
  }

  static getCalendar(month: string): Promise<CalendarResponse> {
    const query: string = encodeURIComponent(month)
    return HttpClient.get<object>(`/profile/calendar?month=${query}`, AuthSession.getToken())
      .then((payload: object) => ProfileApi.mapCalendarPayload(payload, month))
  }

  static getMyPosts(page: number, size: number): Promise<PostListResponse> {
    return HttpClient.get<object>(
      `/profile/posts?page=${page}&size=${size}`,
      AuthSession.getToken()
    ).then((payload: object) => ProfileApi.mapPostListPayload(payload))
  }

  static getWeeklyReport(): Promise<WeeklyReport> {
    return HttpClient.get<WeeklyReport>('/profile/weekly-report', AuthSession.getToken())
  }

  static getMoodCurve(days: number = 7): Promise<MoodCurveResponse> {
    return HttpClient.get<object>(`/profile/mood-curve?days=${days}`, AuthSession.getToken())
      .then((payload: object) => ProfileApi.mapMoodCurvePayload(payload, days))
  }

  private static mapOverviewPayload(payload: object): ProfileOverview {
    const text: string = JSON.stringify(payload)
    const json: ProfileOverviewJson = JSON.parse(text) as ProfileOverviewJson
    const weekRaw: WeekStatsJson | undefined = json.weekStats
    const weekStats: WeekStats = {
      calmPercent: ProfileApi.toInt(weekRaw !== undefined ? weekRaw.calmPercent : 0),
      anxiousPercent: ProfileApi.toInt(weekRaw !== undefined ? weekRaw.anxiousPercent : 0),
      happyPercent: ProfileApi.toInt(weekRaw !== undefined ? weekRaw.happyPercent : 0)
    }
    const activeDays: number = ProfileApi.toInt(
      json.activeDays !== undefined && json.activeDays !== null ? json.activeDays : json.streakDays
    )
    return {
      id: ProfileApi.toInt(json.id),
      nickname: json.nickname !== undefined && json.nickname !== null ? json.nickname : '',
      phone: json.phone !== undefined && json.phone !== null ? json.phone : '',
      email: json.email !== undefined && json.email !== null ? json.email : '',
      avatarKey: json.avatarKey,
      avatarUrl: json.avatarUrl,
      postCount: ProfileApi.toInt(json.postCount),
      totalLikes: ProfileApi.toInt(json.totalLikes),
      streakDays: ProfileApi.toInt(json.streakDays),
      activeDays: activeDays,
      moodClimate: json.moodClimate !== undefined && json.moodClimate !== null ? json.moodClimate : '暂无记录',
      weekStats: weekStats
    }
  }

  private static mapCalendarPayload(payload: object, fallbackMonth: string): CalendarResponse {
    const text: string = JSON.stringify(payload)
    const json: CalendarResponseJson = JSON.parse(text) as CalendarResponseJson
    const days: Array<CalendarDay> = []
    const rawDays: Array<CalendarDayJson> = json.days !== undefined && json.days !== null ? json.days : []
    for (let i: number = 0; i < rawDays.length; i++) {
      const row: CalendarDayJson = rawDays[i]
      const date: string = row.date !== undefined && row.date !== null ? row.date : ''
      if (date.length === 0) {
        continue
      }
      days.push({
        date: date,
        dominantMood: row.dominantMood !== undefined && row.dominantMood !== null ? row.dominantMood : 'calm',
        color: row.color !== undefined && row.color !== null ? row.color : '#E8ECEB',
        postCount: ProfileApi.toInt(row.postCount)
      })
    }
    const month: string = json.month !== undefined && json.month !== null && json.month.length > 0
      ? json.month
      : fallbackMonth
    return { month: month, days: days }
  }

  private static mapMoodCurvePayload(payload: object, fallbackDays: number): MoodCurveResponse {
    const text: string = JSON.stringify(payload)
    const json: MoodCurveResponseJson = JSON.parse(text) as MoodCurveResponseJson
    const points: Array<MoodCurvePoint> = []
    const rawPoints: Array<MoodCurvePointJson> =
      json.points !== undefined && json.points !== null ? json.points : []
    for (let i: number = 0; i < rawPoints.length; i++) {
      const row: MoodCurvePointJson = rawPoints[i]
      const point: MoodCurvePoint = {
        date: row.date !== undefined && row.date !== null ? row.date : '',
        weekday: row.weekday !== undefined && row.weekday !== null ? row.weekday : '',
        dominantMood: row.dominantMood,
        label: row.label,
        color: row.color,
        postCount: ProfileApi.toInt(row.postCount)
      }
      points.push(point)
    }
    return {
      days: ProfileApi.toInt(json.days !== undefined && json.days !== null ? json.days : fallbackDays),
      points: points,
      summary: json.summary !== undefined && json.summary !== null ? json.summary : ''
    }
  }

  private static mapPostListPayload(payload: object): PostListResponse {
    const text: string = JSON.stringify(payload)
    const json: PostListResponseJson = JSON.parse(text) as PostListResponseJson
    const rawList: Array<PostSummaryJson> =
      json.list !== undefined && json.list !== null ? json.list : []
    const list: Array<PostSummary> = []
    for (let i: number = 0; i < rawList.length; i++) {
      list.push(ProfileApi.mapPostSummary(rawList[i]))
    }
    return {
      list: list,
      total: ProfileApi.toInt(json.total),
      page: ProfileApi.toInt(json.page) > 0 ? ProfileApi.toInt(json.page) : 1,
      size: ProfileApi.toInt(json.size) > 0 ? ProfileApi.toInt(json.size) : 20,
      hasMore: json.hasMore === true
    }
  }

  private static mapPostSummary(item: PostSummaryJson): PostSummary {
    const avatarUrl: string | undefined = MediaUrl.resolve(item.avatarUrl)
    const mineAvatarUrl: string = AuthSession.getAvatarUrl()
    const resolvedAvatarUrl: string | undefined = avatarUrl !== undefined
      ? avatarUrl
      : (mineAvatarUrl.length > 0 ? MediaUrl.resolve(mineAvatarUrl) : undefined)
    return {
      id: ProfileApi.toInt(item.id),
      userId: ProfileApi.toInt(item.userId),
      nickname: item.nickname !== undefined && item.nickname !== null ? item.nickname : '',
      mood: item.mood !== undefined && item.mood !== null ? item.mood : 'calm',
      moodLabel: item.moodLabel !== undefined && item.moodLabel !== null ? item.moodLabel : '',
      text: item.text !== undefined && item.text !== null ? item.text : '',
      imageUrl: MediaUrl.resolve(item.imageUrl),
      location: item.location !== undefined && item.location !== null ? item.location : '',
      zoneKey: item.zoneKey !== undefined && item.zoneKey !== null ? item.zoneKey : '',
      likes: ProfileApi.toInt(item.likes),
      liked: item.liked === true || item.isLiked === true,
      color: item.color !== undefined && item.color !== null ? item.color : '#E8ECEB',
      createdAt: item.createdAt !== undefined && item.createdAt !== null ? item.createdAt : '',
      timeText: item.timeText !== undefined && item.timeText !== null ? item.timeText : '',
      avatarKey: item.avatarKey !== undefined && item.avatarKey !== null && item.avatarKey.length > 0
        ? item.avatarKey
        : AuthSession.getAvatarKey(),
      avatarUrl: resolvedAvatarUrl,
      isMine: item.isMine === true,
      commentCount: ProfileApi.toInt(item.commentCount),
      visibility: item.visibility !== undefined && item.visibility !== null && item.visibility.length > 0
        ? item.visibility
        : 'public',
      canDelete: item.canDelete !== false,
      cloudCount: ProfileApi.toInt(item.cloudCount)
    }
  }

  private static toInt(value: number | string | undefined | null): number {
    if (value === undefined || value === null) {
      return 0
    }
    if (typeof value === 'number') {
      return Math.floor(value)
    }
    const parsed: number = parseInt(`${value}`, 10)
    return Number.isNaN(parsed) ? 0 : parsed
  }
}
