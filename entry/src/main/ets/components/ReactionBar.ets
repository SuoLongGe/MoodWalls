import { AppTheme } from '../common/AppTheme'
import { findReactionOption, ReactionOption, REACTION_OPTIONS } from '../common/ReactionConfig'
import { NoteItem } from '../model/MoodWallTypes'

@Component
export struct ReactionBar {
  @Prop note: NoteItem
  @Prop inline: boolean = false
  @Prop showAllOptions: boolean = false
  onReact: (noteId: number, reactionType: string) => void = () => {}
  onCancelReact: (noteId: number) => void = () => {}

  private isSelected(type: string): boolean {
    return this.note.myReaction === type
  }

  private myReactionEmoji(): string {
    if (this.note.myReaction !== undefined && this.note.myReaction !== null &&
      this.note.myReaction.length > 0) {
      const option: ReactionOption | undefined = findReactionOption(this.note.myReaction)
      if (option !== undefined) {
        return option.emoji
      }
    }
    return '🤗'
  }

  private toggleReaction(optionType: string): void {
    if (this.isSelected(optionType)) {
      this.onCancelReact(this.note.id)
    } else {
      this.onReact(this.note.id, optionType)
    }
  }

  @Builder
  buildInlineEmoji(option: ReactionOption) {
    Text(option.emoji)
      .fontSize(18)
      .opacity(this.isSelected(option.type) ? 1 : 0.55)
      .fontWeight(this.isSelected(option.type) ? FontWeight.Bold : FontWeight.Normal)
      .onClick(() => {
        this.toggleReaction(option.type)
      })
  }

  @Builder
  buildReactionMenu() {
    Menu() {
      ForEach(REACTION_OPTIONS, (option: ReactionOption) => {
        MenuItem({
          content: `${option.emoji} ${option.label}`
        })
          .onClick(() => {
            this.toggleReaction(option.type)
          })
      }, (option: ReactionOption) => `menu-${option.type}`)
    }
  }

  @Builder
  buildInlineTrigger() {
    Text(this.myReactionEmoji())
      .fontSize(18)
      .fontColor(this.note.myReaction !== undefined && this.note.myReaction !== null &&
        this.note.myReaction.length > 0 ? AppTheme.PRIMARY : AppTheme.TEXT_HINT)
      .bindMenu(this.buildReactionMenu())
  }

  build() {
    if (this.inline) {
      Row({ space: 14 }) {
        if (this.showAllOptions) {
          ForEach(REACTION_OPTIONS, (option: ReactionOption) => {
            this.buildInlineEmoji(option)
          }, (option: ReactionOption) => option.type)
        } else {
          this.buildInlineTrigger()
        }
      }
    } else {
      Scroll() {
        Row({ space: 8 }) {
          ForEach(REACTION_OPTIONS, (option: ReactionOption) => {
            Text(option.emoji)
              .fontSize(16)
              .opacity(this.isSelected(option.type) ? 1 : 0.55)
              .padding({ left: 4, right: 4, top: 4, bottom: 4 })
              .onClick(() => {
                this.toggleReaction(option.type)
              })
          }, (option: ReactionOption) => option.type)
        }
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
    }
  }
}
