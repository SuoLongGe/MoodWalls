import { AppTheme } from '../common/AppTheme'
import { NoteItem, ReactionResponse } from '../model/MoodWallTypes'
import { PostApi } from '../service/PostApi'
import { AuthSession } from '../common/AuthSession'
import { UiHelper } from '../common/UiHelper'
import { NoteHelper } from '../common/NoteHelper'
import { PostActionHelper } from '../common/PostActionHelper'
import { PostCard } from '../components/PostCard'

@Component
export struct FeedTab {
  @Link notes: Array<NoteItem>
  @Prop filterMood: string = 'all'
  @Prop hasMore: boolean = false
  @Prop loadingMore: boolean = false
  @State private refreshKey: number = 0
  onSupportNote: (note: NoteItem) => void = () => {}
  onFilterChange: (mood: string) => void = () => {}
  onLoadMore: () => void = () => {}
  onRefresh: () => void = () => {}
  @Link isRefreshing: boolean

  private applyReactionUpdate(noteId: number, reaction: ReactionResponse): void {
    const u: NoteItem[] = this.notes.concat()
    const i: number = u.findIndex((n: NoteItem) => n.id === noteId)
    if (i >= 0) {
      u[i] = NoteHelper.applyReaction(u[i], reaction)
      this.notes = u
      this.refreshKey++
    }
  }

  private removeNote(noteId: number): void {
    const u: NoteItem[] = []
    this.notes.forEach((n: NoteItem) => {
      if (n.id !== noteId) {
        u.push(n)
      }
    })
    this.notes = u
    this.refreshKey++
  }

  private handleReact(noteId: number, reactionType: string): void {
    const idx: number = this.notes.findIndex((n: NoteItem) => n.id === noteId)
    if (idx < 0) {
      return
    }
    const note: NoteItem = this.notes[idx]
    const token: string = AuthSession.getToken()
    if (token.length === 0) {
      UiHelper.showToast('请先登录后再表达心意')
      return
    }

    PostApi.reactPost(noteId, reactionType, token)
      .then((res: ReactionResponse) => {
        this.applyReactionUpdate(noteId, res)
      })
      .catch((e: Error) => {
        UiHelper.showToast(e.message || '操作失败，请稍后重试')
      })
  }

