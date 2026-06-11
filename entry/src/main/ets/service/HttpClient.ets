import { http } from '@kit.NetworkKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { ApiConfig } from '../common/ApiConfig'
import { ApiResponse } from '../model/AuthApiTypes'

export class HttpClient {

  static post<T>(path: string, body: object | undefined, token?: string, timeoutMs: number = 20000): Promise<T> {
    return HttpClient.request<T>(path, http.RequestMethod.POST, body, token, timeoutMs)
  }

  static put<T>(path: string, body: object | undefined, token: string, timeoutMs: number = 20000): Promise<T> {
    return HttpClient.request<T>(path, http.RequestMethod.PUT, body, token, timeoutMs)
  }

  static get<T>(path: string, token?: string): Promise<T> {
    return HttpClient.request<T>(path, http.RequestMethod.GET, undefined, token)
  }

  static postEmpty<T>(path: string, token?: string): Promise<T> {
    // body 为 undefined 时 buildExtraData 会写入 '{}'，避免 Parameter error
    return HttpClient.request<T>(path, http.RequestMethod.POST, undefined, token)
  }

  static delete(path: string, token: string): Promise<void> {
    return HttpClient.request<void>(path, http.RequestMethod.DELETE, undefined, token)
  }

  static deleteData<T>(path: string, token: string): Promise<T> {
    return HttpClient.request<T>(path, http.RequestMethod.DELETE, undefined, token)
  }

  private static request<T>(
    path: string,
    method: http.RequestMethod,
    body?: object,
    token?: string,
    timeoutMs: number = 20000
  ): Promise<T> {
    const httpRequest = http.createHttp()
    let headers: HttpHeaders = {
      'Content-Type': 'application/json'
    }
    if (token !== undefined && token.length > 0) {
      headers = {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`
      }
    }

    const extraData: string = HttpClient.buildExtraData(method, body)

    const options: HttpRequestOptions = {
      method: method,
      header: headers,
      extraData: extraData,
      expectDataType: http.HttpDataType.STRING,
      connectTimeout: timeoutMs,
      readTimeout: timeoutMs
    }

    return new Promise<T>((resolve, reject) => {
      httpRequest.request(
        ApiConfig.BASE_URL + path,
        options,
        (err: BusinessError, response: http.HttpResponse) => {
          httpRequest.destroy()
          if (err) {
            console.error('[MoodWalls] HTTP error: code=' + err.code + ' msg=' + err.message)
            const errMsg: string = err.message ?? ''
            if (errMsg.includes('Parameter error')) {
              reject(new Error('请求参数错误，请更新应用后重试'))
              return
            }
            reject(new Error('网络连接失败，请确认后端已启动且 IP 正确'))
            return
          }
          console.info('[MoodWalls] HTTP ' + method + ' ' + path + ' -> ' + response.responseCode)
          HttpClient.parseResponse<T>(response, resolve, reject)
        }
      )
    })
  }

  private static buildExtraData(method: http.RequestMethod, body?: object): string {
    if (body !== undefined) {
      return JSON.stringify(body)
    }
    if (method === http.RequestMethod.POST || method === http.RequestMethod.PUT) {
      return '{}'
    }
    return ''
  }

  private static parseResponse<T>(
    response: http.HttpResponse,
    resolve: (value: T) => void,
    reject: (reason: Error) => void
  ): void {
    if (response.result === undefined || response.result === null) {
      console.error('[MoodWalls] Response result is null, HTTP ' + response.responseCode)
      reject(new Error(`网络错误 (${response.responseCode})`))
      return
    }

    try {
      const raw: string = typeof response.result === 'string'
        ? response.result as string
        : JSON.stringify(response.result)
      console.info('[MoodWalls] Response raw: ' + raw.substring(0, 200))
      const envelope: ApiResponse<Object> = JSON.parse(raw) as ApiResponse<Object>
      const code: number = envelope.code !== undefined ? Number(envelope.code) : 0
      if (code !== 200) {
        console.error('[MoodWalls] API error: code=' + code + ' msg=' + envelope.message)
        reject(new Error(envelope.message || '请求失败'))
        return
      }
      if (envelope.data === undefined || envelope.data === null) {
        console.error('[MoodWalls] API response missing data field')
        reject(new Error('响应缺少 data'))
        return
      }
      resolve(envelope.data as T)
    } catch (e) {
      reject(new Error('响应解析失败'))
    }
  }
}

interface HttpHeaders {
  'Content-Type': string
  'Authorization'?: string
}

interface HttpRequestOptions {
  method: http.RequestMethod
  header: HttpHeaders
  extraData: string
  expectDataType: http.HttpDataType
  connectTimeout: number
  readTimeout: number
}

