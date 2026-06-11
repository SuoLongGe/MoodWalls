export interface ApiResponse<T> {

  code: number

  message: string

  data: T

}



export interface UserProfile {

  id: number

  nickname: string

  phone: string

  email?: string

  studentId: string | null

  avatarKey: string

  avatarUrl?: string

}



export interface AuthResult {

  token: string

  user: UserProfile

}



export interface EmailCodeResult {

  codeId: string

  expireSeconds: number

}



export interface RegisterRequestBody {

  nickname: string

  phone: string

  email: string

  emailCodeId: string

  emailCode: string

  password: string

  avatarKey: string

  avatarBase64?: string

}



export interface SendEmailCodeRequestBody {

  email: string

  scene: string

}



export interface EmailLoginRequestBody {

  email: string

  codeId: string

  code: string

}



export interface LoginRequestBody {

  account: string

  password: string

}



export interface UpdateProfileRequestBody {

  nickname: string

  phone?: string

  email?: string

  emailCodeId?: string

  emailCode?: string

  avatarKey?: string

  avatarBase64?: string

}



export interface ChangePasswordRequestBody {

  oldPassword: string

  newPassword: string

}

