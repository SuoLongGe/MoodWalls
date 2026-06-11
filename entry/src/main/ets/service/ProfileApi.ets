import { AuthSession } from '../common/AuthSession'
import { HttpClient } from './HttpClient'
import {
  CalendarDay,
  CalendarResponse,
  PostListResponse,
  ProfileOverview,
  WeekStats,
  WeeklyReport
} from '../model/ProfileApiTypes'
import { MoodCurvePoint, MoodCurveResponse } from '../model/MoodWallTypes'

interface ProfileOverviewJson {
  id?: number | string
  nickname?: string
  phone?: string
  avatarKey?: string
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
    return HttpClient.get<PostListResponse>(
      `/profile/posts?page=${page}&size=${size}`,
      AuthSession.getToken()
    )
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
      avatarKey: json.avatarKey,
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
