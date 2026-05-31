import {
  AuthResult,
  CaptchaResult,
  LoginRequestBody,
  RegisterRequestBody
} from '../model/AuthApiTypes'
import { HttpClient } from './HttpClient'

export class AuthApi {

  static getCaptcha(): Promise<CaptchaResult> {
    return HttpClient.get<CaptchaResult>('/auth/captcha')
  }

  static register(
    nickname: string,
    phone: string,
    captchaId: string,
    captchaCode: string,
    password: string
  ): Promise<AuthResult> {
    const body: RegisterRequestBody = {
      nickname: nickname,
      phone: phone,
      captchaId: captchaId,
      captchaCode: captchaCode,
      password: password
    }
    return HttpClient.post<AuthResult>('/auth/register', body)
  }

  static login(account: string, password: string): Promise<AuthResult> {
    const body: LoginRequestBody = {
      account: account,
      password: password
    }
    return HttpClient.post<AuthResult>('/auth/login', body)
  }
}
