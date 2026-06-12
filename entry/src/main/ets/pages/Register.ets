import { common } from '@kit.AbilityKit'
import { AppTheme } from '../common/AppTheme'
import { AuthTheme } from '../common/AuthTheme'
import { AuthSession } from '../common/AuthSession'
import { AVATAR_KEYS, getAvatarResource } from '../common/AvatarResources'
import { ImagePickerHelper } from '../common/ImagePickerHelper'
import { UiHelper } from '../common/UiHelper'
import { AuthCodeButton } from '../components/auth/AuthCodeButton'
import { AuthGlassCard } from '../components/auth/AuthGlassCard'
import { AuthInput } from '../components/auth/AuthInput'
import { AuthPrimaryButton } from '../components/auth/AuthPrimaryButton'
import { AuthScaffold } from '../components/auth/AuthScaffold'
import { UserAvatar } from '../components/UserAvatar'
import { AuthResult } from '../model/AuthApiTypes'
import { AuthApi } from '../service/AuthApi'

@Entry
@Component
struct Register {
  @State registerStep: number = 1
  @State nickname: string = ''
  @State phone: string = ''
  @State email: string = ''
  @State emailCode: string = ''
  @State emailCodeId: string = ''
  @State password: string = ''
  @State selectedAvatarKey: string = 'avatar_01'
  @State pickedImageUri: string = ''
  @State agreeTerms: boolean = false
  @State loading: boolean = false
  @State sendingCode: boolean = false
  @State resendSeconds: number = 0
  @State headerOpacity: number = 0
  @State headerOffsetY: number = -16
  @State cardOpacity: number = 0
  @State cardOffsetY: number = 40
  @State stepOpacity: number = 1
  @State stepOffsetX: number = 0
  @State progressWidth: number = 0
  private resendTimer: number = -1

  pageTransition() {
    PageTransitionEnter({ duration: AppTheme.PAGE_FADE_ENTER_MS, curve: Curve.FastOutSlowIn })
      .opacity(0)
      .translate({ y: 32 })
    PageTransitionExit({ duration: AppTheme.PAGE_FADE_EXIT_MS, curve: Curve.EaseIn })
      .opacity(0)
      .translate({ y: -24 })
  }

  aboutToAppear(): void {
    animateTo({ duration: 800, curve: Curve.FastOutSlowIn }, () => {
      this.headerOpacity = 1
      this.headerOffsetY = 0
      this.cardOpacity = 1
      this.cardOffsetY = 0
      this.progressWidth = this.registerStep === 1 ? 50 : 100
    })
  }

