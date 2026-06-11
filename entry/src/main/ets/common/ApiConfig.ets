import { getLocalBaseUrl } from './ApiConfig.local'

/**
 * 后端 API 根地址，实际值在 ApiConfig.local.ets 中配置（见 docs/本地配置注意事项.md）
 */
export class ApiConfig {
  static readonly BASE_URL: string = getLocalBaseUrl()

  /** 去掉 /api 后缀，用于拼接图片等静态资源地址 */
  static getServerOrigin(): string {
    const base: string = ApiConfig.BASE_URL
    if (base.endsWith('/api')) {
      return base.substring(0, base.length - 4)
    }
    if (base.endsWith('/api/')) {
      return base.substring(0, base.length - 5)
    }
    return base
  }
}
