import { AppTheme } from '../common/AppTheme'

@Component
export struct InspirationCard {
  @Prop loading: boolean = false
  @Prop content: string = ''
  @Prop moodLabel: string = ''
  @Prop moodColor: string = ''
  @Prop alreadyDrawn: boolean = false
  onDraw: () => void = () => {}

  private hasContent(): boolean {
    return this.content.length > 0
  }

  private isDrawnToday(): boolean {
    return this.alreadyDrawn
  }

  build() {
    Column({ space: 12 }) {
      Row() {
        Text('陌生人的小纸条')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppTheme.TEXT_TITLE)
        Blank()
        Text('每日一张')
          .fontSize(11)
          .fontColor(AppTheme.TEXT_HINT)
      }
      .width('100%')

      Text('从纸条池里抽一张陌生人写下的鼓励，每天限领一次。')
        .fontSize(12)
        .fontColor(AppTheme.TEXT_SECONDARY)
        .width('100%')

      if (this.loading) {
        Row({ space: 8 }) {
          LoadingProgress()
            .width(24)
            .height(24)
            .color(AppTheme.PRIMARY)
          Text('正在寻找校园里的温暖...')
            .fontSize(13)
            .fontColor(AppTheme.TEXT_HINT)
        }
        .width('100%')
        .padding({ top: 8, bottom: 8 })
      } else if (this.hasContent()) {
        Column({ space: 10 }) {
          Row({ space: 8 }) {
            Column()
              .width(4)
              .height(36)
              .borderRadius(2)
              .backgroundColor(this.moodColor.length > 0 ? this.moodColor : AppTheme.ACCENT)
            Text(this.content)
              .fontSize(14)
              .lineHeight(22)
              .fontColor(AppTheme.TEXT_TITLE)
              .layoutWeight(1)
          }
          .width('100%')
          .alignItems(VerticalAlign.Top)

          Row() {
            Text(this.moodLabel.length > 0 ? this.moodLabel : '温暖')
              .fontSize(11)
              .fontColor(AppTheme.PRIMARY)
              .padding({ left: 10, right: 10, top: 4, bottom: 4 })
              .backgroundColor('#EAF4F0')
              .borderRadius(12)
            Blank()
            Text('来自纸条池')
              .fontSize(11)
              .fontColor(AppTheme.TEXT_HINT)
          }
          .width('100%')
        }
        .width('100%')
        .padding(14)
        .backgroundColor(AppTheme.SURFACE)
        .borderRadius(16)
      }

      Text(this.isDrawnToday() ? '今日已领取' : '抽一张小纸条')
        .width('100%')
        .textAlign(TextAlign.Center)
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .padding({ top: 12, bottom: 12 })
        .backgroundColor(this.isDrawnToday() ? '#B0B8B6' : AppTheme.PRIMARY)
        .borderRadius(AppTheme.RADIUS_PILL)
        .opacity(this.loading ? 0.5 : 1)
        .enabled(!this.loading && !this.isDrawnToday())
        .onClick(() => {
          if (!this.loading && !this.isDrawnToday()) {
            this.onDraw()
          }
        })
    }
    .width('100%')
    .padding(18)
    .backgroundColor(AppTheme.CARD)
    .borderRadius(24)
  }
}
