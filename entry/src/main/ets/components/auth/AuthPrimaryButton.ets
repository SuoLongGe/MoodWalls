import { AuthTheme } from '../../common/AuthTheme'

@Component
export struct AuthPrimaryButton {
  @Prop label: string = '确定'
  @Prop loading: boolean = false
  @Prop buttonEnabled: boolean = true
  onTap: () => void = () => {}

  @State pressed: boolean = false

  build() {
    Button() {
      Row({ space: 8 }) {
        if (this.loading) {
          LoadingProgress()
            .width(20)
            .height(20)
            .color(Color.White)
        }
        Text(this.label)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
      }
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .height(52)
    .borderRadius(26)
    .linearGradient({
      angle: 135,
      colors: this.buttonEnabled && !this.loading
        ? [[AuthTheme.GRADIENT_START, 0.0], [AuthTheme.GRADIENT_END, 1.0]]
        : [['#9BB8B0', 0.0], ['#8AA8B8', 1.0]]
    })
    .shadow({
      radius: this.pressed ? 8 : 18,
      color: 'rgba(46, 107, 94, 0.35)',
      offsetY: this.pressed ? 2 : 8
    })
    .scale({ x: this.pressed ? 0.98 : 1, y: this.pressed ? 0.98 : 1 })
    .animation({ duration: 160, curve: Curve.EaseOut })
    .enabled(this.buttonEnabled && !this.loading)
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.pressed = true
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.pressed = false
      }
    })
    .onClick(() => {
      this.onTap()
    })
  }
}
