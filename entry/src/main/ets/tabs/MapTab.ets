import { ZoneCard, ZonePostItem } from '../model/MoodWallTypes'
import { MoodApi } from '../service/MoodApi'
import { AppTheme } from '../common/AppTheme'

@Component
export struct MapTab {
  @State zones: Array<ZoneCard> = []
  @State mapSummary: string = ''
  @State loading: boolean = true
  @State showZoneSheet: boolean = false
  @State selectedZoneKey: string = ''
  @State selectedZoneTitle: string = ''
  @State zonePosts: Array<ZonePostItem> = []
  @State zonePostsLoading: boolean = false
  onNavigateToPost: () => void = () => {}

  aboutToAppear(): void {
    this.loadZones()
  }

  loadZones(): void {
    this.loading = true
    MoodApi.getMapZones()
      .then((res) => {
        this.mapSummary = res.summary
        this.zones = res.zones
        this.loading = false
      })
      .catch((err: Error) => {
        this.loading = false
        console.error(`loadZones failed: ${err.message}`)
      })
  }

  openZonePosts(zone: ZoneCard): void {
    this.selectedZoneKey = zone.key
    this.selectedZoneTitle = zone.title
    this.showZoneSheet = true
    this.loadZonePosts(zone.key)
  }

  loadZonePosts(zoneKey: string): void {
    this.zonePostsLoading = true
    MoodApi.getZonePosts(zoneKey, 1, 10)
      .then((res) => {
        this.zonePosts = res.list
        this.zonePostsLoading = false
      })
      .catch(() => {
        this.zonePostsLoading = false
      })
  }

  @Builder
  buildZoneSheet() {
    Column() {
      Row() {
        Text(this.selectedZoneTitle)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppTheme.TEXT_TITLE)
        Blank()
        Text('关闭')
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppTheme.TEXT_HINT)
          .onClick(() => {
            this.showZoneSheet = false
          })
      }
      .width('100%')
      .padding({ top: 20, bottom: 16 })

      if (this.zonePostsLoading) {
        Column() {
          LoadingProgress()
            .width(32)
            .height(32)
            .color(AppTheme.PRIMARY)
        }
        .width('100%')
        .padding(40)
        .justifyContent(FlexAlign.Center)
      } else if (this.zonePosts.length === 0) {
        Text('该区域暂无心情纸条')
          .fontSize(13)
          .fontColor(AppTheme.TEXT_HINT)
          .padding(40)
      } else {
        List() {
          ForEach(this.zonePosts, (item: ZonePostItem) => {
            ListItem() {
              Column({ space: 8 }) {
                Text(item.content)
                  .fontSize(14)
                  .lineHeight(22)
                  .fontColor(AppTheme.TEXT_PRIMARY)
                Row() {
                  Text(item.location)
                    .fontSize(11)
                    .fontColor(AppTheme.TEXT_HINT)
                  Blank()
                  Text(`❤ ${item.likeCount}`)
                    .fontSize(11)
                    .fontColor(AppTheme.TEXT_HINT)
                }
                .width('100%')
              }
              .width('100%')
              .padding(14)
              .backgroundColor(AppTheme.CARD)
              .borderRadius(16)
            }
            .margin({ bottom: 10 })
          }, (item: ZonePostItem) => `${item.id}`)
        }
        .scrollBar(BarState.Off)
        .constraintSize({ maxHeight: 400 })
      }
    }
    .width('100%')
    .padding({ left: 20, right: 20, bottom: 20 })
    .backgroundColor(AppTheme.CARD)
    .borderRadius({ topLeft: 24, topRight: 24 })
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column({ space: 14 }) {
        if (this.loading) {
          Column() {
            LoadingProgress()
              .width(36)
              .height(36)
              .color(AppTheme.PRIMARY)
          }
          .width('100%')
          .padding(60)
          .justifyContent(FlexAlign.Center)
        } else {
          Column({ space: 10 }) {
            Text('今日校园情绪气候')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppTheme.TEXT_TITLE)
            Text(this.mapSummary)
              .fontSize(12)
              .lineHeight(20)
              .fontColor(AppTheme.TEXT_SECONDARY)
          }
          .width('100%')
          .padding(18)
          .backgroundColor(AppTheme.CARD_MINE)
          .borderRadius(24)

          ForEach(this.zones, (zone: ZoneCard) => {
            Column({ space: 10 }) {
              Row() {
                Column({ space: 4 }) {
                  Text(zone.title)
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(AppTheme.TEXT_TITLE)
                  Text(`${zone.subtitle} · ${zone.postCount ?? 0} 条心情`)
                    .fontSize(12)
                    .fontColor(zone.accent)
                }
                .alignItems(HorizontalAlign.Start)

                Text('查看')
                  .fontSize(12)
                  .fontColor(AppTheme.PRIMARY)
                  .onClick(() => {
                    this.openZonePosts(zone)
                  })
              }
              .justifyContent(FlexAlign.SpaceBetween)
              .width('100%')

              Text(zone.summary)
                .fontSize(13)
                .lineHeight(21)
                .fontColor(AppTheme.TEXT_HINT)

              Text('去写一张纸条 +')
                .fontSize(12)
                .fontWeight(FontWeight.Bold)
                .fontColor(Color.White)
                .padding({ left: 14, right: 14, top: 9, bottom: 9 })
                .backgroundColor(AppTheme.PRIMARY)
                .borderRadius(18)
                .onClick(() => {
                  this.onNavigateToPost()
                })
            }
            .width('100%')
            .padding(18)
            .backgroundColor(AppTheme.CARD)
            .borderRadius(24)
          }, (zone: ZoneCard) => zone.key)
        }
      }

      if (this.showZoneSheet) {
        Column()
          .width('100%')
          .height('100%')
          .position({ x: 0, y: 0 })
          .backgroundColor(AppTheme.OVERLAY)
          .onClick(() => {
            this.showZoneSheet = false
          })
      }

      if (this.showZoneSheet) {
        this.buildZoneSheet()
      }
    }
  }
}
