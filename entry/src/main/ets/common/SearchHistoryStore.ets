import { preferences } from '@kit.ArkData'
import { common } from '@kit.AbilityKit'

export class SearchHistoryStore {
  private static readonly STORE_NAME: string = 'moodwalls_search'
  private static readonly KEY_HISTORY: string = 'history'
  private static readonly MAX_COUNT: number = 10
  private static cache: Array<string> = []

  static init(context: common.Context): Promise<void> {
    return preferences.getPreferences(context, SearchHistoryStore.STORE_NAME).then((store) => {
      return store.get(SearchHistoryStore.KEY_HISTORY, '[]').then((value: preferences.ValueType) => {
        try {
          const raw: string = `${value}`
          const parsed: string[] = JSON.parse(raw) as string[]
          SearchHistoryStore.cache = Array.isArray(parsed) ? parsed : []
        } catch (err) {
          SearchHistoryStore.cache = []
        }
      })
    }).catch(() => {
      SearchHistoryStore.cache = []
    })
  }

  static getHistory(): Array<string> {
    const copy: Array<string> = []
    SearchHistoryStore.cache.forEach((item: string) => copy.push(item))
    return copy
  }

  static saveKeyword(context: common.Context, keyword: string): Promise<void> {
    const trimmed: string = keyword.trim()
    if (trimmed.length === 0) {
      return Promise.resolve()
    }
    const next: Array<string> = [trimmed]
    SearchHistoryStore.cache.forEach((item: string) => {
      if (item !== trimmed && next.length < SearchHistoryStore.MAX_COUNT) {
        next.push(item)
      }
    })
    SearchHistoryStore.cache = next
    return preferences.getPreferences(context, SearchHistoryStore.STORE_NAME).then((store) => {
      store.put(SearchHistoryStore.KEY_HISTORY, JSON.stringify(next))
      return store.flush()
    }).catch(() => {})
  }
}
