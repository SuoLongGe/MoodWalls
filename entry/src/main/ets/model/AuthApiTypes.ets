export interface ApiResponse<T> {
  code: number
  message: string
  data: T
}

export interface UserProfile {
  id: number
  nickname: string
  phone: string
  studentId: string | null
}

export interface AuthResult {
  token: string
  user: UserProfile
}

export interface CaptchaResult {
  captchaId: string
  captchaText: string
}

export interface RegisterRequestBody {
  nickname: string
  phone: string
  captchaId: string
  captchaCode: string
  password: string
}

export interface LoginRequestBody {
  account: string
  password: string
}
