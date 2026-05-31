import { AuthTheme } from '../common/AuthTheme'
import { AuthSession } from '../common/AuthSession'
import { UiHelper } from '../common/UiHelper'
import { AuthInput } from '../components/auth/AuthInput'
import { AuthResult, CaptchaResult } from '../model/AuthApiTypes'
import { AuthApi } from '../service/AuthApi'

@Entry
@Component
struct Register {
  @State nickname: string = ''
  @State phone: string = ''
  @State captchaCode: string = ''
  @State captchaId: string = ''
  @State captchaText: string = '----'
  @State password: string = ''
  @State agreeTerms: boolean = false
  @State loading: boolean = false
  @State loadingCaptcha: boolean = false

  aboutToAppear(): void {
    this.refreshCaptcha()
  }

  refreshCaptcha(): void {
    if (this.loadingCaptcha) {
      return
    }
    this.loadingCaptcha = true
    AuthApi.getCaptcha().then((result: CaptchaResult) => {
      this.captchaId = result.captchaId
      this.captchaText = result.captchaText
      this.captchaCode = ''
    }).catch((err: Error) => {
      UiHelper.showToast(err.message)
    }).finally(() => {
      this.loadingCaptcha = false
    })
  }

  handleRegister(): void {
    if (this.loading) {
      return
    }
    if (!this.agreeTerms) {
      UiHelper.showToast('请先阅读并同意用户协议与隐私政策')
      return
    }
    if (this.nickname.trim().length === 0) {
      UiHelper.showToast('请填写昵称')
      return
    }
    if (this.phone.trim().length === 0) {
      UiHelper.showToast('请填写手机号')
      return
    }
    if (this.captchaCode.trim().length === 0) {
      UiHelper.showToast('请填写验证码')
      return
    }
    if (this.password.trim().length < 8) {
      UiHelper.showToast('密码建议 8-16 位数字或字母组合')
      return
    }

    this.loading = true
    AuthApi.register(
      this.nickname.trim(),
      this.phone.trim(),
      this.captchaId,
      this.captchaCode.trim(),
      this.password
    ).then((result: AuthResult) => {
      AuthSession.save(result.user, result.token)
      UiHelper.showToast('注册成功，欢迎加入校园心灵墙')
      UiHelper.replaceTo('pages/Index')
    }).catch((err: Error) => {
      UiHelper.showToast(err.message)
      this.refreshCaptcha()
    }).finally(() => {
      this.loading = false
    })
  }

