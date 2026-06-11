/**
 * 校本部平面图热点坐标（相对底图宽高百分比）。
 * 若点击位置与地图不符，只需微调 xPercent / yPercent。
 */
export interface CampusMapHotspot {
  zoneKey: string
  xPercent: number
  yPercent: number
}

export class CampusMapConfig {
  static readonly MAP_RESOURCE: Resource = $r('app.media.map')

  static readonly HOTSPOTS: Array<CampusMapHotspot> = [
    { zoneKey: 'library', xPercent: 46, yPercent: 52 },
    { zoneKey: 'living', xPercent: 62, yPercent: 38 },
    { zoneKey: 'lake', xPercent: 40, yPercent: 16 },
    { zoneKey: 'activity', xPercent: 52, yPercent: 28 },
    { zoneKey: 'sports', xPercent: 28, yPercent: 76 },
    { zoneKey: 'history', xPercent: 24, yPercent: 22 },
    { zoneKey: 'medical', xPercent: 72, yPercent: 10 },
    { zoneKey: 'railway', xPercent: 78, yPercent: 90 }
  ]

  static findHotspot(zoneKey: string): CampusMapHotspot | undefined {
    for (let i: number = 0; i < CampusMapConfig.HOTSPOTS.length; i++) {
      if (CampusMapConfig.HOTSPOTS[i].zoneKey === zoneKey) {
        return CampusMapConfig.HOTSPOTS[i]
      }
    }
    return undefined
  }
}
