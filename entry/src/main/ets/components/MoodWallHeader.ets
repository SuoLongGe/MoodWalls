import { getAvatarResource } from '../common/AvatarResources'
import { UiHelper } from '../common/UiHelper'

@Component
export struct MoodWallHeader {
  @StorageLink('userNickname') userNickname: string = '同学'
  @StorageLink('userAvatarKey') userAvatarKey: string = 'avatar_01'
  @Prop currentTab: number = 0
  @Prop greeting: string = ''
  @Prop anxiousPercent: number = 0
  @Prop calmPercent: number = 0
  @Prop happyPercent: number = 0
  @Prop unreadCount: number = 0

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
  buildChip(title: string, value: number, bgColor: string, textColor: string) {
    Row({ space: 6 }) {
      Circle()
        .width(8)
        .height(8)
        .fill(textColor)
      Text(`${title} ${value}%`)
        .fontSize(11)
        .fontWeight(FontWeight.Medium)
        .fontColor(textColor)
    }
    .padding({ left: 12, right: 12, top: 8, bottom: 8 })
    .backgroundColor(bgColor)
    .borderRadius(18)
  }

  build() {
    Column({ space: 14 }) {
      Row() {
        Row({ space: 12 }) {
          Image(getAvatarResource(this.userAvatarKey))
            .width(44)
            .height(44)
            .borderRadius(22)
            .objectFit(ImageFit.Cover)
            .border({ width: 2, color: '#E8F6EC' })

          Column({ space: 4 }) {
            Text(`${this.greeting}，${this.userNickname}`)
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#22352F')
            Text(this.getSubtitle())
              .fontSize(12)
              .fontColor('#6B7C78')
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
        }

        Stack() {
          Text('通知')
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor('#31534A')
            .padding({ left: 12, right: 12, top: 10, bottom: 10 })
            .backgroundColor('#F3F6F5')
            .borderRadius(18)
            .onClick(() => {
              UiHelper.pushTo('pages/NotificationPage')
            })

          if (this.unreadCount > 0) {
            Text(this.unreadCount > 99 ? '99+' : `${this.unreadCount}`)
              .fontSize(9)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
              .backgroundColor('#E17272')
              .borderRadius(10)
              .constraintSize({ minWidth: 18 })
              .height(18)
              .textAlign(TextAlign.Center)
              .position({ x: this.unreadCount > 9 ? -10 : -6, y: -4 })
          }
        }
      }
      .justifyContent(FlexAlign.SpaceBetween)
      .width('100%')

      if (this.currentTab !== 2) {
        Row({ space: 8 }) {
          this.buildChip('焦虑', this.anxiousPercent, '#FFF1EB', '#D86A3D')
          this.buildChip('平静', this.calmPercent, '#EEF9F1', '#33824A')
          this.buildChip('开心', this.happyPercent, '#FFF7DB', '#A87400')
        }
        .width('100%')
      }
    }
    .width('100%')
    .padding({ left: 18, right: 18, top: 18, bottom: 16 })
    .backgroundColor('#F9FBFA')
  }
}
