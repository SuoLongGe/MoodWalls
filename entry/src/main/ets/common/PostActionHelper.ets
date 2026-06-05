import { promptAction } from '@kit.ArkUI'
import { NoteItem } from '../model/MoodWallTypes'

export class PostActionHelper {

  static showMenu(
    note: NoteItem,
    onDelete: () => void,
    onVisibilityChange: (visibility: string) => void
  ): void {
    const isPrivate: boolean = note.visibility === 'private'
    const visibilityLabel: string = isPrivate ? '恢复公开' : '仅自己可见'
    try {
      promptAction.showActionMenu({
        title: '帖子操作',
        buttons: [
          { text: visibilityLabel, color: '#31534A' },
          { text: '删除', color: '#E17272' }
        ]
      }).then((result) => {
        if (result.index === 0) {
          onVisibilityChange(isPrivate ? 'public' : 'private')
        } else if (result.index === 1) {
          onDelete()
        }
      }).catch((err: Error) => {
        console.error('showActionMenu failed: ' + err.message)
      })
    } catch (err) {
      console.error('showActionMenu failed: ' + JSON.stringify(err))
    }
  }
}
