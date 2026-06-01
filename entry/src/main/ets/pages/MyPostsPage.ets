import { AuthTheme } from '../common/AuthTheme'
import { AuthSession } from '../common/AuthSession'
import { UiHelper } from '../common/UiHelper'
import { PostSummary } from '../model/ProfileApiTypes'
import { ProfileApi } from '../service/ProfileApi'

@Entry
@Component
struct MyPostsPage {
  @State posts: Array<PostSummary> = []
  @State loading: boolean = true
  @State loadingMore: boolean = false
  @State page: number = 1
  @State hasMore: boolean = false

  aboutToAppear(): void {
    if (!AuthSession.isLoggedIn()) {
      UiHelper.replaceTo('pages/Login')
      return
    }
    this.loadPosts(true)
  }

  loadPosts(reset: boolean): void {
    if (reset) {
      this.loading = true
      this.page = 1
    } else {
      if (!this.hasMore || this.loadingMore) {
        return
      }
      this.loadingMore = true
    }

    const requestPage: number = reset ? 1 : this.page
    ProfileApi.getMyPosts(requestPage, 20).then((result) => {
      if (reset) {
        this.posts = result.list
      } else {
        const merged: Array<PostSummary> = []
        this.posts.forEach((item: PostSummary) => merged.push(item))
        result.list.forEach((item: PostSummary) => merged.push(item))
        this.posts = merged
      }
      this.hasMore = result.hasMore
      this.page = result.page + 1
    }).catch((err: Error) => {
      UiHelper.showToast(err.message)
    }).finally(() => {
      this.loading = false
      this.loadingMore = false
    })
  }

  @Builder
  buildPostCard(item: PostSummary) {
    Column({ space: 12 }) {
      Row() {
        Text(item.moodLabel)
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor(item.color)
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .backgroundColor('#FFFFFF')
          .borderRadius(16)
        Text(item.timeText)
          .fontSize(11)
          .fontColor('#95A19F')
      }
      .justifyContent(FlexAlign.SpaceBetween)
      .width('100%')

      Text(item.text)
        .fontSize(15)
        .lineHeight(23)
        .fontColor('#25332F')

      Row() {
        Text(`位置：${item.location}`)
          .fontSize(12)
          .fontColor('#7C8A87')
        Text(`赞 ${item.likes}`)
          .fontSize(12)
          .fontColor('#7C8A87')
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(20)
  }

  build() {
    Column() {
      Row() {
        Text('<')
          .fontSize(18)
          .fontColor('#31534A')
          .padding(12)
          .onClick(() => UiHelper.goBack())
        Text('我的帖子')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#25332F')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        Text('')
          .width(42)
      }
      .width('100%')
      .padding({ left: 4, right: 16, top: 8, bottom: 8 })
      .backgroundColor('#F9FBFA')

      if (this.loading) {
        Column() {
          LoadingProgress()
            .width(36)
            .height(36)
            .color(AuthTheme.PRIMARY)
          Text('加载中...')
            .fontSize(13)
            .fontColor('#6E7C79')
            .margin({ top: 12 })
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .width('100%')
      } else if (this.posts.length === 0) {
        Column({ space: 8 }) {
          Text('还没有帖子')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#31534A')
          Text('去发布页写下第一条心情吧')
            .fontSize(13)
            .fontColor('#6E7C79')
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .width('100%')
      } else {
        Scroll() {
          Column({ space: 12 }) {
            ForEach(this.posts, (item: PostSummary) => {
              this.buildPostCard(item)
            }, (item: PostSummary) => `${item.id}`)

            if (this.hasMore) {
              Row() {
                if (this.loadingMore) {
                  LoadingProgress()
                    .width(24)
                    .height(24)
                    .color(AuthTheme.PRIMARY)
                } else {
                  Text('加载更多')
                    .fontSize(13)
                    .fontColor(AuthTheme.PRIMARY)
                }
              }
              .width('100%')
              .justifyContent(FlexAlign.Center)
              .padding(16)
              .onClick(() => this.loadPosts(false))
            }
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 8, bottom: 24 })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F4F7F6')
  }
}