  build() {
    Column() {
      Row() {
        Text('←')
          .fontSize(22)
          .fontColor(AuthTheme.PRIMARY)
          .width(40)
          .onClick(() => {
            if (!this.loading) {
              UiHelper.goBack()
            }
          })

        Text('创建你的心灵账号')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(AuthTheme.PRIMARY)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Blank()
          .width(40)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12 })

      Row({ space: 0 }) {
        this.buildStepPill('1 账号信息', true)
        Row()
          .layoutWeight(1)
          .height(2)
          .backgroundColor('#E0E8EF')
          .margin({ left: 8, right: 8, top: 18 })
        this.buildStepPill('2 个人资料', false)
      }
      .width('100%')
      .padding({ left: 24, right: 24, top: 20 })

      Scroll() {
        Column({ space: 16 }) {
          Column({ space: 14 }) {
            this.buildFieldLabel('昵称')
            AuthInput({
              placeholder: '起一个温暖的名字吧',
              value: $nickname
            })

            this.buildFieldLabel('手机号')
            AuthInput({
              placeholder: '请输入手机号码',
              value: $phone
            })

            this.buildFieldLabel('验证码')
            Row({ space: 10 }) {
              Column() {
                AuthInput({
                  placeholder: '请输入右侧验证码',
                  value: $captchaCode
                })
              }
              .layoutWeight(1)

              Column({ space: 4 }) {
                Text(this.captchaText)
                  .width(96)
                  .height(44)
                  .textAlign(TextAlign.Center)
                  .fontSize(20)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#2D74C4')
                  .letterSpacing(4)
                  .backgroundColor('#EEF4F8')
                  .borderRadius(12)
                  .border({ width: 1, color: '#C8D9E8' })

                Text(this.loadingCaptcha ? '刷新中' : '换一张')
                  .fontSize(11)
                  .fontColor(AuthTheme.PRIMARY)
                  .textAlign(TextAlign.Center)
                  .width(96)
                  .onClick(() => this.refreshCaptcha())
              }
            }
            .alignItems(VerticalAlign.Top)

            this.buildFieldLabel('设置密码')
            AuthInput({
              placeholder: '建议8-16位数字或字母组合',
              value: $password,
              isPassword: true,
              showToggle: true
            })

            Row({ space: 10 }) {
              Checkbox({ name: 'agree', group: 'register' })
                .select(this.agreeTerms)
                .selectedColor(AuthTheme.PRIMARY)
                .onChange((checked: boolean) => {
                  this.agreeTerms = checked
                })

              Text() {
                Span('我已阅读并同意')
                  .fontSize(12)
                  .fontColor('#5F6F7A')
                Span('《用户协议》')
                  .fontSize(12)
                  .fontColor(AuthTheme.PRIMARY)
                Span('与')
                  .fontSize(12)
                  .fontColor('#5F6F7A')
                Span('《隐私政策》')
                  .fontSize(12)
                  .fontColor(AuthTheme.PRIMARY)
                Span('，愿共建温暖社区。')
                  .fontSize(12)
                  .fontColor('#5F6F7A')
              }
              .layoutWeight(1)
            }
            .alignItems(VerticalAlign.Top)
            .margin({ top: 4 })

            Button(this.loading ? '注册中...' : '立即注册')
              .width('100%')
              .height(50)
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
              .backgroundColor(this.loading ? '#7BA3D4' : AuthTheme.PRIMARY)
              .borderRadius(25)
              .margin({ top: 8 })
              .enabled(!this.loading)
              .onClick(() => this.handleRegister())

            Row() {
              Text('已有账号？')
                .fontSize(13)
                .fontColor(AuthTheme.LINK_MUTED)
              Text('直接登录')
                .fontSize(13)
                .fontWeight(FontWeight.Medium)
                .fontColor(AuthTheme.PRIMARY)
                .onClick(() => {
                  if (!this.loading) {
                    UiHelper.goBack()
                  }
                })
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)
            .margin({ top: 4, bottom: 8 })
          }
          .width('100%')
          .padding(24)
          .backgroundColor(Color.White)
          .borderRadius(32)
          .shadow({ radius: 20, color: 'rgba(30, 74, 122, 0.08)', offsetY: 8 })

          Column({ space: 8 }) {
            Stack() {
              Circle()
                .width(72)
                .height(72)
                .fill(Color.White)
              Image($r('app.media.app_logo'))
                .width(60)
                .height(60)
                .objectFit(ImageFit.Contain)
            }
            Text('校园心灵墙 · 温暖每一刻')
              .fontSize(12)
              .fontColor('#5F6F7A')
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)
          .margin({ top: 8, bottom: 32 })
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 8 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AuthTheme.REGISTER_BG)
  }

  @Builder
  buildFieldLabel(label: string) {
    Text(label)
      .fontSize(13)
      .fontWeight(FontWeight.Medium)
      .fontColor('#4A5A66')
      .width('100%')
  }

  @Builder
  buildStepPill(text: string, active: boolean) {
    Text(text)
      .fontSize(12)
      .fontWeight(FontWeight.Medium)
      .fontColor(active ? Color.White : '#9AA8B5')
      .padding({ left: 16, right: 16, top: 10, bottom: 10 })
      .backgroundColor(active ? AuthTheme.PRIMARY : '#E8EEF3')
      .borderRadius(20)
  }
}
