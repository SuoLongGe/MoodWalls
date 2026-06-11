import { AppTheme } from '../common/AppTheme'
import { UserAvatar } from './UserAvatar'
import { UiHelper } from '../common/UiHelper'

@Component
export struct MoodWallHeader {
  @StorageLink('userNickname') userNickname: string = '同学'
  @StorageLink('userAvatarKey') userAvatarKey: string = 'avatar_01'
  @StorageLink('userAvatarUrl') userAvatarUrl: string = ''
  @StorageLink('unreadNotificationCount') unreadCount: number = 0
  @Prop currentTab: number = 0
  @Prop greeting: string = ''

  getBadgeText(): string {
    if (this.unreadCount > 99) {
      return '99+'
    }
    return `${this.unreadCount}`
  }

  getSubtitle(): string {
    if (this.currentTab === 1) {
      return '看看此刻校园情绪落在哪些角落。'
    }
    if (this.currentTab === 2) {
      return '写下一张心情纸条，贴进校园心墙。'
    }
    return '今天校园里又有一些心情落在了墙上。'
  }

  @Builder
  buildSearchButton() {
    Text('搜索')
      .fontSize(12)
      .fontWeight(FontWeight.Bold)
      .fontColor(AppTheme.PRIMARY)
      .padding({ left: 14, right: 14, top: 10, bottom: 10 })
      .backgroundColor(AppTheme.SURFACE)
      .borderRadius(AppTheme.RADIUS_PILL)
      .flexShrink(0)
      .onClick(() => {
        UiHelper.pushTo('pages/SearchPage')
      })
  }

  @Builder
  buildNotificationButton() {
    Row({ space: 4 }) {
      Text('通知')
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppTheme.PRIMARY)

      if (this.unreadCount > 0) {
        Text(this.getBadgeText())
          .fontSize(9)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .backgroundColor(AppTheme.BADGE)
          .borderRadius(8)
          .constraintSize({ minWidth: 16 })
          .height(16)
          .padding({ left: 4, right: 4 })
          .textAlign(TextAlign.Center)
      }
    }
    .padding({ left: 14, right: 14, top: 10, bottom: 10 })
    .backgroundColor(AppTheme.SURFACE)
    .borderRadius(AppTheme.RADIUS_PILL)
    .flexShrink(0)
    .onClick(() => {
      UiHelper.pushTo('pages/NotificationPage')
    })
  }

  build() {
    Column({ space: 12 }) {
      Row({ space: 10 }) {
        Row({ space: 12 }) {
          Stack() {
            UserAvatar({
              avatarKey: this.userAvatarKey,
              avatarUrl: this.userAvatarUrl,
              avatarSize: 46
            })
          }
          .border({ width: 2, color: AppTheme.ACCENT_BORDER, radius: 23 })
          .shadow({
            radius: 8,
            color: AppTheme.SHADOW_LIGHT,
            offsetY: 2
          })

          Column({ space: 4 }) {
            Text(`${this.greeting}，${this.userNickname}`)
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppTheme.TEXT_PRIMARY)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            Text(this.getSubtitle())
              .fontSize(12)
              .fontColor(AppTheme.TEXT_SECONDARY)
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
        }
        .layoutWeight(1)

        Row({ space: 8 }) {
          if (this.currentTab === 0) {
            this.buildSearchButton()
          }
          this.buildNotificationButton()
        }
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 12 })
    .backgroundColor(AppTheme.CARD)
    .border({ width: { bottom: 0.5 }, color: '#EEEEEE' })
  }
}
