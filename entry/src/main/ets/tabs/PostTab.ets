import { LOCATION_OPTIONS, MOOD_OPTIONS } from '../mock/MoodWallData'
import { MoodOption } from '../model/MoodWallTypes'

@Component
export struct PostTab {
  @Link selectedMoodKey: string
  @Link draftText: string
  @Link locationIndex: number
  onPublish: () => void = () => {}

  getHint(): string {
    const mood: MoodOption | undefined = MOOD_OPTIONS.find((item: MoodOption) => item.key === this.selectedMoodKey)
    return mood ? mood.hint : '写下这一刻真实的感受...'
  }

  build() {
    Column({ space: 16 }) {
      Text('选择情绪标签')
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor('#60706C')

      Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceBetween }) {
        ForEach(MOOD_OPTIONS, (item: MoodOption) => {
          Text(item.label)
            .width('23%')
            .textAlign(TextAlign.Center)
            .fontSize(12)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.selectedMoodKey === item.key ? Color.White : '#4C5B57')
            .padding({ top: 18, bottom: 18 })
            .backgroundColor(this.selectedMoodKey === item.key ? '#31534A' : Color.White)
            .borderRadius(20)
            .margin({ bottom: 10 })
            .onClick(() => {
              this.selectedMoodKey = item.key
            })
        }, (item: MoodOption) => item.key)
      }

      Column({ space: 10 }) {
        Text(this.getHint())
          .fontSize(12)
          .fontColor('#75837F')
        TextArea({ text: this.draftText, placeholder: '写下这一刻真实的感受...' })
          .height(220)
          .backgroundColor('#FFFFFF')
          .borderRadius(24)
          .fontSize(15)
          .placeholderColor('#A0AAA8')
          .onChange((value: string) => {
            this.draftText = value
          })
      }
      .width('100%')
      .padding(16)
      .backgroundColor('#FFFFFF')
      .borderRadius(24)

      Row() {
        Column({ space: 4 }) {
          Text('发布位置')
            .fontSize(12)
            .fontColor('#75837F')
          Text(LOCATION_OPTIONS[this.locationIndex])
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor('#31534A')
        }
        .alignItems(HorizontalAlign.Start)

        Text('切换')
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor('#31534A')
          .onClick(() => {
            this.locationIndex = (this.locationIndex + 1) % LOCATION_OPTIONS.length
          })
      }
      .width('100%')
      .padding(16)
      .backgroundColor('#F5FBF8')
      .borderRadius(20)

      Text('贴上心墙')
        .width('100%')
        .textAlign(TextAlign.Center)
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .padding({ top: 14, bottom: 14 })
        .backgroundColor('#31534A')
        .borderRadius(24)
        .opacity(this.draftText.trim().length > 0 ? 1 : 0.45)
        .onClick(() => {
          this.onPublish()
        })
    }
  }
}
