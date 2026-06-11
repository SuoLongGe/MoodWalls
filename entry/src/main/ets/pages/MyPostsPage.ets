import { AppTheme } from '../common/AppTheme'
import { AuthTheme } from '../common/AuthTheme'
import { AuthSession } from '../common/AuthSession'
import { NoteHelper } from '../common/NoteHelper'
import { PostActionHelper } from '../common/PostActionHelper'
import { UiHelper } from '../common/UiHelper'
import { PageHeader } from '../components/PageHeader'
import { PostCard } from '../components/PostCard'
import { NoteItem } from '../model/MoodWallTypes'
import { PostSummary } from '../model/ProfileApiTypes'
import { PostApi } from '../service/PostApi'
import { ProfileApi } from '../service/ProfileApi'

@Entry
@Component
struct MyPostsPage {
  @State posts: Array<PostSummary> = []
  @State loading: boolean = true
  @State loadingMore: boolean = false
  @State page: number = 1
  @State hasMore: boolean = false
  @State refreshKey: number = 0
  @StorageLink('themeMode') themeMode: string = 'light'

  aboutToAppear(): void {
    if (!AuthSession.isLoggedIn()) {
      UiHelper.replaceTo('pages/Login')
      return
    }
    this.loadPosts(true)
  }

  loadPosts(reset: boolean): void {
    if (reset) {
      this.loading = true
      this.page = 1
    } else {
      if (!this.hasMore || this.loadingMore) {
        return
      }
      this.loadingMore = true
    }

    const requestPage: number = reset ? 1 : this.page
    ProfileApi.getMyPosts(requestPage, 20).then((result) => {
      if (reset) {
        this.posts = result.list
      } else {
        const merged: Array<PostSummary> = []
        this.posts.forEach((item: PostSummary) => merged.push(item))
        result.list.forEach((item: PostSummary) => merged.push(item))
        this.posts = merged
      }
      this.hasMore = result.hasMore
      this.page = result.page + 1
    }).catch((err: Error) => {
      UiHelper.showToast(err.message)
    }).finally(() => {
      this.loading = false
      this.loadingMore = false
    })
  }

  private toNoteItem(item: PostSummary): NoteItem {
    return NoteHelper.fromPostSummary(item, true)
  }

  private removePost(postId: number): void {
    const next: Array<PostSummary> = []
    this.posts.forEach((item: PostSummary) => {
      if (item.id !== postId) {
        next.push(item)
      }
    })
    this.posts = next
    this.refreshKey++
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
          this.removePost(noteId)
          UiHelper.markFeedNeedsRefresh()
          UiHelper.showToast('已删除')
        })
        .catch((err: Error) => {
          UiHelper.showToast(err.message || '删除失败，请稍后重试')
        })
    })
  }

  private patchPostVisibility(postId: number, visibility: string): void {
    const next: Array<PostSummary> = []
    this.posts.forEach((item: PostSummary) => {
      if (item.id === postId) {
        const updated: PostSummary = {
          id: item.id,
          userId: item.userId,
          nickname: item.nickname,
          mood: item.mood,
          moodLabel: item.moodLabel,
          text: item.text,
          location: item.location,
          zoneKey: item.zoneKey,
          likes: item.likes,
          liked: item.liked,
          color: item.color,
          createdAt: item.createdAt,
          timeText: item.timeText,
          avatarKey: item.avatarKey,
          isMine: item.isMine,
          commentCount: item.commentCount,
          visibility: visibility,
          canDelete: item.canDelete
        }
        next.push(updated)
      } else {
        next.push(item)
      }
    })
    this.posts = next
    this.refreshKey++
  }

  private handleVisibility(note: NoteItem, visibility: string): void {
    const token: string = AuthSession.getToken()
    if (token.length === 0) {
      UiHelper.showToast('请先登录')
      return
    }
    PostApi.updateVisibility(note.id, visibility, token)
      .then((updated) => {
        const vis: string = updated.visibility !== undefined ? updated.visibility : visibility
        this.patchPostVisibility(note.id, vis)
        UiHelper.markFeedNeedsRefresh()
        UiHelper.showToast(visibility === 'private' ? '已设为仅自己可见' : '已恢复公开')
      })
      .catch((err: Error) => {
        UiHelper.showToast(err.message || '操作失败，请稍后重试')
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
        title: '我的帖子',
        onBack: () => {
          UiHelper.goBack()
        }
      })

      if (this.loading) {
        Column() {
          LoadingProgress()
            .width(36)
            .height(36)
            .color(AuthTheme.PRIMARY)
          Text('加载中...')
            .fontSize(13)
            .fontColor('#6E7C79')
            .margin({ top: 12 })
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .width('100%')
      } else if (this.posts.length === 0) {
        Column({ space: 8 }) {
          Text('还没有帖子')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#31534A')
          Text('去发布页写下第一条心情吧')
            .fontSize(13)
            .fontColor('#6E7C79')
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .width('100%')
      } else {
        Scroll() {
          Column({ space: 12 }) {
            ForEach(this.posts, (item: PostSummary) => {
              PostCard({
                note: this.toNoteItem(item),
                onReact: () => {
                  UiHelper.showToast('请在心墙页表达心意')
                },
                onCancelReact: () => {},
                onSupport: () => {
                  UiHelper.showToast('请在心墙页使用接住心声')
                },
                onComment: (note: NoteItem) => {
                  UiHelper.pushToPostDetail(note.id)
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
            }, (item: PostSummary) => `${item.id}-${this.refreshKey}`)

            if (this.hasMore) {
              Row() {
                if (this.loadingMore) {
                  LoadingProgress()
                    .width(24)
                    .height(24)
                    .color(AuthTheme.PRIMARY)
                } else {
                  Text('加载更多')
                    .fontSize(13)
                    .fontColor(AuthTheme.PRIMARY)
                }
              }
              .width('100%')
              .justifyContent(FlexAlign.Center)
              .padding(16)
              .onClick(() => this.loadPosts(false))
            }
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 8, bottom: 24 })
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
