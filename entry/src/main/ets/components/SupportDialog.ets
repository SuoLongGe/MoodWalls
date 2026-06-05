import { AppTheme } from '../common/AppTheme'

@Component
export struct SupportDialog {
  @Link visible: boolean
  @Prop title: string = ''
  @Prop message: string = ''
  @Prop loading: boolean = false

  build() {
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
              .fontColor(AppTheme.TEXT_TITLE)
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

          Text('校园倾听树洞')
            .fontSize(13)
            .fontColor(AppTheme.PRIMARY_LIGHT)

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
            Text(this.message)
              .fontSize(14)
              .lineHeight(24)
              .fontColor('#43524E')
          }

          Text('收下这封回信')
            .width('100%')
            .textAlign(TextAlign.Center)
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .padding({ top: 12, bottom: 12 })
            .backgroundColor(AppTheme.PRIMARY)
            .borderRadius(AppTheme.RADIUS_PILL)
            .opacity(this.loading ? 0.45 : 1)
            .onClick(() => {
              if (!this.loading) {
                this.visible = false
              }
            })
        }
        .width('84%')
        .padding(22)
        .backgroundColor(AppTheme.CARD)
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
}
