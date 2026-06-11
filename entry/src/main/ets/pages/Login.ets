import { AuthTheme } from '../common/AuthTheme'
import { AppTheme } from '../common/AppTheme'
import { AuthSession } from '../common/AuthSession'
import { UiHelper } from '../common/UiHelper'
import { AuthInput } from '../components/auth/AuthInput'
import { AuthResult } from '../model/AuthApiTypes'
import { AuthApi } from '../service/AuthApi'

@Entry
@Component
struct Login {
  @State loginMode: string = 'password'
  @State account: string = ''
  @State password: string = ''
  @State email: string = ''
  @State emailCode: string = ''
  @State emailCodeId: string = ''
  @State loading: boolean = false
  @State sendingCode: boolean = false
  @State resendSeconds: number = 0
  private resendTimer: number = -1

  aboutToAppear(): void {
    if (AuthSession.isLoggedIn()) {
      UiHelper.replaceTo('pages/Index')
    }
  }

  aboutToDisappear(): void {
    this.clearResendTimer()
  }

  pageTransition() {
    PageTransitionEnter({ duration: AppTheme.PAGE_FADE_ENTER_MS, curve: Curve.FastOutSlowIn })
      .opacity(0)
      .translate({ y: 32 })
    PageTransitionExit({ duration: AppTheme.PAGE_FADE_EXIT_MS, curve: Curve.EaseIn })
      .opacity(0)
      .translate({ y: -24 })
  }

  private clearResendTimer(): void {
    if (this.resendTimer >= 0) {
      clearInterval(this.resendTimer)
      this.resendTimer = -1
    }
  }

  private startResendCountdown(seconds: number): void {
    this.clearResendTimer()
    this.resendSeconds = seconds
    this.resendTimer = setInterval(() => {
      if (this.resendSeconds <= 1) {
        this.resendSeconds = 0
        this.clearResendTimer()
      } else {
        this.resendSeconds -= 1
      }
    }, 1000)
  }

  private isValidEmail(value: string): boolean {
    const trimmed: string = value.trim()
    return trimmed.includes('@') && trimmed.includes('.') && trimmed.length >= 5
  }

  private sendEmailCode(): void {
    if (this.sendingCode || this.resendSeconds > 0) {
      return
    }
    if (!this.isValidEmail(this.email)) {
      UiHelper.showToast('请输入正确的邮箱地址')
      return
    }
    this.sendingCode = true
    AuthApi.sendEmailCode(this.email.trim(), 'login').then((result) => {
      this.emailCodeId = result.codeId
      this.emailCode = ''
      this.startResendCountdown(60)
      UiHelper.showToast('验证码已发送至邮箱')
    }).catch((err: Error) => {
      UiHelper.showToast(err.message)
    }).finally(() => {
      this.sendingCode = false
    })
  }

  handleLogin(): void {
    if (this.loading) {
      return
    }
    if (this.loginMode === 'password') {
      this.handlePasswordLogin()
    } else {
      this.handleEmailLogin()
    }
  }

  private handlePasswordLogin(): void {
    if (this.account.trim().length === 0 || this.password.trim().length === 0) {
      UiHelper.showToast('请输入账号和密码')
      return
    }
    this.loading = true
    AuthApi.login(this.account.trim(), this.password).then((result: AuthResult) => {
      AuthSession.save(result.user, result.token)
      UiHelper.showToast('登录成功')
      UiHelper.replaceTo('pages/Index')
    }).catch((err: Error) => {
      UiHelper.showToast(err.message)
    }).finally(() => {
      this.loading = false
    })
  }

  private handleEmailLogin(): void {
    if (!this.isValidEmail(this.email)) {
      UiHelper.showToast('请输入正确的邮箱地址')
      return
    }
    if (this.emailCodeId.length === 0) {
      UiHelper.showToast('请先获取邮箱验证码')
      return
    }
    if (this.emailCode.trim().length === 0) {
      UiHelper.showToast('请输入邮箱验证码')
      return
    }
    this.loading = true
    AuthApi.loginByEmail(this.email.trim(), this.emailCodeId, this.emailCode.trim()).then((result: AuthResult) => {
      AuthSession.save(result.user, result.token)
      UiHelper.showToast('登录成功')
      UiHelper.replaceTo('pages/Index')
    }).catch((err: Error) => {
      UiHelper.showToast(err.message)
    }).finally(() => {
      this.loading = false
    })
  }

