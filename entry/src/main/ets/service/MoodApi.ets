import { HttpClient } from './HttpClient'
import {
  MapZonesResponse,
  MoodBreakdownItem,
  SupportResponse,
  WeeklyReportResponse,
  ZonePostsResponse,
  ZoneStoryResponse,
  UnreadCountResponse,
  NotificationListResponse,
  NotificationItem
} from '../model/MoodWallTypes'

export interface NotificationItemFromApi {
  id: number
  type: string
  title: string
  content: string
  refType: string | null
  refId: number | null
  isRead?: boolean
  createdAt: string
}

export interface ReadAllNotificationsResponse {
  updated: number
}

interface MoodBreakdownItemJson {
  mood?: string
  label?: string
  percent?: number | string
  count?: number | string
}

interface ZoneStoryResponseJson {
  zoneKey?: string
  title?: string
  subtitle?: string
  accent?: string
  postCount?: number | string
  dominantMood?: string | null
  dominantMoodLabel?: string | null
  moodBreakdown?: Array<MoodBreakdownItemJson>
  story?: string
  encouragement?: string
}

export class MoodApi {

  private static resolveIsRead(isRead?: boolean): boolean {
    return isRead === true
  }

  private static normalizeNotification(item: NotificationItemFromApi): NotificationItem {
    const result: NotificationItem = {
      id: item.id,
      type: item.type,
      title: item.title,
      content: item.content,
      refType: item.refType,
      refId: item.refId,
      isRead: MoodApi.resolveIsRead(item.isRead),
      createdAt: item.createdAt
    }
    return result
  }

  static getMapZones(): Promise<MapZonesResponse> {
    return HttpClient.get<MapZonesResponse>('/map/zones')
  }

  static getZonePosts(zoneKey: string, page: number = 1, size: number = 10): Promise<ZonePostsResponse> {
    return HttpClient.get<ZonePostsResponse>(`/map/zones/${zoneKey}/posts?page=${page}&size=${size}`)
  }

  static getZoneStory(zoneKey: string): Promise<ZoneStoryResponse> {
    const key: string = encodeURIComponent(zoneKey)
    return HttpClient.get<ZoneStoryResponseJson>(`/map/zones/${key}/story`)
      .then((res: ZoneStoryResponseJson) => MoodApi.normalizeZoneStory(res))
  }

  private static normalizeZoneStory(res: ZoneStoryResponseJson): ZoneStoryResponse {
    const breakdown: Array<MoodBreakdownItem> = []
    const rawBreakdown: Array<MoodBreakdownItemJson> =
      res.moodBreakdown !== undefined && res.moodBreakdown !== null ? res.moodBreakdown : []
    rawBreakdown.forEach((row: MoodBreakdownItemJson) => {
      if (row.mood !== undefined && row.mood.length > 0) {
        breakdown.push({
          mood: row.mood,
          label: row.label !== undefined && row.label !== null ? row.label : row.mood,
          percent: MoodApi.toStatInt(row.percent),
          count: MoodApi.toStatInt(row.count)
        })
      }
    })
    const result: ZoneStoryResponse = {
      zoneKey: res.zoneKey !== undefined && res.zoneKey !== null ? res.zoneKey : '',
      title: res.title !== undefined && res.title !== null ? res.title : '',
      subtitle: res.subtitle !== undefined && res.subtitle !== null ? res.subtitle : '',
      accent: res.accent !== undefined && res.accent !== null ? res.accent : '#73C088',
      postCount: MoodApi.toStatInt(res.postCount),
      dominantMood: res.dominantMood,
      dominantMoodLabel: res.dominantMoodLabel,
      moodBreakdown: breakdown,
      story: res.story !== undefined && res.story !== null ? res.story : '',
      encouragement: res.encouragement !== undefined && res.encouragement !== null ? res.encouragement : ''
    }
    return result
  }

  private static toStatInt(value: number | string | undefined | null): number {
    if (value === undefined || value === null) {
      return 0
    }
    if (typeof value === 'number') {
      return Math.floor(value)
    }
    const parsed: number = parseInt(`${value}`, 10)
    return Number.isNaN(parsed) ? 0 : parsed
  }

  static supportPost(postId: number, token: string): Promise<SupportResponse> {
    return HttpClient.postEmpty<SupportResponse>(`/posts/${postId}/support`, token)
  }

  static getWeeklyReport(token: string): Promise<WeeklyReportResponse> {
    return HttpClient.get<WeeklyReportResponse>('/profile/weekly-report', token)
  }

  static getNotifications(token: string, page: number = 1, size: number = 20): Promise<NotificationListResponse> {
    return HttpClient.get<NotificationListResponse>(`/notifications?page=${page}&size=${size}`, token)
      .then((res: NotificationListResponse) => {
        const list: NotificationItem[] = []
        const rawList: NotificationItemFromApi[] =
          res.list !== undefined && res.list !== null ? res.list as NotificationItemFromApi[] : []
        rawList.forEach((item: NotificationItemFromApi) => {
          list.push(MoodApi.normalizeNotification(item))
        })
        const result: NotificationListResponse = {
          list: list,
          total: res.total,
          page: res.page,
          size: res.size,
          hasMore: res.hasMore
        }
        return result
      })
  }

  static getUnreadCount(token: string): Promise<UnreadCountResponse> {
    return HttpClient.get<UnreadCountResponse>('/notifications/unread-count', token)
      .then((res: UnreadCountResponse) => {
        const count: number = res.count !== undefined ? res.count : 0
        const result: UnreadCountResponse = { count: count }
        return result
      })
  }

  static readAllNotifications(token: string): Promise<ReadAllNotificationsResponse> {
    return HttpClient.postEmpty<ReadAllNotificationsResponse>('/notifications/read-all', token)
  }

  static readNotification(id: number, token: string): Promise<Object> {
    return HttpClient.postEmpty<Object>(`/notifications/${id}/read`, token)
  }
}
