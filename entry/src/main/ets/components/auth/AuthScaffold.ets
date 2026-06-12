@Component
export struct AuthScaffold {
  @BuilderParam hero: () => void = this.emptyHero
  @BuilderParam body: () => void = this.emptyBody
  @Prop heroHeight: number = 280

  @Builder
  emptyHero() {
  }

  @Builder
  emptyBody() {
  }

  build() {
    Stack({ alignContent: Alignment.Top }) {
      Image($r('app.media.lobackground'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)

      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          angle: 180,
          colors: [
            ['rgba(10, 30, 26, 0.35)', 0.0],
            ['rgba(10, 30, 26, 0.08)', 0.38],
            ['rgba(255, 250, 245, 0.88)', 0.72],
            ['rgba(255, 252, 248, 0.96)', 1.0]
          ]
        })

      Scroll() {
        Column() {
          Column() {
            this.hero()
          }
          .width('100%')
          .constraintSize({ minHeight: this.heroHeight })
          .justifyContent(FlexAlign.End)
          .padding({ left: 24, right: 24, bottom: 8 })

          Column() {
            this.body()
          }
          .width('100%')
          .padding({ left: 20, right: 20, bottom: 36 })
        }
        .width('100%')
        .constraintSize({ minHeight: '100%' })
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
  }
}
