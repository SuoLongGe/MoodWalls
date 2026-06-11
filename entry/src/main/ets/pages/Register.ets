import { common } from '@kit.AbilityKit'
import { AppTheme } from '../common/AppTheme'
import { AuthTheme } from '../common/AuthTheme'
import { AuthSession } from '../common/AuthSession'
import { AVATAR_KEYS, getAvatarResource } from '../common/AvatarResources'
import { ImagePickerHelper } from '../common/ImagePickerHelper'
import { UiHelper } from '../common/UiHelper'
import { AuthInput } from '../components/auth/AuthInput'
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
  private resendTimer: number = -1

  pageTransition() {
    PageTransitionEnter({ duration: AppTheme.PAGE_FADE_ENTER_MS, curve: Curve.FastOutSlowIn })
      .opacity(0)
      .translate({ y: 32 })
    PageTransitionExit({ duration: AppTheme.PAGE_FADE_EXIT_MS, curve: Curve.EaseIn })
      .opacity(0)
      .translate({ y: -24 })
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
    this.registerStep = 2
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
      this.registerStep = 1
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
            if (this.loading) {
              return
            }
            if (this.registerStep === 2) {
              this.registerStep = 1
            } else {
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
        this.buildStepPill('1 账号信息', this.registerStep === 1)
        Row()
          .layoutWeight(1)
          .height(2)
          .backgroundColor(this.registerStep >= 2 ? AuthTheme.PRIMARY : '#E0E8EF')
          .margin({ left: 8, right: 8, top: 18 })
        this.buildStepPill('2 个人资料', this.registerStep === 2)
      }
      .width('100%')
      .padding({ left: 24, right: 24, top: 20 })

      Scroll() {
        Column({ space: 16 }) {
          Column({ space: 14 }) {
            if (this.registerStep === 1) {
              this.buildAccountStep()
            } else {
              this.buildProfileStep()
            }
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

    Button('下一步')
      .width('100%')
      .height(50)
      .fontSize(16)
      .fontWeight(FontWeight.Bold)
      .fontColor(Color.White)
      .backgroundColor(AuthTheme.PRIMARY)
      .borderRadius(25)
      .margin({ top: 8 })
      .onClick(() => this.goNextStep())

    Row() {
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
    .margin({ top: 4, bottom: 8 })
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
      .fontSize(14)
      .fontWeight(FontWeight.Medium)
      .fontColor('#4A5A66')
      .width('100%')

    Row({ space: 12 }) {
      if (this.pickedImageUri.length > 0) {
        Image(this.pickedImageUri)
          .width(56)
          .height(56)
          .borderRadius(28)
          .objectFit(ImageFit.Cover)
          .border({ width: 2, color: AuthTheme.PRIMARY })
      } else {
        UserAvatar({
          avatarKey: this.selectedAvatarKey,
          avatarSize: 56
        })
      }
      Column({ space: 6 }) {
        Text('从相册选择')
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor(AuthTheme.PRIMARY)
          .onClick(() => {
            this.pickCustomAvatar()
          })
        if (this.pickedImageUri.length > 0) {
          Text('清除本地照片')
            .fontSize(12)
            .fontColor('#D86A3D')
            .onClick(() => {
              this.pickedImageUri = ''
            })
        }
      }
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')

    Text('或选择预设头像')
      .fontSize(12)
      .fontColor('#95A19F')
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
              ? AuthTheme.PRIMARY : '#E8EEF3'
          })
          .width('23%')
          .margin({ bottom: 12 })
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

    Button(this.loading ? '注册中...' : '完成注册')
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

    Text('上一步')
      .fontSize(13)
      .fontColor(AuthTheme.PRIMARY)
      .width('100%')
      .textAlign(TextAlign.Center)
      .margin({ top: 8, bottom: 8 })
      .onClick(() => {
        if (!this.loading) {
          this.registerStep = 1
        }
      })
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
