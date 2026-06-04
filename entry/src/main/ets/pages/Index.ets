import { AuthSession } from '../common/AuthSession'
import { NotificationStore } from '../common/NotificationStore'
import { UiHelper } from '../common/UiHelper'
import { MoodWallHeader } from '../components/MoodWallHeader'
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
  @State @Watch('onCurrentTabChange') currentTab: number = 0
  @State filterMood: string = 'all'
  @State selectedMoodKey: string = 'calm'
  @State draftText: string = ''
  @State locationIndex: number = 0
  @State @Watch('onSupportVisibleChange') supportVisible: boolean = false
  @State supportTitle: string = ''
  @State supportMessage: string = ''
  @State supportLoading: boolean = false
  @State notes: Array<NoteItem> = []
  @State loadingMore: boolean = false
  @State loadingFirst: boolean = true
  @State isFeedRefreshing: boolean = false
  @State publishing: boolean = false
  @State headerStatsRefreshTick: number = 0
  @State profileRefreshTick: number = 0

  private currentPage: number = 1
  private hasMore: boolean = true
  private readonly PAGE_SIZE: number = 20
  private unreadPollTimer: number = -1

  aboutToAppear(): void {
    if (!AuthSession.isLoggedIn()) {
      UiHelper.replaceTo('pages/Login')
      return
    }
    this.isFeedRefreshing = false
    this.loadStats()
    this.loadPosts(true)
    this.refreshUnreadCount()
    this.startUnreadPolling()
  }

  aboutToDisappear(): void {
    this.stopUnreadPolling()
  }

  onPageShow(): void {
    if (!AuthSession.isLoggedIn()) {
      return
    }
    this.loadStats()
    this.refreshUnreadCount()
    if (this.currentTab === 3) {
      this.profileRefreshTick++
    }
    if (this.notes.length === 0 && !this.loadingFirst) {
      this.loadPosts(true)
    }
  }

  refreshUnreadCount(): void {
    NotificationStore.refreshUnreadCount()
  }

  startUnreadPolling(): void {
    this.stopUnreadPolling()
    this.unreadPollTimer = setInterval(() => {
      NotificationStore.refreshUnreadCount()
    }, 12000)
  }

  stopUnreadPolling(): void {
    if (this.unreadPollTimer >= 0) {
      clearInterval(this.unreadPollTimer)
      this.unreadPollTimer = -1
    }
  }

  onCurrentTabChange(): void {
    this.refreshUnreadCount()
    if (this.currentTab === 3) {
      this.profileRefreshTick++
    }
  }

  onSupportVisibleChange(): void {
    if (!this.supportVisible) {
      this.refreshUnreadCount()
    }
  }

  loadStats(): void {
    this.headerStatsRefreshTick++
  }

  private finishPostsLoading(): void {
    this.loadingFirst = false
    this.loadingMore = false
    this.isFeedRefreshing = false
  }

  loadPosts(refresh: boolean = false): Promise<void> {
    if (refresh) {
      this.currentPage = 1
      this.hasMore = true
    }
    if (!this.hasMore && !refresh) {
      this.finishPostsLoading()
      return Promise.resolve()
    }
    if (this.loadingMore && !refresh) {
      return Promise.resolve()
    }

    if (refresh && this.notes.length === 0) {
      this.loadingFirst = true
    } else if (refresh) {
      this.loadingFirst = false
    } else {
      this.loadingMore = true
    }

    return PostApi.getPosts(this.currentPage, this.PAGE_SIZE, this.filterMood, AuthSession.getToken())
      .then((res) => {
        if (refresh) {
          this.notes = res.list
        } else {
          this.notes = this.notes.concat(res.list)
        }
        this.hasMore = res.hasMore
        this.currentPage = res.page + 1
      })
      .catch((e: Error) => {
        console.error('loadPosts 失败: ' + e.message)
        if (refresh && this.notes.length === 0) {
          UiHelper.showToast('帖子加载失败，请检查后端与网络')
        }
      })
      .finally(() => {
        this.finishPostsLoading()
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
            this.refreshUnreadCount()
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
            this.refreshUnreadCount()
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
        this.profileRefreshTick++
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
        MoodWallHeader({
          currentTab: this.currentTab,
          greeting: this.getGreeting(),
          statsRefreshTick: this.headerStatsRefreshTick
        })

        if (this.currentTab === 0) {
          if (this.loadingFirst) {
            this.buildLoading()
          } else {
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
              .layoutWeight(1)
          }
        } else {
          Scroll() {
            Column({ space: 16 }) {
              if (this.currentTab === 1) {
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
                  profileRefreshTick: this.profileRefreshTick,
                  onOpenReport: (report: string) => {
                    this.supportTitle = '这一周的心情周报'
                    this.supportMessage = report
                    this.supportVisible = true
                    this.refreshUnreadCount()
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

      MoodWallTabBar({
        currentTab: $currentTab,
        onTabChange: () => {
          this.refreshUnreadCount()
        }
      })
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

}
