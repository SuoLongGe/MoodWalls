@Component
export struct SunGiftAnimation {
  onFinish: () => void = () => {}
  @State sunScale: number = 0.2
  @State sunOpacity: number = 0
  @State sunOffsetY: number = 0
  @State glowScale: number = 0.5
  @State glowOpacity: number = 0
  @State rayOpacity: number = 0

  aboutToAppear(): void {
    animateTo({ duration: 350, curve: Curve.FastOutSlowIn }, () => {
      this.sunOpacity = 1
      this.sunScale = 1.2
      this.glowOpacity = 0.75
      this.glowScale = 1.3
      this.rayOpacity = 1
    })
    setTimeout(() => {
      animateTo({ duration: 280, curve: Curve.EaseOut }, () => {
        this.sunScale = 1.05
      })
    }, 350)
    setTimeout(() => {
      animateTo({ duration: 1100, curve: Curve.EaseIn }, () => {
        this.sunOffsetY = -140
        this.sunOpacity = 0
        this.glowOpacity = 0
        this.rayOpacity = 0
        this.sunScale = 0.85
      })
    }, 700)
    setTimeout(() => {
      this.onFinish()
    }, 1850)
  }

  @Builder
  buildSunRays() {
    Stack({ alignContent: Alignment.Center }) {
      ForEach([0, 45, 90, 135], (deg: number) => {
        Column()
          .width(4)
          .height(28)
          .backgroundColor('#FFC94A')
          .borderRadius(2)
          .rotate({ angle: deg })
          .opacity(this.rayOpacity)
      }, (deg: number) => `ray-${deg}`)
    }
    .width(120)
    .height(120)
    .scale({ x: this.glowScale, y: this.glowScale })
    .opacity(this.glowOpacity)
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Circle()
        .width(110)
        .height(110)
        .fill('#FFF4CC')
        .scale({ x: this.glowScale, y: this.glowScale })
        .opacity(this.glowOpacity)

      Circle()
        .width(76)
        .height(76)
        .fill('#FFE566')
        .opacity(this.glowOpacity * 0.9)

      this.buildSunRays()

      Text('☀️')
        .fontSize(76)
        .fontWeight(FontWeight.Bold)
    }
    .width('100%')
    .height(200)
    .translate({ y: this.sunOffsetY })
    .scale({ x: this.sunScale, y: this.sunScale })
    .opacity(this.sunOpacity)
  }
}
