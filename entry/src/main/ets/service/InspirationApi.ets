import { HttpClient } from './HttpClient'
import {
  CreateEncouragementNoteBody,
  EncouragementNoteResponse,
  InspirationDrawResponse
} from '../model/MoodWallTypes'

interface EncouragementNoteJson {
  id?: number | string
  content?: string
  mood?: string
  moodLabel?: string
  moodColor?: string
  createdAt?: string
  timeText?: string
}

interface InspirationDrawJson {
  alreadyDrawn?: boolean
  content?: string
  mood?: string
  moodLabel?: string
  moodColor?: string
  source?: string
  drawnAt?: string
  remainingToday?: number | string
}

export class InspirationApi {

  static getToday(token: string): Promise<InspirationDrawResponse> {
    return HttpClient.get<InspirationDrawJson>('/inspiration/today', token)
      .then((row: InspirationDrawJson) => InspirationApi.mapResponse(row))
  }

  static draw(token: string): Promise<InspirationDrawResponse> {
    return HttpClient.postEmpty<InspirationDrawJson>('/inspiration/draw', token)
      .then((row: InspirationDrawJson) => InspirationApi.mapResponse(row))
  }

  static createNote(body: CreateEncouragementNoteBody, token: string): Promise<EncouragementNoteResponse> {
    return HttpClient.post<EncouragementNoteJson>('/inspiration/notes', body, token)
      .then((row: EncouragementNoteJson) => InspirationApi.mapNote(row))
  }

  private static mapNote(row: EncouragementNoteJson): EncouragementNoteResponse {
    const idRaw: number | string | undefined = row.id
    let id: number = 0
    if (typeof idRaw === 'number') {
      id = Math.floor(idRaw)
    } else if (idRaw !== undefined) {
      const parsed: number = parseInt(`${idRaw}`, 10)
      id = Number.isNaN(parsed) ? 0 : parsed
    }
    return {
      id: id,
      content: row.content !== undefined && row.content !== null ? row.content : '',
      mood: row.mood !== undefined && row.mood !== null ? row.mood : 'calm',
      moodLabel: row.moodLabel !== undefined && row.moodLabel !== null ? row.moodLabel : '平静',
      moodColor: row.moodColor !== undefined && row.moodColor !== null ? row.moodColor : '#73C088',
      createdAt: row.createdAt !== undefined && row.createdAt !== null ? row.createdAt : '',
      timeText: row.timeText !== undefined && row.timeText !== null ? row.timeText : ''
    }
  }

  private static mapResponse(row: InspirationDrawJson): InspirationDrawResponse {
    let remaining: number = 0
    if (row.remainingToday !== undefined && row.remainingToday !== null) {
      if (typeof row.remainingToday === 'number') {
        remaining = Math.floor(row.remainingToday)
      } else {
        const parsed: number = parseInt(`${row.remainingToday}`, 10)
        remaining = Number.isNaN(parsed) ? 0 : parsed
      }
    }
    return {
      alreadyDrawn: row.alreadyDrawn === true,
      content: row.content !== undefined && row.content !== null ? row.content : '',
      mood: row.mood,
      moodLabel: row.moodLabel,
      moodColor: row.moodColor,
      source: row.source,
      drawnAt: row.drawnAt,
      remainingToday: remaining
    }
  }
}
