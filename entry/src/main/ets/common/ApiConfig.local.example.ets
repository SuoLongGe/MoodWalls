/**
 * 复制本文件为 ApiConfig.local.ets，并修改为你的电脑局域网 IP。
 * ApiConfig.local.ets 已被 Git 忽略，不会提交到仓库。
 *
 * 获取 IP（Windows）：ipconfig，查看 IPv4 地址
 * 真机/模拟器不要使用 localhost，需使用电脑局域网 IP
 */
export function getLocalBaseUrl(): string {
  return 'http://YOUR_LAN_IP:8080/api'
}
