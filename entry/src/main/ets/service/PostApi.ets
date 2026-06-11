import { HttpClient } from './HttpClient'
import { AuthSession } from '../common/AuthSession'
import {
  CloudGiftResponse,
  LikeResponse,
  LikeResponseFromApi,
  NoteItem,
  NoteItemFromApi,
  PostDetailResponse,
  PostListResponse,
  PublishPostResponse,
  MoodStatItem,
  MoodStatsResponse,
  ReactionResponse,
  TodayStatsResponse,
  TopReactionItem
} from '../model/MoodWallTypes'

interface MoodStatItemJson {
  mood?: string
  label?: string
  color?: string
  percent?: number | string
  count?: number | string
}

interface MoodStatsResponseJson {
  period?: string
  totalPosts?: number | string
  items?: Array<MoodStatItemJson>
}

interface TopReactionJson {
  type?: string
  label?: string
  count?: number | string
}

interface ReactionResponseJson {
  totalReactions?: number | string
  myReaction?: string | null
  reactionStats?: Record<string, number | string>
  topReactions?: Array<TopReactionJson>
}

interface CloudGiftResponseJson {
  cloudCount?: number | string
  sent?: boolean
}

export interface CreatePostBody {
  mood: string
  text: string
  location: string
  zoneKey?: string
}

export interface UpdateVisibilityBody {
  visibility: string
}

export interface ReactPostBody {
  reactionType: string
}

export class PostApi {

  private static resolveLiked(liked?: boolean, isLiked?: boolean): boolean {
    return liked === true || isLiked === true
  }

  private static toUserId(value: number | string | undefined | null): number {
    if (value === undefined || value === null) {
      return 0
    }
    if (typeof value === 'number') {
      return Math.floor(value)
    }
    const parsed: number = parseInt(`${value}`, 10)
    return Number.isNaN(parsed) ? 0 : parsed
  }

  private static resolveIsMine(item: NoteItemFromApi): boolean {
    if (item.isMine === true || item.mine === true) {
      return true
    }
    if (item.canDelete === true) {
      return true
    }
    const currentUserId: number = AuthSession.getUserId()
    const postUserId: number = PostApi.toUserId(item.userId)
    if (currentUserId > 0 && postUserId > 0 && postUserId === currentUserId) {
      return true
    }
    return false
  }

  private static normalizeNote(item: NoteItemFromApi): NoteItem {
    const isMine: boolean = PostApi.resolveIsMine(item)
    const result: NoteItem = {
      id: item.id,
      userId: PostApi.toUserId(item.userId),
      nickname: item.nickname,
      mood: item.mood,
      moodLabel: item.moodLabel,
      text: item.text,
      location: item.location,
      zoneKey: item.zoneKey,
      timeText: item.timeText,
      likes: item.likes,
      liked: PostApi.resolveLiked(item.liked, item.isLiked),
      color: item.color,
      createdAt: item.createdAt,
      avatarKey: item.avatarKey !== undefined && item.avatarKey.length > 0
        ? item.avatarKey
        : (isMine ? AuthSession.getAvatarKey() : 'avatar_01'),
      isMine: isMine,
      commentCount: item.commentCount !== undefined ? item.commentCount : 0,
      visibility: item.visibility !== undefined && item.visibility.length > 0 ? item.visibility : 'public',
      canDelete: item.canDelete === true || isMine,
      totalReactions: PostApi.toStatInt(item.totalReactions),
      myReaction: item.myReaction,
      topReactions: PostApi.normalizeTopReactions(item.topReactions),
      reactionStats: PostApi.normalizeReactionStats(item.reactionStats),
      whisperCount: PostApi.toStatInt(item.whisperCount),
      cloudCount: PostApi.toStatInt(item.cloudCount)
    }
    return result
  }

  private static normalizeTopReactions(raw?: Array<TopReactionJson>): Array<TopReactionItem> {
    const items: Array<TopReactionItem> = []
    if (raw === undefined || raw === null) {
      return items
    }
    raw.forEach((row: TopReactionJson) => {
      if (row.type !== undefined && row.type.length > 0) {
        items.push({
          type: row.type,
          label: row.label !== undefined && row.label !== null ? row.label : row.type,
          count: PostApi.toStatInt(row.count)
        })
      }
    })
    return items
  }

