import { NoteItem, ReactionResponse, TopReactionItem } from '../model/MoodWallTypes'
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
      imageUrl: src.imageUrl,
      location: src.location,
      zoneKey: src.zoneKey,
      timeText: src.timeText,
      likes: likes !== undefined ? likes : src.likes,
      liked: liked !== undefined ? liked : src.liked,
      color: src.color,
      createdAt: src.createdAt,
      avatarKey: src.avatarKey,
      avatarUrl: src.avatarUrl,
      isMine: src.isMine,
      commentCount: src.commentCount,
      visibility: src.visibility,
      canDelete: src.canDelete,
      totalReactions: src.totalReactions,
      myReaction: src.myReaction,
      topReactions: src.topReactions,
      reactionStats: src.reactionStats,
      whisperCount: src.whisperCount,
      cloudCount: src.cloudCount
    }
    return result
  }

  static applyReaction(src: NoteItem, reaction: ReactionResponse): NoteItem {
    const result: NoteItem = NoteHelper.copy(src)
    result.totalReactions = reaction.totalReactions
    result.myReaction = reaction.myReaction
    result.reactionStats = reaction.reactionStats
    result.topReactions = reaction.topReactions
    return result
  }

  static fromPostSummary(item: PostSummary, forceMine: boolean = false): NoteItem {
    const result: NoteItem = {
      id: item.id,
      userId: item.userId,
      nickname: item.nickname !== undefined && item.nickname !== null ? item.nickname : '',
      mood: item.mood !== undefined && item.mood !== null ? item.mood : 'calm',
      moodLabel: item.moodLabel !== undefined && item.moodLabel !== null ? item.moodLabel : '',
      text: item.text !== undefined && item.text !== null ? item.text : '',
      location: item.location !== undefined && item.location !== null ? item.location : '',
      zoneKey: item.zoneKey !== undefined && item.zoneKey !== null ? item.zoneKey : '',
      timeText: item.timeText !== undefined && item.timeText !== null ? item.timeText : '',
      likes: item.likes,
      liked: item.liked,
      color: item.color !== undefined && item.color !== null ? item.color : '#E8ECEB',
      createdAt: item.createdAt !== undefined && item.createdAt !== null ? item.createdAt : '',
      avatarKey: item.avatarKey !== undefined && item.avatarKey !== null && item.avatarKey.length > 0
        ? item.avatarKey
        : AuthSession.getAvatarKey(),
      avatarUrl: item.avatarUrl !== undefined && item.avatarUrl !== null ? item.avatarUrl : undefined,
      isMine: forceMine || item.isMine === true,
      commentCount: item.commentCount !== undefined ? item.commentCount : 0,
      visibility: item.visibility !== undefined && item.visibility !== null && item.visibility.length > 0
        ? item.visibility
        : 'public',
      canDelete: item.canDelete !== false,
      cloudCount: item.cloudCount !== undefined ? item.cloudCount : 0,
      imageUrl: item.imageUrl
    }
    return result
  }
}
