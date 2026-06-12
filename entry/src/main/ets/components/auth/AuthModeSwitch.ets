import { AuthTheme } from '../../common/AuthTheme'

@Component
export struct AuthModeSwitch {
  @Prop activeMode: string = 'password'
  @Prop leftLabel: string = '密码登录'
  @Prop rightLabel: string = '邮箱验证码'
  @Prop leftMode: string = 'password'
  @Prop rightMode: string = 'email'
  onChange: (mode: string) => void = () => {}

  build() {
    Row({ space: 4 }) {
      Text(this.leftLabel)
        .fontSize(13)
        .fontWeight(this.activeMode === this.leftMode ? FontWeight.Bold : FontWeight.Normal)
        .fontColor(this.activeMode === this.leftMode ? AuthTheme.PRIMARY_DARK : AuthTheme.LINK_MUTED)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
        .height(40)
        .borderRadius(20)
        .backgroundColor(this.activeMode === this.leftMode ? Color.White : Color.Transparent)
        .shadow(this.activeMode === this.leftMode
          ? { radius: 12, color: 'rgba(30, 74, 60, 0.12)', offsetY: 4 } : { radius: 0, color: Color.Transparent })
        .animation({ duration: 280, curve: Curve.FastOutSlowIn })
        .onClick(() => {
          this.onChange(this.leftMode)
        })

      Text(this.rightLabel)
        .fontSize(13)
        .fontWeight(this.activeMode === this.rightMode ? FontWeight.Bold : FontWeight.Normal)
        .fontColor(this.activeMode === this.rightMode ? AuthTheme.PRIMARY_DARK : AuthTheme.LINK_MUTED)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
        .height(40)
        .borderRadius(20)
        .backgroundColor(this.activeMode === this.rightMode ? Color.White : Color.Transparent)
        .shadow(this.activeMode === this.rightMode
          ? { radius: 12, color: 'rgba(30, 74, 60, 0.12)', offsetY: 4 } : { radius: 0, color: Color.Transparent })
        .animation({ duration: 280, curve: Curve.FastOutSlowIn })
        .onClick(() => {
          this.onChange(this.rightMode)
        })
    }
    .width('100%')
    .height(48)
    .padding(4)
    .backgroundColor('rgba(255,255,255,0.45)')
    .borderRadius(24)
    .border({ width: 1, color: AuthTheme.INPUT_BORDER })
  }
}
