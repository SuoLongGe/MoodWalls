@Component
export struct AuthGlassCard {
  @Prop cardOpacity: number = 1
  @Prop cardOffsetY: number = 0
  @BuilderParam content: () => void = this.emptyContent

  @Builder
  emptyContent() {
  }

  build() {
    Column() {
      this.content()
    }
    .width('100%')
    .padding(24)
    .backgroundColor('rgba(255, 255, 255, 0.78)')
    .backgroundBlurStyle(BlurStyle.Thin)
    .borderRadius(28)
    .border({ width: 1, color: 'rgba(255, 255, 255, 0.95)' })
    .shadow({ radius: 32, color: 'rgba(20, 50, 45, 0.14)', offsetY: 12 })
    .opacity(this.cardOpacity)
    .translate({ y: this.cardOffsetY })
  }
}
