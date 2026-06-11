import { AppTheme } from '../common/AppTheme'
import { CloudGiftThrottle } from '../common/CloudGiftThrottle'
import { UiHelper } from '../common/UiHelper'
import { NoteItem } from '../model/MoodWallTypes'
import { getAvatarResource } from '../common/AvatarResources'
import { AuthSession } from '../common/AuthSession'
import { PostApi } from '../service/PostApi'
import { SunGiftAnimation } from './SunGiftAnimation'
import { ReactionBar } from './ReactionBar'

@Component
export struct PostCard {
  @Prop note: NoteItem
  @Prop reactionExpanded: boolean = false
  onReact: (noteId: number, reactionType: string) => void = () => {}
  onCancelReact: (noteId: number) => void = () => {}
  onSupport: (note: NoteItem) => void = () => {}
  onComment: (note: NoteItem) => void = () => {}
  onMore: (note: NoteItem) => void = () => {}
  onLongPress: (note: NoteItem) => void = () => {}
  onOpen: (note: NoteItem) => void = () => {}
  @State sunVisible: boolean = false
  @State sunSending: boolean = false

  private isMine(): boolean {
    if (this.note.isMine === true || this.note.canDelete === true) {
      return true
    }
    const currentUserId: number = AuthSession.getUserId()
    if (currentUserId <= 0 || this.note.userId === undefined) {
      return false
    }
    const postUserId: number = typeof this.note.userId === 'number'
      ? this.note.userId
      : parseInt(`${this.note.userId}`, 10)
    return !Number.isNaN(postUserId) && postUserId === currentUserId
  }

  private displayName(): string {
    if (this.isMine()) {
      return '我'
    }
    if (this.note.nickname !== undefined && this.note.nickname.length > 0) {
      return this.note.nickname
    }
    return '匿名用户'
  }

  private avatarKey(): string {
    if (this.note.avatarKey !== undefined && this.note.avatarKey.length > 0) {
      return this.note.avatarKey
    }
    return 'avatar_01'
  }

  private commentCount(): number {
    return this.note.commentCount !== undefined ? this.note.commentCount : 0
  }

  private cloudCount(): number {
    return this.note.cloudCount !== undefined ? this.note.cloudCount : 0
  }

  private trySendCloud(): void {
    if (this.isMine() || this.sunVisible || this.sunSending) {
      return
    }
    if (!CloudGiftThrottle.canSend(this.note.id)) {
      UiHelper.showToast('稍后再送吧')
      return
    }
    const token: string = AuthSession.getToken()
    if (token.length === 0) {
      UiHelper.showToast('请先登录')
      return
    }
    this.sunSending = true
    PostApi.sendCloud(this.note.id, token)
      .then(() => {
        CloudGiftThrottle.markSent(this.note.id)
        this.sunVisible = true
        UiHelper.showToast('一个小太阳送给了 TA')
      })
      .catch((err: Error) => {
        UiHelper.showToast(err.message || '赠送失败，请稍后重试')
      })
      .finally(() => {
        this.sunSending = false
      })
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Column({ space: 0 }) {
        Column({ space: 8 }) {
          this.buildHeader()
          this.buildBody()
          if (this.note.location.length > 0) {
            this.buildLocation()
          }
          if (this.isMine() && this.cloudCount() > 0) {
            this.buildSunReceivedHint()
          }
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 8 })
        .onClick(() => {
          this.onOpen(this.note)
        })
        .gesture(
          LongPressGesture({ repeat: false })
            .onAction(() => {
              if (this.isMine()) {
                this.onLongPress(this.note)
              } else {
                this.trySendCloud()
              }
            }),
          GestureMask.IgnoreInternal
        )

        this.buildActionBar()
      }
      .width('100%')
      .backgroundColor(AppTheme.CARD)

      if (this.sunVisible) {
        SunGiftAnimation({
          onFinish: () => {
            this.sunVisible = false
          }
        })
      }
    }
    .width('100%')
  }

  @Builder
  buildHeader() {
    Row({ space: 10 }) {
      Image(getAvatarResource(this.avatarKey()))
        .width(40)
        .height(40)
        .borderRadius(20)
        .objectFit(ImageFit.Cover)

      Column({ space: 3 }) {
        Row({ space: 6 }) {
          Text(this.displayName())
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppTheme.TEXT_TITLE)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text(this.note.moodLabel)
            .fontSize(10)
            .fontColor('#6CB1F0')
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .backgroundColor('#F0F7FF')

          if (this.isMine()) {
            Text('我的')
              .fontSize(10)
              .fontColor('#73C088')
              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
              .backgroundColor('#F0FAF3')
          }
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        Text(`${this.note.timeText} · 心墙`)
          .fontSize(11)
          .fontColor('#999999')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      if (this.isMine()) {
        Text('···')
          .fontSize(18)
          .fontColor('#BBBBBB')
          .width(28)
          .height(28)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            this.onMore(this.note)
          })
      }
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
  }

  @Builder
  buildLocation() {
    Text(this.note.location)
      .fontSize(12)
      .fontColor('#999999')
      .width('100%')
  }

  @Builder
  buildBody() {
    Text(this.note.text)
      .fontSize(16)
      .lineHeight(24)
      .fontColor(AppTheme.TEXT_TITLE)
      .width('100%')
  }

  @Builder
  buildSunReceivedHint() {
    Text(`☀️ 收到 ${this.cloudCount()} 个小太阳`)
      .fontSize(12)
      .fontColor('#E8A317')
      .width('100%')
  }

  @Builder
  buildActionBar() {
    Row() {
      Blank()
      Row({ space: 18 }) {
        ReactionBar({
          note: this.note,
          inline: true,
          showAllOptions: this.reactionExpanded,
          onReact: (noteId: number, reactionType: string) => {
            this.onReact(noteId, reactionType)
          },
          onCancelReact: (noteId: number) => {
            this.onCancelReact(noteId)
          }
        })
        this.buildCommentAction()
        this.buildSupportAction()
      }
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 4, bottom: 12 })
  }

  @Builder
  buildCommentAction() {
    Row({ space: 4 }) {
      Text('💬')
        .fontSize(17)
        .fontColor('#999999')
      if (this.commentCount() > 0) {
        Text(`${this.commentCount()}`)
          .fontSize(12)
          .fontColor('#999999')
      }
    }
    .onClick(() => {
      this.onComment(this.note)
    })
  }

  @Builder
  buildSupportAction() {
    Text('接住')
      .fontSize(13)
      .fontColor(AppTheme.PRIMARY)
      .onClick(() => {
        this.onSupport(this.note)
      })
  }
}
