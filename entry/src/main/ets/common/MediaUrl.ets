import { ApiConfig } from './ApiConfig'

export class MediaUrl {

  static resolve(url?: string | null): string | undefined {
    if (url === undefined || url === null || url.length === 0) {
      return undefined
    }
    const uploadsMarker: string = '/uploads/'
    const markerIndex: number = url.indexOf(uploadsMarker)
    if (markerIndex >= 0) {
      return ApiConfig.getServerOrigin() + url.substring(markerIndex)
    }
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url
    }
    const normalized: string = url.startsWith('/') ? url : `/${url}`
    return ApiConfig.getServerOrigin() + normalized
  }
}
