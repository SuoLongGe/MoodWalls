import { router } from '@kit.ArkUI'
import { AuthSession } from '../common/AuthSession'
import { MoodApi } from '../service/MoodApi'
import { NotificationItem } from '../model/MoodWallTypes'

@Entry
@Component
struct NotificationPage {
  @State notifications: Array<NotificationItem> = []
  @State loading: boolean = true
  @State unreadCount: number = 0

  aboutToAppear(): void {
    this.loadNotifications()
  }

  loadNotifications(): void {
    const token: string = AuthSession.getToken()
    this.loading = true
    MoodApi.getNotifications(token, 1, 50)
      .then((res) => {
        this.notifications = res.list
        this.loading = false
      })
      .catch(() => {
        this.loading = false
      })
  }

  markAllRead(): void {
    const token: string = AuthSession.getToken()
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
      })
  }

  getTypeLabel(type: string): string {
    if (type === 'like') return '点赞'
    if (type === 'support') return '接住心声'
    if (type === 'system') return '系统通知'
    if (type === 'weekly_report') return '温情周报'
    return type
  }

  getTypeColor(type: string): string {
    if (type === 'like') return '#F08C62'
    if (type === 'support') return '#73C088'
    if (type === 'system') return '#92A0B0'
    if (type === 'weekly_report') return '#B786F7'
    return '#6E7C79'
  }

  formatTime(dateStr: string): string {
    if (!dateStr) return ''
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

  build() {
    Column() {
      Row() {
        Text('← 返回')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#31534A')
          .onClick(() => {
            router.back()
          })

        Blank()

        Text('全部已读')
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor('#31534A')
          .padding({ left: 12, right: 12, top: 8, bottom: 8 })
          .backgroundColor('#F3F6F5')
          .borderRadius(16)
          .onClick(() => {
            this.markAllRead()
          })
      }
      .width('100%')
      .padding({ left: 18, right: 18, top: 16, bottom: 14 })

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
              .backgroundColor(item.isRead ? '#FAFBFC' : Color.White)
              .borderRadius(20)
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
    .backgroundColor('#F4F7F6')
  }
}
