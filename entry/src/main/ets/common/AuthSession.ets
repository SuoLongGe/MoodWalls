import { UserProfile } from '../model/AuthApiTypes'

export class AuthSession {
  static readonly KEY_TOKEN: string = 'authToken'
  static readonly KEY_LOGGED_IN: string = 'isLoggedIn'
  static readonly KEY_USER_ID: string = 'userId'
  static readonly KEY_NICKNAME: string = 'userNickname'
  static readonly KEY_ACCOUNT: string = 'userAccount'
  static readonly KEY_EMAIL: string = 'userEmail'
  static readonly KEY_PHONE: string = 'userPhone'
  static readonly KEY_AVATAR: string = 'userAvatarKey'
  static readonly KEY_AVATAR_URL: string = 'userAvatarUrl'

  static save(result: UserProfile, token: string): void {
    AppStorage.setOrCreate(AuthSession.KEY_TOKEN, token)
    AppStorage.setOrCreate(AuthSession.KEY_LOGGED_IN, true)
    AppStorage.setOrCreate(AuthSession.KEY_USER_ID, result.id)
    AppStorage.setOrCreate(AuthSession.KEY_NICKNAME, result.nickname)
    AuthSession.applyContactInfo(result)
    AppStorage.setOrCreate(AuthSession.KEY_AVATAR, result.avatarKey !== undefined ? result.avatarKey : 'avatar_01')
    AuthSession.applyAvatarUrl(result.avatarUrl)
  }

  static updateUser(profile: UserProfile): void {
    AppStorage.setOrCreate(AuthSession.KEY_NICKNAME, profile.nickname)
    AppStorage.setOrCreate(AuthSession.KEY_AVATAR, profile.avatarKey)
    AuthSession.applyContactInfo(profile)
    AuthSession.applyAvatarUrl(profile.avatarUrl)
  }

  private static applyContactInfo(profile: UserProfile): void {
    const email: string = profile.email !== undefined && profile.email !== null ? profile.email : ''
    const phone: string = profile.phone !== undefined && profile.phone !== null ? profile.phone : ''
    AppStorage.setOrCreate(AuthSession.KEY_EMAIL, email)
    AppStorage.setOrCreate(AuthSession.KEY_PHONE, phone)
    AppStorage.setOrCreate(AuthSession.KEY_ACCOUNT, AuthSession.resolveAccountLabel(profile))
  }

  private static applyAvatarUrl(avatarUrl?: string | null): void {
    const resolved: string = AuthSession.normalizeAvatarUrl(avatarUrl)
    AppStorage.setOrCreate(AuthSession.KEY_AVATAR_URL, resolved)
  }

  private static resolveAccountLabel(profile: UserProfile): string {
    if (profile.email !== undefined && profile.email !== null && profile.email.length > 0) {
      return profile.email
    }
    if (profile.phone !== undefined && profile.phone !== null && profile.phone.length > 0) {
      return profile.phone
    }
    return ''
  }

  private static normalizeAvatarUrl(avatarUrl?: string | null): string {
    if (avatarUrl === undefined || avatarUrl === null || avatarUrl.length === 0) {
      return ''
    }
    return avatarUrl
  }

  static getToken(): string {
    const token: string | undefined = AppStorage.get<string>(AuthSession.KEY_TOKEN)
    return token !== undefined ? token : ''
  }

  static getAvatarKey(): string {
    const key: string | undefined = AppStorage.get<string>(AuthSession.KEY_AVATAR)
    return key !== undefined && key.length > 0 ? key : 'avatar_01'
  }

  static getAvatarUrl(): string {
    const url: string | undefined = AppStorage.get<string>(AuthSession.KEY_AVATAR_URL)
    return AuthSession.normalizeAvatarUrl(url)
  }

  static getUserId(): number {
    const id: number | undefined = AppStorage.get<number>(AuthSession.KEY_USER_ID)
    return id !== undefined ? id : 0
  }

  static isLoggedIn(): boolean {
    const logged: boolean | undefined = AppStorage.get<boolean>(AuthSession.KEY_LOGGED_IN)
    return logged === true && AuthSession.getToken().length > 0
  }

  static clear(): void {
    AppStorage.setOrCreate(AuthSession.KEY_TOKEN, '')
    AppStorage.setOrCreate(AuthSession.KEY_LOGGED_IN, false)
    AppStorage.setOrCreate(AuthSession.KEY_USER_ID, 0)
    AppStorage.setOrCreate(AuthSession.KEY_NICKNAME, '')
    AppStorage.setOrCreate(AuthSession.KEY_ACCOUNT, '')
    AppStorage.setOrCreate(AuthSession.KEY_EMAIL, '')
    AppStorage.setOrCreate(AuthSession.KEY_PHONE, '')
    AppStorage.setOrCreate(AuthSession.KEY_AVATAR, '')
    AppStorage.setOrCreate(AuthSession.KEY_AVATAR_URL, '')
  }
}
