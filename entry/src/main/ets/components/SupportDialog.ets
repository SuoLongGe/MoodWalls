@Component
export struct SupportDialog {
  @Link visible: boolean
  @Prop title: string = ''
  @Prop message: string = ''

  build() {
    if (this.visible) {
      Stack({ alignContent: Alignment.Center }) {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(26, 39, 36, 0.35)')

        Column({ space: 14 }) {
          Row() {
            Text(this.title)
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor('#25332F')
            Text('关闭')
              .fontSize(12)
              .fontWeight(FontWeight.Bold)
              .fontColor('#7A8784')
              .onClick(() => {
                this.visible = false
              })
          }
          .justifyContent(FlexAlign.SpaceBetween)
          .width('100%')

          Text('校园倾听树洞')
            .fontSize(13)
            .fontColor('#73A18F')

          Text(this.message)
            .fontSize(14)
            .lineHeight(24)
            .fontColor('#43524E')

          Text('收下这封回信')
            .width('100%')
            .textAlign(TextAlign.Center)
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .padding({ top: 12, bottom: 12 })
            .backgroundColor('#31534A')
            .borderRadius(22)
            .onClick(() => {
              this.visible = false
            })
        }
        .width('84%')
        .padding(20)
        .backgroundColor('#FFFFFF')
        .borderRadius(28)
      }
      .width('100%')
      .height('100%')
      .position({ x: 0, y: 0 })
    }
  }
}