  build() {
    Stack({ alignContent: Alignment.Top }) {
      Image($r('app.media.login_bg'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)

      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(AuthTheme.OVERLAY)

      Scroll() {
        Column({ space: 0 }) {
          Column({ space: 10 }) {
            Stack() {
              Circle()
                .width(92)
                .height(92)
                .fill(Color.White)
                .shadow({ radius: 16, color: 'rgba(45, 116, 196, 0.15)', offsetY: 6 })
              Image($r('app.media.app_logo'))
                .width(76)
                .height(76)
                .objectFit(ImageFit.Contain)
            }
            .margin({ top: 56 })

            Text('校园心灵墙')
              .fontSize(28)
              .fontWeight(FontWeight.Bold)
              .fontColor(AuthTheme.TITLE)

            Text('温暖传递，心灵栖息')
              .fontSize(14)
              .fontColor(AuthTheme.SUBTITLE)
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)

          Column({ space: 18 }) {
            if (this.loginMode === 'password') {
              this.buildPasswordForm()
            } else {
              this.buildEmailForm()
            }

            Button(this.loading ? '登录中...' : '登录')
              .width('100%')
              .height(50)
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
              .backgroundColor(this.loading ? '#7BA3D4' : AuthTheme.PRIMARY)
              .borderRadius(25)
              .margin({ top: 6 })
              .enabled(!this.loading)
              .onClick(() => this.handleLogin())

            Row() {
              Text('忘记密码？')
                .fontSize(13)
                .fontColor(AuthTheme.LINK_MUTED)
                .onClick(() => {
                  UiHelper.showToast('请使用邮箱验证码登录，或在个人中心修改密码')
                })

              Text('新用户注册')
                .fontSize(13)
                .fontWeight(FontWeight.Medium)
                .fontColor(AuthTheme.PRIMARY)
                .onClick(() => {
                  if (!this.loading) {
                    UiHelper.pushTo('pages/Register')
                  }
                })
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)

            Row({ space: 12 }) {
              Divider()
                .layoutWeight(1)
                .color(AuthTheme.DIVIDER)
              Text('其他登录方式')
                .fontSize(12)
                .fontColor(AuthTheme.LINK_MUTED)
              Divider()
                .layoutWeight(1)
                .color(AuthTheme.DIVIDER)
            }
            .width('100%')
            .margin({ top: 4 })

            Button(this.loginMode === 'password' ? '使用邮箱验证码登录' : '使用账号密码登录')
              .width('100%')
              .height(44)
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor(AuthTheme.PRIMARY)
              .backgroundColor('#F2F7FC')
              .borderRadius(22)
              .enabled(!this.loading)
              .onClick(() => {
                this.loginMode = this.loginMode === 'password' ? 'email' : 'password'
              })
          }
          .width('100%')
          .padding(28)
          .margin({ left: 20, right: 20, top: 28 })
          .backgroundColor(AuthTheme.CARD_BG)
          .borderRadius(40)
          .shadow({ radius: 28, color: 'rgba(30, 74, 122, 0.12)', offsetY: 10 })

          Column({ space: 6 }) {
            Text('登录即代表您已阅读并同意')
              .fontSize(11)
              .fontColor(AuthTheme.LINK_MUTED)
            Row({ space: 4 }) {
              Text('《用户服务协议》')
                .fontSize(11)
                .fontColor(AuthTheme.PRIMARY)
                .decoration({ type: TextDecorationType.Underline })
              Text('与')
                .fontSize(11)
                .fontColor(AuthTheme.LINK_MUTED)
              Text('《隐私保护政策》')
                .fontSize(11)
                .fontColor(AuthTheme.PRIMARY)
                .decoration({ type: TextDecorationType.Underline })
            }
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)
          .margin({ top: 28, bottom: 40 })
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

  @Builder
  buildPasswordForm() {
    AuthInput({
      placeholder: '昵称 / 手机号 / 邮箱',
      value: $account,
      leadingLabel: '账'
    })

    AuthInput({
      placeholder: '密码',
      value: $password,
      leadingLabel: '密',
      isPassword: true,
      showToggle: true
    })
  }

  @Builder
  buildEmailForm() {
    AuthInput({
      placeholder: '请输入邮箱',
      value: $email,
      leadingLabel: '邮'
    })

    Row({ space: 10 }) {
      Column() {
        AuthInput({
          placeholder: '请输入邮箱验证码',
          value: $emailCode
        })
      }
      .layoutWeight(1)

      Button(this.sendingCode ? '发送中' : (this.resendSeconds > 0 ? `${this.resendSeconds}s` : '获取验证码'))
        .width(108)
        .height(44)
        .fontSize(12)
        .fontColor(Color.White)
        .backgroundColor(this.resendSeconds > 0 || this.sendingCode ? '#9AB8D8' : AuthTheme.PRIMARY)
        .borderRadius(12)
        .enabled(!this.sendingCode && this.resendSeconds === 0)
        .onClick(() => this.sendEmailCode())
    }
    .alignItems(VerticalAlign.Top)
  }
}
