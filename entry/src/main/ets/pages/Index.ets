import { AppTheme } from '../common/AppTheme'
import { AuthSession } from '../common/AuthSession'
import { NoteHelper } from '../common/NoteHelper'
import { NotificationStore } from '../common/NotificationStore'
import { ProfileStore } from '../common/ProfileStore'
import { UiHelper } from '../common/UiHelper'
import { MoodWallHeader } from '../components/MoodWallHeader'
import { MoodWallTabBar } from '../components/MoodWallTabBar'
import { SupportDialog } from '../components/SupportDialog'
import { LOCATION_OPTIONS, MOOD_OPTIONS } from '../mock/MoodWallData'
import { MoodOption, NoteItem } from '../model/MoodWallTypes'
import { MoodApi } from '../service/MoodApi'
import { InspirationApi } from '../service/InspirationApi'
import { PostApi } from '../service/PostApi'
import { CreateEncouragementNoteBody } from '../model/MoodWallTypes'
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
  @State supportComfortNote: string = ''
  @State supportRiskLevel: number = 0
  @State supportLoading: boolean = false
  @State notes: Array<NoteItem> = []
  @State loadingMore: boolean = false
  @State loadingFirst: boolean = true
  @State isFeedRefreshing: boolean = false
  @State publishing: boolean = false
  @State noteDraftText: string = ''
  @State noteMoodKey: string = 'calm'
  @State submittingNote: boolean = false
  @State profileRefreshTick: number = 0
  @State tabContentOpacity: number = 1
  @State tabContentOffsetY: number = 0
  @State tabContentScale: number = 1
  @StorageLink('themeMode') themeMode: string = 'light'

  private currentPage: number = 1
  private hasMore: boolean = true
  private readonly PAGE_SIZE: number = 20
  private unreadPollTimer: number = -1
  private lastPostDetailRefreshTick: number = 0

  aboutToAppear(): void {
    if (!AuthSession.isLoggedIn()) {
      UiHelper.replaceTo('pages/Login')
      return
    }
    this.isFeedRefreshing = false
    ProfileStore.refreshFromApi().catch(() => {})
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
    this.refreshUnreadCount()
    const detailTick: number | undefined = AppStorage.get<number>('postDetailRefreshTick')
    const nextDetailTick: number = detailTick !== undefined ? detailTick : 0
    if (nextDetailTick > this.lastPostDetailRefreshTick) {
      this.lastPostDetailRefreshTick = nextDetailTick
      if (this.currentTab === 0) {
        this.loadPosts(true)
      }
    }
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
    this.tabContentOpacity = 0.15
    this.tabContentOffsetY = 36
    this.tabContentScale = 0.92
    animateTo({ duration: AppTheme.TAB_ENTER_MS, curve: Curve.FastOutSlowIn }, () => {
      this.tabContentOpacity = 1
      this.tabContentOffsetY = 0
      this.tabContentScale = 1
    })
  }

  pageTransition() {
    PageTransitionEnter({ duration: AppTheme.PAGE_FADE_ENTER_MS, curve: Curve.FastOutSlowIn })
      .opacity(0)
      .translate({ y: 28 })
    PageTransitionExit({ duration: AppTheme.PAGE_FADE_EXIT_MS, curve: Curve.EaseIn })
      .opacity(0)
      .translate({ y: -20 })
  }

  onSupportVisibleChange(): void {
    if (!this.supportVisible) {
      this.refreshUnreadCount()
    }
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
    this.loadPosts(true)
    if (this.currentTab === 3) {
      this.profileRefreshTick++
    }
  }

  private buildNoteItem(src: NoteItem, likes: number, liked: boolean): NoteItem {
    return NoteHelper.copy(src, likes, liked)
  }

  likeNote(noteId: number): void {
    const token: string = AuthSession.getToken()
    if (token.length === 0) return

    const idx: number = this.notes.findIndex((n: NoteItem) => n.id === noteId)
    if (idx < 0) return
    const note: NoteItem = this.notes[idx]

    if (!note.liked) {
      const updated: NoteItem[] = this.notes.concat()
      updated[idx] = NoteHelper.copy(note, note.likes + 1, true)
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
            this.supportRiskLevel = res.riskLevel !== undefined ? res.riskLevel : 0
            this.supportComfortNote = res.comfortNote !== undefined ? res.comfortNote : ''
            if (res.riskLevel === 2) {
              this.supportTitle = '⚠️ 我们很关心你'
            } else if (res.riskLevel === 1) {
              this.supportTitle = '💚 温心小纸条'
            }
            this.supportLoading = false
            this.refreshUnreadCount()
          })
          .catch((err: Error) => {
            console.error('[MoodWalls] supportPost failed: ' + (err.message || String(err)))
            this.supportMessage = '你已经很努力了。先把这份情绪放在这里，慢慢呼吸一下，再给自己一点点缓冲空间。'
            this.supportRiskLevel = 0
            this.supportComfortNote = ''
            this.supportLoading = false
          })
      } else {
        this.supportMessage = '你已经很努力了。先把这份情绪放在这里，慢慢呼吸一下，再给自己一点点缓冲空间。'
        this.supportRiskLevel = 0
        this.supportComfortNote = ''
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

  submitEncouragementNote(): void {
    const content: string = this.noteDraftText.trim()
    if (content.length < 8) {
      UiHelper.showToast('小纸条至少需要 8 个字')
      return
    }

    const token: string = AuthSession.getToken()
    if (token.length === 0) {
      UiHelper.showToast('请先登录')
      return
    }

    this.submittingNote = true
    const body: CreateEncouragementNoteBody = {
      content: content,
      mood: this.noteMoodKey
    }
    InspirationApi.createNote(body, token)
      .then(() => {
        this.noteDraftText = ''
        this.submittingNote = false
        this.currentTab = 3
        UiHelper.showToast('小纸条已放进池里，等待陌生人领取')
      })
      .catch((e: Error) => {
        this.submittingNote = false
        UiHelper.showToast(e.message || '放入失败，请稍后重试')
      })
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
        const riskLevel: number = res.riskLevel !== undefined ? res.riskLevel : 0
        const comfortNote: string = res.comfortNote !== undefined ? res.comfortNote : ''
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
          createdAt: res.post.createdAt,
          avatarKey: res.post.avatarKey !== undefined ? res.post.avatarKey : AuthSession.getAvatarKey(),
          isMine: true,
          commentCount: res.post.commentCount !== undefined ? res.post.commentCount : 0,
          visibility: res.post.visibility !== undefined ? res.post.visibility : 'public',
          canDelete: true
        }
        this.notes = [newNote, ...this.notes]
        this.draftText = ''
        this.publishing = false
        this.currentTab = 0
        if (riskLevel === 2) {
          this.supportTitle = '⚠️ 我们很关心你'
        } else if (riskLevel === 1) {
          this.supportTitle = '💚 温心小纸条'
        } else {
          this.supportTitle = `给「${newNote.moodLabel}」的回信`
        }
        this.supportMessage = aiResponse
        this.supportRiskLevel = riskLevel
        this.supportComfortNote = comfortNote
        this.supportLoading = false
        this.supportVisible = true
        this.profileRefreshTick++
      })
      .catch((e: Error) => {
        console.error('发帖失败: ' + e.message)
        this.publishing = false
        UiHelper.showToast(e.message || '发帖失败，请稍后重试')
      })
  }

  build() {
    Stack() {
      Column() {
        Column() {
          if (this.currentTab !== 3) {
            MoodWallHeader({
              currentTab: this.currentTab,
              greeting: this.getGreeting()
            })
          }

          Column() {
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
            } else if (this.currentTab === 1) {
              MapTab({
                onNavigateToPost: () => {
                  this.currentTab = 2
                }
              })
                .layoutWeight(1)
                .padding({ left: 16, right: 16, top: 10, bottom: 18 })
            } else {
              Scroll() {
                Column({ space: this.currentTab === 3 ? 0 : 16 }) {
                  if (this.currentTab === 2) {
                    PostTab({
                      selectedMoodKey: $selectedMoodKey,
                      draftText: $draftText,
                      locationIndex: $locationIndex,
                      noteDraftText: $noteDraftText,
                      noteMoodKey: $noteMoodKey,
                      publishing: this.publishing,
                      submittingNote: this.submittingNote,
                      onPublish: () => this.publishNote(),
                      onSubmitNote: () => this.submitEncouragementNote()
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
                  left: this.currentTab === 3 ? 0 : 16,
                  right: this.currentTab === 3 ? 0 : 16,
                  top: this.currentTab === 3 ? 0 : 10,
                  bottom: this.currentTab === 3 ? 0 : 18
                })
                .width('100%')
              }
              .scrollBar(BarState.Off)
              .layoutWeight(1)
            }
          }
          .layoutWeight(1)
          .opacity(this.tabContentOpacity)
          .translate({ y: this.tabContentOffsetY })
          .scale({ x: this.tabContentScale, y: this.tabContentScale })
        }
        .layoutWeight(1)
        .width('100%')

        MoodWallTabBar({
          currentTab: $currentTab,
          onTabChange: () => {
            this.refreshUnreadCount()
          }
        })
      }
      .width('100%')
      .height('100%')
      .backgroundColor(AppTheme.BG)

      SupportDialog({
        visible: $supportVisible,
        title: this.supportTitle,
        message: this.supportMessage,
        comfortNote: this.supportComfortNote,
        riskLevel: this.supportRiskLevel,
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
        .fontColor(AppTheme.TEXT_HINT)
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
