import { AppTheme } from '../common/AppTheme'
import { moodIndex } from '../common/MoodIndexConfig'
import { MoodCurvePoint } from '../model/MoodWallTypes'

@Component
export struct MoodCurveChart {
  @Prop points: Array<MoodCurvePoint> = []
  @Prop summary: string = ''
  @Prop @Watch('onDataChanged') refreshKey: number = 0
  @State selectedIndex: number = -1
  @State chartWidth: number = 300

  private readonly chartHeight: number = 180
  private readonly padLeft: number = 24
  private readonly padRight: number = 12
  private readonly padTop: number = 16
  private readonly padBottom: number = 28
  private settings: RenderingContextSettings = new RenderingContextSettings(true)
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings)

  private plotWidth(): number {
    return Math.max(this.chartWidth - this.padLeft - this.padRight, 1)
  }

  private plotHeight(): number {
    return this.chartHeight - this.padTop - this.padBottom
  }

  private pointX(index: number): number {
    const count: number = this.points.length
    if (count <= 1) {
      return this.padLeft + this.plotWidth() / 2
    }
    return this.padLeft + (index / (count - 1)) * this.plotWidth()
  }

  private pointY(mood: string): number {
    const idx: number = moodIndex(mood)
    const level: number = idx >= 0 ? idx : 0
    return this.padTop + (1 - level / 7) * this.plotHeight()
  }

  onDataChanged(): void {
    this.drawChart()
  }

  private hasData(point: MoodCurvePoint): boolean {
    return point.dominantMood !== undefined &&
      point.dominantMood !== null &&
      point.dominantMood.length > 0
  }

  private drawChart(): void {
    const ctx: CanvasRenderingContext2D = this.context
    const w: number = this.chartWidth
    const h: number = this.chartHeight
    ctx.clearRect(0, 0, w, h)

    ctx.strokeStyle = '#E8ECEB'
    ctx.lineWidth = 1
    for (let i: number = 0; i <= 7; i++) {
      const y: number = this.padTop + (i / 7) * this.plotHeight()
      ctx.beginPath()
      ctx.moveTo(this.padLeft, y)
      ctx.lineTo(w - this.padRight, y)
      ctx.stroke()
    }

    const segments: Array<Array<number>> = []
    let current: Array<number> = []
    for (let i: number = 0; i < this.points.length; i++) {
      if (this.hasData(this.points[i])) {
        current.push(i)
      } else if (current.length > 0) {
        segments.push(current)
        current = []
      }
    }
    if (current.length > 0) {
      segments.push(current)
    }

    segments.forEach((segment: Array<number>) => {
      if (segment.length < 2) {
        return
      }
      const first: MoodCurvePoint = this.points[segment[0]]
      const firstMood: string = first.dominantMood !== undefined && first.dominantMood !== null
        ? first.dominantMood
        : 'calm'
      const segmentColor: string = first.color !== undefined && first.color !== null && first.color.length > 0
        ? first.color
        : '#73C088'

      ctx.beginPath()
      ctx.moveTo(this.pointX(segment[0]), this.pointY(firstMood))
      for (let j: number = 1; j < segment.length; j++) {
        const idx: number = segment[j]
        const point: MoodCurvePoint = this.points[idx]
        const mood: string = point.dominantMood !== undefined && point.dominantMood !== null
          ? point.dominantMood
          : 'calm'
        ctx.lineTo(this.pointX(idx), this.pointY(mood))
      }
      ctx.strokeStyle = segmentColor
      ctx.lineWidth = 2
      ctx.stroke()

      ctx.beginPath()
      ctx.moveTo(this.pointX(segment[0]), this.padTop + this.plotHeight())
      ctx.lineTo(this.pointX(segment[0]), this.pointY(firstMood))
      for (let j: number = 1; j < segment.length; j++) {
        const idx: number = segment[j]
        const point: MoodCurvePoint = this.points[idx]
        const mood: string = point.dominantMood !== undefined && point.dominantMood !== null
          ? point.dominantMood
          : 'calm'
        ctx.lineTo(this.pointX(idx), this.pointY(mood))
      }
      const lastIdx: number = segment[segment.length - 1]
      ctx.lineTo(this.pointX(lastIdx), this.padTop + this.plotHeight())
      ctx.closePath()
      ctx.fillStyle = segmentColor
      ctx.globalAlpha = 0.15
      ctx.fill()
      ctx.globalAlpha = 1
    })

    for (let i: number = 0; i < this.points.length; i++) {
      const point: MoodCurvePoint = this.points[i]
      if (!this.hasData(point)) {
        continue
      }
      const mood: string = point.dominantMood !== undefined && point.dominantMood !== null
        ? point.dominantMood
        : 'calm'
      const color: string = point.color !== undefined && point.color !== null && point.color.length > 0
        ? point.color
        : '#73C088'
      const x: number = this.pointX(i)
      const y: number = this.pointY(mood)
      ctx.beginPath()
      ctx.arc(x, y, 4, 0, Math.PI * 2)
      ctx.fillStyle = color
      ctx.fill()
      if (this.selectedIndex === i) {
        ctx.strokeStyle = AppTheme.PRIMARY
        ctx.lineWidth = 2
        ctx.stroke()
      }
    }

    ctx.fillStyle = '#95A19F'
    ctx.font = '10vp sans-serif'
    ctx.textAlign = 'center'
    for (let i: number = 0; i < this.points.length; i++) {
      const weekday: string = this.points[i].weekday
      ctx.fillText(weekday, this.pointX(i), h - 8)
    }
  }

  private tooltipText(): string {
    if (this.selectedIndex < 0 || this.selectedIndex >= this.points.length) {
      return ''
    }
    const point: MoodCurvePoint = this.points[this.selectedIndex]
    if (!this.hasData(point)) {
      return `周${point.weekday} · 无记录`
    }
    const label: string = point.label !== undefined && point.label !== null ? point.label : '心情'
    return `周${point.weekday} · ${label} · ${point.postCount} 条心情`
  }

  @Builder
  buildTapLayer() {
    Row() {
      ForEach(this.points, (_: MoodCurvePoint, index: number) => {
        Column()
          .layoutWeight(1)
          .height(this.chartHeight)
          .onClick(() => {
            this.selectedIndex = this.selectedIndex === index ? -1 : index
            this.drawChart()
          })
      }, (_: MoodCurvePoint, index: number) => `tap-${this.refreshKey}-${index}`)
    }
    .width('100%')
    .height(this.chartHeight)
  }

  build() {
    Column({ space: 10 }) {
      Stack({ alignContent: Alignment.TopStart }) {
        Canvas(this.context)
          .width('100%')
          .height(this.chartHeight)
          .onReady(() => {
            this.drawChart()
          })
          .onAreaChange((_: Area, newArea: Area) => {
            const nextWidth: number = Number(newArea.width)
            if (nextWidth > 0 && nextWidth !== this.chartWidth) {
              this.chartWidth = nextWidth
              this.drawChart()
            }
          })

        this.buildTapLayer()
      }
      .width('100%')

      if (this.selectedIndex >= 0) {
        Text(this.tooltipText())
          .fontSize(12)
          .fontColor(AppTheme.PRIMARY)
          .width('100%')
          .textAlign(TextAlign.Center)
      }

      if (this.summary.length > 0) {
        Text(this.summary)
          .fontSize(13)
          .lineHeight(20)
          .fontColor(AppTheme.TEXT_SECONDARY)
          .width('100%')
      }
    }
    .width('100%')
  }
}
