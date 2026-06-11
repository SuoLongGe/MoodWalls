import { common } from '@kit.AbilityKit'
import { AppTheme } from '../common/AppTheme'
import { AuthSession } from '../common/AuthSession'
import { NoteHelper } from '../common/NoteHelper'
import { PostActionHelper } from '../common/PostActionHelper'
import { SearchHistoryStore } from '../common/SearchHistoryStore'
import { UiHelper } from '../common/UiHelper'
import { PageHeader } from '../components/PageHeader'
import { PostCard } from '../components/PostCard'
import { NoteItem, ReactionResponse } from '../model/MoodWallTypes'
import { MoodApi } from '../service/MoodApi'
import { PostApi } from '../service/PostApi'

@Entry
@Component
struct SearchPage {
  @State keyword: string = ''
  @State results: Array<NoteItem> = []
  @State history: Array<string> = []
  @State loading: boolean = false
  @State searched: boolean = false
  @State filterMood: string = 'all'
  @State filterPeriod: string = 'all'
  @State refreshKey: number = 0
  @StorageLink('themeMode') themeMode: string = 'light'
  private debounceTimer: number = -1
  private pageContext: common.Context | null = null

  aboutToAppear(): void {
    this.pageContext = getContext(this) as common.Context
    if (this.pageContext !== null) {
      SearchHistoryStore.init(this.pageContext).then(() => {
        this.history = SearchHistoryStore.getHistory()
      })
    }
  }

  aboutToDisappear(): void {
    this.clearDebounce()
  }

  private clearDebounce(): void {
    if (this.debounceTimer >= 0) {
      clearTimeout(this.debounceTimer)
      this.debounceTimer = -1
    }
  }

  private scheduleSearch(): void {
    this.clearDebounce()
    this.debounceTimer = setTimeout(() => {
      this.debounceTimer = -1
      this.runSearch(true)
    }, 300)
  }

  private runSearch(resetPage: boolean): void {
    const trimmed: string = this.keyword.trim()
    if (trimmed.length === 0) {
      this.results = []
      this.searched = false
      return
    }

    this.loading = true
    this.searched = true
    const token: string = AuthSession.getToken()
    PostApi.searchPosts(
      trimmed,
      1,
      20,
      this.filterMood,
      this.filterPeriod,
      token.length > 0 ? token : undefined
    ).then((res) => {
      this.results = res.list
      if (this.pageContext !== null) {
        SearchHistoryStore.saveKeyword(this.pageContext, trimmed).then(() => {
          this.history = SearchHistoryStore.getHistory()
        })
      }
    }).catch((err: Error) => {
      UiHelper.showToast(err.message || '搜索失败')
      this.results = []
    }).finally(() => {
      this.loading = false
      if (resetPage) {
        this.refreshKey++
      }
    })
  }

  private applyNoteUpdate(noteId: number, likes: number, liked: boolean): void {
    const next: NoteItem[] = []
    this.results.forEach((item: NoteItem) => {
      if (item.id === noteId) {
        next.push(NoteHelper.copy(item, likes, liked))
      } else {
        next.push(item)
      }
    })
    this.results = next
    this.refreshKey++
  }

  private removeNote(noteId: number): void {
    const next: NoteItem[] = []
    this.results.forEach((item: NoteItem) => {
      if (item.id !== noteId) {
        next.push(item)
      }
    })
    this.results = next
    this.refreshKey++
  }

  private applyReactionUpdate(noteId: number, reaction: ReactionResponse): void {
    const next: NoteItem[] = []
    this.results.forEach((item: NoteItem) => {
      if (item.id === noteId) {
        next.push(NoteHelper.applyReaction(item, reaction))
      } else {
        next.push(item)
      }
    })
    this.results = next
    this.refreshKey++
  }

  private handleReact(noteId: number, reactionType: string): void {
    const token: string = AuthSession.getToken()
    if (token.length === 0) {
      UiHelper.showToast('请先登录后再表达心意')
      return
    }
    const idx: number = this.results.findIndex((n: NoteItem) => n.id === noteId)
    if (idx < 0) {
      return
    }
    const note: NoteItem = this.results[idx]
    PostApi.reactPost(noteId, reactionType, token)
      .then((res: ReactionResponse) => this.applyReactionUpdate(noteId, res))
      .catch((err: Error) => UiHelper.showToast(err.message || '操作失败'))
  }

