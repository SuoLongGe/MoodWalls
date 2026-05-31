import { ZoneCard } from '../model/MoodWallTypes'

@Component
export struct MapTab {
  @Prop zones: Array<ZoneCard> = []
  onNavigateToPost: () => void = () => {}

  build() {
    Column({ space: 14 }) {
      Column({ space: 10 }) {
        Text('今日校园情绪气候')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#25332F')
        Text('整体偏多云转温柔。图书馆附近压力偏高，生活区和湖边更适合慢下来。')
          .fontSize(12)
          .lineHeight(20)
          .fontColor('#6E7C79')
      }
      .width('100%')
      .padding(18)
      .backgroundColor('#F5FBF8')
      .borderRadius(24)

      ForEach(this.zones, (zone: ZoneCard) => {
        Column({ space: 10 }) {
          Row() {
            Column({ space: 4 }) {
              Text(zone.title)
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor('#25332F')
              Text(zone.subtitle)
                .fontSize(12)
                .fontColor(zone.accent)
            }
            .alignItems(HorizontalAlign.Start)

            Text('查看')
              .fontSize(12)
              .fontColor('#31534A')
          }
          .justifyContent(FlexAlign.SpaceBetween)
          .width('100%')

          Text(zone.summary)
            .fontSize(13)
            .lineHeight(21)
            .fontColor('#5F706C')

          Text('去写一张纸条 +')
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .padding({ left: 14, right: 14, top: 9, bottom: 9 })
            .backgroundColor('#31534A')
            .borderRadius(18)
            .onClick(() => {
              this.onNavigateToPost()
            })
        }
        .width('100%')
        .padding(18)
        .backgroundColor(Color.White)
        .borderRadius(24)
      }, (zone: ZoneCard) => zone.key)
    }
  }
}
