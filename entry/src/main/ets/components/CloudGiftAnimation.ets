@Component
export struct CloudGiftAnimation {
  onFinish: () => void = () => {}
  @State cloudScale: number = 0.6
  @State cloudOpacity: number = 0
  @State cloudOffsetY: number = 0

  aboutToAppear(): void {
    animateTo({ duration: 200, curve: Curve.EaseOut }, () => {
      this.cloudOpacity = 1
      this.cloudScale = 1
    })
    setTimeout(() => {
      animateTo({ duration: 1000, curve: Curve.EaseOut }, () => {
        this.cloudOffsetY = -120
        this.cloudOpacity = 0
      })
    }, 200)
    setTimeout(() => {
      this.onFinish()
    }, 1250)
  }

  @Builder
  buildCloudShape() {
    Stack({ alignContent: Alignment.Center }) {
      Row({ space: -6 }) {
        Column()
          .width(18)
          .height(18)
          .borderRadius(9)
          .backgroundColor('#F8FCFF')
        Column()
          .width(28)
          .height(28)
          .borderRadius(14)
          .backgroundColor('#FFFFFF')
        Column()
          .width(20)
          .height(20)
          .borderRadius(10)
          .backgroundColor('#F8FCFF')
      }
      Column()
        .width(52)
        .height(16)
        .borderRadius(8)
        .backgroundColor('#FFFFFF')
        .margin({ top: 14 })
    }
    .shadow({
      radius: 12,
      color: 'rgba(108, 177, 240, 0.35)',
      offsetX: 0,
      offsetY: 4
    })
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      this.buildCloudShape()
    }
    .width('100%')
    .height(120)
    .translate({ y: this.cloudOffsetY })
    .scale({ x: this.cloudScale, y: this.cloudScale })
    .opacity(this.cloudOpacity)
  }
}
