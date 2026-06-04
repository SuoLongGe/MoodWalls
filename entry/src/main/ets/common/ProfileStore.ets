import { AuthSession } from './AuthSession'
import { ProfileOverview } from '../model/ProfileApiTypes'
import { ProfileApi } from '../service/ProfileApi'

/**
 * 个人概览统计写入 AppStorage，用 @StorageLink 驱动「我的」页刷新（与 NotificationStore 同理）。
 */
export class ProfileStore {
  static readonly KEY_POST_COUNT: string = 'profilePostCount'
  static readonly KEY_TOTAL_LIKES: string = 'profileTotalLikes'
  static readonly KEY_ACTIVE_DAYS: string = 'profileActiveDays'
  static readonly KEY_MOOD_CLIMATE: string = 'profileMoodClimate'
  static readonly KEY_CALM_PERCENT: string = 'profileCalmPercent'
  static readonly KEY_ANXIOUS_PERCENT: string = 'profileAnxiousPercent'
  static readonly KEY_HAPPY_PERCENT: string = 'profileHappyPercent'

  static ensureInitialized(): void {
    AppStorage.setOrCreate<number>(ProfileStore.KEY_POST_COUNT, 0)
    AppStorage.setOrCreate<number>(ProfileStore.KEY_TOTAL_LIKES, 0)
    AppStorage.setOrCreate<number>(ProfileStore.KEY_ACTIVE_DAYS, 0)
    AppStorage.setOrCreate<string>(ProfileStore.KEY_MOOD_CLIMATE, '暂无记录')
    AppStorage.setOrCreate<number>(ProfileStore.KEY_CALM_PERCENT, 0)
    AppStorage.setOrCreate<number>(ProfileStore.KEY_ANXIOUS_PERCENT, 0)
    AppStorage.setOrCreate<number>(ProfileStore.KEY_HAPPY_PERCENT, 0)
  }

  static applyOverview(overview: ProfileOverview): void {
    ProfileStore.ensureInitialized()
    AppStorage.set<number>(ProfileStore.KEY_POST_COUNT, overview.postCount)
    AppStorage.set<number>(ProfileStore.KEY_TOTAL_LIKES, overview.totalLikes)
    AppStorage.set<number>(ProfileStore.KEY_ACTIVE_DAYS, overview.activeDays)
    AppStorage.set<string>(ProfileStore.KEY_MOOD_CLIMATE, overview.moodClimate)
    AppStorage.set<number>(ProfileStore.KEY_CALM_PERCENT, overview.weekStats.calmPercent)
    AppStorage.set<number>(ProfileStore.KEY_ANXIOUS_PERCENT, overview.weekStats.anxiousPercent)
    AppStorage.set<number>(ProfileStore.KEY_HAPPY_PERCENT, overview.weekStats.happyPercent)

    const avatarKey: string = overview.avatarKey ?? ''
    if (avatarKey.length > 0) {
      AppStorage.setOrCreate('userAvatarKey', avatarKey)
    }
    if (overview.nickname.length > 0) {
      AppStorage.setOrCreate('userNickname', overview.nickname)
    }
    if (overview.phone.length > 0) {
      AppStorage.setOrCreate('userAccount', overview.phone)
    }
    console.info(
      `[MoodWalls] profile stats: posts=${overview.postCount} likes=${overview.totalLikes} activeDays=${overview.activeDays}`
    )
  }

  static refreshFromApi(): Promise<void> {
    if (!AuthSession.isLoggedIn()) {
      return Promise.resolve()
    }
    return ProfileApi.getOverview()
      .then((overview: ProfileOverview) => {
        ProfileStore.applyOverview(overview)
      })
  }

  static clear(): void {
    AppStorage.set<number>(ProfileStore.KEY_POST_COUNT, 0)
    AppStorage.set<number>(ProfileStore.KEY_TOTAL_LIKES, 0)
    AppStorage.set<number>(ProfileStore.KEY_ACTIVE_DAYS, 0)
    AppStorage.set<string>(ProfileStore.KEY_MOOD_CLIMATE, '暂无记录')
    AppStorage.set<number>(ProfileStore.KEY_CALM_PERCENT, 0)
    AppStorage.set<number>(ProfileStore.KEY_ANXIOUS_PERCENT, 0)
    AppStorage.set<number>(ProfileStore.KEY_HAPPY_PERCENT, 0)
  }
}
