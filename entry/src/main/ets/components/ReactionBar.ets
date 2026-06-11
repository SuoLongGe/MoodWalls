import { AppTheme } from '../common/AppTheme'
import { findReactionOption, ReactionOption, REACTION_OPTIONS } from '../common/ReactionConfig'
import { NoteItem, TopReactionItem } from '../model/MoodWallTypes'

@Component
export struct ReactionBar {
  @Prop note: NoteItem
  @Prop compact: boolean = false
  onReact: (noteId: number, reactionType: string) => void = () => {}
  onCancelReact: (noteId: number) => void = () => {}

  private isSelected(type: string): boolean {
    return this.note.myReaction === type
  }

  private reactionCount(type: string): number {
    if (this.note.reactionStats !== undefined && this.note.reactionStats[type] !== undefined) {
      return this.note.reactionStats[type]
    }
    return 0
  }

  private countText(type: string): string {
    const count: number = this.reactionCount(type)
    if (count <= 0) {
      return ''
    }
    return `${count}`
  }

  @Builder
  buildReactionChip(optionType: string, emoji: string, label: string) {
    Row({ space: 3 }) {
      Text(emoji)
        .fontSize(this.compact ? 14 : 15)
      if (!this.compact || this.countText(optionType).length > 0) {
        Text(this.compact ? this.countText(optionType) : label)
          .fontSize(11)
          .fontWeight(this.isSelected(optionType) ? FontWeight.Bold : FontWeight.Normal)
          .fontColor(this.isSelected(optionType) ? AppTheme.PRIMARY : AppTheme.TEXT_HINT)
      }
    }
    .padding({
      left: this.compact ? 8 : 10,
      right: this.compact ? 8 : 10,
      top: 6,
      bottom: 6
    })
    .backgroundColor(this.isSelected(optionType) ? '#EAF4F0' : AppTheme.SURFACE)
    .borderRadius(AppTheme.RADIUS_MD)
    .border({
      width: this.isSelected(optionType) ? 1 : 0,
      color: AppTheme.PRIMARY
    })
    .onClick(() => {
      if (this.isSelected(optionType)) {
        this.onCancelReact(this.note.id)
      } else {
        this.onReact(this.note.id, optionType)
      }
    })
  }

  build() {
    if (this.compact) {
      Row({ space: 6 }) {
        if (this.note.topReactions !== undefined && this.note.topReactions.length > 0) {
          ForEach(this.note.topReactions, (item: TopReactionItem) => {
            Row({ space: 2 }) {
              Text(findReactionOption(item.type)?.emoji ?? '💬')
                .fontSize(13)
              Text(`${item.count}`)
                .fontSize(11)
                .fontColor(AppTheme.TEXT_HINT)
            }
          }, (item: TopReactionItem) => `top-${item.type}`)
        }
        Text(this.note.totalReactions !== undefined && this.note.totalReactions > 0
          ? `心意 ${this.note.totalReactions}`
          : '表达心意')
          .fontSize(11)
          .fontColor(AppTheme.PRIMARY)
          .fontWeight(FontWeight.Bold)
          .padding({ left: 8, right: 8, top: 6, bottom: 6 })
          .backgroundColor('#F3F8F6')
          .borderRadius(AppTheme.RADIUS_MD)
          .bindMenu(this.buildReactionMenu())
      }
      .width('100%')
    } else {
      Scroll() {
        Row({ space: 8 }) {
          ForEach(REACTION_OPTIONS, (option: ReactionOption) => {
            this.buildReactionChip(option.type, option.emoji, option.label)
          }, (option: ReactionOption) => option.type)
        }
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')
    }
  }

  @Builder
  buildReactionMenu() {
    Menu() {
      ForEach(REACTION_OPTIONS, (option: ReactionOption) => {
        MenuItem({
          content: `${option.emoji} ${option.label}${this.countText(option.type).length > 0 ? ' ' + this.countText(option.type) : ''}`
        })
          .onClick(() => {
            if (this.isSelected(option.type)) {
              this.onCancelReact(this.note.id)
            } else {
              this.onReact(this.note.id, option.type)
            }
          })
      }, (option: ReactionOption) => `menu-${option.type}`)
    }
  }
}
