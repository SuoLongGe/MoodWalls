import { NoteItem } from '../model/MoodWallTypes'
import { PostSummary } from '../model/ProfileApiTypes'
import { AuthSession } from './AuthSession'

export class NoteHelper {

  static copy(src: NoteItem, likes?: number, liked?: boolean): NoteItem {
    const result: NoteItem = {
      id: src.id,
      userId: src.userId,
      nickname: src.nickname,
      mood: src.mood,
      moodLabel: src.moodLabel,
      text: src.text,
      location: src.location,
      zoneKey: src.zoneKey,
      timeText: src.timeText,
      likes: likes !== undefined ? likes : src.likes,
      liked: liked !== undefined ? liked : src.liked,
      color: src.color,
      createdAt: src.createdAt,
      avatarKey: src.avatarKey,
      isMine: src.isMine,
      commentCount: src.commentCount,
      visibility: src.visibility,
      canDelete: src.canDelete
    }
    return result
  }

  static fromPostSummary(item: PostSummary, forceMine: boolean = false): NoteItem {
    const result: NoteItem = {
      id: item.id,
      userId: item.userId,
      nickname: item.nickname,
      mood: item.mood,
      moodLabel: item.moodLabel,
      text: item.text,
      location: item.location,
      zoneKey: item.zoneKey,
      timeText: item.timeText,
      likes: item.likes,
      liked: item.liked,
      color: item.color,
      createdAt: item.createdAt,
      avatarKey: item.avatarKey !== undefined && item.avatarKey.length > 0
        ? item.avatarKey
        : AuthSession.getAvatarKey(),
      isMine: forceMine || item.isMine === true,
      commentCount: item.commentCount !== undefined ? item.commentCount : 0,
      visibility: item.visibility !== undefined && item.visibility.length > 0 ? item.visibility : 'public',
      canDelete: item.canDelete !== false
    }
    return result
  }
}