  private handleCancelReact(noteId: number): void {
    const idx: number = this.notes.findIndex((n: NoteItem) => n.id === noteId)
    if (idx < 0) {
      return
    }
    const note: NoteItem = this.notes[idx]
    const token: string = AuthSession.getToken()
    if (token.length === 0) {
      UiHelper.showToast('请先登录')
      return
    }

    PostApi.cancelReact(noteId, token)
      .then((res: ReactionResponse) => {
        this.applyReactionUpdate(noteId, res)
      })
      .catch((e: Error) => {
        UiHelper.showToast(e.message || '操作失败，请稍后重试')
      })
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
        .catch((e: Error) => {
          console.error('删帖失败: ' + e.message)
          UiHelper.showToast(e.message || '删除失败，请稍后重试')
        })
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
        }
        UiHelper.markFeedNeedsRefresh()
        UiHelper.showToast(visibility === 'private' ? '已设为仅自己可见' : '已恢复公开')
      })
      .catch((e: Error) => {
        UiHelper.showToast(e.message || '操作失败，请稍后重试')
      })
  }

  private showPostActions(note: NoteItem): void {
    PostActionHelper.showMenu(
      note,
      () => {
        this.handleDelete(note.id)
      },
      (visibility: string) => {
        this.handleVisibility(note, visibility)
      }
    )
  }

  aboutToAppear(): void {
    this.isRefreshing = false
  }

  build() {
    Refresh({ refreshing: this.isRefreshing }) {
      Scroll() {
        Column({ space: 0 }) {
          this.buildFilterChips()
          List() {
            ForEach(this.notes, (item: NoteItem) => {
              ListItem() {
                PostCard({
                  note: item,
                  onReact: (noteId: number, reactionType: string) => {
                    this.handleReact(noteId, reactionType)
                  },
                  onCancelReact: (noteId: number) => {
                    this.handleCancelReact(noteId)
                  },
                  onSupport: (note: NoteItem) => {
                    this.onSupportNote(note)
                  },
                  onComment: (note: NoteItem) => {
                    UiHelper.pushToPostDetail(note.id, true)
                  },
                  onOpen: (note: NoteItem) => {
                    UiHelper.pushToPostDetail(note.id)
                  },
                  onMore: (note: NoteItem) => {
                    this.showPostActions(note)
                  },
                  onLongPress: (note: NoteItem) => {
                    this.showPostActions(note)
                  }
                })
              }
            }, (item: NoteItem) => `${item.id}-${this.refreshKey}`)

            if (this.hasMore) {
              ListItem() {
                Row() {
                  if (this.loadingMore) {
                    Text('加载更多...')
                      .fontSize(13)
                      .fontColor('#7C8A87')
                  } else {
                    Text('上拉加载更多')
                      .fontSize(13)
                      .fontColor('#7C8A87')
                  }
                }
                .width('100%')
                .justifyContent(FlexAlign.Center)
                .padding({ top: 8, bottom: 8 })
              }
              .onClick(() => {
                if (!this.loadingMore) {
                  this.onLoadMore()
                }
              })
            }

            if (!this.hasMore && this.notes.length > 0) {
              ListItem() {
                Text('— 没有更多了 —')
                  .fontSize(12)
                  .fontColor('#B0B8B6')
                  .width('100%')
                  .textAlign(TextAlign.Center)
                  .padding({ top: 8, bottom: 8 })
              }
            }

            if (this.notes.length === 0) {
              ListItem() {
                Column({ space: 8 }) {
                  Text('暂无帖子')
                    .fontSize(16)
                    .fontColor('#7C8A87')
                  Text('成为第一个分享心情的人吧')
                    .fontSize(13)
                    .fontColor('#B0B8B6')
                }
                .width('100%')
                .padding({ top: 40, bottom: 40 })
                .alignItems(HorizontalAlign.Center)
              }
            }
          }
          .width('100%')
          .listDirection(Axis.Vertical)
          .divider({ strokeWidth: 8, color: '#F4F4F4', startMargin: 0, endMargin: 0 })
          .sticky(StickyStyle.None)
          .onScrollIndex((startIndex: number) => {
            const threshold = this.notes.length - 3
            if (startIndex >= threshold && !this.loadingMore && this.hasMore) {
              this.onLoadMore()
            }
          })
        }
      }
      .scrollBar(BarState.Off)
    }
    .onRefreshing(() => {
      this.onRefresh()
    })
    .width('100%')
    .layoutWeight(1)
    .padding({ top: 0, bottom: 0 })
  }

  @Builder
  buildFilterChips() {
    Scroll() {
      Row({ space: 8 }) {
        this.buildFilterChip('all', '全部')
        this.buildFilterChip('happy', '开心')
        this.buildFilterChip('calm', '平静')
        this.buildFilterChip('moved', '感动')
        this.buildFilterChip('anxious', '焦虑')
        this.buildFilterChip('sad', '低落')
        this.buildFilterChip('tired', '疲惫')
        this.buildFilterChip('angry', '生气')
        this.buildFilterChip('lonely', '孤单')
      }
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
    .backgroundColor(AppTheme.CARD)
    .border({ width: { bottom: 0.5 }, color: '#EEEEEE' })
  }

  @Builder
  buildFilterChip(key: string, label: string) {
    Text(label)
      .fontSize(12)
      .fontWeight(this.filterMood === key ? FontWeight.Bold : FontWeight.Medium)
      .fontColor(this.filterMood === key ? Color.White : '#666666')
      .padding({ left: 12, right: 12, top: 6, bottom: 6 })
      .backgroundColor(this.filterMood === key ? '#333333' : '#F0F0F0')
      .borderRadius(4)
      .animation({ duration: AppTheme.TAB_ENTER_MS, curve: Curve.Smooth })
      .onClick(() => {
        if (this.filterMood !== key) {
          this.onFilterChange(key)
        }
      })
  }
}
