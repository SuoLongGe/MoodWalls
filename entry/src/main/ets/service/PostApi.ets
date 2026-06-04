import { HttpClient } from './HttpClient'
import {
  PostDetailResponse,
  PostListResponse,
  LikeResponse,
  TodayStatsResponse,
  PublishPostResponse
} from '../model/MoodWallTypes'

export interface CreatePostBody {
  mood: string
  text: string
  location: string
  zoneKey?: string
}

export class PostApi {

  static getPosts(
    page: number = 1,
    size: number = 20,
    mood: string = 'all',
    token?: string
  ): Promise<PostListResponse> {
    const moodParam = mood !== 'all' ? `&mood=${mood}` : ''
    const path = `/posts?page=${page}&size=${size}${moodParam}`
    return HttpClient.get<PostListResponse>(path, token)
  }

  static getPostDetail(postId: number, token?: string): Promise<PostDetailResponse> {
    return HttpClient.get<PostDetailResponse>(`/posts/${postId}`, token)
  }

  static createPost(body: CreatePostBody, token: string): Promise<PublishPostResponse> {
    return HttpClient.post<PublishPostResponse>('/posts', body as object as Record<string, Object>, token)
  }

  static deletePost(postId: number, token: string): Promise<void> {
    return HttpClient.delete(`/posts/${postId}`, token)
  }

  static likePost(postId: number, token: string): Promise<LikeResponse> {
    return HttpClient.postEmpty<LikeResponse>(`/posts/${postId}/like`, token)
  }

  static getTodayStats(): Promise<TodayStatsResponse> {
    return HttpClient.get<TodayStatsResponse>('/stats/today')
  }
}
