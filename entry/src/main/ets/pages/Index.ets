import { AuthSession } from '../common/AuthSession'
import { UiHelper } from '../common/UiHelper'
import { MoodWallHeader } from '../components/MoodWallHeader'
import { MoodWallTabBar } from '../components/MoodWallTabBar'
import { SupportDialog } from '../components/SupportDialog'
import { INITIAL_NOTES, LOCATION_OPTIONS, MOOD_OPTIONS, ZONE_CARDS } from '../mock/MoodWallData'
import { MoodOption, NoteItem } from '../model/MoodWallTypes'
import { FeedTab } from '../tabs/FeedTab'
import { MapTab } from '../tabs/MapTab'
import { PostTab } from '../tabs/PostTab'
import { ProfileTab } from '../tabs/ProfileTab'

@Entry
@Component
struct Index {
  @State currentTab: number = 0
  @State filterMood: string = 'all'
  @State selectedMoodKey: string = 'calm'
  @State draftText: string = ''
  @State locationIndex: number = 0
  @State supportVisible: boolean = false
  @State supportTitle: string = ''
  @State supportMessage: string = ''
  @State notes: Array<NoteItem> = INITIAL_NOTES

  aboutToAppear(): void {
    if (!AuthSession.isLoggedIn()) {
      UiHelper.replaceTo('pages/Login')
    }
  }

  getGreeting(): string {
    const hour: number = new Date().getHours()
    if (hour < 6) {
      return '凌晨好'
    }
    if (hour < 11) {
      return '早上好'
    }
    if (hour < 14) {
      return '中午好'
    }
    if (hour < 18) {
      return '下午好'
    }
    return '晚上好'
  }

  getSelectedMood(): MoodOption {
    const found: MoodOption | undefined = MOOD_OPTIONS.find((item: MoodOption) => item.key === this.selectedMoodKey)
    return found ? found : MOOD_OPTIONS[0]
  }

  getMoodPercent(keys: Array<string>): number {
    const total: number = this.notes.length > 0 ? this.notes.length : 1
    const count: number = this.notes.filter((item: NoteItem) => keys.indexOf(item.mood) >= 0).length
    return Math.round(count / total * 100)
  }

  openSupport(note?: NoteItem): void {
    if (note) {
      this.supportTitle = `给「${note.moodLabel}」的回信`
      this.supportMessage = '你已经很努力了。先把这份情绪放在这里，慢慢呼吸一下，再给自己一点点缓冲空间。校园里也有人和你一样，正在慢慢穿过这段情绪。'
    } else {
      this.supportTitle = '这一周的心情周报'
      this.supportMessage = '这周你的情绪底色更偏平静，说明你在忙碌里依然保留了稳定自己的能力。焦虑并不代表脆弱，它只是提醒你最近真的很辛苦。'
    }
    this.supportVisible = true
  }

  likeNote(noteId: number): void {
    const nextList: Array<NoteItem> = []
    this.notes.forEach((item: NoteItem) => {
      if (item.id === noteId) {
        nextList.push({
          id: item.id,
          mood: item.mood,
          moodLabel: item.moodLabel,
          text: item.text,
          location: item.location,
          timeText: item.timeText,
          likes: item.likes + 1,
          color: item.color
        })
      } else {
        nextList.push(item)
      }
    })
    this.notes = nextList
  }

  publishNote(): void {
    const content: string = this.draftText.trim()
    if (content.length === 0) {
      return
    }

    const mood: MoodOption = this.getSelectedMood()
    const nextItem: NoteItem = {
      id: new Date().getTime(),
      mood: mood.key,
      moodLabel: mood.label,
      text: content,
      location: LOCATION_OPTIONS[this.locationIndex],
      timeText: '刚刚',
      likes: 0,
      color: mood.color
    }

    this.notes = [nextItem, ...this.notes]
    this.draftText = ''
    this.currentTab = 0
    this.openSupport(nextItem)
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column() {
        MoodWallHeader({
          currentTab: this.currentTab,
          greeting: this.getGreeting(),
          anxiousPercent: this.getMoodPercent(['anxious', 'sad', 'tired']),
          calmPercent: this.getMoodPercent(['calm', 'moved']),
          happyPercent: this.getMoodPercent(['happy'])
        })

        Scroll() {
          Column({ space: 16 }) {
            if (this.currentTab === 0) {
              FeedTab({
                notes: this.notes,
                filterMood: $filterMood,
                onLikeNote: (noteId: number) => this.likeNote(noteId),
                onSupportNote: (note: NoteItem) => this.openSupport(note)
              })
            } else if (this.currentTab === 1) {
              MapTab({
                zones: ZONE_CARDS,
                onNavigateToPost: () => {
                  this.currentTab = 2
                }
              })
            } else if (this.currentTab === 2) {
              PostTab({
                selectedMoodKey: $selectedMoodKey,
                draftText: $draftText,
                locationIndex: $locationIndex,
                onPublish: () => this.publishNote()
              })
            } else {
              ProfileTab({
                calmPercent: this.getMoodPercent(['calm', 'moved']),
                anxiousPercent: this.getMoodPercent(['anxious', 'sad', 'tired']),
                happyPercent: this.getMoodPercent(['happy']),
                onOpenReport: () => this.openSupport()
              })
            }
          }
          .padding({ left: 16, right: 16, top: 10, bottom: 120 })
          .width('100%')
        }
        .scrollBar(BarState.Off)
        .layoutWeight(1)
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F4F7F6')

      MoodWallTabBar({ currentTab: $currentTab })
      SupportDialog({
        visible: $supportVisible,
        title: this.supportTitle,
        message: this.supportMessage
      })
    }
    .width('100%')
    .height('100%')
  }
}
