import { AppTheme } from '../common/AppTheme'
import { CampusMapConfig } from '../common/CampusMapConfig'
import { UiHelper } from '../common/UiHelper'
import { ZoneStorySheet } from '../components/ZoneStorySheet'
import { ZoneCard, ZonePostItem, ZoneStoryResponse } from '../model/MoodWallTypes'
import { MoodApi } from '../service/MoodApi'

interface MapZoneItem extends ZoneCard {
  xPercent: number
  yPercent: number
}

@Component
export struct MapTab {
  @State zones: Array<MapZoneItem> = []
  @State mapSummary: string = ''
  @State loading: boolean = true
  @State showStorySheet: boolean = false
  @State storyLoading: boolean = false
  @State zoneStory: ZoneStoryResponse | null = null
  @State showZoneSheet: boolean = false
  @State selectedZoneKey: string = ''
  @State selectedZoneTitle: string = ''
  @State zonePosts: Array<ZonePostItem> = []
  @State zonePostsLoading: boolean = false
  @State activeZoneKey: string = ''
  @State mapWidth: number = 0
  @State mapHeight: number = 0
  onNavigateToPost: () => void = () => {}

  private readonly HOTSPOT_SIZE: number = 80

  aboutToAppear(): void {
    this.loadZones()
  }

  private mergeZonesWithHotspots(zones: Array<ZoneCard>): Array<MapZoneItem> {
    const merged: Array<MapZoneItem> = []
    zones.forEach((zone: ZoneCard) => {
      const hotspot = CampusMapConfig.findHotspot(zone.key)
      if (hotspot !== undefined) {
        const item: MapZoneItem = {
          key: zone.key,
          title: zone.title,
          subtitle: zone.subtitle,
          summary: zone.summary,
          accent: zone.accent,
          postCount: zone.postCount,
          dominantMood: zone.dominantMood,
          xPercent: hotspot.xPercent,
          yPercent: hotspot.yPercent
        }
        merged.push(item)
      }
    })
    return merged
  }

  private hotspotLeft(zone: MapZoneItem): number {
    if (this.mapWidth <= 0) {
      return 0
    }
    return this.mapWidth * zone.xPercent / 100 - this.HOTSPOT_SIZE / 2
  }

  private hotspotTop(zone: MapZoneItem): number {
    if (this.mapHeight <= 0) {
      return 0
    }
    return this.mapHeight * zone.yPercent / 100 - this.HOTSPOT_SIZE / 2
  }

  loadZones(): void {
    this.loading = true
    MoodApi.getMapZones()
      .then((res) => {
        this.mapSummary = res.summary
        this.zones = this.mergeZonesWithHotspots(res.zones)
        this.loading = false
      })
      .catch((err: Error) => {
        this.loading = false
        console.error(`loadZones failed: ${err.message}`)
      })
  }

  openZoneStory(zone: MapZoneItem): void {
    this.activeZoneKey = zone.key
    this.selectedZoneKey = zone.key
    this.selectedZoneTitle = zone.title
    this.showStorySheet = true
    this.showZoneSheet = false
    this.zoneStory = null
    this.storyLoading = true
    MoodApi.getZoneStory(zone.key)
      .then((story: ZoneStoryResponse) => {
        this.zoneStory = story
      })
      .catch((err: Error) => {
        console.error(`loadZoneStory failed: ${err.message}`)
        UiHelper.showToast(err.message || '区域故事加载失败')
      })
      .finally(() => {
        this.storyLoading = false
      })
  }

  openZonePostsFromStory(): void {
    this.showStorySheet = false
    this.showZoneSheet = true
    this.loadZonePosts(this.selectedZoneKey)
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

  private postCountText(zone: MapZoneItem): string {
    const count: number = zone.postCount !== undefined ? zone.postCount : 0
    return count > 0 ? `${count}` : ''
  }

  @Builder
  buildSummaryCard() {
    Column({ space: 8 }) {
      Row({ space: 8 }) {
        Text('今日校园情绪气候')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppTheme.TEXT_TITLE)
        Blank()
        Text('点击地图热点查看')
          .fontSize(11)
          .fontColor(AppTheme.TEXT_HINT)
      }
      .width('100%')

      Text(this.mapSummary)
        .fontSize(12)
        .lineHeight(20)
        .fontColor(AppTheme.TEXT_SECONDARY)
        .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor(AppTheme.CARD_MINE)
    .borderRadius(AppTheme.RADIUS_LG)
  }

  @Builder
  buildHotspot(zone: MapZoneItem) {
    Column({ space: 4 }) {
      Stack({ alignContent: Alignment.Center }) {
        Circle()
          .width(this.activeZoneKey === zone.key ? 34 : 28)
          .height(this.activeZoneKey === zone.key ? 34 : 28)
          .fill(zone.accent)
          .opacity(0.22)
        Circle()
          .width(12)
          .height(12)
          .fill(zone.accent)
          .border({ width: 2, color: AppTheme.CARD })
      }

      if (this.postCountText(zone).length > 0) {
        Text(this.postCountText(zone))
          .fontSize(10)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          .backgroundColor(zone.accent)
          .borderRadius(10)
      }

      Text(zone.title)
        .fontSize(10)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppTheme.TEXT_PRIMARY)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .padding({ left: 6, right: 6, top: 3, bottom: 3 })
        .backgroundColor(AppTheme.CARD)
        .borderRadius(8)
        .shadow({
          radius: 6,
          color: AppTheme.SHADOW_LIGHT,
          offsetY: 2
        })
    }
    .width(this.HOTSPOT_SIZE)
    .height(this.HOTSPOT_SIZE)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .position({
      x: this.hotspotLeft(zone),
      y: this.hotspotTop(zone)
    })
    .zIndex(2)
    .hitTestBehavior(HitTestMode.Block)
    .onClick(() => {
      this.openZoneStory(zone)
    })
  }

