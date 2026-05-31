import { UserProfile } from '../model/AuthApiTypes'

export class AuthSession {
  static readonly KEY_TOKEN: string = 'authToken'
  static readonly KEY_LOGGED_IN: string = 'isLoggedIn'
  static readonly KEY_USER_ID: string = 'userId'
  static readonly KEY_NICKNAME: string = 'userNickname'
  static readonly KEY_ACCOUNT: string = 'userAccount'

  static save(result: UserProfile, token: string): void {
    AppStorage.setOrCreate(AuthSession.KEY_TOKEN, token)
    AppStorage.setOrCreate(AuthSession.KEY_LOGGED_IN, true)
    AppStorage.setOrCreate(AuthSession.KEY_USER_ID, result.id)
    AppStorage.setOrCreate(AuthSession.KEY_NICKNAME, result.nickname)
    AppStorage.setOrCreate(AuthSession.KEY_ACCOUNT, result.phone)
  }

  static getToken(): string {
    const token: string | undefined = AppStorage.get<string>(AuthSession.KEY_TOKEN)
    return token !== undefined ? token : ''
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
  }
}
