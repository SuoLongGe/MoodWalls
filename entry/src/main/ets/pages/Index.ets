import { AuthSession } from '../common/AuthSession'
import { UiHelper } from '../common/UiHelper'
import { getAvatarResource } from '../common/AvatarResources'
import { MoodWallTabBar } from '../components/MoodWallTabBar'
import { SupportDialog } from '../components/SupportDialog'
import { LOCATION_OPTIONS, MOOD_OPTIONS } from '../mock/MoodWallData'
import { MoodOption, NoteItem } from '../model/MoodWallTypes'
import { MoodApi } from '../service/MoodApi'
import { PostApi } from '../service/PostApi'
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
  @State supportLoading: boolean = false
  @State notes: Array<NoteItem> = []
  @State unreadCount: number = 0
  @State loadingMore: boolean = false
  @State loadingFirst: boolean = true
  @State isFeedRefreshing: boolean = false
  @State publishing: boolean = false
  @State totalPosts: number = 0
  @State anxiousPercent: number = 0
  @State calmPercent: number = 0
  @State happyPercent: number = 0

  private currentPage: number = 1
  private hasMore: boolean = true
  private readonly PAGE_SIZE: number = 20

  aboutToAppear(): void {
    if (!AuthSession.isLoggedIn()) {
      UiHelper.replaceTo('pages/Login')
      return
    }
    console.info('[Index] aboutToAppear, anxiousPercent=' + this.anxiousPercent)
    this.loadStats()
    this.loadPosts(true)
  }

  onPageShow(): void {
    if (AuthSession.isLoggedIn()) {
      this.loadStats()
      this.loadPosts(true)
    }
  }

  loadStats(): void {
    PostApi.getTodayStats()
      .then((res) => {
        this.anxiousPercent = res.anxiousPercent
        this.calmPercent = res.calmPercent
        this.happyPercent = res.happyPercent
        this.totalPosts = res.totalPosts
        console.info('[Index] anxiousPercent=' + this.anxiousPercent + ' totalPosts=' + this.totalPosts)
      })
      .catch((e: Error) => {
        console.error('loadStats 失败: ' + e.message)
      })
  }

  loadPosts(refresh: boolean = false): void {
    if (refresh) {
      this.currentPage = 1
      this.hasMore = true
    }
    if (!this.hasMore && !refresh) return
    if (this.loadingMore && !refresh) return

    if (refresh) {
      this.loadingFirst = true
    } else {
      this.loadingMore = true
    }

    PostApi.getPosts(this.currentPage, this.PAGE_SIZE, this.filterMood, AuthSession.getToken())
      .then((res) => {
        if (refresh) {
          this.notes = res.list
        } else {
          this.notes = this.notes.concat(res.list)
        }
        this.hasMore = res.hasMore
        this.currentPage = res.page + 1
        this.loadingFirst = false
        this.loadingMore = false
      })
      .catch(() => {
        this.loadingFirst = false
        this.loadingMore = false
      })
  }

  loadMorePosts(): void {
    if (!this.loadingMore && this.hasMore) {
      this.loadPosts(false)
    }
  }

  onFilterChange(mood: string): void {
    this.filterMood = mood
    this.loadPosts(true)
  }

  onRefresh(): void {
    this.loadStats()
    this.loadPosts(true)
  }

  private buildNoteItem(src: NoteItem, likes: number, liked: boolean): NoteItem {
    return {
      id: src.id,
      userId: src.userId,
      nickname: src.nickname,
      mood: src.mood,
      moodLabel: src.moodLabel,
      text: src.text,
      location: src.location,
      zoneKey: src.zoneKey,
      timeText: src.timeText,
      likes: likes,
      liked: liked,
      color: src.color,
      createdAt: src.createdAt
    }
  }

  likeNote(noteId: number): void {
    const token: string = AuthSession.getToken()
    if (token.length === 0) return

    const idx: number = this.notes.findIndex((n: NoteItem) => n.id === noteId)
    if (idx < 0) return
    const note: NoteItem = this.notes[idx]

    if (!note.liked) {
      const updated: NoteItem[] = this.notes.concat()
      updated[idx] = {
        id: note.id,
        userId: note.userId,
        nickname: note.nickname,
        mood: note.mood,
        moodLabel: note.moodLabel,
        text: note.text,
        location: note.location,
        zoneKey: note.zoneKey,
        timeText: note.timeText,
        likes: note.likes + 1,
        liked: true,
        color: note.color,
        createdAt: note.createdAt
      }
      this.notes = updated
    }

    PostApi.likePost(noteId, token)
      .then((res) => {
        const u: NoteItem[] = this.notes.concat()
        const i: number = u.findIndex((n: NoteItem) => n.id === noteId)
        if (i >= 0) {
          u[i] = this.buildNoteItem(u[i], res.likes, res.liked)
          this.notes = u
        }
      })
      .catch((e: Error) => {
        console.error('点赞操作失败: ' + e.message)
        const msg = e.message || ''
        if (msg.includes('未登录') || msg.includes('Token') || msg.includes('401')) {
          UiHelper.showToast('请先登录后再点赞')
        }
        const u: NoteItem[] = this.notes.concat()
        const i: number = u.findIndex((n: NoteItem) => n.id === noteId)
        if (i >= 0) {
          u[i] = this.buildNoteItem(u[i], note.likes, note.liked ?? false)
          this.notes = u
        }
      })
  }

  openSupport(note?: NoteItem): void {
    const token: string = AuthSession.getToken()
    if (note) {
      this.supportTitle = `给「${note.moodLabel}」的回信`
      this.supportMessage = '正在倾听...'
      this.supportLoading = true
      this.supportVisible = true

      if (token.length > 0) {
        MoodApi.supportPost(note.id, token)
          .then((res) => {
            this.supportMessage = res.response
            this.supportLoading = false
          })
          .catch((err: Error) => {
            console.error('[MoodWalls] supportPost failed: ' + (err.message || String(err)))
            this.supportMessage = '你已经很努力了。先把这份情绪放在这里，慢慢呼吸一下，再给自己一点点缓冲空间。'
            this.supportLoading = false
          })
      } else {
        this.supportMessage = '你已经很努力了。先把这份情绪放在这里，慢慢呼吸一下，再给自己一点点缓冲空间。'
        this.supportLoading = false
      }
    } else {
      this.supportTitle = '这一周的心情周报'
      this.supportMessage = '正在生成周报...'
      this.supportLoading = true
      this.supportVisible = true

      if (token.length > 0) {
        MoodApi.getWeeklyReport(token)
          .then((res) => {
            this.supportMessage = res.report
            this.supportLoading = false
          })
          .catch(() => {
            this.supportMessage = '这周你的情绪底色更偏平静，说明你在忙碌里依然保留了稳定自己的能力。'
            this.supportLoading = false
          })
      } else {
        this.supportMessage = '这周你的情绪底色更偏平静，说明你在忙碌里依然保留了稳定自己的能力。'
        this.supportLoading = false
      }
    }
  }

  publishNote(): void {
    const content: string = this.draftText.trim()
    if (content.length === 0) return
    if (content.length < 10) {
      UiHelper.showToast('内容至少需要 10 个字')
      return
    }

    const token: string = AuthSession.getToken()
    if (token.length === 0) {
      UiHelper.showToast('请先登录')
      return
    }

    this.publishing = true

    const mood: MoodOption = MOOD_OPTIONS.find((item: MoodOption) => item.key === this.selectedMoodKey) ?? MOOD_OPTIONS[0]
    const location: string = LOCATION_OPTIONS[this.locationIndex]

    PostApi.createPost({
      mood: mood.key,
      text: content,
      location: location
    }, token)
      .then((res) => {
        const aiResponse: string = res.aiResponse ?? '你已经很努力了。先把这份情绪放在这里，慢慢呼吸一下，再给自己一点点缓冲空间。'
        const newNote: NoteItem = {
          id: res.post.id,
          userId: res.post.userId,
          nickname: res.post.nickname,
          mood: res.post.mood,
          moodLabel: res.post.moodLabel,
          text: res.post.text,
          location: res.post.location,
          zoneKey: res.post.zoneKey,
          timeText: res.post.timeText,
          likes: res.post.likes,
          liked: false,
          color: res.post.color,
          createdAt: res.post.createdAt
        }
        this.notes = [newNote, ...this.notes]
        this.draftText = ''
        this.publishing = false
        this.currentTab = 0
        this.supportTitle = `给「${newNote.moodLabel}」的回信`
        this.supportMessage = aiResponse
        this.supportLoading = false
        this.supportVisible = true
        this.loadStats()
      })
      .catch((e: Error) => {
        console.error('发帖失败: ' + e.message)
        this.publishing = false
        UiHelper.showToast(e.message || '发帖失败，请稍后重试')
      })
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column() {
        this.buildHeader()

        if (this.loadingFirst) {
          this.buildLoading()
        } else {
          Scroll() {
            Column({ space: 16 }) {
              if (this.currentTab === 0) {
                FeedTab({
                  notes: $notes,
                  filterMood: this.filterMood,
                  onSupportNote: (note: NoteItem) => this.openSupport(note),
                  onFilterChange: (mood: string) => this.onFilterChange(mood),
                  onLoadMore: () => this.loadMorePosts(),
                  onRefresh: () => this.onRefresh(),
                  hasMore: this.hasMore,
                  loadingMore: this.loadingMore,
                  isRefreshing: $isFeedRefreshing
                })
              } else if (this.currentTab === 1) {
                MapTab({
                  onNavigateToPost: () => {
                    this.currentTab = 2
                  }
                })
              } else if (this.currentTab === 2) {
                PostTab({
                  selectedMoodKey: $selectedMoodKey,
                  draftText: $draftText,
                  locationIndex: $locationIndex,
                  publishing: this.publishing,
                  onPublish: () => this.publishNote()
                })
              } else {
                ProfileTab({
                  onOpenReport: (report: string) => {
                    this.supportTitle = '这一周的心情周报'
                    this.supportMessage = report
                    this.supportVisible = true
                  }
                })
              }
            }
            .padding({
              left: 16,
              right: 16,
              top: this.currentTab === 3 ? 18 : 10,
              bottom: 120
            })
            .width('100%')
          }
          .scrollBar(BarState.Off)
          .layoutWeight(1)
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F4F7F6')

      MoodWallTabBar({ currentTab: $currentTab })
      SupportDialog({
        visible: $supportVisible,
        title: this.supportTitle,
        message: this.supportMessage,
        loading: this.supportLoading
      })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  buildLoading() {
    Column() {
      Text('加载中...')
        .fontSize(14)
        .fontColor('#7C8A87')
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  getGreeting(): string {
    const hour: number = new Date().getHours()
    if (hour < 6) return '凌晨好'
    if (hour < 11) return '早上好'
    if (hour < 14) return '中午好'
    if (hour < 18) return '下午好'
    return '晚上好'
  }

  getSubtitle(): string {
    if (this.currentTab === 1) {
      return '看看此刻校园情绪落在哪些角落。'
    }
    if (this.currentTab === 2) {
      return '写下一张心情纸条，贴进校园心墙。'
    }
    return '今天校园里又有一些心情落在了墙上。'
  }


  @Builder
  buildHeader() {
    Column({ space: 14 }) {
      Row() {
        Row({ space: 12 }) {
          Image(getAvatarResource(AppStorage.get<string>('userAvatarKey') ?? 'avatar_01'))
            .width(44)
            .height(44)
            .borderRadius(22)
            .objectFit(ImageFit.Cover)
            .border({ width: 2, color: '#E8F6EC' })

          Column({ space: 4 }) {
            Text(`${this.getGreeting()}，${AppStorage.get<string>('userNickname') ?? '同学'}`)
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

        Stack() {
          Text('通知')
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor('#31534A')
            .padding({ left: 12, right: 12, top: 10, bottom: 10 })
            .backgroundColor('#F3F6F5')
            .borderRadius(18)
            .onClick(() => {
              UiHelper.pushTo('pages/NotificationPage')
            })

          if (this.unreadCount > 0) {
            Text(this.unreadCount > 99 ? '99+' : `${this.unreadCount}`)
              .fontSize(9)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
              .backgroundColor('#E17272')
              .borderRadius(10)
              .constraintSize({ minWidth: 18 })
              .height(18)
              .textAlign(TextAlign.Center)
              .position({ x: this.unreadCount > 9 ? -10 : -6, y: -4 })
          }
        }
      }
      .justifyContent(FlexAlign.SpaceBetween)
      .width('100%')

      if (this.currentTab !== 2) {
        Row({ space: 8 }) {
          Row({ space: 6 }) {
            Circle().width(8).height(8).fill('#D86A3D')
            Text('焦虑 ' + this.anxiousPercent + '%').fontSize(11).fontWeight(FontWeight.Medium).fontColor('#D86A3D')
          }.padding({ left: 12, right: 12, top: 8, bottom: 8 }).backgroundColor('#FFF1EB').borderRadius(18)

          Row({ space: 6 }) {
            Circle().width(8).height(8).fill('#33824A')
            Text('平静 ' + this.calmPercent + '%').fontSize(11).fontWeight(FontWeight.Medium).fontColor('#33824A')
          }.padding({ left: 12, right: 12, top: 8, bottom: 8 }).backgroundColor('#EEF9F1').borderRadius(18)

          Row({ space: 6 }) {
            Circle().width(8).height(8).fill('#A87400')
            Text('开心 ' + this.happyPercent + '%').fontSize(11).fontWeight(FontWeight.Medium).fontColor('#A87400')
          }.padding({ left: 12, right: 12, top: 8, bottom: 8 }).backgroundColor('#FFF7DB').borderRadius(18)
        }.width('100%')
      }
    }
    .width('100%')
    .padding({ left: 18, right: 18, top: 18, bottom: 16 })
    .backgroundColor('#F9FBFA')
  }

}
