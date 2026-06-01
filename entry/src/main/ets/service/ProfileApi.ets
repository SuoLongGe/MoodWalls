import { AuthSession } from '../common/AuthSession'
import { HttpClient } from './HttpClient'
import {
  CalendarResponse,
  PostListResponse,
  ProfileOverview,
  WeeklyReport
} from '../model/ProfileApiTypes'

export class ProfileApi {

  static getOverview(): Promise<ProfileOverview> {
    return HttpClient.get<ProfileOverview>('/profile', AuthSession.getToken())
  }

  static getCalendar(month: string): Promise<CalendarResponse> {
    const query: string = encodeURIComponent(month)
    return HttpClient.get<CalendarResponse>(`/profile/calendar?month=${query}`, AuthSession.getToken())
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
}
