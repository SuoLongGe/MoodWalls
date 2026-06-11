import { getAvatarResource } from '../common/AvatarResources'
import { MediaUrl } from '../common/MediaUrl'

@Component
export struct UserAvatar {
  @Prop avatarKey: string = 'avatar_01'
  @Prop avatarUrl: string = ''
  @Prop avatarSize: number = 40

  private resolvedUrl(): string | undefined {
    if (this.avatarUrl === undefined || this.avatarUrl === null || this.avatarUrl.length === 0) {
      return undefined
    }
    return MediaUrl.resolve(this.avatarUrl)
  }

  build() {
    if (this.resolvedUrl() !== undefined) {
      Image(this.resolvedUrl())
        .width(this.avatarSize)
        .height(this.avatarSize)
        .borderRadius(this.avatarSize / 2)
        .objectFit(ImageFit.Cover)
    } else {
      Image(getAvatarResource(this.avatarKey))
        .width(this.avatarSize)
        .height(this.avatarSize)
        .borderRadius(this.avatarSize / 2)
        .objectFit(ImageFit.Cover)
    }
  }
}
