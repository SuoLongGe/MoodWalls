@Component
export struct MoodWallHeader {
  @Prop currentTab: number = 0
  @Prop greeting: string = ''
  @Prop anxiousPercent: number = 0
  @Prop calmPercent: number = 0
  @Prop happyPercent: number = 0

  getSubtitle(): string {
    if (this.currentTab === 1) {
      return '看看此刻校园情绪落在哪些角落。'
    }
    if (this.currentTab === 2) {
      return '写下一张心情纸条，贴进校园心墙。'
    }
    if (this.currentTab === 3) {
      return '这一页收集你的情绪足迹。'
    }
    return '今天校园里又有一些心情落在了墙上。'
  }

  @Builder
  buildChip(title: string, value: number, bgColor: string, textColor: string) {
    Row({ space: 6 }) {
      Circle()
        .width(8)
        .height(8)
        .fill(textColor)
      Text(`${title} ${value}%`)
        .fontSize(11)
        .fontWeight(FontWeight.Medium)
        .fontColor(textColor)
    }
    .padding({ left: 12, right: 12, top: 8, bottom: 8 })
    .backgroundColor(bgColor)
    .borderRadius(18)
  }

  build() {
    Column({ space: 14 }) {
      Row() {
        Row({ space: 12 }) {
          Stack() {
            Circle()
              .width(44)
              .height(44)
              .fill('#C6EBDD')
            Text('MW')
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor('#2E4B43')
          }

          Column({ space: 4 }) {
            Text(`${this.greeting}，蓝色小鱼`)
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#22352F')
            Text(this.getSubtitle())
              .fontSize(12)
              .fontColor('#6B7C78')
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
        }

        Text('通知')
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor('#31534A')
          .padding({ left: 12, right: 12, top: 10, bottom: 10 })
          .backgroundColor('#F3F6F5')
          .borderRadius(18)
      }
      .justifyContent(FlexAlign.SpaceBetween)
      .width('100%')

      if (this.currentTab !== 2) {
        Row({ space: 8 }) {
          this.buildChip('焦虑', this.anxiousPercent, '#FFF1EB', '#D86A3D')
          this.buildChip('平静', this.calmPercent, '#EEF9F1', '#33824A')
          this.buildChip('开心', this.happyPercent, '#FFF7DB', '#A87400')
        }
        .width('100%')
      }
    }
    .width('100%')
    .padding({ left: 18, right: 18, top: 18, bottom: 16 })
    .backgroundColor('#F9FBFA')
  }
}
