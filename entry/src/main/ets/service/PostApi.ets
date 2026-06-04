import { HttpClient } from './HttpClient'
import {
  LikeResponse,
  LikeResponseFromApi,
  NoteItem,
  NoteItemFromApi,
  PostDetailResponse,
  PostListResponse,
  PublishPostResponse,
  MoodStatItem,
  MoodStatsResponse,
  TodayStatsResponse
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

export interface CreatePostBody {
  mood: string
  text: string
  location: string
  zoneKey?: string
}

export class PostApi {

  private static resolveLiked(liked?: boolean, isLiked?: boolean): boolean {
    return liked === true || isLiked === true
  }

  private static normalizeNote(item: NoteItemFromApi): NoteItem {
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
      liked: PostApi.resolveLiked(item.liked, item.isLiked),
      color: item.color,
      createdAt: item.createdAt
    }
    return result
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
        aiResponse: res.aiResponse
      }
      return result
    })
  }

  static deletePost(postId: number, token: string): Promise<void> {
    return HttpClient.delete(`/posts/${postId}`, token)
  }

  static likePost(postId: number, token: string): Promise<LikeResponse> {
    return HttpClient.postEmpty<LikeResponseFromApi>(`/posts/${postId}/like`, token)
      .then((res: LikeResponseFromApi) => PostApi.normalizeLike(res))
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
