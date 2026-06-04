import { HttpClient } from './HttpClient'
import {
  MapZonesResponse,
  SupportResponse,
  WeeklyReportResponse,
  ZonePostsResponse,
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
