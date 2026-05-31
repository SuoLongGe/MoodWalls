import { AuthTheme } from '../common/AuthTheme'
import { AuthSession } from '../common/AuthSession'
import { UiHelper } from '../common/UiHelper'
import { AuthInput } from '../components/auth/AuthInput'
import { AuthResult } from '../model/AuthApiTypes'
import { AuthApi } from '../service/AuthApi'

@Entry
@Component
struct Login {
  @State account: string = ''
  @State password: string = ''
  @State loading: boolean = false

  aboutToAppear(): void {
    if (AuthSession.isLoggedIn()) {
      UiHelper.replaceTo('pages/Index')
    }
  }

  handleLogin(): void {
    if (this.loading) {
      return
    }
    if (this.account.trim().length === 0 || this.password.trim().length === 0) {
      UiHelper.showToast('请输入昵称/手机号和密码')
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
            AuthInput({
              placeholder: '昵称 / 手机号',
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
                  UiHelper.showToast('请联系校园心理中心重置密码')
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
              Text('第三方登录')
                .fontSize(12)
                .fontColor(AuthTheme.LINK_MUTED)
              Divider()
                .layoutWeight(1)
                .color(AuthTheme.DIVIDER)
            }
            .width('100%')
            .margin({ top: 4 })

            Row({ space: 36 }) {
              this.buildSocialButton('微信', '#07C160')
              this.buildSocialButton('QQ', '#2D74C4')
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)
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
  buildSocialButton(label: string, color: string) {
    Stack({ alignContent: Alignment.Center }) {
      Circle()
        .width(48)
        .height(48)
        .fill(Color.White)
        .shadow({ radius: 10, color: 'rgba(0,0,0,0.06)', offsetY: 4 })
      Text(label)
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .fontColor(color)
    }
    .onClick(() => {
      UiHelper.showToast(`${label} 登录即将开放`)
    })
  }
}
