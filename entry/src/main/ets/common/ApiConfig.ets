import { getLocalBaseUrl } from './ApiConfig.local'

/**
 * 后端 API 根地址，实际值在 ApiConfig.local.ets 中配置（见 docs/本地配置注意事项.md）
 */
export class ApiConfig {
  static readonly BASE_URL: string = getLocalBaseUrl()
}