  private static normalizeReactionStats(raw?: Record<string, number | string>): Record<string, number> {
    const stats: Record<string, number> = {}
    if (raw === undefined || raw === null) {
      return stats
    }
    const keys: string[] = Object.keys(raw)
    keys.forEach((key: string) => {
      stats[key] = PostApi.toStatInt(raw[key])
    })
    return stats
  }

  static normalizeReactionResponse(raw: ReactionResponseJson): ReactionResponse {
    return {
      totalReactions: PostApi.toStatInt(raw.totalReactions),
      myReaction: raw.myReaction,
      reactionStats: PostApi.normalizeReactionStats(raw.reactionStats),
      topReactions: PostApi.normalizeTopReactions(raw.topReactions)
    }
  }

  private static normalizeLike(res: LikeResponseFromApi): LikeResponse {
    const result: LikeResponse = {
      likes: res.likes,
      liked: PostApi.resolveLiked(res.liked, res.isLiked)
    }
    return result
  }

  private static buildPostListResponse(
    list: NoteItem[],
    total: number | undefined,
    page: number | undefined,
    size: number | undefined,
    hasMore: boolean | undefined,
    fallbackPage: number,
    fallbackSize: number
  ): PostListResponse {
    const result: PostListResponse = {
      list: list,
      total: total !== undefined ? total : list.length,
      page: page !== undefined ? page : fallbackPage,
      size: size !== undefined ? size : fallbackSize,
      hasMore: hasMore === true
    }
    return result
  }

  static searchPosts(
    keyword: string,
    page: number = 1,
    size: number = 20,
    mood: string = 'all',
    period: string = 'all',
    token?: string
  ): Promise<PostListResponse> {
    const queryKeyword: string = encodeURIComponent(keyword.trim())
    const queryMood: string = encodeURIComponent(mood)
    const queryPeriod: string = encodeURIComponent(period)
    const path = `/posts/search?keyword=${queryKeyword}&page=${page}&size=${size}&mood=${queryMood}&period=${queryPeriod}`
    return HttpClient.get<PostListResponse>(path, token).then((res: PostListResponse) => {
      const list: NoteItem[] = []
      const rawList: NoteItemFromApi[] = res.list !== undefined && res.list !== null ? res.list as NoteItemFromApi[] : []
      rawList.forEach((item: NoteItemFromApi) => {
        list.push(PostApi.normalizeNote(item))
      })
      return PostApi.buildPostListResponse(
        list,
        res.total,
        res.page,
        res.size,
        res.hasMore,
        page,
        size
      )
    })
  }

  static getPosts(
    page: number = 1,
    size: number = 20,
    mood: string = 'all',
    token?: string
  ): Promise<PostListResponse> {
    const moodParam = mood !== 'all' ? `&mood=${mood}` : ''
    const path = `/posts?page=${page}&size=${size}${moodParam}`
    return HttpClient.get<PostListResponse>(path, token).then((res: PostListResponse) => {
      const list: NoteItem[] = []
      const rawList: NoteItemFromApi[] = res.list !== undefined && res.list !== null ? res.list as NoteItemFromApi[] : []
      rawList.forEach((item: NoteItemFromApi) => {
        list.push(PostApi.normalizeNote(item))
      })
      return PostApi.buildPostListResponse(
        list,
        res.total,
        res.page,
        res.size,
        res.hasMore,
        page,
        size
      )
    })
  }

  static getPostDetail(postId: number, token?: string): Promise<PostDetailResponse> {
    return HttpClient.get<NoteItemFromApi>(`/posts/${postId}`, token)
      .then((item: NoteItemFromApi) => PostApi.normalizeNote(item))
  }

