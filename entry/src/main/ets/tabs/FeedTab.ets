import { NoteItem } from '../model/MoodWallTypes'
import { PostApi } from '../service/PostApi'
import { AuthSession } from '../common/AuthSession'
import { UiHelper } from '../common/UiHelper'

@Component
export struct FeedTab {
  @Link notes: Array<NoteItem>
  @Prop filterMood: string = 'all'
  @Prop hasMore: boolean = false
  @Prop loadingMore: boolean = false
  @State private refreshKey: number = 0
  onSupportNote: (note: NoteItem) => void = () => {}
  onFilterChange: (mood: string) => void = () => {}
  onLoadMore: () => void = () => {}
  onRefresh: () => void = () => {}
  @Link isRefreshing: boolean

  private applyNoteUpdate(noteId: number, likes: number, liked: boolean): void {
    const u: NoteItem[] = this.notes.concat()
    const i: number = u.findIndex((n: NoteItem) => n.id === noteId)
    if (i >= 0) {
      u[i] = {
        id: u[i].id,
        userId: u[i].userId,
        nickname: u[i].nickname,
        mood: u[i].mood,
        moodLabel: u[i].moodLabel,
        text: u[i].text,
        location: u[i].location,
        zoneKey: u[i].zoneKey,
        timeText: u[i].timeText,
        likes: likes,
        liked: liked,
        color: u[i].color,
        createdAt: u[i].createdAt
      }
      this.notes = u
      this.refreshKey++
    }
  }

  private handleLike(noteId: number): void {
    const idx: number = this.notes.findIndex((n: NoteItem) => n.id === noteId)
    if (idx < 0) return
    const note: NoteItem = this.notes[idx]
    if (!note.liked) {
      this.applyNoteUpdate(noteId, note.likes + 1, true)
    }

    const token: string = AuthSession.getToken()
    if (token.length > 0) {
      PostApi.likePost(noteId, token)
        .then((res) => {
          this.applyNoteUpdate(noteId, res.likes, res.liked)
        })
        .catch((e: Error) => {
          console.error('点赞操作失败: ' + e.message)
          const msg = e.message || ''
          if (msg.includes('未登录') || msg.includes('Token') || msg.includes('401')) {
            UiHelper.showToast('请先登录后再点赞')
          }
          this.applyNoteUpdate(noteId, note.likes, note.liked ?? false)
        })
    }
  }

  build() {
    Refresh({ refreshing: this.isRefreshing }) {
      Scroll() {
        Column({ space: 14 }) {
          this.buildFilterChips()
          List() {
            ForEach(this.notes, (item: NoteItem) => {
              ListItem() {
                this.buildNoteCard(item)
              }
              .padding({ bottom: 14 })
            }, (item: NoteItem) => `${item.id}-${this.refreshKey}`)

            if (this.hasMore) {
              ListItem() {
                Row() {
                  if (this.loadingMore) {
                    Text('加载更多...')
                      .fontSize(13)
                      .fontColor('#7C8A87')
                  } else {
                    Text('上拉加载更多')
                      .fontSize(13)
                      .fontColor('#7C8A87')
                  }
                }
                .width('100%')
                .justifyContent(FlexAlign.Center)
                .padding({ top: 8, bottom: 8 })
              }
              .onClick(() => {
                if (!this.loadingMore) {
                  this.onLoadMore()
                }
              })
            }

            if (!this.hasMore && this.notes.length > 0) {
              ListItem() {
                Text('— 没有更多了 —')
                  .fontSize(12)
                  .fontColor('#B0B8B6')
                  .width('100%')
                  .textAlign(TextAlign.Center)
                  .padding({ top: 8, bottom: 8 })
              }
            }

            if (this.notes.length === 0) {
              ListItem() {
                Column({ space: 8 }) {
                  Text('暂无帖子')
                    .fontSize(16)
                    .fontColor('#7C8A87')
                  Text('成为第一个分享心情的人吧')
                    .fontSize(13)
                    .fontColor('#B0B8B6')
                }
                .width('100%')
                .padding({ top: 40, bottom: 40 })
                .alignItems(HorizontalAlign.Center)
              }
            }
          }
          .width('100%')
          .listDirection(Axis.Vertical)
          .divider({ strokeWidth: 0 })
          .sticky(StickyStyle.None)
          .onScrollIndex((startIndex: number) => {
            const threshold = this.notes.length - 3
            if (startIndex >= threshold && !this.loadingMore && this.hasMore) {
              this.onLoadMore()
            }
          })
        }
      }
      .scrollBar(BarState.Off)
    }
    .onStateChange((state: number) => {
      if (state === 1) {
        this.isRefreshing = true
        this.onRefresh()
      }
      if (state === 2) {
        this.isRefreshing = false
      }
    })
    .width('100%')
    .layoutWeight(1)
  }

  @Builder
  buildFilterChips() {
    Scroll() {
      Row({ space: 8 }) {
        this.buildFilterChip('all', '全部')
        this.buildFilterChip('happy', '开心')
        this.buildFilterChip('calm', '平静')
        this.buildFilterChip('moved', '感动')
        this.buildFilterChip('anxious', '焦虑')
        this.buildFilterChip('sad', '低落')
        this.buildFilterChip('tired', '疲惫')
      }
      .padding({ top: 6, bottom: 6 })
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
  }

  @Builder
  buildFilterChip(key: string, label: string) {
    Text(label)
      .fontSize(12)
      .fontWeight(this.filterMood === key ? FontWeight.Bold : FontWeight.Medium)
      .fontColor(this.filterMood === key ? Color.White : '#60706C')
      .padding({ left: 14, right: 14, top: 9, bottom: 9 })
      .backgroundColor(this.filterMood === key ? '#31534A' : Color.White)
      .borderRadius(18)
      .onClick(() => {
        if (this.filterMood !== key) {
          this.onFilterChange(key)
        }
      })
  }

  @Builder
  buildNoteCard(item: NoteItem) {
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
        if (item.nickname) {
          Text(item.nickname)
            .fontSize(11)
            .fontColor('#B0B8B6')
        }
      }
      .justifyContent(FlexAlign.SpaceBetween)
      .width('100%')

      Text(item.text)
        .fontSize(15)
        .lineHeight(23)
        .fontColor('#25332F')

      Text(`位置：${item.location}`)
        .fontSize(12)
        .fontColor('#7C8A87')

      Row() {
        this.buildLikeButton(item)

        Text('接住心声')
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor('#31534A')
          .padding({ left: 16, right: 16, top: 9, bottom: 9 })
          .backgroundColor('#F3F8F6')
          .borderRadius(18)
          .onClick(() => {
            this.onSupportNote(item)
          })
      }
      .justifyContent(FlexAlign.SpaceBetween)
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(24)
    .border({ width: { left: 5 }, color: item.color })
  }

  @Builder
  buildLikeButton(item: NoteItem) {
    Column({ space: 4 }) {
      Text(item.liked ? '❤' : '🤍')
        .fontSize(18)
        .fontColor(item.liked ? '#E85A5A' : '#B0B8B6')
      Text(`${item.likes}`)
        .fontSize(11)
        .fontColor(item.liked ? '#E85A5A' : '#7D8A88')
    }
    .padding({ left: 10, right: 10, top: 6, bottom: 6 })
    .backgroundColor(item.liked ? '#FFF0F0' : '#F5F5F5')
    .borderRadius(12)
    .onClick(() => {
      this.handleLike(item.id)
    })
  }
}
