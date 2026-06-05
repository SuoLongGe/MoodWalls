import { AppTheme } from '../common/AppTheme'
import { NoteItem } from '../model/MoodWallTypes'
import { getAvatarResource } from '../common/AvatarResources'
import { AuthSession } from '../common/AuthSession'

@Component
export struct PostCard {
  @Prop note: NoteItem
  onLike: (noteId: number) => void = () => {}
  onSupport: (note: NoteItem) => void = () => {}
  onComment: (note: NoteItem) => void = () => {}
  onMore: (note: NoteItem) => void = () => {}
  onLongPress: (note: NoteItem) => void = () => {}
  onOpen: (note: NoteItem) => void = () => {}

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

  build() {
    Stack({ alignContent: Alignment.TopEnd }) {
      Column({ space: 10 }) {
        Column({ space: 10 }) {
          this.buildHeader()
          if (this.note.location.length > 0) {
            this.buildLocation()
          }
          this.buildBody()
        }
        .width('100%')
        .onClick(() => {
          this.onOpen(this.note)
        })

        this.buildActionBar()
      }
      .width('100%')
      .padding({
        left: this.isMine() ? 13 : 16,
        right: 16,
        top: 14,
        bottom: 14
      })
      .backgroundColor(this.isMine() ? AppTheme.CARD_MINE : AppTheme.CARD)
      .borderRadius(AppTheme.RADIUS_MD)
      .border({
        width: { left: this.isMine() ? 3 : 1, top: 1, right: 1, bottom: 1 },
        color: this.isMine() ? AppTheme.ACCENT : AppTheme.OUTLINE
      })
      .shadow({
        radius: 14,
        color: AppTheme.SHADOW,
        offsetX: 0,
        offsetY: 4
      })
      .gesture(
        LongPressGesture({ repeat: false })
          .onAction(() => {
            if (this.isMine()) {
              this.onLongPress(this.note)
            }
          })
      )

      if (this.isMine()) {
        Text('···')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppTheme.PRIMARY)
          .width(36)
          .height(36)
          .textAlign(TextAlign.Center)
          .margin({ top: 6, right: 8 })
          .onClick(() => {
            this.onMore(this.note)
          })
      }
    }
    .width('100%')
    .alignContent(Alignment.TopEnd)
  }

  @Builder
  buildHeader() {
    Row({ space: 10 }) {
      Image(getAvatarResource(this.avatarKey()))
        .width(36)
        .height(36)
        .borderRadius(18)
        .objectFit(ImageFit.Cover)

      Column({ space: 4 }) {
        Row({ space: 6 }) {
          Text(this.displayName())
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppTheme.TEXT_TITLE)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        Row({ space: 8 }) {
          Text(this.note.timeText)
            .fontSize(11)
            .fontColor('#95A19F')
          Text(this.note.moodLabel)
            .fontSize(11)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.note.color)
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
  }

  @Builder
  buildLocation() {
    Text(`📍 ${this.note.location}`)
      .fontSize(12)
      .fontColor('#7C8A87')
      .width('100%')
  }

  @Builder
  buildBody() {
    Text(this.note.text)
      .fontSize(15)
      .lineHeight(22)
      .fontColor(AppTheme.TEXT_TITLE)
      .width('100%')
  }

  @Builder
  buildActionBar() {
    Row() {
      this.buildLikeAction()
      this.buildCommentAction()
      this.buildSupportAction()
    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceBetween)
    .padding({ top: 4 })
  }

  @Builder
  buildLikeAction() {
    Row({ space: 4 }) {
      Text(this.note.liked === true ? '❤' : '🤍')
        .fontSize(16)
        .fontColor(this.note.liked === true ? AppTheme.LIKE : AppTheme.TEXT_MUTED)
      Text(`${this.note.likes}`)
        .fontSize(12)
        .fontColor(this.note.liked === true ? AppTheme.LIKE : AppTheme.TEXT_HINT)
    }
    .padding({ left: 10, right: 10, top: 8, bottom: 8 })
    .backgroundColor(this.note.liked === true ? '#FFF0F0' : AppTheme.SURFACE)
    .borderRadius(AppTheme.RADIUS_MD)
    .onClick(() => {
      this.onLike(this.note.id)
    })
  }

  @Builder
  buildCommentAction() {
    Row({ space: 4 }) {
      Text('💬')
        .fontSize(16)
      Text(`${this.commentCount()}`)
        .fontSize(12)
        .fontColor('#7D8A88')
    }
    .padding({ left: 10, right: 10, top: 8, bottom: 8 })
    .backgroundColor(AppTheme.SURFACE)
    .borderRadius(AppTheme.RADIUS_MD)
    .onClick(() => {
      this.onComment(this.note)
    })
  }

  @Builder
  buildSupportAction() {
    Row({ space: 4 }) {
      Text('🤝')
        .fontSize(16)
      Text('接住')
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppTheme.PRIMARY)
    }
    .padding({ left: 12, right: 12, top: 8, bottom: 8 })
    .backgroundColor('#F3F8F6')
    .borderRadius(AppTheme.RADIUS_MD)
    .onClick(() => {
      this.onSupport(this.note)
    })
  }
}
