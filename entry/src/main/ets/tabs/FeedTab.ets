import { NoteItem } from '../model/MoodWallTypes'

@Component
export struct FeedTab {
  @Prop notes: Array<NoteItem> = []
  @Link filterMood: string
  onLikeNote: (noteId: number) => void = () => {}
  onSupportNote: (note: NoteItem) => void = () => {}

  getFilteredNotes(): Array<NoteItem> {
    if (this.filterMood === 'all') {
      return this.notes
    }
    return this.notes.filter((item: NoteItem) => item.mood === this.filterMood)
  }

  @Builder
  buildFilterChip(key: string, label: string) {
    Text(label)
      .fontSize(12)
      .fontWeight(this.filterMood === key ? FontWeight.Bold : FontWeight.Medium)
      .fontColor(this.filterMood === key ? Color.White : '#60706C')
      .padding({ left: 14, right: 14, top: 9, bottom: 9 })
      .backgroundColor(this.filterMood === key ? '#31534A' : Color.White)
      .borderRadius(18)
      .onClick(() => {
        this.filterMood = key
      })
  }

  build() {
    Column({ space: 14 }) {
      Scroll() {
        Row({ space: 8 }) {
          this.buildFilterChip('all', '全部')
          this.buildFilterChip('happy', '开心')
          this.buildFilterChip('calm', '平静')
          this.buildFilterChip('moved', '感动')
          this.buildFilterChip('anxious', '焦虑')
          this.buildFilterChip('sad', '低落')
          this.buildFilterChip('tired', '疲惫')
        }
        .padding({ top: 6, bottom: 6 })
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)

      ForEach(this.getFilteredNotes(), (item: NoteItem) => {
        Column({ space: 12 }) {
          Row() {
            Text(item.moodLabel)
              .fontSize(12)
              .fontWeight(FontWeight.Bold)
              .fontColor(item.color)
              .padding({ left: 10, right: 10, top: 6, bottom: 6 })
              .backgroundColor('#FFFFFF')
              .borderRadius(16)
            Text(item.timeText)
              .fontSize(11)
              .fontColor('#95A19F')
          }
          .justifyContent(FlexAlign.SpaceBetween)
          .width('100%')

          Text(item.text)
            .fontSize(15)
            .lineHeight(23)
            .fontColor('#25332F')

          Text(`位置：${item.location}`)
            .fontSize(12)
            .fontColor('#7C8A87')

          Row() {
            Row({ space: 6 }) {
              Text('点赞')
                .fontSize(12)
                .fontWeight(FontWeight.Medium)
                .fontColor('#7D8A88')
              Text(`${item.likes}`)
                .fontSize(12)
                .fontColor('#7D8A88')
            }
            .onClick(() => {
              this.onLikeNote(item.id)
            })

            Text('接住心声')
              .fontSize(12)
              .fontWeight(FontWeight.Bold)
              .fontColor('#31534A')
              .padding({ left: 16, right: 16, top: 9, bottom: 9 })
              .backgroundColor('#F3F8F6')
              .borderRadius(18)
              .onClick(() => {
                this.onSupportNote(item)
              })
          }
          .justifyContent(FlexAlign.SpaceBetween)
          .width('100%')
        }
        .width('100%')
        .padding(16)
        .backgroundColor(Color.White)
        .borderRadius(24)
        .border({ width: { left: 5 }, color: item.color })
      }, (item: NoteItem) => `${item.id}`)
    }
    .alignItems(HorizontalAlign.Start)
  }
}
