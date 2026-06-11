import { AppTheme } from '../common/AppTheme'
import { AuthSession } from '../common/AuthSession'
import { NotificationStore } from '../common/NotificationStore'
import { UiHelper } from '../common/UiHelper'
import { PageHeader } from '../components/PageHeader'
import { MoodApi } from '../service/MoodApi'
import { NotificationItem } from '../model/MoodWallTypes'

@Entry
@Component
struct NotificationPage {
  @StorageLink('unreadNotificationCount') unreadCount: number = 0
  @State notifications: Array<NotificationItem> = []
  @State loading: boolean = true
  @State markingAll: boolean = false
  @StorageLink('themeMode') themeMode: string = 'light'

  aboutToAppear(): void {
    this.loadNotifications()
  }

  onPageShow(): void {
    this.loadNotifications()
  }

  loadNotifications(): void {
    const token: string = AuthSession.getToken()
    if (token.length === 0) {
      UiHelper.replaceTo('pages/Login')
      return
    }
    this.loading = true
    MoodApi.getNotifications(token, 1, 50)
      .then((res) => {
        this.notifications = res.list
        this.syncUnreadFromList()
      })
      .catch((err: Error) => {
        UiHelper.showToast(err.message || '通知加载失败')
      })
      .finally(() => {
        this.loading = false
      })

    MoodApi.getUnreadCount(token)
      .then((res) => {
        NotificationStore.setUnreadCount(res.count)
      })
      .catch(() => {})
  }

  syncUnreadFromList(): void {
    let count: number = 0
    this.notifications.forEach((item: NotificationItem) => {
      if (!item.isRead) {
        count++
      }
    })
    NotificationStore.setUnreadCount(count)
  }

  markAllRead(): void {
    if (this.markingAll) {
      return
    }
    const token: string = AuthSession.getToken()
    if (token.length === 0) {
      UiHelper.showToast('请先登录')
      return
    }
    this.markingAll = true
    MoodApi.readAllNotifications(token)
      .then(() => {
        const updated: Array<NotificationItem> = []
        this.notifications.forEach((item: NotificationItem) => {
          updated.push({
            id: item.id,
            type: item.type,
            title: item.title,
            content: item.content,
            refType: item.refType,
            refId: item.refId,
            isRead: true,
            createdAt: item.createdAt
          })
        })
        this.notifications = updated
        NotificationStore.setUnreadCount(0)
        UiHelper.showToast('已全部标记为已读')
      })
      .catch((err: Error) => {
        UiHelper.showToast(err.message || '操作失败，请稍后重试')
      })
      .finally(() => {
        this.markingAll = false
      })
  }

  getTypeLabel(type: string): string {
    if (type === 'like') return '点赞'
    if (type === 'support') return '接住心声'
    if (type === 'comment') return '评论'
    if (type === 'whisper') return '悄悄话'
    if (type === 'cloud') return '送云'
    if (type === 'reply') return '回复'
    if (type === 'system') return '系统通知'
    if (type === 'weekly_report') return '温情周报'
    return type
  }

  getTypeColor(type: string): string {
    if (type === 'like') return '#F08C62'
    if (type === 'support') return '#73C088'
    if (type === 'comment') return '#6CB1F0'
    if (type === 'whisper') return '#8B7AD6'
    if (type === 'cloud') return '#6CB1F0'
    if (type === 'reply') return '#B786F7'
    if (type === 'system') return '#92A0B0'
    if (type === 'weekly_report') return '#B786F7'
    return '#6E7C79'
  }

  private markNotificationRead(item: NotificationItem): void {
    if (item.isRead) {
      return
    }
    const token: string = AuthSession.getToken()
    if (token.length === 0) {
      return
    }
    MoodApi.readNotification(item.id, token).catch(() => {})
    const updated: Array<NotificationItem> = []
    this.notifications.forEach((row: NotificationItem) => {
      if (row.id === item.id) {
        updated.push({
          id: row.id,
          type: row.type,
          title: row.title,
          content: row.content,
          refType: row.refType,
          refId: row.refId,
          isRead: true,
          createdAt: row.createdAt
        })
      } else {
        updated.push(row)
      }
    })
    this.notifications = updated
    this.syncUnreadFromList()
  }

  private openNotificationTarget(item: NotificationItem): void {
    this.markNotificationRead(item)

    const postTypes: string[] = ['comment', 'reply', 'like', 'support', 'whisper', 'cloud']
    if (postTypes.indexOf(item.type) >= 0 && item.refType === 'post' && item.refId !== null && item.refId > 0) {
      const scrollToComments: boolean = item.type === 'like' || item.type === 'comment' || item.type === 'reply'
      UiHelper.pushToPostDetail(item.refId, scrollToComments)
      return
    }

    if (item.type === 'weekly_report') {
      UiHelper.showToast('请在「我的」页查看温情周报')
      return
    }

    UiHelper.showToast(item.content)
  }

