import { AuthTheme } from '../../common/AuthTheme'

@Component
export struct AuthInput {
  @Prop placeholder: string = ''
  @Link value: string
  @Prop leadingLabel: string = ''
  @Prop isPassword: boolean = false
  @Prop showToggle: boolean = false
  @State passwordVisible: boolean = false

  build() {
    Row({ space: 10 }) {
      if (this.leadingLabel.length > 0) {
        Text(this.leadingLabel)
          .width(22)
          .textAlign(TextAlign.Center)
          .fontSize(14)
          .fontColor(AuthTheme.PRIMARY)
      }

      TextInput({
        text: this.value,
        placeholder: this.placeholder
      })
        .layoutWeight(1)
        .height(48)
        .fontSize(14)
        .fontColor(AuthTheme.INPUT_TEXT)
        .placeholderColor(AuthTheme.PLACEHOLDER)
        .backgroundColor(Color.Transparent)
        .border({ width: 0 })
        .padding({ left: 0, right: 0 })
        .type(this.isPassword && !this.passwordVisible ? InputType.Password : InputType.Normal)
        .onChange((text: string) => {
          this.value = text
        })

      if (this.showToggle) {
        Text(this.passwordVisible ? '隐藏' : '显示')
          .fontSize(11)
          .fontColor(AuthTheme.LINK_MUTED)
          .onClick(() => {
            this.passwordVisible = !this.passwordVisible
          })
      }
    }
    .width('100%')
    .height(52)
    .padding({ left: 16, right: 16 })
    .backgroundColor(AuthTheme.INPUT_BG)
    .borderRadius(20)
  }
}
