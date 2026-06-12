import { AuthTheme } from '../../common/AuthTheme'

@Component
export struct AuthCodeButton {
  @Prop label: string = '获取验证码'
  @Prop buttonEnabled: boolean = true
  onTap: () => void = () => {}

  build() {
    Button(this.label)
      .width(108)
      .height(54)
      .fontSize(12)
      .fontWeight(FontWeight.Medium)
      .fontColor(Color.White)
      .borderRadius(16)
      .linearGradient({
        angle: 135,
        colors: this.buttonEnabled
          ? [[AuthTheme.GRADIENT_START, 0.0], [AuthTheme.GRADIENT_END, 1.0]]
          : [['#A8C4BC', 0.0], ['#9BB0BE', 1.0]]
      })
      .shadow({
        radius: this.buttonEnabled ? 10 : 4,
        color: 'rgba(46, 107, 94, 0.25)',
        offsetY: 4
      })
      .enabled(this.buttonEnabled)
      .onClick(() => {
        this.onTap()
      })
  }
}
