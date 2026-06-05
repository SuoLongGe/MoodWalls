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

  static pushToPostDetail(postId: number, scrollToComments: boolean = false): void {
    try {
      router.pushUrl({
        url: 'pages/PostDetailPage',
        params: {
          postId: postId,
          scrollToComments: scrollToComments
        }
      })
    } catch (err) {
      console.error(`pushToPostDetail failed: ${JSON.stringify(err)}`)
    }
  }

  static markFeedNeedsRefresh(): void {
    const tick: number | undefined = AppStorage.get<number>('postDetailRefreshTick')
    const next: number = tick !== undefined ? tick + 1 : 1
    AppStorage.setOrCreate('postDetailRefreshTick', next)
  }

  static goBack(): void {
    try {
      router.back()
    } catch (err) {
      console.error(`back failed: ${JSON.stringify(err)}`)
    }
  }

  static showConfirmDialog(title: string, message: string, onConfirm: () => void): void {
    try {
      promptAction.showDialog({
        title: title,
        message: message,
        buttons: [
          { text: '取消', color: '#999999' },
          { text: '删除', color: '#E17272' }
        ]
      }).then((result) => {
        if (result.index === 1) {
          onConfirm()
        }
      }).catch((err: Error) => {
        console.error(`showDialog failed: ${err.message}`)
      })
    } catch (err) {
      console.error(`showDialog failed: ${JSON.stringify(err)}`)
    }
  }
}
