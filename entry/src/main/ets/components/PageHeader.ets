import { AppTheme } from '../common/AppTheme'

@Component
export struct PageHeader {
  @Prop title: string = ''
  onBack: () => void = () => {}
  @BuilderParam rightAction: () => void = this.emptyRight

  @Builder
  emptyRight() {
  }

  build() {
    Row() {
      Row({ space: 2 }) {
        Text('‹')
          .fontSize(26)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppTheme.PRIMARY)
          .margin({ top: -2 })
        Text('返回')
          .fontSize(14)
          .fontColor(AppTheme.TEXT_SECONDARY)
      }
      .padding({ left: 8, right: 12, top: 10, bottom: 10 })
      .onClick(() => {
        this.onBack()
      })

      Text(this.title)
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppTheme.TEXT_TITLE)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Row() {
        this.rightAction()
      }
      .width(80)
      .justifyContent(FlexAlign.End)
    }
    .width('100%')
    .padding({ left: 4, right: 16, top: 4, bottom: 8 })
    .backgroundColor(AppTheme.CARD)
    .border({ width: { bottom: 0.5 }, color: '#EEEEEE' })
  }
}
