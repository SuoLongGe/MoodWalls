import { http } from '@kit.NetworkKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { ApiConfig } from '../common/ApiConfig'
import { ApiResponse } from '../model/AuthApiTypes'

export class HttpClient {

  static post<T>(path: string, body: object | undefined, token?: string): Promise<T> {
    return HttpClient.request<T>(path, http.RequestMethod.POST, body, token)
  }

  static put<T>(path: string, body: object | undefined, token: string): Promise<T> {
    return HttpClient.request<T>(path, http.RequestMethod.PUT, body, token)
  }

  static get<T>(path: string, token?: string): Promise<T> {
    return HttpClient.request<T>(path, http.RequestMethod.GET, undefined, token)
  }

  static postEmpty<T>(path: string, token?: string): Promise<T> {
    return HttpClient.request<T>(path, http.RequestMethod.POST, undefined, token)
  }

  static delete(path: string, token: string): Promise<void> {
    return HttpClient.request<void>(path, http.RequestMethod.DELETE, undefined, token)
  }

  private static request<T>(
    path: string,
    method: http.RequestMethod,
    body?: object,
    token?: string
  ): Promise<T> {
    const httpRequest = http.createHttp()
    let headers: Record<string, string> = {
      'Content-Type': 'application/json'
    }
    if (token !== undefined && token.length > 0) {
      headers['Authorization'] = `Bearer ${token}`
    }

    return new Promise<T>((resolve, reject) => {
      httpRequest.request(
        ApiConfig.BASE_URL + path,
        {
          method: method,
          header: headers,
          extraData: body,
          expectDataType: http.HttpDataType.STRING,
          connectTimeout: 20000,
          readTimeout: 20000
        },
        (err: BusinessError, response: http.HttpResponse) => {
          httpRequest.destroy()
          if (err) {
            console.error('HTTP请求失败 err.code=' + err.code + ' msg=' + err.message)
            reject(new Error('网络连接失败，请确认后端已启动且 IP 正确'))
            return
          }
          console.info('HTTP响应 code=' + response.responseCode + ' result=' + JSON.stringify(response.result))
          HttpClient.parseResponse<T>(response, resolve, reject)
        }
      )
    })
  }

  private static parseResponse<T>(
    response: http.HttpResponse,
    resolve: (value: T) => void,
    reject: (reason: Error) => void
  ): void {
    if (response.result === undefined || response.result === null) {
      reject(new Error(`网络错误 (${response.responseCode})`))
      return
    }

    try {
      const raw: string = typeof response.result === 'string'
        ? response.result as string
        : JSON.stringify(response.result)
      const parsed: ApiResponse<T> = JSON.parse(raw) as ApiResponse<T>
      if (parsed.code !== 200) {
        reject(new Error(parsed.message || '请求失败'))
        return
      }
      resolve(parsed.data)
    } catch (e) {
      reject(new Error('响应解析失败'))
    }
  }
}
