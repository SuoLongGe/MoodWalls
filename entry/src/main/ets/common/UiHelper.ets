import { promptAction, router } from '@kit.ArkUI'

/**
 * 统一封装路由与 Toast，避免页面内重复处理弃用 API 的异常警告。
 */
export class UiHelper {

  static showToast(message: string): void {
    try {
      promptAction.showToast({ message: message })
    } catch (err) {
      console.error(`showToast failed: ${JSON.stringify(err)}`)
    }
  }

  static replaceTo(url: string): void {
    try {
      router.replaceUrl({ url: url })
    } catch (err) {
      console.error(`replaceUrl failed: ${JSON.stringify(err)}`)
    }
  }

  static pushTo(url: string): void {
    try {
      router.pushUrl({ url: url })
    } catch (err) {
      console.error(`pushUrl failed: ${JSON.stringify(err)}`)
    }
  }

  static goBack(): void {
    try {
      router.back()
    } catch (err) {
      console.error(`back failed: ${JSON.stringify(err)}`)
    }
  }
}