  @Builder
  buildCampusMap() {
    Stack({ alignContent: Alignment.TopStart }) {
      Image(CampusMapConfig.MAP_RESOURCE)
        .width('100%')
        .objectFit(ImageFit.Contain)
        .borderRadius(AppTheme.RADIUS_LG)
        .backgroundColor(AppTheme.SURFACE)
        .onAreaChange((_: Area, newArea: Area) => {
          const nextWidth: number = Number(newArea.width)
          const nextHeight: number = Number(newArea.height)
          if (nextWidth > 0 && nextHeight > 0) {
            this.mapWidth = nextWidth
            this.mapHeight = nextHeight
          }
        })

      ForEach(this.zones, (zone: MapZoneItem) => {
        this.buildHotspot(zone)
      }, (zone: MapZoneItem) => zone.key)
    }
    .width('100%')
    .clip(true)
    .borderRadius(AppTheme.RADIUS_LG)
    .shadow({
      radius: 12,
      color: AppTheme.SHADOW_LIGHT,
      offsetY: 4
    })
  }

  @Builder
  buildZoneLegend() {
    Scroll() {
      Row({ space: 8 }) {
        ForEach(this.zones, (zone: MapZoneItem) => {
          Text(zone.title)
            .fontSize(11)
            .fontWeight(this.activeZoneKey === zone.key ? FontWeight.Bold : FontWeight.Medium)
            .fontColor(this.activeZoneKey === zone.key ? Color.White : AppTheme.TEXT_HINT)
            .padding({ left: 12, right: 12, top: 8, bottom: 8 })
            .backgroundColor(this.activeZoneKey === zone.key ? zone.accent : AppTheme.SURFACE)
            .borderRadius(AppTheme.RADIUS_PILL)
            .onClick(() => {
              this.openZoneStory(zone)
            })
        }, (zone: MapZoneItem) => `legend-${zone.key}`)
      }
      .padding({ top: 4, bottom: 4 })
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
  }

  @Builder
  buildStorySheet() {
    ZoneStorySheet({
      story: this.zoneStory,
      loading: this.storyLoading,
      onClose: () => {
        this.showStorySheet = false
        this.activeZoneKey = ''
      },
      onViewPosts: () => {
        this.openZonePostsFromStory()
      },
      onNavigateToPost: () => {
        this.showStorySheet = false
        this.activeZoneKey = ''
        this.onNavigateToPost()
      }
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
            this.activeZoneKey = ''
          })
      }
      .width('100%')
      .padding({ top: 20, bottom: 12 })

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
        Column({ space: 12 }) {
          Text('该区域暂无心情纸条')
            .fontSize(13)
            .fontColor(AppTheme.TEXT_HINT)
          Text('去写一张纸条 +')
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .padding({ left: 14, right: 14, top: 9, bottom: 9 })
            .backgroundColor(AppTheme.PRIMARY)
            .borderRadius(18)
            .onClick(() => {
              this.showZoneSheet = false
              this.onNavigateToPost()
            })
        }
        .width('100%')
        .padding({ top: 24, bottom: 24 })
        .alignItems(HorizontalAlign.Center)
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
              .backgroundColor(AppTheme.SURFACE)
              .borderRadius(AppTheme.RADIUS_MD)
            }
            .margin({ bottom: 10 })
          }, (item: ZonePostItem) => `${item.id}`)
        }
        .scrollBar(BarState.Off)
        .constraintSize({ maxHeight: 360 })
      }
    }
    .width('100%')
    .padding({ left: 20, right: 20, bottom: 20 })
    .backgroundColor(AppTheme.CARD)
    .borderRadius({ topLeft: 24, topRight: 24 })
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Scroll() {
        Column({ space: 14 }) {
          if (this.loading) {
          Column() {
            LoadingProgress()
              .width(36)
              .height(36)
              .color(AppTheme.PRIMARY)
            Text('加载校园地图...')
              .fontSize(13)
              .fontColor(AppTheme.TEXT_HINT)
              .margin({ top: 12 })
          }
          .width('100%')
          .padding({ top: 80, bottom: 80 })
          .justifyContent(FlexAlign.Center)
        } else {
          this.buildSummaryCard()
          this.buildCampusMap()
          this.buildZoneLegend()
        }
        }
        .width('100%')
      }
      .scrollBar(BarState.Off)
      .width('100%')
      .height('100%')

      if (this.showStorySheet || this.showZoneSheet) {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor(AppTheme.OVERLAY)
          .onClick(() => {
            this.showStorySheet = false
            this.showZoneSheet = false
            this.activeZoneKey = ''
          })
      }

      if (this.showStorySheet) {
        this.buildStorySheet()
      }

      if (this.showZoneSheet) {
        this.buildZoneSheet()
      }
    }
    .width('100%')
    .height('100%')
  }
}
