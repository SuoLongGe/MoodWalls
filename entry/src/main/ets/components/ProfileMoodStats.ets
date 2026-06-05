import { MoodStatItem } from '../model/MoodWallTypes'
import { PostApi } from '../service/PostApi'

type StatsPeriod = 'today' | 'week' | 'month'

@Component
export struct ProfileMoodStats {
  @Prop @Watch('onRefreshTick') refreshTick: number = 0

  @State selectedPeriod: StatsPeriod = 'today'
  @State moodStats: Array<MoodStatItem> = []
  @State statsLoading: boolean = false

  aboutToAppear(): void {
    this.fetchMoodStats()
  }

  onRefreshTick(): void {
    if (this.refreshTick > 0) {
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

  @Builder
  buildPeriodTab(period: StatsPeriod) {
    Text(ProfileMoodStats.periodLabel(period))
      .fontSize(12)
      .fontWeight(this.selectedPeriod === period ? FontWeight.Bold : FontWeight.Normal)
      .fontColor(this.selectedPeriod === period ? '#31534A' : '#6E7C79')
      .padding({ left: 12, right: 12, top: 6, bottom: 6 })
      .backgroundColor(this.selectedPeriod === period ? '#E8F6EC' : '#F0F4F2')
      .borderRadius(14)
      .onClick(() => {
        this.selectPeriod(period)
      })
  }

  build() {
    Column({ space: 12 }) {
      Column({ space: 4 }) {
        Text('我的心情分布')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#25332F')
        Text('按发帖情绪统计占比，仅显示有记录的类型')
          .fontSize(11)
          .fontColor('#95A19F')
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')

      Row({ space: 8 }) {
        this.buildPeriodTab('today')
        this.buildPeriodTab('week')
        this.buildPeriodTab('month')
      }
      .width('100%')

      if (this.statsLoading) {
        LoadingProgress()
          .width(24)
          .height(24)
          .color('#73C088')
      } else if (this.moodStats.length === 0) {
        Text('该时段暂无心情记录')
          .fontSize(12)
          .fontColor('#95A19F')
          .width('100%')
          .textAlign(TextAlign.Center)
          .padding({ top: 8, bottom: 8 })
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
            .padding({ left: 10, right: 10, top: 7, bottom: 7 })
            .backgroundColor(ProfileMoodStats.chipBackground(item.mood))
            .borderRadius(16)
            .margin({ right: 8, bottom: 8 })
          }, (item: MoodStatItem) => `${this.selectedPeriod}-${item.mood}`)
        }
        .width('100%')
      }
    }
    .width('100%')
    .padding(18)
    .backgroundColor('#FFFFFF')
    .borderRadius(24)
  }
}