  aboutToDisappear(): void {
    this.clearResendTimer()
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

  private isValidPhone(value: string): boolean {
    return /^1\d{10}$/.test(value.trim())
  }

  private animateStepChange(nextStep: number): void {
    const goingForward: boolean = nextStep > this.registerStep
    animateTo({ duration: 200, curve: Curve.EaseIn }, () => {
      this.stepOpacity = 0
      this.stepOffsetX = goingForward ? -28 : 28
    })
    setTimeout(() => {
      this.registerStep = nextStep
      this.stepOffsetX = goingForward ? 28 : -28
      animateTo({ duration: 320, curve: Curve.FastOutSlowIn }, () => {
        this.stepOpacity = 1
        this.stepOffsetX = 0
        this.progressWidth = nextStep === 1 ? 50 : 100
      })
    }, 180)
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
    AuthApi.sendEmailCode(this.email.trim(), 'register').then((result) => {
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

  goNextStep(): void {
    if (!this.agreeTerms) {
      UiHelper.showToast('请先阅读并同意用户协议与隐私政策')
      return
    }
    if (!this.isValidPhone(this.phone)) {
      UiHelper.showToast('请输入正确的手机号码')
      return
    }
    if (!this.isValidEmail(this.email)) {
      UiHelper.showToast('请输入正确的邮箱地址')
      return
    }
    if (this.emailCodeId.length === 0) {
      UiHelper.showToast('请先获取邮箱验证码')
      return
    }
    if (this.emailCode.trim().length === 0) {
      UiHelper.showToast('请填写邮箱验证码')
      return
    }
    if (this.password.trim().length < 8) {
      UiHelper.showToast('密码建议 8-16 位数字或字母组合')
      return
    }
    this.animateStepChange(2)
  }

  handleRegister(): void {
    if (this.loading) {
      return
    }
    if (this.nickname.trim().length === 0) {
      UiHelper.showToast('请填写昵称')
      return
    }

    this.loading = true
    const pageContext: common.UIAbilityContext = getContext(this) as common.UIAbilityContext
    const pickedUri: string | undefined = this.pickedImageUri.length > 0 ? this.pickedImageUri : undefined
    AuthApi.register(
      this.nickname.trim(),
      this.phone.trim(),
      this.email.trim(),
      this.emailCodeId,
      this.emailCode.trim(),
      this.password,
      this.selectedAvatarKey,
      pageContext,
      pickedUri
    ).then((result: AuthResult) => {
      AuthSession.save(result.user, result.token)
      UiHelper.showToast('注册成功，欢迎加入校园心灵墙')
      UiHelper.replaceTo('pages/Index')
    }).catch((err: Error) => {
      UiHelper.showToast(err.message)
      this.animateStepChange(1)
    }).finally(() => {
      this.loading = false
    })
  }

  build() {
    Column() {
      AuthScaffold({
        heroHeight: 200,
        hero: () => {
          this.buildHeader()
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
  buildHeader() {
    Column({ space: 16 }) {
      Row() {
        Row({ space: 6 }) {
          Text('←')
            .fontSize(20)
            .fontColor(Color.White)
          Text('返回')
            .fontSize(14)
            .fontColor(AuthTheme.SUBTITLE)
        }
        .padding({ left: 4, right: 12, top: 8, bottom: 8 })
        .borderRadius(20)
        .backgroundColor('rgba(255,255,255,0.18)')
        .onClick(() => {
          if (this.loading) {
            return
          }
          if (this.registerStep === 2) {
            this.animateStepChange(1)
          } else {
            UiHelper.goBack()
          }
        })

        Blank()
      }
      .width('100%')

      Column({ space: 8 }) {
        Text('创建心灵账号')
          .fontSize(26)
          .fontWeight(FontWeight.Bold)
          .fontColor(AuthTheme.TITLE)
          .letterSpacing(1)
          .shadow({ radius: 6, color: 'rgba(0,0,0,0.2)', offsetY: 2 })

        Text(this.registerStep === 1 ? '填写联系方式，开启温暖社区' : '挑选头像与昵称，让大家认识你')
          .fontSize(13)
          .fontColor(AuthTheme.SUBTITLE)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      this.buildStepProgress()
    }
    .width('100%')
    .opacity(this.headerOpacity)
    .translate({ y: this.headerOffsetY })
  }

  @Builder
  buildStepProgress() {
    Column({ space: 10 }) {
      Row() {
        Text('账号信息')
          .fontSize(12)
          .fontWeight(this.registerStep === 1 ? FontWeight.Bold : FontWeight.Normal)
          .fontColor(this.registerStep === 1 ? AuthTheme.PRIMARY_DARK : AuthTheme.LINK_MUTED)
        Blank()
        Text('个人资料')
          .fontSize(12)
          .fontWeight(this.registerStep === 2 ? FontWeight.Bold : FontWeight.Normal)
          .fontColor(this.registerStep === 2 ? AuthTheme.PRIMARY_DARK : AuthTheme.LINK_MUTED)
      }
      .width('100%')

      Stack({ alignContent: Alignment.Start }) {
        Row()
          .width('100%')
          .height(6)
          .borderRadius(3)
          .backgroundColor('rgba(255,255,255,0.35)')

        Row()
          .width(`${this.progressWidth}%`)
          .height(6)
          .borderRadius(3)
          .linearGradient({
            angle: 90,
            colors: [[AuthTheme.ACCENT, 0.0], [AuthTheme.GRADIENT_START, 1.0]]
          })
          .animation({ duration: 400, curve: Curve.FastOutSlowIn })
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor('rgba(255,255,255,0.22)')
    .borderRadius(18)
    .border({ width: 1, color: 'rgba(255,255,255,0.35)' })
  }

  @Builder
  buildBody() {
    Column({ space: 16 }) {
      AuthGlassCard({
        cardOpacity: this.cardOpacity,
        cardOffsetY: this.cardOffsetY,
        content: () => {
          this.buildCardContent()
        }
      })

      Text('校园心灵墙 · 温暖每一刻')
        .fontSize(12)
        .fontColor(AuthTheme.LINK_MUTED)
        .width('100%')
        .textAlign(TextAlign.Center)
        .opacity(this.cardOpacity)
    }
    .width('100%')
  }

  @Builder
  buildCardContent() {
    Column({ space: 16 }) {
      Column({ space: 14 }) {
        if (this.registerStep === 1) {
          this.buildAccountStep()
        } else {
          this.buildProfileStep()
        }
      }
      .width('100%')
      .opacity(this.stepOpacity)
      .translate({ x: this.stepOffsetX })
    }
    .width('100%')
  }

  @Builder
  buildAccountStep() {
    this.buildFieldLabel('手机号')
    AuthInput({
      placeholder: '请输入11位手机号码',
      value: $phone
    })

    this.buildFieldLabel('邮箱')
    AuthInput({
      placeholder: '请输入常用邮箱',
      value: $email
    })

    this.buildFieldLabel('邮箱验证码')
    Row({ space: 10 }) {
      Column() {
        AuthInput({
          placeholder: '请输入邮箱验证码',
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
          .fontColor(AuthTheme.LINK_MUTED)
        Span('《用户协议》')
          .fontSize(12)
          .fontColor(AuthTheme.PRIMARY)
        Span('与')
          .fontSize(12)
          .fontColor(AuthTheme.LINK_MUTED)
        Span('《隐私政策》')
          .fontSize(12)
          .fontColor(AuthTheme.PRIMARY)
        Span('，愿共建温暖社区。')
          .fontSize(12)
          .fontColor(AuthTheme.LINK_MUTED)
      }
      .layoutWeight(1)
    }
    .alignItems(VerticalAlign.Top)
    .margin({ top: 4 })

    AuthPrimaryButton({
      label: '下一步',
      onTap: () => {
        this.goNextStep()
      }
    })

    Row({ space: 4 }) {
      Text('已有账号？')
        .fontSize(13)
        .fontColor(AuthTheme.LINK_MUTED)
      Text('直接登录')
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor(AuthTheme.PRIMARY)
        .onClick(() => {
          UiHelper.goBack()
        })
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .margin({ top: 4 })
  }

  private pickCustomAvatar(): void {
    ImagePickerHelper.pickOne()
      .then((uri: string) => {
        if (uri.length > 0) {
          this.pickedImageUri = uri
        }
      })
      .catch(() => {
        UiHelper.showToast('未能选择图片，请重试')
      })
  }

  @Builder
  buildProfileStep() {
    Text('选择你的头像')
      .fontSize(15)
      .fontWeight(FontWeight.Bold)
      .fontColor(AuthTheme.PRIMARY_DARK)
      .width('100%')

    Row({ space: 14 }) {
      Stack() {
        if (this.pickedImageUri.length > 0) {
          Image(this.pickedImageUri)
            .width(68)
            .height(68)
            .borderRadius(34)
            .objectFit(ImageFit.Cover)
        } else {
          UserAvatar({
            avatarKey: this.selectedAvatarKey,
            avatarSize: 68
          })
        }

        Circle()
          .width(76)
          .height(76)
          .fill(Color.Transparent)
          .stroke(AuthTheme.PRIMARY_LIGHT)
          .strokeWidth(2)
      }

      Column({ space: 8 }) {
        Text('从相册选择')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(AuthTheme.PRIMARY)
          .padding({ left: 14, right: 14, top: 8, bottom: 8 })
          .backgroundColor(AuthTheme.ACCENT_SOFT)
          .borderRadius(16)
          .onClick(() => {
            this.pickCustomAvatar()
          })

        if (this.pickedImageUri.length > 0) {
          Text('清除本地照片')
            .fontSize(12)
            .fontColor('#C45C3A')
            .onClick(() => {
              this.pickedImageUri = ''
            })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .padding(12)
    .backgroundColor('rgba(255,255,255,0.45)')
    .borderRadius(20)

    Text('或选择预设头像')
      .fontSize(12)
      .fontColor(AuthTheme.LINK_MUTED)
      .width('100%')

    Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceBetween }) {
      ForEach(AVATAR_KEYS, (key: string) => {
        Image(getAvatarResource(key))
          .width(52)
          .height(52)
          .borderRadius(26)
          .objectFit(ImageFit.Cover)
          .border({
            width: this.selectedAvatarKey === key && this.pickedImageUri.length === 0 ? 3 : 1,
            color: this.selectedAvatarKey === key && this.pickedImageUri.length === 0
              ? AuthTheme.PRIMARY : 'rgba(255,255,255,0.8)'
          })
          .shadow({
            radius: this.selectedAvatarKey === key && this.pickedImageUri.length === 0 ? 10 : 4,
            color: 'rgba(46, 107, 94, 0.2)',
            offsetY: 3
          })
          .width('23%')
          .margin({ bottom: 12 })
          .scale({
            x: this.selectedAvatarKey === key && this.pickedImageUri.length === 0 ? 1.06 : 1,
            y: this.selectedAvatarKey === key && this.pickedImageUri.length === 0 ? 1.06 : 1
          })
          .animation({ duration: 200, curve: Curve.EaseOut })
          .onClick(() => {
            this.selectedAvatarKey = key
            this.pickedImageUri = ''
          })
      }, (key: string) => key)
    }
    .width('100%')

    this.buildFieldLabel('昵称')
    AuthInput({
      placeholder: '起一个温暖的名字吧',
      value: $nickname
    })

    AuthPrimaryButton({
      label: '完成注册',
      loading: this.loading,
      buttonEnabled: !this.loading,
      onTap: () => {
        this.handleRegister()
      }
    })

    Text('← 上一步')
      .fontSize(13)
      .fontColor(AuthTheme.PRIMARY)
      .width('100%')
      .textAlign(TextAlign.Center)
      .margin({ top: 4 })
      .onClick(() => {
        if (!this.loading) {
          this.animateStepChange(1)
        }
      })
  }

  @Builder
  buildFieldLabel(label: string) {
    Text(label)
      .fontSize(13)
      .fontWeight(FontWeight.Medium)
      .fontColor(AuthTheme.PRIMARY_DARK)
      .width('100%')
      .margin({ top: 4 })
  }
}
