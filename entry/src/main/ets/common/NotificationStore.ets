import { AuthSession } from './AuthSession'
import { MoodApi } from '../service/MoodApi'

/**
 * 统一管理未读通知数，写入 AppStorage 以驱动 Header 角标刷新。
 * 必须使用 AppStorage.set（不要用 setOrCreate），否则 @StorageLink 可能不更新。
 */
export class NotificationStore {

  static setUnreadCount(count: number): void {
    AppStorage.set<number>('unreadNotificationCount', count)
  }

  static refreshUnreadCount(): void {
    const token: string = AuthSession.getToken()
    if (token.length === 0) {
      NotificationStore.setUnreadCount(0)
      return
    }
    MoodApi.getUnreadCount(token)
      .then((res) => {
        NotificationStore.setUnreadCount(res.count)
      })
      .catch((err: Error) => {
        console.error('refreshUnreadCount 失败: ' + err.message)
      })
  }
}
