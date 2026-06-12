import { AuthTheme } from '../../common/AuthTheme'

@Component
export struct AuthInput {
  @Prop placeholder: string = ''
  @Link value: string
  @Prop isPassword: boolean = false
  @Prop showToggle: boolean = false
  @State passwordVisible: boolean = false
  @State focused: boolean = false

  build() {
    Row({ space: 8 }) {
      TextInput({
        text: this.value,
        placeholder: this.placeholder
      })
        .layoutWeight(1)
        .height(48)
        .fontSize(15)
        .fontColor(AuthTheme.INPUT_TEXT)
        .placeholderColor(AuthTheme.PLACEHOLDER)
        .backgroundColor(Color.Transparent)
        .border({ width: 0 })
        .padding({ left: 4, right: 4 })
        .type(this.isPassword && !this.passwordVisible ? InputType.Password : InputType.Normal)
        .onChange((text: string) => {
          this.value = text
        })
        .onFocus(() => {
          this.focused = true
        })
        .onBlur(() => {
          this.focused = false
        })

      if (this.showToggle) {
        Text(this.passwordVisible ? '隐藏' : '显示')
          .fontSize(12)
          .fontColor(AuthTheme.PRIMARY)
          .padding({ left: 8, right: 4 })
          .onClick(() => {
            this.passwordVisible = !this.passwordVisible
          })
      }
    }
    .width('100%')
    .height(52)
    .padding({ left: 16, right: 12 })
    .backgroundColor(this.focused ? Color.White : AuthTheme.INPUT_BG)
    .borderRadius(14)
    .border({
      width: this.focused ? 2 : 1.5,
      color: this.focused ? AuthTheme.PRIMARY : AuthTheme.INPUT_BORDER
    })
    .shadow({
      radius: this.focused ? 10 : 4,
      color: this.focused ? 'rgba(46, 107, 94, 0.16)' : 'rgba(30, 60, 55, 0.08)',
      offsetY: this.focused ? 3 : 1
    })
    .animation({ duration: 200, curve: Curve.EaseOut })
  }
}
