@Component
export struct MoodWallTabBar {
  @Link currentTab: number
  onTabChange: () => void = () => {}

  @Builder
  buildTabItem(index: number, label: string) {
    Text(label)
      .layoutWeight(1)
      .textAlign(TextAlign.Center)
      .fontSize(11)
      .fontWeight(this.currentTab === index ? FontWeight.Bold : FontWeight.Medium)
      .fontColor(this.currentTab === index ? '#153A31' : '#778380')
      .padding({ top: 12, bottom: 12 })
      .backgroundColor(this.currentTab === index ? '#CBEADF' : '#FFFFFF')
      .borderRadius(18)
      .onClick(() => {
        if (this.currentTab !== index) {
          this.currentTab = index
          this.onTabChange()
        }
      })
  }

  build() {
    Row({ space: 8 }) {
      this.buildTabItem(0, '心墙')
      this.buildTabItem(1, '地图')
      this.buildTabItem(2, '写一张')
      this.buildTabItem(3, '我的')
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 10, bottom: 18 })
    .backgroundColor('#FFFFFF')
  }
}
