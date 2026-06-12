import { AuthTheme } from '../common/AuthTheme'
import { AppTheme } from '../common/AppTheme'
import { AuthSession } from '../common/AuthSession'
import { UiHelper } from '../common/UiHelper'
import { AuthCodeButton } from '../components/auth/AuthCodeButton'
import { AuthGlassCard } from '../components/auth/AuthGlassCard'
import { AuthInput } from '../components/auth/AuthInput'
import { AuthModeSwitch } from '../components/auth/AuthModeSwitch'
import { AuthPrimaryButton } from '../components/auth/AuthPrimaryButton'
import { AuthScaffold } from '../components/auth/AuthScaffold'
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
  @State heroOpacity: number = 0
  @State heroOffsetY: number = 28
  @State cardOpacity: number = 0
  @State cardOffsetY: number = 56
  @State logoScale: number = 0.86
  @State floatOffset: number = 0
  @State formOpacity: number = 1
  @State formOffsetX: number = 0
  private resendTimer: number = -1
  private floatTimer: number = -1
  private floatUp: boolean = true

  aboutToAppear(): void {
    if (AuthSession.isLoggedIn()) {
      UiHelper.replaceTo('pages/Index')
      return
    }
    animateTo({ duration: 880, curve: Curve.FastOutSlowIn }, () => {
      this.heroOpacity = 1
      this.heroOffsetY = 0
      this.cardOpacity = 1
      this.cardOffsetY = 0
      this.logoScale = 1
    })
    this.startFloatAnimation()
  }

  aboutToDisappear(): void {
    this.clearResendTimer()
    this.clearFloatTimer()
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

  private clearFloatTimer(): void {
    if (this.floatTimer >= 0) {
      clearInterval(this.floatTimer)
      this.floatTimer = -1
    }
  }

  private startFloatAnimation(): void {
    this.clearFloatTimer()
    this.floatTimer = setInterval(() => {
      animateTo({ duration: 2200, curve: Curve.EaseInOut }, () => {
        this.floatOffset = this.floatUp ? -10 : 0
        this.floatUp = !this.floatUp
      })
    }, 2300)
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

  private switchLoginMode(mode: string): void {
    if (this.loginMode === mode || this.loading) {
      return
    }
    animateTo({ duration: 180, curve: Curve.EaseIn }, () => {
      this.formOpacity = 0
      this.formOffsetX = mode === 'email' ? 20 : -20
    })
    setTimeout(() => {
      this.loginMode = mode
      this.formOffsetX = mode === 'email' ? -20 : 20
      animateTo({ duration: 300, curve: Curve.FastOutSlowIn }, () => {
        this.formOpacity = 1
        this.formOffsetX = 0
      })
    }, 160)
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
    Column() {
      AuthScaffold({
        heroHeight: 300,
        hero: () => {
          this.buildHero()
        },
        body: () => {
          this.buildBody()
        }
      })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  buildHero() {
    Column({ space: 12 }) {
      Stack() {
        Circle()
          .width(108)
          .height(108)
          .fill(AuthTheme.HERO_GLOW)
          .blur(18)
          .scale({ x: 1.12, y: 1.12 })

        Circle()
          .width(92)
          .height(92)
          .fill('rgba(255, 255, 255, 0.92)')
          .shadow({ radius: 24, color: 'rgba(20, 50, 45, 0.2)', offsetY: 8 })

        Image($r('app.media.app_logo'))
          .width(72)
          .height(72)
          .objectFit(ImageFit.Contain)
      }
      .scale({ x: this.logoScale, y: this.logoScale })
      .translate({ y: this.floatOffset })

      Text('校园心灵墙')
        .fontSize(30)
        .fontWeight(FontWeight.Bold)
        .fontColor(AuthTheme.TITLE)
        .letterSpacing(2)
        .shadow({ radius: 8, color: 'rgba(0,0,0,0.25)', offsetY: 2 })

      Text('温暖传递 · 心灵栖息')
        .fontSize(14)
        .fontColor(AuthTheme.SUBTITLE)
        .letterSpacing(1)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
    .opacity(this.heroOpacity)
    .translate({ y: this.heroOffsetY })
  }

  @Builder
  buildBody() {
    Column({ space: 20 }) {
      AuthGlassCard({
        cardOpacity: this.cardOpacity,
        cardOffsetY: this.cardOffsetY,
        content: () => {
          this.buildCardContent()
        }
      })

      Column({ space: 6 }) {
        Text('登录即代表您已阅读并同意')
          .fontSize(11)
          .fontColor(AuthTheme.LINK_MUTED)
        Row({ space: 4 }) {
          Text('《用户服务协议》')
            .fontSize(11)
            .fontColor(AuthTheme.PRIMARY_DARK)
            .decoration({ type: TextDecorationType.Underline })
          Text('与')
            .fontSize(11)
            .fontColor(AuthTheme.LINK_MUTED)
          Text('《隐私保护政策》')
            .fontSize(11)
            .fontColor(AuthTheme.PRIMARY_DARK)
            .decoration({ type: TextDecorationType.Underline })
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
      .opacity(this.cardOpacity)
    }
    .width('100%')
  }

  @Builder
  buildCardContent() {
    Column({ space: 18 }) {
      Column({ space: 6 }) {
        Text('欢迎回来')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(AuthTheme.PRIMARY_DARK)
        Text('选择你喜欢的方式，继续心灵之旅')
          .fontSize(13)
          .fontColor(AuthTheme.LINK_MUTED)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      AuthModeSwitch({
        activeMode: this.loginMode,
        leftLabel: '密码登录',
        rightLabel: '邮箱验证码',
        leftMode: 'password',
        rightMode: 'email',
        onChange: (mode: string) => {
          this.switchLoginMode(mode)
        }
      })

      Column({ space: 14 }) {
        if (this.loginMode === 'password') {
          this.buildPasswordForm()
        } else {
          this.buildEmailForm()
        }
      }
      .width('100%')
      .opacity(this.formOpacity)
      .translate({ x: this.formOffsetX })

      AuthPrimaryButton({
        label: '登录',
        loading: this.loading,
        buttonEnabled: !this.loading,
        onTap: () => {
          this.handleLogin()
        }
      })

      Row() {
        Text('忘记密码？')
          .fontSize(13)
          .fontColor(AuthTheme.LINK_MUTED)
          .onClick(() => {
            UiHelper.showToast('请使用邮箱验证码登录，或在个人中心修改密码')
          })

        Text('新用户注册 →')
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
    }
    .width('100%')
  }

  @Builder
  buildPasswordForm() {
    AuthInput({
      placeholder: '昵称 / 手机号 / 邮箱',
      value: $account
    })

    AuthInput({
      placeholder: '密码',
      value: $password,
      isPassword: true,
      showToggle: true
    })
  }

  @Builder
  buildEmailForm() {
    AuthInput({
      placeholder: '请输入邮箱',
      value: $email
    })

    Row({ space: 10 }) {
      Column() {
        AuthInput({
          placeholder: '邮箱验证码',
          value: $emailCode
        })
      }
      .layoutWeight(1)

      AuthCodeButton({
        label: this.sendingCode ? '发送中' : (this.resendSeconds > 0 ? `${this.resendSeconds}s` : '获取验证码'),
        buttonEnabled: !this.sendingCode && this.resendSeconds === 0,
        onTap: () => {
          this.sendEmailCode()
        }
      })
    }
    .alignItems(VerticalAlign.Top)
  }
}
