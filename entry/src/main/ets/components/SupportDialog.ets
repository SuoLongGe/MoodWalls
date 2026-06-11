import { AppTheme } from '../common/AppTheme'

@Component
export struct SupportDialog {
  @Link visible: boolean
  @Prop title: string = ''
  @Prop message: string = ''
  @Prop comfortNote: string = ''
  @Prop riskLevel: number = 0
  @Watch('onLoadingChange')
  @Prop loading: boolean = false
  @State displayText: string = ''
  @State typingDone: boolean = false
  private typingTimer: number = -1

  aboutToAppear(): void {
    if (!this.loading && this.message.length > 0 && this.visible) {
      this.startTypewriter()
    }
  }

  onLoadingChange(): void {
    if (this.loading) {
      this.displayText = ''
      this.typingDone = false
      if (this.typingTimer >= 0) {
        clearInterval(this.typingTimer)
        this.typingTimer = -1
      }
    } else if (this.message.length > 0 && this.visible) {
      this.startTypewriter()
    }
  }

  startTypewriter(): void {
    this.displayText = ''
    this.typingDone = false
    let index: number = 0
    const fullText: string = this.message
    this.typingTimer = setInterval(() => {
      index++
      if (index <= fullText.length) {
        this.displayText = fullText.substring(0, index)
      }
      if (index >= fullText.length) {
        clearInterval(this.typingTimer)
        this.typingTimer = -1
        this.typingDone = true
      }
    }, 35)
  }

  aboutToDisappear(): void {
    if (this.typingTimer >= 0) {
      clearInterval(this.typingTimer)
      this.typingTimer = -1
    }
  }

  private getTagColor(): string {
    if (this.riskLevel === 2) return '#E54040'
    if (this.riskLevel === 1) return '#F6C445'
    return '#73A18F'
  }

  private getTagLabel(): string {
    if (this.riskLevel === 2) return '校园倾听树洞 · 紧急关注'
    if (this.riskLevel === 1) return '校园倾听树洞 · 温心纸条'
    return '校园倾听树洞'
  }

  private getBgColor(): string {
    if (this.riskLevel === 2) return '#FFF5F5'
    if (this.riskLevel === 1) return '#FFFDF5'
    return '#FFFFFF'
  }

  build() {
    Stack() {
      if (this.visible) {
        Stack({ alignContent: Alignment.Center }) {
          Column()
            .width('100%')
            .height('100%')
            .backgroundColor(AppTheme.OVERLAY)
            .transition(TransitionEffect.OPACITY.animation({
              duration: AppTheme.DIALOG_ENTER_MS,
              curve: Curve.FastOutSlowIn
            }))

          Column({ space: 14 }) {
            Row() {
              Text(this.title)
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.riskLevel === 2 ? '#C62828' : '#25332F')
              Text('关闭')
                .fontSize(12)
                .fontWeight(FontWeight.Bold)
                .fontColor(AppTheme.TEXT_HINT)
                .onClick(() => {
                  this.visible = false
                })
            }
            .justifyContent(FlexAlign.SpaceBetween)
            .width('100%')

            Text(this.getTagLabel())
              .fontSize(13)
              .fontColor(this.getTagColor())
              .fontWeight(this.riskLevel >= 1 ? FontWeight.Bold : FontWeight.Normal)

            if (this.loading) {
              Column({ space: 10 }) {
                LoadingProgress()
                  .width(32)
                  .height(32)
                  .color(AppTheme.PRIMARY)
                Text('正在倾听...')
                  .fontSize(13)
                  .fontColor(AppTheme.TEXT_HINT)
              }
              .width('100%')
              .padding({ top: 20, bottom: 20 })
              .justifyContent(FlexAlign.Center)
            } else {
              Column({ space: 12 }) {
                Text(this.displayText.length > 0 ? this.displayText : this.message)
                  .fontSize(14)
                  .lineHeight(24)
                  .fontColor('#43524E')

                if (this.typingDone && this.comfortNote.length > 0) {
                  Divider()
                    .strokeWidth(1)
                    .color('#E8EDEB')
                    .margin({ top: 4, bottom: 4 })

                  Text(this.comfortNote)
                    .fontSize(13)
                    .lineHeight(22)
                    .fontColor(this.riskLevel === 2 ? '#C62828' : '#B0853A')
                    .fontWeight(FontWeight.Medium)
                    .padding({
                      top: 10,
                      bottom: 10,
                      left: 14,
                      right: 14
                    })
                    .backgroundColor(this.riskLevel === 2 ? '#FFEBEE' : '#FFF8E1')
                    .borderRadius(12)
                    .width('100%')
                }
              }
              .width('100%')
            }

            Text(this.riskLevel === 2 ? '我已收到，谢谢' : '收下这封回信')
              .width('100%')
              .textAlign(TextAlign.Center)
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
              .padding({ top: 12, bottom: 12 })
              .backgroundColor(this.riskLevel === 2 ? '#C62828' : '#31534A')
              .borderRadius(22)
              .opacity(this.loading ? 0.45 : 1)
              .onClick(() => {
                if (!this.loading) {
                  this.visible = false
                }
              })
          }
          .width('84%')
          .padding(22)
          .backgroundColor(this.getBgColor())
          .borderRadius(28)
          .shadow({
            radius: 28,
            color: AppTheme.SHADOW,
            offsetY: 8
          })
          .transition(
            TransitionEffect.translate({ y: 48 })
              .combine(TransitionEffect.scale({ x: 0.82, y: 0.82 }))
              .combine(TransitionEffect.OPACITY)
              .animation({ duration: AppTheme.DIALOG_ENTER_MS, curve: Curve.FastOutSlowIn })
          )
        }
        .width('100%')
        .height('100%')
        .position({ x: 0, y: 0 })
      }
    }
    .width('100%')
    .height('100%')
    .hitTestBehavior(this.visible ? HitTestMode.Default : HitTestMode.None)
  }
}