  private handleCancelReact(noteId: number): void {
    const token: string = AuthSession.getToken()
    if (token.length === 0) {
      UiHelper.showToast('请先登录')
      return
    }
    PostApi.cancelReact(noteId, token)
      .then((res: ReactionResponse) => this.applyReactionUpdate(noteId, res))
      .catch((err: Error) => UiHelper.showToast(err.message || '操作失败'))
  }

  private handleDelete(noteId: number): void {
    const token: string = AuthSession.getToken()
    if (token.length === 0) {
      UiHelper.showToast('请先登录')
      return
    }
    UiHelper.showConfirmDialog('删除帖子', '删除后无法恢复，确定吗？', () => {
      PostApi.deletePost(noteId, token)
        .then(() => {
          this.removeNote(noteId)
          UiHelper.markFeedNeedsRefresh()
          UiHelper.showToast('已删除')
        })
        .catch((err: Error) => UiHelper.showToast(err.message || '删除失败'))
    })
  }

  private handleVisibility(note: NoteItem, visibility: string): void {
    const token: string = AuthSession.getToken()
    if (token.length === 0) {
      UiHelper.showToast('请先登录')
      return
    }
    PostApi.updateVisibility(note.id, visibility, token)
      .then(() => {
        if (visibility === 'private') {
          this.removeNote(note.id)
        } else {
          const next: NoteItem[] = []
          this.results.forEach((item: NoteItem) => {
            if (item.id === note.id) {
              const updated: NoteItem = NoteHelper.copy(item)
              updated.visibility = 'public'
              next.push(updated)
            } else {
              next.push(item)
            }
          })
          this.results = next
          this.refreshKey++
        }
        UiHelper.markFeedNeedsRefresh()
        UiHelper.showToast(visibility === 'private' ? '已设为仅自己可见' : '已恢复公开')
      })
      .catch((err: Error) => UiHelper.showToast(err.message || '操作失败'))
  }

  private handleSupport(note: NoteItem): void {
    const token: string = AuthSession.getToken()
    if (token.length === 0) {
      UiHelper.showToast('请先登录')
      return
    }
    MoodApi.supportPost(note.id, token)
      .then((res) => UiHelper.showToast(res.response.length > 36 ? '已收到温暖回信' : res.response))
      .catch((err: Error) => UiHelper.showToast(err.message || '接住心声失败'))
  }

  private showPostActions(note: NoteItem): void {
    PostActionHelper.showMenu(
      note,
      () => this.handleDelete(note.id),
      (visibility: string) => this.handleVisibility(note, visibility)
    )
  }

  private useHistory(word: string): void {
    this.keyword = word
    this.runSearch(true)
  }

