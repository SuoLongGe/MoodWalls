import { HttpClient } from './HttpClient'
import {
  CommentItem,
  CommentListResponse,
  CommentReplyItem,
  CreateCommentBody
} from '../model/MoodWallTypes'

interface CommentReplyJson {
  id?: number | string
  postId?: number | string
  userId?: number | string
  parentId?: number | string
  authorNickname?: string
  authorAvatarKey?: string
  content?: string
  commentType?: string
  replyToNickname?: string
  isMine?: boolean
  canDelete?: boolean
  createdAt?: string
  timeText?: string
}

interface CommentJson {
  id?: number | string
  postId?: number | string
  userId?: number | string
  authorNickname?: string
  authorAvatarKey?: string
  content?: string
  commentType?: string
  parentId?: number | string | null
  replyToNickname?: string
  isMine?: boolean
  canDelete?: boolean
  createdAt?: string
  timeText?: string
  replies?: Array<CommentReplyJson>
}

interface CommentListJson {
  list?: Array<CommentJson>
  total?: number | string
  page?: number | string
  size?: number | string
  hasMore?: boolean
  whisperCount?: number | string
}

export class CommentApi {

  static getComments(
    postId: number,
    page: number = 1,
    size: number = 20,
    token?: string
  ): Promise<CommentListResponse> {
    const path = `/posts/${postId}/comments?page=${page}&size=${size}`
    return HttpClient.get<object>(path, token).then((payload: object) => {
      return CommentApi.mapCommentList(payload, page, size)
    })
  }

  static createComment(postId: number, body: CreateCommentBody, token: string): Promise<CommentItem> {
    return HttpClient.post<object>(`/posts/${postId}/comments`, body, token)
      .then((payload: object) => CommentApi.mapComment(payload))
  }

  static deleteComment(postId: number, commentId: number, token: string): Promise<void> {
    return HttpClient.delete(`/posts/${postId}/comments/${commentId}`, token)
  }

  private static mapCommentList(payload: object, fallbackPage: number, fallbackSize: number): CommentListResponse {
    const text: string = JSON.stringify(payload)
    const json: CommentListJson = JSON.parse(text) as CommentListJson
    const list: Array<CommentItem> = []
    const rawList: Array<CommentJson> = json.list !== undefined && json.list !== null ? json.list : []
    rawList.forEach((row: CommentJson) => {
      list.push(CommentApi.mapComment(row))
    })
    return {
      list: list,
      total: CommentApi.toInt(json.total),
      page: CommentApi.toInt(json.page) > 0 ? CommentApi.toInt(json.page) : fallbackPage,
      size: CommentApi.toInt(json.size) > 0 ? CommentApi.toInt(json.size) : fallbackSize,
      hasMore: json.hasMore === true,
      whisperCount: CommentApi.toInt(json.whisperCount)
    }
  }

  private static mapComment(row: CommentJson): CommentItem {
    const replies: Array<CommentReplyItem> = []
    const rawReplies: Array<CommentReplyJson> = row.replies !== undefined && row.replies !== null ? row.replies : []
    rawReplies.forEach((reply: CommentReplyJson) => {
      replies.push(CommentApi.mapReply(reply))
    })
    return {
      id: CommentApi.toInt(row.id),
      postId: CommentApi.toInt(row.postId),
      userId: CommentApi.toInt(row.userId),
      authorNickname: row.authorNickname !== undefined && row.authorNickname !== null ? row.authorNickname : '匿名用户',
      authorAvatarKey: row.authorAvatarKey,
      content: row.content !== undefined && row.content !== null ? row.content : '',
      commentType: row.commentType !== undefined && row.commentType !== null ? row.commentType : 'resonance',
      parentId: row.parentId !== undefined && row.parentId !== null ? CommentApi.toInt(row.parentId) : null,
      replyToNickname: row.replyToNickname,
      isMine: row.isMine === true,
      canDelete: row.canDelete === true,
      createdAt: row.createdAt !== undefined && row.createdAt !== null ? row.createdAt : '',
      timeText: row.timeText !== undefined && row.timeText !== null ? row.timeText : '',
      replies: replies
    }
  }

  private static mapReply(row: CommentReplyJson): CommentReplyItem {
    return {
      id: CommentApi.toInt(row.id),
      postId: CommentApi.toInt(row.postId),
      userId: CommentApi.toInt(row.userId),
      parentId: CommentApi.toInt(row.parentId),
      authorNickname: row.authorNickname !== undefined && row.authorNickname !== null ? row.authorNickname : '匿名用户',
      authorAvatarKey: row.authorAvatarKey,
      content: row.content !== undefined && row.content !== null ? row.content : '',
      commentType: row.commentType !== undefined && row.commentType !== null ? row.commentType : 'resonance',
      replyToNickname: row.replyToNickname,
      isMine: row.isMine === true,
      canDelete: row.canDelete === true,
      createdAt: row.createdAt !== undefined && row.createdAt !== null ? row.createdAt : '',
      timeText: row.timeText !== undefined && row.timeText !== null ? row.timeText : ''
    }
  }

  private static toInt(value: number | string | undefined | null): number {
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
