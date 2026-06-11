import { router } from '@kit.ArkUI'
import { AppTheme } from '../common/AppTheme'
import { AuthSession } from '../common/AuthSession'
import { UserAvatar } from '../components/UserAvatar'
import { NoteHelper } from '../common/NoteHelper'
import { PostActionHelper } from '../common/PostActionHelper'
import { UiHelper } from '../common/UiHelper'
import { PageHeader } from '../components/PageHeader'
import { PostCard } from '../components/PostCard'
import {
  CommentItem,
  CommentReplyItem,
  CreateCommentBody,
  NoteItem,
  ReactionResponse
} from '../model/MoodWallTypes'
import { CommentApi } from '../service/CommentApi'
import { MoodApi } from '../service/MoodApi'
import { PostApi } from '../service/PostApi'

interface ReplyTarget {
  parentId: number
  replyToUserId: number
  nickname: string
}

@Entry
@Component
struct PostDetailPage {
  @State postId: number = 0
  @State post: NoteItem | null = null
  @State comments: Array<CommentItem> = []
  @State loading: boolean = true
  @State sending: boolean = false
  @State draftText: string = ''
  @State replyTarget: ReplyTarget | null = null
  @State commentTotal: number = 0
  @State whisperCount: number = 0
  @State commentMode: string = 'resonance'
  @State listRefreshKey: number = 0
  @State pendingCommentScroll: boolean = false
  @StorageLink('themeMode') themeMode: string = 'light'
  private scroller: Scroller = new Scroller()
  private focusComments: boolean = false

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, Object>
    const rawId: Object | undefined = params['postId']
    if (rawId !== undefined) {
      if (typeof rawId === 'number') {
        this.postId = rawId
      } else {
        const parsed: number = parseInt(`${rawId}`, 10)
        this.postId = Number.isNaN(parsed) ? 0 : parsed
      }
    }
    const rawScroll: Object | undefined = params['scrollToComments']
    if (rawScroll === true || rawScroll === 1 || rawScroll === 'true') {
      this.focusComments = true
    }
    if (this.postId <= 0) {
      UiHelper.showToast('帖子不存在')
      UiHelper.goBack()
      return
    }
    this.loadPageData()
  }

  loadPageData(): void {
    this.loading = true
    const token: string = AuthSession.getToken()
    PostApi.getPostDetail(this.postId, token.length > 0 ? token : undefined)
      .then((detail) => {
        this.post = detail
        return CommentApi.getComments(this.postId, 1, 50, token.length > 0 ? token : undefined)
      })
      .then((res) => {
        this.comments = res.list
        this.commentTotal = res.total
        this.whisperCount = res.whisperCount !== undefined ? res.whisperCount : 0
        if (this.post !== null) {
          const nextPost: NoteItem = NoteHelper.copy(this.post, this.post.likes, this.post.liked)
          nextPost.commentCount = res.total
          this.post = nextPost
        }
      })
      .catch((err: Error) => {
        UiHelper.showToast(err.message || '加载失败')
      })
      .finally(() => {
        this.loading = false
        if (this.focusComments) {
          this.pendingCommentScroll = true
        } else {
          this.scroller.scrollTo({ xOffset: 0, yOffset: 0 })
        }
      })
  }

  private tryScrollToComments(yOffset: number): void {
    if (!this.pendingCommentScroll || yOffset <= 0) {
      return
    }
    this.scroller.scrollTo({
      xOffset: 0,
      yOffset: Math.max(0, yOffset - 8),
      animation: {
        duration: 280,
        curve: Curve.EaseOut
      }
    })
    this.pendingCommentScroll = false
  }

  private handleReact(noteId: number, reactionType: string): void {
    const token: string = AuthSession.getToken()
    if (token.length === 0) {
      UiHelper.showToast('请先登录后再表达心意')
      return
    }
    if (this.post === null || this.post.id !== noteId) {
      return
    }
    PostApi.reactPost(noteId, reactionType, token)
      .then((res: ReactionResponse) => {
        if (this.post !== null) {
          this.post = NoteHelper.applyReaction(this.post, res)
          UiHelper.markFeedNeedsRefresh()
        }
      })
      .catch((err: Error) => {
        UiHelper.showToast(err.message || '操作失败')
      })
  }

  private handleCancelReact(noteId: number): void {
    const token: string = AuthSession.getToken()
    if (token.length === 0) {
      UiHelper.showToast('请先登录')
      return
    }
    if (this.post === null || this.post.id !== noteId) {
      return
    }
    PostApi.cancelReact(noteId, token)
      .then((res: ReactionResponse) => {
        if (this.post !== null) {
          this.post = NoteHelper.applyReaction(this.post, res)
          UiHelper.markFeedNeedsRefresh()
        }
      })
      .catch((err: Error) => {
        UiHelper.showToast(err.message || '操作失败')
      })
  }

  private isPostAuthor(): boolean {
    return this.post !== null && this.post.isMine === true
  }

  private isWhisperComment(item: CommentItem | CommentReplyItem): boolean {
    return item.commentType === 'whisper'
  }

  private switchCommentMode(mode: string): void {
    this.commentMode = mode
    if (mode === 'whisper') {
      this.replyTarget = null
    }
  }

  private handleSupport(note: NoteItem): void {
    const token: string = AuthSession.getToken()
    if (token.length === 0) {
      UiHelper.showToast('请先登录')
      return
    }
    MoodApi.supportPost(note.id, token)
      .then((res) => {
        UiHelper.showToast(res.response.length > 40 ? '已收到温暖回信' : res.response)
      })
      .catch((err: Error) => {
        UiHelper.showToast(err.message || '接住心声失败')
      })
  }

  private startReply(parentId: number, replyToUserId: number, nickname: string): void {
    const target: ReplyTarget = {
      parentId: parentId,
      replyToUserId: replyToUserId,
      nickname: nickname
    }
    this.replyTarget = target
  }

  private cancelReply(): void {
    this.replyTarget = null
  }

  private sendComment(): void {
    const content: string = this.draftText.trim()
    if (content.length === 0) {
      UiHelper.showToast('请输入评论内容')
      return
    }
    const token: string = AuthSession.getToken()
    if (token.length === 0) {
      UiHelper.showToast('请先登录后再评论')
      return
    }

    const body: CreateCommentBody = {
      content: content,
      commentType: this.commentMode
    }
    if (this.replyTarget !== null) {
      body.parentId = this.replyTarget.parentId
      body.replyToUserId = this.replyTarget.replyToUserId
    }

    this.sending = true
    CommentApi.createComment(this.postId, body, token)
      .then(() => {
        this.draftText = ''
        this.replyTarget = null
        UiHelper.showToast(this.commentMode === 'whisper' ? '悄悄话已送达' : '评论成功')
        UiHelper.markFeedNeedsRefresh()
        return CommentApi.getComments(this.postId, 1, 50, token)
      })
      .then((res) => {
        this.comments = res.list
        this.commentTotal = res.total
        this.whisperCount = res.whisperCount !== undefined ? res.whisperCount : 0
        this.listRefreshKey++
        if (this.post !== null) {
          const nextPost: NoteItem = NoteHelper.copy(this.post)
          nextPost.commentCount = res.total
          nextPost.whisperCount = this.whisperCount
          this.post = nextPost
        }
      })
      .catch((err: Error) => {
        UiHelper.showToast(err.message || '评论失败')
      })
      .finally(() => {
        this.sending = false
      })
  }

  private handleDeletePost(): void {
    const token: string = AuthSession.getToken()
    if (token.length === 0) {
      UiHelper.showToast('请先登录')
      return
    }
    UiHelper.showConfirmDialog('删除帖子', '删除后无法恢复，确定吗？', () => {
      PostApi.deletePost(this.postId, token)
        .then(() => {
          UiHelper.markFeedNeedsRefresh()
          UiHelper.showToast('已删除')
          UiHelper.goBack()
        })
        .catch((err: Error) => {
          UiHelper.showToast(err.message || '删除失败')
        })
    })
  }

  private handleVisibilityChange(visibility: string): void {
    const token: string = AuthSession.getToken()
    if (token.length === 0) {
      UiHelper.showToast('请先登录')
      return
    }
    PostApi.updateVisibility(this.postId, visibility, token)
      .then((updated) => {
        if (this.post !== null) {
          const nextPost: NoteItem = NoteHelper.copy(updated)
          this.post = nextPost
        }
        UiHelper.markFeedNeedsRefresh()
        UiHelper.showToast(visibility === 'private' ? '已设为仅自己可见' : '已恢复公开')
      })
      .catch((err: Error) => {
        UiHelper.showToast(err.message || '操作失败')
      })
  }

  private showPostActions(note: NoteItem): void {
    PostActionHelper.showMenu(
      note,
      () => {
        this.handleDeletePost()
      },
      (visibility: string) => {
        this.handleVisibilityChange(visibility)
      }
    )
  }

  private deleteComment(commentId: number, parentId: number | null): void {
    const token: string = AuthSession.getToken()
    if (token.length === 0) {
      UiHelper.showToast('请先登录')
      return
    }
    UiHelper.showConfirmDialog('删除评论', '确定删除这条评论吗？', () => {
      CommentApi.deleteComment(this.postId, commentId, token)
        .then(() => {
          UiHelper.showToast('已删除')
          UiHelper.markFeedNeedsRefresh()
          return CommentApi.getComments(this.postId, 1, 50, token)
        })
        .then((res) => {
          this.comments = res.list
          this.commentTotal = res.total
          this.whisperCount = res.whisperCount !== undefined ? res.whisperCount : 0
          this.listRefreshKey++
          if (this.post !== null) {
            const nextPost: NoteItem = NoteHelper.copy(this.post)
            nextPost.commentCount = res.total
            nextPost.whisperCount = this.whisperCount
            this.post = nextPost
          }
        })
        .catch((err: Error) => {
          UiHelper.showToast(err.message || '删除失败')
        })
    })
  }

  @Builder
  buildCommentModeChip(mode: string, label: string) {
    Text(label)
      .fontSize(12)
      .fontWeight(this.commentMode === mode ? FontWeight.Bold : FontWeight.Normal)
      .fontColor(this.commentMode === mode ? '#31534A' : '#7C8A87')
      .padding({ left: 12, right: 12, top: 6, bottom: 6 })
      .backgroundColor(this.commentMode === mode ? '#EAF4F0' : '#FFFFFF')
      .borderRadius(14)
      .border({
        width: 1,
        color: this.commentMode === mode ? '#31534A' : '#E2E8E6'
      })
      .onClick(() => this.switchCommentMode(mode))
  }

  @Builder
  buildCommentRow(item: CommentItem) {
    Column({ space: 8 }) {
      Row({ space: 10 }) {
        UserAvatar({
          avatarKey: item.authorAvatarKey !== undefined ? item.authorAvatarKey : 'avatar_01',
          avatarUrl: item.authorAvatarUrl !== undefined ? item.authorAvatarUrl : '',
          avatarSize: 32
        })

        Column({ space: 4 }) {
          Row() {
            if (this.isWhisperComment(item)) {
              Text('🔒')
                .fontSize(12)
            }
            Text(item.authorNickname)
              .fontSize(13)
              .fontWeight(FontWeight.Bold)
              .fontColor('#25332F')
              .layoutWeight(1)
            if (this.isWhisperComment(item)) {
              Text('悄悄话')
                .fontSize(10)
                .fontColor('#C9A227')
                .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                .backgroundColor('#FFF0C2')
            }
            Text(item.timeText)
              .fontSize(11)
              .fontColor('#95A19F')
          }
          .width('100%')

          Text(item.content)
            .fontSize(14)
            .lineHeight(20)
            .fontColor('#3A4744')
            .width('100%')

          Row({ space: 16 }) {
            if (!this.isWhisperComment(item)) {
              Text('回复')
                .fontSize(12)
                .fontColor('#31534A')
                .onClick(() => {
                  this.startReply(item.id, item.userId, item.authorNickname)
                })
            }
            if (item.canDelete === true) {
              Text('删除')
                .fontSize(12)
                .fontColor('#E17272')
                .onClick(() => {
                  this.deleteComment(item.id, null)
                })
            }
          }
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)

      if (item.replies.length > 0) {
        Column({ space: 10 }) {
          ForEach(item.replies, (reply: CommentReplyItem) => {
            this.buildReplyRow(item.id, reply)
          }, (reply: CommentReplyItem) => `${reply.id}-${this.listRefreshKey}`)
        }
        .width('100%')
        .padding({ left: 42 })
      }
    }
    .width('100%')
    .padding({
      left: 16,
      right: 16,
      top: 12,
      bottom: 12
    })
    .backgroundColor(this.isWhisperComment(item) ? '#F5F0FF' : AppTheme.CARD)
  }

  @Builder
  buildReplyRow(parentId: number, reply: CommentReplyItem) {
    Row({ space: 8 }) {
      UserAvatar({
        avatarKey: reply.authorAvatarKey !== undefined ? reply.authorAvatarKey : 'avatar_01',
        avatarUrl: reply.authorAvatarUrl !== undefined ? reply.authorAvatarUrl : '',
        avatarSize: 26
      })

      Column({ space: 4 }) {
        Row() {
          Text(reply.authorNickname)
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor('#25332F')
          if (reply.replyToNickname !== undefined && reply.replyToNickname.length > 0) {
            Text(` 回复 @${reply.replyToNickname}`)
              .fontSize(12)
              .fontColor('#7C8A87')
          }
          Blank()
          Text(reply.timeText)
            .fontSize(10)
            .fontColor('#95A19F')
        }
        .width('100%')

        Text(reply.content)
          .fontSize(13)
          .lineHeight(18)
          .fontColor('#3A4744')
          .width('100%')

        Row({ space: 16 }) {
          Text('回复')
            .fontSize(11)
            .fontColor('#31534A')
            .onClick(() => {
              this.startReply(parentId, reply.userId, reply.authorNickname)
            })
          if (reply.canDelete === true) {
            Text('删除')
              .fontSize(11)
              .fontColor('#E17272')
              .onClick(() => {
                this.deleteComment(reply.id, parentId)
              })
          }
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
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
        title: '帖子详情',
        onBack: () => {
          UiHelper.goBack()
        }
      })

      if (this.loading) {
        Column() {
          LoadingProgress()
            .width(36)
            .height(36)
            .color('#31534A')
          Text('加载中...')
            .fontSize(13)
            .fontColor('#6E7C79')
            .margin({ top: 12 })
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .width('100%')
      } else if (this.post === null) {
        Column() {
          Text('帖子不存在或已删除')
            .fontSize(15)
            .fontColor('#6E7C79')
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .width('100%')
      } else {
        Scroll(this.scroller) {
          Column({ space: 0 }) {
            PostCard({
              note: this.post,
              onReact: (noteId: number, reactionType: string) => {
                this.handleReact(noteId, reactionType)
              },
              onCancelReact: (noteId: number) => {
                this.handleCancelReact(noteId)
              },
              onSupport: (note: NoteItem) => {
                this.handleSupport(note)
              },
              onComment: () => {},
              onMore: (note: NoteItem) => {
                this.showPostActions(note)
              },
              onLongPress: (note: NoteItem) => {
                this.showPostActions(note)
              },
              onOpen: () => {}
            })

            Row()
              .width('100%')
              .height(8)
              .backgroundColor('#F4F4F4')

            if (this.isPostAuthor() && this.whisperCount > 0) {
              Row() {
                Text(`🔒 收到了 ${this.whisperCount} 条悄悄话`)
                  .fontSize(13)
                  .fontColor('#8B7AD6')
              }
              .width('100%')
              .padding({ left: 16, right: 16, top: 12, bottom: 12 })
              .backgroundColor('#F5F0FF')
            }

            Row() {
              Text(`评论 ${this.commentTotal}`)
                .fontSize(15)
                .fontWeight(FontWeight.Bold)
                .fontColor('#25332F')
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 12, bottom: 8 })
            .backgroundColor(AppTheme.CARD)
            .onAreaChange((_oldValue: Area, newValue: Area) => {
              const y: number = newValue.position.y as number
              this.tryScrollToComments(y)
            })

            if (this.comments.length === 0) {
              Text('还没有评论，来写下第一条共鸣吧')
                .fontSize(13)
                .fontColor('#95A19F')
                .width('100%')
                .textAlign(TextAlign.Center)
                .padding({ top: 20, bottom: 20 })
            } else {
              Column({ space: 0 }) {
                ForEach(this.comments, (item: CommentItem) => {
                  Column({ space: 0 }) {
                    this.buildCommentRow(item)
                    Row()
                      .width('100%')
                      .height(8)
                      .backgroundColor('#F4F4F4')
                  }
                }, (item: CommentItem) => `${item.id}-${this.listRefreshKey}`)
              }
              .width('100%')
              .padding({ bottom: 8 })
            }
          }
          .width('100%')
          .padding({ bottom: 16 })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .align(Alignment.Top)

        Column({ space: 8 }) {
          if (!this.isPostAuthor()) {
            Row({ space: 8 }) {
              this.buildCommentModeChip('resonance', '公开共鸣')
              this.buildCommentModeChip('whisper', '悄悄话')
            }
            .width('100%')
          }

          if (this.replyTarget !== null) {
            Row() {
              Text(`回复 @${this.replyTarget.nickname}`)
                .fontSize(12)
                .fontColor('#31534A')
                .layoutWeight(1)
              Text('取消')
                .fontSize(12)
                .fontColor('#7C8A87')
                .onClick(() => this.cancelReply())
            }
            .width('100%')
          }

          Row({ space: 10 }) {
            TextArea({
              placeholder: this.commentMode === 'whisper'
                ? '这句话只有 TA 能看到，像轻轻拍了一下肩膀。'
                : '写下你的共鸣...',
              text: this.draftText
            })
              .layoutWeight(1)
              .height(40)
              .fontSize(14)
              .backgroundColor('#FFFFFF')
              .borderRadius(4)
              .padding({ top: 8, bottom: 8 })
              .onChange((value: string) => {
                this.draftText = value
              })

            Button(this.sending ? '发送中' : '发送')
              .fontSize(13)
              .fontColor(Color.White)
              .backgroundColor('#31534A')
              .borderRadius(4)
              .width(64)
              .height(40)
              .enabled(!this.sending)
              .onClick(() => this.sendComment())
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 10, bottom: 16 })
        .backgroundColor(AppTheme.BG)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppTheme.BG)
  }
}