  @Builder
  buildFilterChip(key: string, label: string, selected: string, onPick: (value: string) => void) {
    Text(label)
      .fontSize(12)
      .fontWeight(selected === key ? FontWeight.Bold : FontWeight.Medium)
      .fontColor(selected === key ? Color.White : AppTheme.TEXT_HINT)
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })
      .backgroundColor(selected === key ? AppTheme.PRIMARY : AppTheme.CARD)
      .borderRadius(AppTheme.RADIUS_MD)
      .animation({ duration: AppTheme.TAB_ENTER_MS, curve: Curve.Smooth })
      .onClick(() => {
        if (selected !== key) {
          onPick(key)
          if (this.keyword.trim().length > 0) {
            this.runSearch(true)
          }
        }
      })
  }

  pageTransition() {
    PageTransitionEnter({ duration: AppTheme.PAGE_PUSH_MS, curve: Curve.FastOutSlowIn })
      .slide(SlideEffect.Right)
      .opacity(0)
      .scale({ x: 0.92, y: 0.92 })
    PageTransitionExit({ duration: AppTheme.PAGE_PUSH_MS - 80, curve: Curve.EaseIn })
      .slide(SlideEffect.Left)
      .opacity(0.5)
      .scale({ x: 0.96, y: 0.96 })
    PageTransitionEnter({ type: RouteType.Pop, duration: AppTheme.PAGE_POP_MS, curve: Curve.FastOutSlowIn })
      .slide(SlideEffect.Left)
      .opacity(0)
      .scale({ x: 0.92, y: 0.92 })
    PageTransitionExit({ type: RouteType.Pop, duration: AppTheme.PAGE_POP_MS - 60, curve: Curve.EaseIn })
      .slide(SlideEffect.Right)
      .opacity(0)
      .scale({ x: 0.94, y: 0.94 })
  }

  build() {
    Column() {
      PageHeader({
        title: '搜索心情',
        onBack: () => {
          UiHelper.goBack()
        }
      })

      Column({ space: 12 }) {
        Search({ placeholder: '搜索帖子内容...', value: this.keyword })
          .width('100%')
          .height(42)
          .backgroundColor(AppTheme.CARD)
          .borderRadius(AppTheme.RADIUS_PILL)
          .shadow({
            radius: 8,
            color: AppTheme.SHADOW_LIGHT,
            offsetY: 2
          })
          .onChange((value: string) => {
            this.keyword = value
            this.scheduleSearch()
          })
          .onSubmit(() => {
            this.clearDebounce()
            this.runSearch(true)
          })

        Scroll() {
          Row({ space: 8 }) {
            this.buildFilterChip('all', '全部情绪', this.filterMood, (value: string) => {
              this.filterMood = value
            })
            this.buildFilterChip('happy', '开心', this.filterMood, (value: string) => {
              this.filterMood = value
            })
            this.buildFilterChip('calm', '平静', this.filterMood, (value: string) => {
              this.filterMood = value
            })
            this.buildFilterChip('anxious', '焦虑', this.filterMood, (value: string) => {
              this.filterMood = value
            })
            this.buildFilterChip('sad', '低落', this.filterMood, (value: string) => {
              this.filterMood = value
            })
          }
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)

        Scroll() {
          Row({ space: 8 }) {
            this.buildFilterChip('all', '全部时间', this.filterPeriod, (value: string) => {
              this.filterPeriod = value
            })
            this.buildFilterChip('today', '今天', this.filterPeriod, (value: string) => {
              this.filterPeriod = value
            })
            this.buildFilterChip('week', '本周', this.filterPeriod, (value: string) => {
              this.filterPeriod = value
            })
            this.buildFilterChip('month', '本月', this.filterPeriod, (value: string) => {
              this.filterPeriod = value
            })
          }
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)

        if (this.history.length > 0 && !this.searched) {
          Column({ space: 8 }) {
            Text('最近搜索')
              .fontSize(13)
              .fontColor('#7C8A87')
              .width('100%')
            Flex({ wrap: FlexWrap.Wrap }) {
              ForEach(this.history, (word: string) => {
                Text(word)
                  .fontSize(12)
                  .fontColor('#31534A')
                  .padding({ left: 12, right: 12, top: 8, bottom: 8 })
                  .backgroundColor('#F3F6F5')
                  .borderRadius(16)
                  .margin({ right: 8, bottom: 8 })
                  .onClick(() => this.useHistory(word))
              }, (word: string) => word)
            }
            .width('100%')
          }
          .width('100%')
        }
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })

      if (this.loading) {
        Column() {
          LoadingProgress()
            .width(32)
            .height(32)
            .color('#31534A')
          Text('搜索中...')
            .fontSize(13)
            .fontColor('#7C8A87')
            .margin({ top: 10 })
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .width('100%')
      } else if (this.searched && this.results.length === 0) {
        Column({ space: 8 }) {
          Text('没有找到相关心情')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#31534A')
          Text('换个词试试')
            .fontSize(13)
            .fontColor('#7C8A87')
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .width('100%')
      } else {
        Scroll() {
          Column({ space: 0 }) {
            ForEach(this.results, (item: NoteItem) => {
              Column() {
                PostCard({
                note: item,
                onReact: (noteId: number, reactionType: string) => this.handleReact(noteId, reactionType),
                onCancelReact: (noteId: number) => this.handleCancelReact(noteId),
                onSupport: (note: NoteItem) => this.handleSupport(note),
                onComment: (note: NoteItem) => UiHelper.pushToPostDetail(note.id, true),
                onMore: (note: NoteItem) => this.showPostActions(note),
                onLongPress: (note: NoteItem) => this.showPostActions(note),
                onOpen: (note: NoteItem) => UiHelper.pushToPostDetail(note.id)
                })
                Row()
                  .width('100%')
                  .height(8)
                  .backgroundColor('#F4F4F4')
              }
            }, (item: NoteItem) => `${item.id}-${this.refreshKey}`)
          }
          .width('100%')
          .padding({ bottom: 24 })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppTheme.BG)
  }
}
