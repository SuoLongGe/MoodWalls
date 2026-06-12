import { common } from '@kit.AbilityKit'

import {

  AuthResult,

  ChangePasswordRequestBody,

  EmailCodeResult,

  EmailLoginRequestBody,

  LoginRequestBody,

  RegisterRequestBody,

  SendEmailCodeRequestBody,

  UpdateProfileRequestBody,

  UserProfile

} from '../model/AuthApiTypes'

import { AuthSession } from '../common/AuthSession'

import { PostUploadHelper } from '../common/PostUploadHelper'

import { HttpClient } from './HttpClient'



export class AuthApi {



  static sendEmailCode(email: string, scene: string): Promise<EmailCodeResult> {

    const body: SendEmailCodeRequestBody = {

      email: email,

      scene: scene

    }

    return HttpClient.post<EmailCodeResult>('/auth/email/code', body)

  }



  static register(

    nickname: string,

    phone: string,

    email: string,

    emailCodeId: string,

    emailCode: string,

    password: string,

    avatarKey: string,

    context?: common.UIAbilityContext,

    pickedImageUri?: string

  ): Promise<AuthResult> {

    const body: RegisterRequestBody = {

      nickname: nickname,

      phone: phone,

      email: email,

      emailCodeId: emailCodeId,

      emailCode: emailCode,

      password: password,

      avatarKey: avatarKey

    }

    if (pickedImageUri !== undefined && pickedImageUri.length > 0 && context !== undefined) {

      try {

        body.avatarBase64 = PostUploadHelper.readImageBase64(context, pickedImageUri)

      } catch (err) {

        const message: string = err instanceof Error ? err.message : '头像读取失败'

        return Promise.reject(new Error(message))

      }

    }

    const timeoutMs: number = body.avatarBase64 !== undefined ? 90000 : 20000

    return HttpClient.post<AuthResult>('/auth/register', body, undefined, timeoutMs)

  }



  static login(account: string, password: string): Promise<AuthResult> {

    const body: LoginRequestBody = {

      account: account,

      password: password

    }

    return HttpClient.post<AuthResult>('/auth/login', body)

  }



  static loginByEmail(email: string, codeId: string, code: string): Promise<AuthResult> {

    const body: EmailLoginRequestBody = {

      email: email,

      codeId: codeId,

      code: code

    }

    return HttpClient.post<AuthResult>('/auth/login/email', body)

  }



  static getMe(): Promise<UserProfile> {

    return HttpClient.get<UserProfile>('/auth/me', AuthSession.getToken())

  }



  static updateProfile(

    nickname: string,

    avatarKey: string,

    phone?: string,

    email?: string,

    emailCodeId?: string,

    emailCode?: string,

    context?: common.UIAbilityContext,

    pickedImageUri?: string

  ): Promise<UserProfile> {

    const body: UpdateProfileRequestBody = {

      nickname: nickname,

      avatarKey: avatarKey

    }

    if (phone !== undefined && phone.length > 0) {

      body.phone = phone

    }

    if (email !== undefined && email.length > 0) {

      body.email = email

    }

    if (emailCodeId !== undefined && emailCodeId.length > 0) {

      body.emailCodeId = emailCodeId

    }

    if (emailCode !== undefined && emailCode.length > 0) {

      body.emailCode = emailCode

    }

    if (pickedImageUri !== undefined && pickedImageUri.length > 0 && context !== undefined) {

      try {

        body.avatarBase64 = PostUploadHelper.readImageBase64(context, pickedImageUri)

      } catch (err) {

        const message: string = err instanceof Error ? err.message : '头像读取失败'

        return Promise.reject(new Error(message))

      }

    }

    return HttpClient.put<UserProfile>('/auth/profile', body, AuthSession.getToken(), 90000)

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

