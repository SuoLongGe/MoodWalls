import { photoAccessHelper } from '@kit.MediaLibraryKit'

export class ImagePickerHelper {

  static async pickOne(): Promise<string> {
    try {
      const options: photoAccessHelper.PhotoSelectOptions = new photoAccessHelper.PhotoSelectOptions()
      options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE
      options.maxSelectNumber = 1
      const picker: photoAccessHelper.PhotoViewPicker = new photoAccessHelper.PhotoViewPicker()
      const result: photoAccessHelper.PhotoSelectResult = await picker.select(options)
      if (result.photoUris.length === 0) {
        return ''
      }
      return result.photoUris[0]
    } catch (e) {
      return ''
    }
  }
}
