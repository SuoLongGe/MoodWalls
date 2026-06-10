import { AppTheme } from '../common/AppTheme'
import { LOCATION_OPTIONS, MOOD_OPTIONS } from '../mock/MoodWallData'
import { MoodOption } from '../model/MoodWallTypes'

interface NoteMoodOption {
  key: string
  label: string
  color: string
}

const NOTE_MOOD_OPTIONS: Array<NoteMoodOption> = [
  { key: 'happy', label: '开心', color: '#F6C445' },
  { key: 'calm', label: '平静', color: '#73C088' },
  { key: 'moved', label: '感动', color: '#B786F7' }
]

@Component
export struct PostTab {
  @Link selectedMoodKey: string
  @Link draftText: string
  @Link locationIndex: number
  @Link noteDraftText: string
  @Link noteMoodKey: string
  @Prop publishing: boolean = false
  @Prop submittingNote: boolean = false
  @State composeMode: string = 'post'
  onPublish: () => void = () => {}
  onSubmitNote: () => void = () => {}

  private isPostMode(): boolean {
    return this.composeMode === 'post'
  }

  getHint(): string {
    const mood: MoodOption | undefined = MOOD_OPTIONS.find((item: MoodOption) => item.key === this.selectedMoodKey)
    return mood ? mood.hint : '写下这一刻真实的感受...'
  }

  getTextLength(): number {
    return this.draftText.trim().length
  }

  getNoteTextLength(): number {
    return this.noteDraftText.trim().length
  }

  isPublishEnabled(): boolean {
    return this.getTextLength() >= 10 && !this.publishing
  }

  isNoteSubmitEnabled(): boolean {
    return this.getNoteTextLength() >= 8 && !this.submittingNote
  }

  getButtonOpacity(): number {
    if (this.publishing) {
      return 0.45
    }
    return this.getTextLength() >= 10 ? 1 : 0.45
  }

  getNoteButtonOpacity(): number {
    if (this.submittingNote) {
      return 0.45
    }
    return this.getNoteTextLength() >= 8 ? 1 : 0.45
  }

  getButtonText(): string {
    return this.publishing ? '发布中...' : '贴上心墙'
  }

  getNoteButtonText(): string {
    return this.submittingNote ? '放入中...' : '放进纸条池'
  }

  @Builder
  buildModeChip(mode: string, label: string) {
    Text(label)
      .fontSize(13)
      .fontWeight(this.composeMode === mode ? FontWeight.Bold : FontWeight.Medium)
      .fontColor(this.composeMode === mode ? AppTheme.PRIMARY : '#6E7C79')
      .padding({ left: 16, right: 16, top: 10, bottom: 10 })
      .backgroundColor(this.composeMode === mode ? '#EAF4F0' : AppTheme.CARD)
      .borderRadius(18)
      .layoutWeight(1)
      .textAlign(TextAlign.Center)
      .onClick(() => {
        this.composeMode = mode
      })
  }

  @Builder
  buildPostForm() {
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
            .backgroundColor(this.selectedMoodKey === item.key ? AppTheme.PRIMARY : AppTheme.CARD)
            .borderRadius(AppTheme.RADIUS_LG)
            .margin({ bottom: 10 })
            .shadow({
              radius: this.selectedMoodKey === item.key ? 0 : 6,
              color: AppTheme.SHADOW_LIGHT,
              offsetY: 2
            })
            .animation({ duration: AppTheme.TAB_ENTER_MS, curve: Curve.Smooth })
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
          .backgroundColor(AppTheme.CARD)
          .borderRadius(AppTheme.RADIUS_LG)
          .fontSize(15)
          .placeholderColor('#A0AAA8')
          .onChange((value: string) => {
            if (value.length <= 500) {
              this.draftText = value
            } else {
              this.draftText = value.substring(0, 500)
            }
          })
      }
      .width('100%')
      .padding(16)
      .backgroundColor(AppTheme.CARD)
      .borderRadius(AppTheme.RADIUS_LG)
      .shadow({
        radius: 12,
        color: AppTheme.SHADOW_LIGHT,
        offsetY: 4
      })

      Row() {
        Text(`${this.getTextLength()}/500`)
          .fontSize(12)
          .fontColor(this.getTextLength() >= 10 ? '#73C088' : '#B0B8B6')
        if (this.getTextLength() > 0 && this.getTextLength() < 10) {
          Text(`还需 ${10 - this.getTextLength()} 字`)
            .fontSize(11)
            .fontColor('#D86A3D')
            .margin({ left: 8 })
        }
      }
      .width('100%')
      .justifyContent(FlexAlign.End)

