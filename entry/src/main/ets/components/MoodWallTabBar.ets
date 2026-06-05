import { AppTheme } from '../common/AppTheme'

@Component
export struct MoodWallTabBar {
  @Link currentTab: number
  onTabChange: () => void = () => {}

  @Builder
  buildTabItem(index: number, label: string) {
    Column() {
      Text(label)
        .fontSize(11)
        .fontWeight(this.currentTab === index ? FontWeight.Bold : FontWeight.Medium)
        .fontColor(this.currentTab === index ? AppTheme.PRIMARY_DARK : AppTheme.TEXT_HINT)
    }
    .layoutWeight(1)
    .padding({ top: 11, bottom: 11 })
    .backgroundColor(this.currentTab === index ? AppTheme.PRIMARY_SOFT : Color.Transparent)
    .borderRadius(22)
    .scale({
      x: this.currentTab === index ? 1.06 : 1,
      y: this.currentTab === index ? 1.06 : 1
    })
    .animation({ duration: AppTheme.TAB_ENTER_MS, curve: Curve.FastOutSlowIn })
    .onClick(() => {
      if (this.currentTab !== index) {
        this.currentTab = index
        this.onTabChange()
      }
    })
  }

  build() {
    Column() {
      Row({ space: 6 }) {
        this.buildTabItem(0, '心墙')
        this.buildTabItem(1, '地图')
        this.buildTabItem(2, '写一张')
        this.buildTabItem(3, '我的')
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 10, bottom: 10 })
      .backgroundColor(AppTheme.CARD)
      .borderRadius(28)
      .shadow({
        radius: 24,
        color: AppTheme.SHADOW,
        offsetX: 0,
        offsetY: 0
      })
    }
    .width('100%')
    .backgroundColor(AppTheme.CARD)
  }
}
