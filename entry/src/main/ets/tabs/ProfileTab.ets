@Component
export struct ProfileTab {
  @Prop calmPercent: number = 0
  @Prop anxiousPercent: number = 0
  @Prop happyPercent: number = 0
  onOpenReport: () => void = () => {}

  @Builder
  buildDayItem(day: string, color: string) {
    Column({ space: 8 }) {
      Text(day)
        .fontSize(12)
        .fontColor('#55635F')
      Circle()
        .width(12)
        .height(12)
        .fill(color)
    }
    .padding(8)
    .backgroundColor('#F8FAF9')
    .borderRadius(16)
  }

  @Builder
  buildProgressRow(label: string, percent: number, color: string) {
    Row({ space: 10 }) {
      Text(label)
        .width(46)
        .fontSize(12)
        .fontColor('#6E7C79')
      Stack({ alignContent: Alignment.Start }) {
        Row()
          .width('100%')
          .height(28)
          .backgroundColor('#F4F7F6')
          .borderRadius(14)
        Row() {
          Text(`${percent}%`)
            .fontSize(11)
            .fontWeight(FontWeight.Bold)
            .fontColor('#284138')
        }
        .height(28)
        .width(`${percent}%`)
        .padding({ left: 10 })
        .backgroundColor(color)
        .borderRadius(14)
      }
      .layoutWeight(1)
    }
    .width('100%')
  }

  build() {
    Column({ space: 16 }) {
      Column({ space: 10 }) {
        Text('蓝色小鱼 #2341')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#31534A')
        Text('心情气候：平静多云')
          .fontSize(12)
          .fontColor('#2F7C49')
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .backgroundColor('#E8F6EC')
          .borderRadius(18)
      }
      .width('100%')
      .padding(20)
      .backgroundColor('#FFFFFF')
      .borderRadius(24)

      Column({ space: 12 }) {
        Text('情绪日历')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#25332F')
        Row({ space: 10 }) {
          this.buildDayItem('12', '#73C088')
          this.buildDayItem('13', '#73C088')
          this.buildDayItem('14', '#F08C62')
          this.buildDayItem('15', '#6CB1F0')
          this.buildDayItem('16', '#73C088')
          this.buildDayItem('17', '#D8DEDC')
          this.buildDayItem('18', '#D8DEDC')
        }
      }
      .width('100%')
      .padding(18)
      .backgroundColor('#FFFFFF')
      .borderRadius(24)

      Column({ space: 12 }) {
        Text('这一周，走过的情绪')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#25332F')
        this.buildProgressRow('平静', this.calmPercent, '#73C088')
        this.buildProgressRow('焦虑', this.anxiousPercent, '#F08C62')
        this.buildProgressRow('开心', this.happyPercent, '#F6C445')
        Text('翻开温情周报')
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor('#31534A')
          .onClick(() => {
            this.onOpenReport()
          })
      }
      .width('100%')
      .padding(18)
      .backgroundColor('#FFFFFF')
      .borderRadius(24)
    }
  }
}