  static createPost(body: CreatePostBody, token: string): Promise<PublishPostResponse> {
    return HttpClient.post<PublishPostResponse>('/posts', body, token).then((res: PublishPostResponse) => {
      const postRaw: NoteItemFromApi = res.post as NoteItemFromApi
      const result: PublishPostResponse = {
        post: PostApi.normalizeNote(postRaw),
        aiResponse: res.aiResponse,
        riskLevel: res.riskLevel !== undefined ? res.riskLevel : 0,
        comfortNote: res.comfortNote !== undefined ? res.comfortNote : ''
      }
      return result
    })
  }

  static deletePost(postId: number, token: string): Promise<void> {
    return HttpClient.delete(`/posts/${postId}`, token)
  }

  static updateVisibility(postId: number, visibility: string, token: string): Promise<NoteItem> {
    const body: UpdateVisibilityBody = { visibility: visibility }
    return HttpClient.put<NoteItemFromApi>(`/posts/${postId}/visibility`, body, token)
      .then((item: NoteItemFromApi) => PostApi.normalizeNote(item))
  }

  static likePost(postId: number, token: string): Promise<LikeResponse> {
    return HttpClient.postEmpty<LikeResponseFromApi>(`/posts/${postId}/like`, token)
      .then((res: LikeResponseFromApi) => PostApi.normalizeLike(res))
  }

  static reactPost(postId: number, reactionType: string, token: string): Promise<ReactionResponse> {
    const body: ReactPostBody = { reactionType: reactionType }
    return HttpClient.post<ReactionResponseJson>(`/posts/${postId}/react`, body, token)
      .then((res: ReactionResponseJson) => PostApi.normalizeReactionResponse(res))
  }

  static cancelReact(postId: number, token: string): Promise<ReactionResponse> {
    return HttpClient.deleteData<ReactionResponseJson>(`/posts/${postId}/react`, token)
      .then((res: ReactionResponseJson) => PostApi.normalizeReactionResponse(res))
  }

  static sendCloud(postId: number, token: string): Promise<CloudGiftResponse> {
    return HttpClient.postEmpty<CloudGiftResponseJson>(`/posts/${postId}/cloud`, token)
      .then((res: CloudGiftResponseJson) => {
        const result: CloudGiftResponse = {
          cloudCount: PostApi.toStatInt(res.cloudCount),
          sent: res.sent === true
        }
        return result
      })
  }

  static getTodayStats(): Promise<TodayStatsResponse> {
    return HttpClient.get<TodayStatsResponse>('/stats/today')
  }

  static getMoodStats(period: string): Promise<MoodStatsResponse> {
    const query: string = encodeURIComponent(period)
    return HttpClient.get<object>(`/stats/moods?period=${query}`)
      .then((payload: object) => PostApi.mapMoodStatsPayload(payload, period))
  }

  private static mapMoodStatsPayload(payload: object, fallbackPeriod: string): MoodStatsResponse {
    const text: string = JSON.stringify(payload)
    const json: MoodStatsResponseJson = JSON.parse(text) as MoodStatsResponseJson
    const items: Array<MoodStatItem> = []
    const rawItems: Array<MoodStatItemJson> =
      json.items !== undefined && json.items !== null ? json.items : []
    for (let i: number = 0; i < rawItems.length; i++) {
      const row: MoodStatItemJson = rawItems[i]
      const mood: string = row.mood !== undefined && row.mood !== null ? row.mood : ''
      if (mood.length === 0) {
        continue
      }
      const count: number = PostApi.toStatInt(row.count)
      if (count <= 0) {
        continue
      }
      items.push({
        mood: mood,
        label: row.label !== undefined && row.label !== null ? row.label : mood,
        color: row.color !== undefined && row.color !== null ? row.color : '#D8DEDC',
        percent: PostApi.toStatInt(row.percent),
        count: count
      })
    }
    const period: string = json.period !== undefined && json.period !== null && json.period.length > 0
      ? json.period
      : fallbackPeriod
    return {
      period: period,
      totalPosts: PostApi.toStatInt(json.totalPosts),
      items: items
    }
  }

  private static toStatInt(value: number | string | undefined | null): number {
    if (value === undefined || value === null) {
      return 0
    }
    if (typeof value === 'number') {
      return Math.floor(value)
    }
    const parsed: number = parseInt(`${value}`, 10)
    return Number.isNaN(parsed) ? 0 : parsed
  }
}
