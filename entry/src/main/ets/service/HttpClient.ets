import { http } from '@kit.NetworkKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { ApiConfig } from '../common/ApiConfig'
import {
  ApiResponse,
  ChangePasswordRequestBody,
  LoginRequestBody,
  RegisterRequestBody,
  UpdateProfileRequestBody
} from '../model/AuthApiTypes'

export type HttpRequestBody =
  RegisterRequestBody |
  LoginRequestBody |
  UpdateProfileRequestBody |
  ChangePasswordRequestBody

export class HttpClient {

  static post<T>(path: string, body: HttpRequestBody, token?: string): Promise<T> {
    return HttpClient.request<T>(path, http.RequestMethod.POST, body, token)
  }

  static put<T>(path: string, body: HttpRequestBody, token: string): Promise<T> {
    return HttpClient.request<T>(path, http.RequestMethod.PUT, body, token)
  }

  static get<T>(path: string, token?: string): Promise<T> {
    return HttpClient.request<T>(path, http.RequestMethod.GET, undefined, token)
  }

  static postEmpty<T>(path: string, token?: string): Promise<T> {
    return HttpClient.request<T>(path, http.RequestMethod.POST, undefined, token)
  }

  private static request<T>(
    path: string,
    method: http.RequestMethod,
    body?: HttpRequestBody,
    token?: string
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

    const options: HttpRequestOptions = {
      method: method,
      header: headers,
      extraData: body !== undefined ? JSON.stringify(body) : '',
      expectDataType: http.HttpDataType.STRING,
      connectTimeout: 20000,
      readTimeout: 20000
    }

    return new Promise<T>((resolve, reject) => {
      httpRequest.request(
        ApiConfig.BASE_URL + path,
        options,
        (err: BusinessError, response: http.HttpResponse) => {
          httpRequest.destroy()
          if (err) {
            reject(new Error('网络连接失败，请确认后端已启动且 IP 正确'))
            return
          }
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