  formatTime(dateStr: string): string {
    if (dateStr.length === 0) {
      return ''
    }
    try {
      const d: Date = new Date(dateStr)
      const now: Date = new Date()
      const diff: number = now.getTime() - d.getTime()
      const minutes: number = Math.floor(diff / 60000)
      if (minutes < 1) return '刚刚'
      if (minutes < 60) return `${minutes} 分钟前`
      const hours: number = Math.floor(minutes / 60)
      if (hours < 24) return `${hours} 小时前`
      const days: number = Math.floor(hours / 24)
      if (days < 7) return `${days} 天前`
      return `${d.getMonth() + 1}/${d.getDate()}`
    } catch (e) {
      return dateStr
    }
  }

  @Builder
  buildMarkAllAction() {
    Text(this.markingAll ? '处理中' : '全部已读')
      .fontSize(11)
      .fontWeight(FontWeight.Bold)
      .fontColor(this.notifications.length > 0 ? AppTheme.PRIMARY : AppTheme.TEXT_MUTED)
      .padding({ left: 10, right: 10, top: 7, bottom: 7 })
      .backgroundColor(AppTheme.SURFACE)
      .borderRadius(AppTheme.RADIUS_MD)
      .enabled(this.notifications.length > 0 && !this.markingAll)
      .onClick(() => {
        this.markAllRead()
      })
  }

  pageTransition() {
    PageTransitionEnter({ duration: AppTheme.PAGE_PUSH_MS, curve: Curve.FastOutSlowIn })
      .slide(SlideEffect.Right)
      .opacity(0)
      .scale({ x: 0.92, y: 0.92 })
    PageTransitionExit({ duration: AppTheme.PAGE_PUSH_MS - 80, curve: Curve.EaseIn })
      .slide(SlideEffect.Left)
      .opacity(0.5)
      .scale({ x: 0.96, y: 0.96 })
    PageTransitionEnter({ type: RouteType.Pop, duration: AppTheme.PAGE_POP_MS, curve: Curve.FastOutSlowIn })
      .slide(SlideEffect.Left)
      .opacity(0)
      .scale({ x: 0.92, y: 0.92 })
    PageTransitionExit({ type: RouteType.Pop, duration: AppTheme.PAGE_POP_MS - 60, curve: Curve.EaseIn })
      .slide(SlideEffect.Right)
      .opacity(0)
      .scale({ x: 0.94, y: 0.94 })
  }

  build() {
    Column() {
      PageHeader({
        title: '通知',
        onBack: () => {
          UiHelper.goBack()
        },
        rightAction: () => {
          this.buildMarkAllAction()
        }
      })

      if (this.loading) {
        Column() {
          LoadingProgress()
            .width(36)
            .height(36)
            .color('#31534A')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.notifications.length === 0) {
        Column() {
          Text('暂无通知')
            .fontSize(14)
            .fontColor('#95A19F')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        List() {
          ForEach(this.notifications, (item: NotificationItem) => {
            ListItem() {
              Row() {
                Row({ space: 10 }) {
                  if (!item.isRead) {
                    Circle()
                      .width(8)
                      .height(8)
                      .fill('#F08C62')
                  } else {
                    Circle()
                      .width(8)
                      .height(8)
                      .fill(Color.Transparent)
                  }

                  Column({ space: 6 }) {
                    Row({ space: 8 }) {
                      Text(this.getTypeLabel(item.type))
                        .fontSize(11)
                        .fontWeight(FontWeight.Bold)
                        .fontColor(this.getTypeColor(item.type))
                        .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                        .backgroundColor('#F5F7F6')
                        .borderRadius(8)
                      Text(item.title)
                        .fontSize(14)
                        .fontWeight(FontWeight.Medium)
                        .fontColor('#25332F')
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                        .layoutWeight(1)
                    }
                    .width('100%')

                    Text(item.content)
                      .fontSize(12)
                      .lineHeight(18)
                      .fontColor('#6E7C79')
                      .maxLines(2)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })

                    Text(this.formatTime(item.createdAt))
                      .fontSize(11)
                      .fontColor('#A0AAA8')
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1)
                }
                .width('100%')
                .alignItems(VerticalAlign.Top)
              }
              .width('100%')
              .padding(16)
              .backgroundColor(item.isRead ? '#FAFBFC' : AppTheme.CARD)
              .borderRadius(AppTheme.RADIUS_LG)
              .shadow({
                radius: item.isRead ? 4 : 10,
                color: AppTheme.SHADOW_LIGHT,
                offsetY: 2
              })
              .onClick(() => {
                this.openNotificationTarget(item)
              })
            }
            .margin({ bottom: 10 })
          }, (item: NotificationItem) => `${item.id}`)
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 16, right: 16 })
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppTheme.BG)
  }
}