      Row() {
        Column({ space: 4 }) {
          Text('发布位置')
            .fontSize(12)
            .fontColor('#75837F')
          Text(LOCATION_OPTIONS[this.locationIndex])
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppTheme.PRIMARY)
        }
        .alignItems(HorizontalAlign.Start)

        Text('切换')
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppTheme.PRIMARY)
          .onClick(() => {
            this.locationIndex = (this.locationIndex + 1) % LOCATION_OPTIONS.length
          })
      }
      .width('100%')
      .padding(16)
      .backgroundColor('#F5FBF8')
      .borderRadius(20)

      Text(this.getButtonText())
        .width('100%')
        .textAlign(TextAlign.Center)
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .padding({ top: 14, bottom: 14 })
        .backgroundColor(AppTheme.PRIMARY)
        .borderRadius(AppTheme.RADIUS_PILL)
        .shadow({
          radius: 14,
          color: AppTheme.SHADOW,
          offsetY: 4
        })
        .opacity(this.getButtonOpacity())
        .onClick(() => {
          if (this.isPublishEnabled()) {
            this.onPublish()
          }
        })
    }
  }

  @Builder
  buildNoteForm() {
    Column({ space: 16 }) {
      Text('写一句鼓励的话，放进纸条池。陌生人每日可抽取一张，不会显示你的名字。')
        .fontSize(12)
        .fontColor('#75837F')
        .lineHeight(18)
        .width('100%')

      Text('选择语气')
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor('#60706C')

      Row({ space: 10 }) {
        ForEach(NOTE_MOOD_OPTIONS, (item: NoteMoodOption) => {
          Text(item.label)
            .fontSize(12)
            .fontWeight(this.noteMoodKey === item.key ? FontWeight.Bold : FontWeight.Medium)
            .fontColor(this.noteMoodKey === item.key ? Color.White : '#4C5B57')
            .padding({ left: 14, right: 14, top: 10, bottom: 10 })
            .backgroundColor(this.noteMoodKey === item.key ? item.color : AppTheme.CARD)
            .borderRadius(16)
            .onClick(() => {
              this.noteMoodKey = item.key
            })
        }, (item: NoteMoodOption) => item.key)
      }
      .width('100%')

      Column({ space: 10 }) {
        Text('像悄悄递给陌生人一张小纸条')
          .fontSize(12)
          .fontColor('#8B7AD6')
        TextArea({
          text: this.noteDraftText,
          placeholder: '例如：期中周会过去的，你已经很棒了，今晚也值得好好休息。'
        })
          .height(180)
          .backgroundColor('#F5F0FF')
          .borderRadius(AppTheme.RADIUS_LG)
          .fontSize(15)
          .placeholderColor('#A0AAA8')
          .onChange((value: string) => {
            if (value.length <= 120) {
              this.noteDraftText = value
            } else {
              this.noteDraftText = value.substring(0, 120)
            }
          })
      }
      .width('100%')
      .padding(16)
      .backgroundColor(AppTheme.CARD)
      .borderRadius(AppTheme.RADIUS_LG)
      .shadow({
        radius: 12,
        color: AppTheme.SHADOW_LIGHT,
        offsetY: 4
      })

      Row() {
        Text(`${this.getNoteTextLength()}/120`)
          .fontSize(12)
          .fontColor(this.getNoteTextLength() >= 8 ? '#73C088' : '#B0B8B6')
        if (this.getNoteTextLength() > 0 && this.getNoteTextLength() < 8) {
          Text(`还需 ${8 - this.getNoteTextLength()} 字`)
            .fontSize(11)
            .fontColor('#D86A3D')
            .margin({ left: 8 })
        }
      }
      .width('100%')
      .justifyContent(FlexAlign.End)

      Text(this.getNoteButtonText())
        .width('100%')
        .textAlign(TextAlign.Center)
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .padding({ top: 14, bottom: 14 })
        .backgroundColor('#8B7AD6')
        .borderRadius(AppTheme.RADIUS_PILL)
        .shadow({
          radius: 14,
          color: 'rgba(139, 122, 214, 0.25)',
          offsetY: 4
        })
        .opacity(this.getNoteButtonOpacity())
        .onClick(() => {
          if (this.isNoteSubmitEnabled()) {
            this.onSubmitNote()
          }
        })
    }
  }

  build() {
    Column({ space: 16 }) {
      Row({ space: 10 }) {
        this.buildModeChip('post', '贴心情')
        this.buildModeChip('note', '写小纸条')
      }
      .width('100%')

      if (this.isPostMode()) {
        this.buildPostForm()
      } else {
        this.buildNoteForm()
      }
    }
  }
}
