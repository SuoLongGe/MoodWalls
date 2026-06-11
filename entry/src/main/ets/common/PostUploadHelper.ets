import { common } from '@kit.AbilityKit'
import { util } from '@kit.ArkTS'
import { fileIo as fs } from '@kit.CoreFileKit'

export class PostUploadHelper {

  static readImageBase64(context: common.UIAbilityContext, sourceUri: string): string {
    const fileName: string = `post_${Date.now()}.jpg`
    const destPath: string = `${context.cacheDir}/${fileName}`
    const srcFile = fs.openSync(sourceUri, fs.OpenMode.READ_ONLY)
    const destFile = fs.openSync(destPath, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY)
    fs.copyFileSync(srcFile.fd, destFile.fd)
    fs.closeSync(srcFile)
    fs.closeSync(destFile)

    const stat = fs.statSync(destPath)
    const buffer: ArrayBuffer = new ArrayBuffer(stat.size)
    const readFile = fs.openSync(destPath, fs.OpenMode.READ_ONLY)
    fs.readSync(readFile.fd, buffer)
    fs.closeSync(readFile)

    const base64Helper: util.Base64Helper = new util.Base64Helper()
    const bytes: Uint8Array = new Uint8Array(buffer)
    return base64Helper.encodeToStringSync(bytes)
  }
}
