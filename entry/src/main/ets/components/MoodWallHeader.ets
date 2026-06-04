import { getAvatarResource } from '../common/AvatarResources'
import { UiHelper } from '../common/UiHelper'
import { MoodStatItem } from '../model/MoodWallTypes'
import { PostApi } from '../service/PostApi'

type StatsPeriod = 'today' | 'week' | 'month'

@Component
export struct MoodWallHeader {
  @StorageLink('userNickname') userNickname: string = '同学'
  @StorageLink('userAvatarKey') userAvatarKey: string = 'avatar_01'
  @StorageLink('unreadNotificationCount') unreadCount: number = 0
  @Prop currentTab: number = 0
  @Prop greeting: string = ''
  @Prop @Watch('onStatsRefreshTick') statsRefreshTick: number = 0

  @State selectedPeriod: StatsPeriod = 'today'
  @State moodStats: Array<MoodStatItem> = []
  @State statsLoading: boolean = false

  aboutToAppear(): void {
    this.fetchMoodStats()
  }

  onStatsRefreshTick(): void {
    if (this.statsRefreshTick > 0) {
      this.fetchMoodStats()
    }
  }

  fetchMoodStats(): void {
    this.statsLoading = true
    PostApi.getMoodStats(this.selectedPeriod).then((res) => {
      this.moodStats = res.items
      this.statsLoading = false
    }).catch((err: Error) => {
      console.error(`fetchMoodStats: ${err.message}`)
      this.moodStats = []
      this.statsLoading = false
    })
  }

  selectPeriod(period: StatsPeriod): void {
    if (this.selectedPeriod === period) {
      return
    }
    this.selectedPeriod = period
    this.fetchMoodStats()
  }

  static chipBackground(mood: string): string {
    if (mood === 'happy') {
      return '#FFF7DB'
    }
    if (mood === 'calm') {
      return '#EEF9F1'
    }
    if (mood === 'moved') {
      return '#F3EDFD'
    }
    if (mood === 'tired') {
      return '#F0F3F6'
    }
    if (mood === 'anxious') {
      return '#FFF1EB'
    }
    if (mood === 'sad') {
      return '#EBF5FD'
    }
    if (mood === 'angry') {
      return '#FDECEC'
    }
    if (mood === 'lonely') {
      return '#F0EDFA'
    }
    return '#F4F7F6'
  }

  static periodLabel(period: StatsPeriod): string {
    if (period === 'week') {
      return '本周'
    }
    if (period === 'month') {
      return '本月'
    }
    return '本日'
  }

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
  buildPeriodTab(period: StatsPeriod) {
    Text(MoodWallHeader.periodLabel(period))
      .fontSize(12)
      .fontWeight(this.selectedPeriod === period ? FontWeight.Bold : FontWeight.Normal)
      .fontColor(this.selectedPeriod === period ? '#31534A' : '#6E7C79')
      .padding({ left: 14, right: 14, top: 8, bottom: 8 })
      .backgroundColor(this.selectedPeriod === period ? '#E8F6EC' : '#F0F4F2')
      .borderRadius(16)
      .onClick(() => {
        this.selectPeriod(period)
      })
  }

  @Builder
  buildNotificationButton() {
    Row({ space: 4 }) {
      Text('通知')
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .fontColor('#31534A')

      if (this.unreadCount > 0) {
        Text(this.getBadgeText())
          .fontSize(9)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .backgroundColor('#E17272')
          .borderRadius(8)
          .constraintSize({ minWidth: 16 })
          .height(16)
          .padding({ left: 4, right: 4 })
          .textAlign(TextAlign.Center)
      }
    }
    .padding({ left: 12, right: 12, top: 10, bottom: 10 })
    .backgroundColor('#F3F6F5')
    .borderRadius(18)
    .flexShrink(0)
    .onClick(() => {
      UiHelper.pushTo('pages/NotificationPage')
    })
  }

  build() {
    Column({ space: 12 }) {
      Row({ space: 10 }) {
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
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            Text(this.getSubtitle())
              .fontSize(12)
              .fontColor('#6B7C78')
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
        }
        .layoutWeight(1)

        this.buildNotificationButton()
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      if (this.currentTab !== 2) {
        Column({ space: 10 }) {
          Row({ space: 8 }) {
            this.buildPeriodTab('today')
            this.buildPeriodTab('week')
            this.buildPeriodTab('month')
          }
          .width('100%')

          if (this.statsLoading) {
            Text('统计加载中…')
              .fontSize(11)
              .fontColor('#95A19F')
          } else if (this.moodStats.length === 0) {
            Text('该时段暂无心情统计')
              .fontSize(11)
              .fontColor('#95A19F')
          } else {
            Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
              ForEach(this.moodStats, (item: MoodStatItem) => {
                Row({ space: 6 }) {
                  Circle()
                    .width(8)
                    .height(8)
                    .fill(item.color)
                  Text(`${item.label} ${item.percent}%`)
                    .fontSize(11)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(item.color)
                }
                .padding({ left: 12, right: 12, top: 8, bottom: 8 })
                .backgroundColor(MoodWallHeader.chipBackground(item.mood))
                .borderRadius(18)
                .margin({ right: 8, bottom: 8 })
              }, (item: MoodStatItem) => item.mood)
            }
            .width('100%')
          }
        }
        .width('100%')
      }
    }
    .width('100%')
    .padding({ left: 18, right: 18, top: 18, bottom: 16 })
    .backgroundColor('#F9FBFA')
  }
}
