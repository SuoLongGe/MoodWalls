import { AppTheme } from '../common/AppTheme'

@Component
export struct MoodWallTabBar {
  @Link currentTab: number
  onTabChange: () => void = () => {}

  @Builder
  buildTabItem(index: number, label: string) {
    Column({ space: 2 }) {
      Text(label)
        .fontSize(12)
        .fontWeight(this.currentTab === index ? FontWeight.Bold : FontWeight.Normal)
        .fontColor(this.currentTab === index ? AppTheme.PRIMARY_DARK : AppTheme.TEXT_HINT)
    }
    .layoutWeight(1)
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      if (this.currentTab !== index) {
        this.currentTab = index
        this.onTabChange()
      }
    })
  }

  build() {
    Row() {
      this.buildTabItem(0, '心墙')
      this.buildTabItem(1, '地图')
      this.buildTabItem(2, '写一张')
      this.buildTabItem(3, '我的')
    }
    .width('100%')
    .height(52)
    .backgroundColor(AppTheme.CARD)
    .border({ width: { top: 0.5 }, color: '#E8E8E8' })
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
  }
}
