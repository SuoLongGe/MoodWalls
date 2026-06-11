import { AppTheme } from '../common/AppTheme'
import { moodColor } from '../common/MoodColorConfig'
import { MoodBreakdownItem, ZoneStoryResponse } from '../model/MoodWallTypes'

@Component
export struct ZoneStorySheet {
  @Prop story: ZoneStoryResponse | null = null
  @Prop loading: boolean = false
  onClose: () => void = () => {}
  onViewPosts: () => void = () => {}
  onNavigateToPost: () => void = () => {}

  private postCount(): number {
    if (this.story === null) {
      return 0
    }
    return this.story.postCount
  }

  private breakdownItems(): Array<MoodBreakdownItem> {
    if (this.story === null || this.story.moodBreakdown === undefined) {
      return []
    }
    return this.story.moodBreakdown
  }

  @Builder
  buildBreakdownRow(item: MoodBreakdownItem) {
    Row({ space: 8 }) {
      Text(item.label)
        .fontSize(11)
        .fontColor(AppTheme.TEXT_SECONDARY)
        .width(36)
      Stack({ alignContent: Alignment.Start }) {
        Row()
          .width('100%')
          .height(8)
          .backgroundColor(AppTheme.SURFACE)
          .borderRadius(4)
        Row()
          .width(`${item.percent}%`)
          .height(8)
          .backgroundColor(moodColor(item.mood))
          .borderRadius(4)
          .opacity(0.85)
      }
      .layoutWeight(1)
      Text(`${item.percent}%`)
        .fontSize(10)
        .fontColor(AppTheme.TEXT_HINT)
        .width(32)
        .textAlign(TextAlign.End)
    }
    .width('100%')
  }

  build() {
    Column({ space: 14 }) {
      Row() {
        if (this.story !== null) {
          Column({ space: 4 }) {
            Text(this.story.title)
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppTheme.TEXT_TITLE)
            if (this.story.subtitle.length > 0) {
              Text(this.story.subtitle)
                .fontSize(12)
                .fontColor(AppTheme.TEXT_HINT)
            }
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
        }
        Text('关闭')
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppTheme.TEXT_HINT)
          .onClick(() => {
            this.onClose()
          })
      }
      .width('100%')
      .padding({ top: 20, bottom: 4 })

      if (this.loading) {
        Column() {
          LoadingProgress()
            .width(32)
            .height(32)
            .color(AppTheme.PRIMARY)
        }
        .width('100%')
        .padding(40)
        .justifyContent(FlexAlign.Center)
      } else if (this.story !== null) {
        Row({ space: 8 }) {
          Text(`近 24h · ${this.postCount()} 条心情`)
            .fontSize(12)
            .fontColor(AppTheme.TEXT_SECONDARY)
          if (this.story.dominantMoodLabel !== undefined &&
            this.story.dominantMoodLabel !== null &&
            this.story.dominantMoodLabel.length > 0) {
            Text(`主导 · ${this.story.dominantMoodLabel}`)
              .fontSize(11)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.story.accent)
              .padding({ left: 8, right: 8, top: 3, bottom: 3 })
              .backgroundColor('#F5F7F6')
              .borderRadius(8)
          }
        }
        .width('100%')

        Text(this.story.story)
          .fontSize(15)
          .lineHeight(24)
          .fontColor(AppTheme.TEXT_PRIMARY)
          .width('100%')

        if (this.breakdownItems().length > 0) {
          Column({ space: 8 }) {
            Text('情绪分布')
              .fontSize(12)
              .fontWeight(FontWeight.Medium)
              .fontColor(AppTheme.TEXT_SECONDARY)
              .width('100%')
            ForEach(this.breakdownItems(), (item: MoodBreakdownItem) => {
              this.buildBreakdownRow(item)
            }, (item: MoodBreakdownItem) => item.mood)
          }
          .width('100%')
        }

        Text(this.story.encouragement)
          .fontSize(13)
          .lineHeight(20)
          .fontColor(this.story.accent)
          .fontStyle(FontStyle.Italic)
          .width('100%')
          .padding({ top: 4 })

        Row({ space: 10 }) {
          if (this.postCount() > 0) {
            Text('看看这里的帖子')
              .fontSize(13)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
              .layoutWeight(1)
              .textAlign(TextAlign.Center)
              .padding({ top: 12, bottom: 12 })
              .backgroundColor(AppTheme.PRIMARY)
              .borderRadius(20)
              .onClick(() => {
                this.onViewPosts()
              })
          }
          Text(this.postCount() > 0 ? '去写一张纸条' : '去写第一张纸条')
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppTheme.PRIMARY)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
            .padding({ top: 12, bottom: 12 })
            .backgroundColor(AppTheme.PRIMARY_SOFT)
            .borderRadius(20)
            .onClick(() => {
              this.onNavigateToPost()
            })
        }
        .width('100%')
        .padding({ top: 4, bottom: 8 })
      } else {
        Text('故事加载失败，请稍后重试')
          .fontSize(13)
          .fontColor(AppTheme.TEXT_HINT)
          .width('100%')
          .textAlign(TextAlign.Center)
          .padding({ top: 24, bottom: 24 })
      }
    }
    .width('100%')
    .padding({ left: 20, right: 20, bottom: 20 })
    .backgroundColor(AppTheme.CARD)
    .borderRadius({ topLeft: 24, topRight: 24 })
  }
}
