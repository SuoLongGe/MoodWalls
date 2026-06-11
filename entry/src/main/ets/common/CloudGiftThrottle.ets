export class CloudGiftThrottle {
  private static readonly COOLDOWN_MS: number = 60000
  private static readonly KEY_PREFIX: string = 'cloud_gift_'

  static canSend(postId: number): boolean {
    const key: string = CloudGiftThrottle.KEY_PREFIX + postId
    const last: number | undefined = AppStorage.get<number>(key)
    if (last === undefined) {
      return true
    }
    return Date.now() - last >= CloudGiftThrottle.COOLDOWN_MS
  }

  static markSent(postId: number): void {
    const key: string = CloudGiftThrottle.KEY_PREFIX + postId
    AppStorage.setOrCreate(key, Date.now())
  }
}
