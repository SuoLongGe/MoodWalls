import {
  AuthResult,
  CaptchaResult,
  ChangePasswordRequestBody,
  LoginRequestBody,
  RegisterRequestBody,
  UpdateProfileRequestBody,
  UserProfile
} from '../model/AuthApiTypes'
import { AuthSession } from '../common/AuthSession'
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
    password: string,
    avatarKey: string
  ): Promise<AuthResult> {
    const body: RegisterRequestBody = {
      nickname: nickname,
      phone: phone,
      captchaId: captchaId,
      captchaCode: captchaCode,
      password: password,
      avatarKey: avatarKey
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

  static getMe(): Promise<UserProfile> {
    return HttpClient.get<UserProfile>('/auth/me', AuthSession.getToken())
  }

  static updateProfile(nickname: string, avatarKey: string): Promise<UserProfile> {
    const body: UpdateProfileRequestBody = {
      nickname: nickname,
      avatarKey: avatarKey
    }
    return HttpClient.put<UserProfile>('/auth/profile', body, AuthSession.getToken())
  }

  static changePassword(oldPassword: string, newPassword: string): Promise<void> {
    const body: ChangePasswordRequestBody = {
      oldPassword: oldPassword,
      newPassword: newPassword
    }
    return HttpClient.put<void>('/auth/password', body, AuthSession.getToken())
  }

  static logout(): Promise<void> {
    return HttpClient.postEmpty<void>('/auth/logout', AuthSession.getToken())
  }
}
