import { HttpClient } from './HttpClient'
import {
  MapZonesResponse,
  SupportResponse,
  WeeklyReportResponse,
  ZonePostsResponse,
  UnreadCountResponse,
  NotificationListResponse
} from '../model/MoodWallTypes'

export class MoodApi {

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
  }

  static getUnreadCount(token: string): Promise<UnreadCountResponse> {
    return HttpClient.get<UnreadCountResponse>('/notifications/unread-count', token)
  }

  static readAllNotifications(token: string): Promise<Object> {
    return HttpClient.postEmpty<Object>('/notifications/read-all', token)
  }

  static readNotification(id: number, token: string): Promise<Object> {
    return HttpClient.postEmpty<Object>(`/notifications/${id}/read`, token)
  }
}
