import { AuthTheme } from '../common/AuthTheme'
import { AppTheme } from '../common/AppTheme'
import { AuthSession } from '../common/AuthSession'
import { AVATAR_KEYS, getAvatarResource } from '../common/AvatarResources'
import { UiHelper } from '../common/UiHelper'
import { AuthInput } from '../components/auth/AuthInput'
import { CalendarCell, CalendarDay, CalendarResponse, ProfileOverview } from '../model/ProfileApiTypes'
import { NotificationStore } from '../common/NotificationStore'
import { ProfileStore } from '../common/ProfileStore'
import { AuthApi } from '../service/AuthApi'
import { ProfileApi } from '../service/ProfileApi'
import { InspirationDrawResponse, MoodCurvePoint, MoodStatItem } from '../model/MoodWallTypes'
import { InspirationApi } from '../service/InspirationApi'
import { PostApi } from '../service/PostApi'
import { InspirationCard } from '../components/InspirationCard'
import { MoodCurveChart } from '../components/MoodCurveChart'

type StatsPeriod = 'today' | 'week' | 'month'
type MoodViewTab = 'curve' | 'distribution'

@Component
export struct ProfileTab {
  @StorageLink('userNickname') userNickname: string = '同学'
  @StorageLink('userAccount') userAccount: string = ''
  @StorageLink('userAvatarKey') userAvatarKey: string = 'avatar_01'
  @Prop @Watch('onProfileRefreshTick') profileRefreshTick: number = 0
  onOpenReport: (report: string) => void = () => {}

  @State showEditProfile: boolean = false
  @State editNickname: string = ''
  @State editAvatarKey: string = 'avatar_01'
  @State oldPassword: string = ''
  @State newPassword: string = ''
  @State confirmPassword: string = ''
  @State saving: boolean = false

  @StorageLink('profilePostCount') postCount: number = 0
  @StorageLink('profileTotalLikes') totalLikes: number = 0
  @StorageLink('profileActiveDays') activeDays: number = 0
  @StorageLink('profileMoodClimate') moodClimate: string = '暂无记录'
  @StorageLink('profileCalmPercent') calmPercent: number = 0
  @StorageLink('profileAnxiousPercent') anxiousPercent: number = 0
  @StorageLink('profileHappyPercent') happyPercent: number = 0
  @StorageLink('unreadNotificationCount') unreadCount: number = 0
  @StorageLink('themeMode') themeMode: string = 'light'
  @State loadingProfile: boolean = true

  @State calendarMonth: string = ''
  @State calendarCells: Array<CalendarCell> = []
  @State calendarTitle: string = ''

  @State moodViewTab: MoodViewTab = 'curve'
  @State moodPeriod: StatsPeriod = 'week'
  @State moodStats: Array<MoodStatItem> = []
  @State moodStatsLoading: boolean = false
  @State moodCurveLoading: boolean = false
  @State moodCurvePoints: Array<MoodCurvePoint> = []
  @State moodCurveSummary: string = ''
  @State curveRefreshKey: number = 0

  @State inspirationLoading: boolean = false
  @State inspirationContent: string = ''
  @State inspirationMoodLabel: string = ''
  @State inspirationMoodColor: string = ''
  @State inspirationAlreadyDrawn: boolean = false

  aboutToAppear(): void {
    ProfileStore.ensureInitialized()
    this.calendarMonth = ProfileTab.formatMonthKey(new Date())
    this.refreshProfile()
    this.loadArchive()
    this.fetchMoodCurve()
    this.fetchMoodStats()
    this.loadInspirationToday()
  }

  onProfileRefreshTick(): void {
    if (this.profileRefreshTick > 0) {
      this.loadOverview()
      this.reloadCalendar()
      this.fetchMoodCurve()
      this.fetchMoodStats()
    }
  }

  private fetchMoodCurve(): void {
    if (!AuthSession.isLoggedIn()) {
      return
    }
    this.moodCurveLoading = true
    ProfileApi.getMoodCurve(7)
      .then((res) => {
        this.moodCurvePoints = res.points
        this.moodCurveSummary = res.summary
        this.curveRefreshKey++
      })
      .catch((err: Error) => {
        console.error(`fetchMoodCurve: ${err.message}`)
        this.moodCurvePoints = []
        this.moodCurveSummary = ''
      })
      .finally(() => {
        this.moodCurveLoading = false
      })
  }

  private hasCurveData(): boolean {
    for (let i: number = 0; i < this.moodCurvePoints.length; i++) {
      if (this.moodCurvePoints[i].postCount > 0) {
        return true
      }
    }
    return false
  }

  private selectMoodViewTab(tab: MoodViewTab): void {
    if (this.moodViewTab === tab) {
      return
    }
    this.moodViewTab = tab
    if (tab === 'distribution' && this.moodStats.length === 0 && !this.moodStatsLoading) {
      this.fetchMoodStats()
    }
  }

  private applyInspiration(res: InspirationDrawResponse): void {
    this.inspirationContent = res.content !== undefined ? res.content : ''
    this.inspirationMoodLabel = res.moodLabel !== undefined ? res.moodLabel : ''
    this.inspirationMoodColor = res.moodColor !== undefined ? res.moodColor : ''
    this.inspirationAlreadyDrawn = res.alreadyDrawn === true || this.inspirationContent.length > 0
  }

  private loadInspirationToday(): void {
    const token: string = AuthSession.getToken()
    if (token.length === 0) {
      return
    }
    this.inspirationLoading = true
    InspirationApi.getToday(token)
      .then((res: InspirationDrawResponse) => {
        this.applyInspiration(res)
      })
      .catch((err: Error) => {
        console.error(`loadInspirationToday: ${err.message}`)
      })
      .finally(() => {
        this.inspirationLoading = false
      })
  }

  private drawInspiration(): void {
    const token: string = AuthSession.getToken()
    if (token.length === 0) {
      UiHelper.showToast('请先登录')
      return
    }
    if (this.inspirationAlreadyDrawn) {
      return
    }
    this.inspirationLoading = true
    InspirationApi.draw(token)
      .then((res: InspirationDrawResponse) => {
        this.applyInspiration(res)
        UiHelper.showToast('收好这张小纸条吧')
      })
      .catch((err: Error) => {
        UiHelper.showToast(err.message || '抽取失败')
      })
      .finally(() => {
        this.inspirationLoading = false
      })
  }

  private fetchMoodStats(): void {
    this.moodStatsLoading = true
    PostApi.getMoodStats(this.moodPeriod).then((res) => {
      this.moodStats = res.items
      this.moodStatsLoading = false
    }).catch((err: Error) => {
      console.error(`fetchMoodStats: ${err.message}`)
      this.moodStats = []
      this.moodStatsLoading = false
    })
  }

  private selectMoodPeriod(period: StatsPeriod): void {
    if (this.moodPeriod === period) {
      return
    }
    this.moodPeriod = period
    this.fetchMoodStats()
  }

  private periodLabel(period: StatsPeriod): string {
    if (period === 'today') return '本日'
    if (period === 'month') return '本月'
    return '本周'
  }

  @Builder
  buildMoodViewChip(tab: MoodViewTab, label: string) {
    Text(label)
      .fontSize(12)
      .fontWeight(this.moodViewTab === tab ? FontWeight.Bold : FontWeight.Medium)
      .fontColor(this.moodViewTab === tab ? AppTheme.PRIMARY : AppTheme.TEXT_SECONDARY)
      .padding({ left: 12, right: 12, top: 6, bottom: 6 })
      .backgroundColor(this.moodViewTab === tab ? AppTheme.PRIMARY_SOFT : AppTheme.SURFACE)
      .borderRadius(14)
      .onClick(() => {
        this.selectMoodViewTab(tab)
      })
  }

  @Builder
  buildPeriodChip(period: StatsPeriod) {
    Text(this.periodLabel(period))
      .fontSize(12)
      .fontWeight(this.moodPeriod === period ? FontWeight.Bold : FontWeight.Medium)
      .fontColor(this.moodPeriod === period ? AppTheme.PRIMARY : AppTheme.TEXT_SECONDARY)
      .padding({ left: 12, right: 12, top: 6, bottom: 6 })
      .backgroundColor(this.moodPeriod === period ? AppTheme.PRIMARY_SOFT : AppTheme.SURFACE)
      .borderRadius(14)
      .onClick(() => {
        this.selectMoodPeriod(period)
      })
  }

  static formatMonthKey(date: Date): string {
    const month: number = date.getMonth() + 1
    const monthText: string = month < 10 ? `0${month}` : `${month}`
    return `${date.getFullYear()}-${monthText}`
  }

  static formatDateKey(year: number, month: number, day: number): string {
    const monthText: string = month < 10 ? `0${month}` : `${month}`
    const dayText: string = day < 10 ? `0${day}` : `${day}`
    return `${year}-${monthText}-${dayText}`
  }

  refreshProfile(): void {
    if (!AuthSession.isLoggedIn()) {
      return
    }
    AuthApi.getMe().then((profile) => {
      AuthSession.updateUser(profile)
    }).catch((err: Error) => {
      console.error(`refreshProfile: ${err.message}`)
    })
  }

  loadOverview(): void {
    if (!AuthSession.isLoggedIn()) {
      return
    }
    ProfileApi.getOverview().then((overview: ProfileOverview) => {
      ProfileStore.applyOverview(overview)
    }).catch((err: Error) => {
      console.error(`loadOverview: ${err.message}`)
      UiHelper.showToast(err.message || '加载个人数据失败')
    })
  }

  reloadCalendar(): void {
    if (!AuthSession.isLoggedIn()) {
      return
    }
    ProfileApi.getCalendar(this.calendarMonth).then((calendar) => {
      this.applyCalendar(calendar)
    }).catch((err: Error) => {
      console.error(`reloadCalendar: ${err.message}`)
    })
  }

  applyCalendar(calendar: CalendarResponse): void {
    this.calendarMonth = calendar.month
    this.calendarTitle = ProfileTab.formatMonthTitle(this.calendarMonth)
    this.calendarCells = ProfileTab.buildCalendarCells(this.calendarMonth, calendar.days)
  }

  loadArchive(): void {
    if (!AuthSession.isLoggedIn()) {
      return
    }
    this.loadingProfile = true
    this.loadOverview()
    ProfileApi.getCalendar(this.calendarMonth).then((calendar) => {
      this.applyCalendar(calendar)
      this.loadingProfile = false
    }).catch((err: Error) => {
      UiHelper.showToast(err.message)
      this.loadingProfile = false
    })
  }

  static formatMonthTitle(monthKey: string): string {
    const parts: Array<string> = monthKey.split('-')
    if (parts.length < 2) {
      return monthKey
    }
    return `${parts[0]}年${parseInt(parts[1])}月`
  }

  static buildCalendarCells(monthKey: string, days: Array<CalendarDay>): Array<CalendarCell> {
    const parts: Array<string> = monthKey.split('-')
    const year: number = parseInt(parts[0])
    const month: number = parseInt(parts[1])
    const firstDate: Date = new Date(year, month - 1, 1)
    const daysInMonth: number = new Date(year, month, 0).getDate()
    let startOffset: number = firstDate.getDay() - 1
    if (startOffset < 0) {
      startOffset = 6
    }

    const cells: Array<CalendarCell> = []
    for (let i: number = 0; i < startOffset; i++) {
      cells.push({ day: 0, isEmpty: true, color: '#F4F7F6', hasRecord: false })
    }
    for (let day: number = 1; day <= daysInMonth; day++) {
      const dateKey: string = ProfileTab.formatDateKey(year, month, day)
      const found: CalendarDay | undefined = ProfileTab.findCalendarDay(days, dateKey)
      cells.push({
        day: day,
        isEmpty: false,
        color: found !== undefined ? found.color : '#E8ECEB',
        hasRecord: found !== undefined
      })
    }
    return cells
  }

  static findCalendarDay(days: Array<CalendarDay>, dateKey: string): CalendarDay | undefined {
    for (let i: number = 0; i < days.length; i++) {
      if (days[i].date === dateKey) {
        return days[i]
      }
    }
    return undefined
  }

  shiftCalendarMonth(delta: number): void {
    const parts: Array<string> = this.calendarMonth.split('-')
    let year: number = parseInt(parts[0])
    let month: number = parseInt(parts[1])
    month += delta
    if (month < 1) {
      month = 12
      year -= 1
    }
    if (month > 12) {
      month = 1
      year += 1
    }
    this.calendarMonth = ProfileTab.formatMonthKey(new Date(year, month - 1, 1))
    ProfileApi.getCalendar(this.calendarMonth).then((calendar) => {
      this.applyCalendar(calendar)
    }).catch((err: Error) => {
      UiHelper.showToast(err.message)
    })
  }

  openWeeklyReport(): void {
    ProfileApi.getWeeklyReport().then((result) => {
      this.onOpenReport(result.report)
      NotificationStore.refreshUnreadCount()
    }).catch((err: Error) => {
      UiHelper.showToast(err.message)
    })
  }

  openEditProfile(): void {
    this.editNickname = this.userNickname
    this.editAvatarKey = this.userAvatarKey
    this.oldPassword = ''
    this.newPassword = ''
    this.confirmPassword = ''
    this.showEditProfile = true
  }

  saveAll(): void {
    if (this.saving) {
      return
    }
    if (this.editNickname.trim().length === 0) {
      UiHelper.showToast('昵称不能为空')
      return
    }
    const needChangePassword: boolean =
      this.oldPassword.length > 0 || this.newPassword.length > 0 || this.confirmPassword.length > 0
    if (needChangePassword) {
      if (this.oldPassword.length === 0 || this.newPassword.length === 0 || this.confirmPassword.length === 0) {
        UiHelper.showToast('修改密码请填写完整')
        return
      }
      if (this.newPassword.length < 8) {
        UiHelper.showToast('新密码长度至少 8 位')
        return
      }
      if (this.newPassword !== this.confirmPassword) {
        UiHelper.showToast('两次输入的新密码不一致')
        return
      }
    }

    this.saving = true
    AuthApi.updateProfile(this.editNickname.trim(), this.editAvatarKey).then((profile) => {
      AuthSession.updateUser(profile)
      if (!needChangePassword) {
        return Promise.resolve(false)
      }
      return AuthApi.changePassword(this.oldPassword, this.newPassword).then(() => true)
    }).then((passwordChanged: boolean) => {
      this.oldPassword = ''
      this.newPassword = ''
      this.confirmPassword = ''
      this.showEditProfile = false
      UiHelper.showToast(passwordChanged ? '资料与密码已更新' : '资料已更新')
      this.loadArchive()
    }).catch((err: Error) => {
      UiHelper.showToast(err.message)
    }).finally(() => {
      this.saving = false
    })
  }

  handleLogout(): void {
    AuthApi.logout().catch(() => {
    })
    ProfileStore.clear()
    AuthSession.clear()
    UiHelper.showToast('已退出登录')
    UiHelper.replaceTo('pages/Login')
  }

  @Builder
  buildWeekdayHeader(label: string) {
    Text(label)
      .fontSize(11)
      .fontColor('#95A19F')
      .width('14.28%')
      .textAlign(TextAlign.Center)
  }

  @Builder
  buildCalendarCell(cell: CalendarCell) {
    Column({ space: 4 }) {
      if (cell.isEmpty) {
        Text('')
          .fontSize(12)
          .height(12)
      } else {
        Text(`${cell.day}`)
          .fontSize(12)
          .fontColor(cell.hasRecord ? '#31534A' : '#B0BAB7')
        Circle()
          .width(cell.hasRecord ? 10 : 6)
          .height(cell.hasRecord ? 10 : 6)
          .fill(cell.color)
      }
    }
    .width('14.28%')
    .height(44)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  buildProgressRow(label: string, percent: number, color: string) {
    Row({ space: 10 }) {
      Text(label)
        .width(46)
        .fontSize(12)
        .fontColor(AppTheme.TEXT_SECONDARY)
      Stack({ alignContent: Alignment.Start }) {
        Row()
          .width('100%')
          .height(28)
          .backgroundColor(AppTheme.SURFACE)
          .borderRadius(14)
        Row() {
          Text(`${percent}%`)
            .fontSize(11)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppTheme.TEXT_PRIMARY)
        }
        .height(28)
        .width(`${percent}%`)
        .padding({ left: 10 })
        .backgroundColor(color)
        .borderRadius(14)
      }
      .layoutWeight(1)
    }
    .width('100%')
  }

  @Builder
  buildSettingRow(title: string, onTap: () => void) {
    Row() {
      Text(title)
        .fontSize(14)
        .fontColor(AppTheme.PRIMARY)
      Text('>')
        .fontSize(14)
        .fontColor(AppTheme.TEXT_HINT)
    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceBetween)
    .padding({ top: 14, bottom: 14 })
    .onClick(() => onTap())
  }

  private toggleTheme(): void {
    const next: string = this.themeMode === 'dark' ? 'light' : 'dark'
    AppStorage.setOrCreate('themeMode', next)
  }

  @Builder
  buildEditProfilePanel() {
    Scroll() {
      Column({ space: 14 }) {
        Text('编辑个人信息')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#25332F')
          .width('100%')

        Text('选择头像')
          .fontSize(13)
          .fontColor('#6E7C79')
          .width('100%')

        Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceBetween }) {
          ForEach(AVATAR_KEYS, (key: string) => {
            Image(getAvatarResource(key))
              .width(44)
              .height(44)
              .borderRadius(22)
              .objectFit(ImageFit.Cover)
              .border({
                width: this.editAvatarKey === key ? 3 : 1,
                color: this.editAvatarKey === key ? AuthTheme.PRIMARY : '#E8EEF3'
              })
              .width('18%')
              .margin({ bottom: 10 })
              .onClick(() => {
                this.editAvatarKey = key
              })
          }, (key: string) => key)
        }
        .width('100%')
        .height(200)

        Text('昵称')
          .fontSize(13)
          .fontColor('#6E7C79')
          .width('100%')
        AuthInput({
          placeholder: '输入新昵称',
          value: $editNickname
        })

        Divider().color('#F0F4F8').margin({ top: 4, bottom: 4 })

        Text('修改密码（选填）')
          .fontSize(13)
          .fontColor('#6E7C79')
          .width('100%')
        AuthInput({
          placeholder: '原密码',
          value: $oldPassword,
          isPassword: true,
          showToggle: true
        })
        AuthInput({
          placeholder: '新密码（8-16位）',
          value: $newPassword,
          isPassword: true,
          showToggle: true
        })
        AuthInput({
          placeholder: '确认新密码',
          value: $confirmPassword,
          isPassword: true,
          showToggle: true
        })

        Row({ space: 12 }) {
          Button('取消')
            .layoutWeight(1)
            .height(44)
            .fontColor('#6E7C79')
            .backgroundColor('#F0F4F8')
            .onClick(() => {
              this.showEditProfile = false
            })
          Button(this.saving ? '保存中' : '保存')
            .layoutWeight(1)
            .height(44)
            .fontColor(Color.White)
            .backgroundColor(AuthTheme.PRIMARY)
            .enabled(!this.saving)
            .onClick(() => this.saveAll())
        }
        .width('100%')
      }
      .width('100%')
    }
    .width('100%')
    .height(520)
    .scrollBar(BarState.Off)
    .padding(20)
    .backgroundColor(Color.White)
    .borderRadius(24)
  }

  getBadgeText(): string {
    if (this.unreadCount > 99) {
      return '99+'
    }
    return `${this.unreadCount}`
  }

  @Builder
  buildProfileNotificationButton() {
    Row({ space: 4 }) {
      Text('通知')
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .fontColor('#31534A')
      if (this.unreadCount > 0) {
        Text(this.getBadgeText())
          .fontSize(9)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .backgroundColor('#E17272')
          .borderRadius(8)
          .constraintSize({ minWidth: 16 })
          .height(16)
          .padding({ left: 4, right: 4 })
          .textAlign(TextAlign.Center)
      }
    }
    .padding({ left: 12, right: 12, top: 8, bottom: 8 })
    .backgroundColor('#F3F6F5')
    .borderRadius(16)
    .onClick(() => {
      UiHelper.pushTo('pages/NotificationPage')
    })
  }

  build() {
    Stack({ alignContent: Alignment.Top }) {
      Column({ space: 16 }) {
        Column({ space: 12 }) {
          Row({ space: 12 }) {
            Image(getAvatarResource(this.userAvatarKey))
              .width(72)
              .height(72)
              .borderRadius(36)
              .objectFit(ImageFit.Cover)

            Column({ space: 6 }) {
              Text(this.userNickname)
                .fontSize(22)
                .fontWeight(FontWeight.Bold)
                .fontColor('#31534A')
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              Text(`账号：${this.userAccount}`)
                .fontSize(12)
                .fontColor('#6E7C79')
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            this.buildProfileNotificationButton()
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          Text(`心情气候：${this.moodClimate}`)
            .fontSize(12)
            .fontColor('#2F7C49')
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .backgroundColor('#E8F6EC')
            .borderRadius(18)

          Row({ space: 8 }) {
            Column({ space: 4 }) {
              Text(`${this.postCount}`)
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor(AppTheme.PRIMARY)
              Text('发帖')
                .fontSize(11)
                .fontColor(AppTheme.TEXT_SECONDARY)
            }
            .layoutWeight(1)

            Column({ space: 4 }) {
              Text(`${this.totalLikes}`)
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor(AppTheme.PRIMARY)
              Text('获赞')
                .fontSize(11)
                .fontColor(AppTheme.TEXT_SECONDARY)
            }
            .layoutWeight(1)

            Column({ space: 4 }) {
              Text(`${this.activeDays}天`)
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor(AppTheme.PRIMARY)
              Text('活跃天数')
                .fontSize(11)
                .fontColor(AppTheme.TEXT_SECONDARY)
            }
            .layoutWeight(1)
          }
          .width('100%')
          .padding({ top: 4 })
        }
        .width('100%')
        .padding(20)
        .backgroundColor(AppTheme.CARD)
        .borderRadius(24)

        InspirationCard({
          loading: this.inspirationLoading,
          content: this.inspirationContent,
          moodLabel: this.inspirationMoodLabel,
          moodColor: this.inspirationMoodColor,
          alreadyDrawn: this.inspirationAlreadyDrawn,
          onDraw: () => {
            this.drawInspiration()
          }
        })

        Column({ space: 0 }) {
          this.buildSettingRow('编辑个人信息', () => this.openEditProfile())
          Divider().color('#F0F4F8')
          this.buildSettingRow('我的帖子', () => UiHelper.pushTo('pages/MyPostsPage'))
          Divider().color('#F0F4F8')
          this.buildSettingRow(
            this.themeMode === 'dark' ? '深色模式（已开启）' : '深色模式',
            () => this.toggleTheme()
          )
          Divider().color('#F0F4F8')
          this.buildSettingRow('退出登录', () => this.handleLogout())
        }
        .width('100%')
        .padding({ left: 18, right: 18 })
        .backgroundColor(AppTheme.CARD)
        .borderRadius(24)

        Column({ space: 12 }) {
          Row() {
            Text('情绪日历')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppTheme.TEXT_TITLE)
            Blank()
            Text('<')
              .fontSize(16)
              .fontColor(AppTheme.TEXT_SECONDARY)
              .padding(8)
              .onClick(() => this.shiftCalendarMonth(-1))
            Text(this.calendarTitle.length > 0 ? this.calendarTitle : '本月')
              .fontSize(13)
              .fontColor(AppTheme.PRIMARY)
            Text('>')
              .fontSize(16)
              .fontColor(AppTheme.TEXT_SECONDARY)
              .padding(8)
              .onClick(() => this.shiftCalendarMonth(1))
          }
          .width('100%')

          Row() {
            this.buildWeekdayHeader('一')
            this.buildWeekdayHeader('二')
            this.buildWeekdayHeader('三')
            this.buildWeekdayHeader('四')
            this.buildWeekdayHeader('五')
            this.buildWeekdayHeader('六')
            this.buildWeekdayHeader('日')
          }
          .width('100%')

          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(this.calendarCells, (cell: CalendarCell, index: number) => {
              this.buildCalendarCell(cell)
            }, (cell: CalendarCell, index: number) => `${index}-${cell.day}`)
          }
          .width('100%')
        }
        .width('100%')
        .padding(18)
        .backgroundColor('#FFFFFF')
        .borderRadius(24)

        Column({ space: 12 }) {
          Row({ space: 10 }) {
            Text('走过的情绪')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#25332F')
            Blank()
            Row({ space: 8 }) {
              this.buildMoodViewChip('curve', '曲线')
              this.buildMoodViewChip('distribution', '分布')
            }
          }
          .width('100%')

          if (this.moodViewTab === 'curve') {
            if (this.moodCurveLoading) {
              LoadingProgress()
                .width(28)
                .height(28)
                .color(AuthTheme.PRIMARY)
            } else if (!this.hasCurveData()) {
              Column({ space: 8 }) {
                Text('🌱')
                  .fontSize(28)
                  .width('100%')
                  .textAlign(TextAlign.Center)
                Text('还没有足够的心情记录，去贴第一张吧')
                  .fontSize(12)
                  .fontColor('#95A19F')
                  .width('100%')
                  .textAlign(TextAlign.Center)
                  .lineHeight(18)
              }
              .width('100%')
              .padding({ top: 12, bottom: 12 })
            } else {
              MoodCurveChart({
                points: this.moodCurvePoints,
                summary: this.moodCurveSummary,
                refreshKey: this.curveRefreshKey
              })
            }
          } else {
            Row({ space: 8 }) {
              this.buildPeriodChip('today')
              this.buildPeriodChip('week')
              this.buildPeriodChip('month')
            }
            .width('100%')
            .justifyContent(FlexAlign.End)

            if (this.moodStatsLoading) {
              LoadingProgress()
                .width(28)
                .height(28)
                .color(AuthTheme.PRIMARY)
            } else if (this.moodStats.length === 0) {
              Text('该时段暂无心情记录')
                .fontSize(12)
                .fontColor('#95A19F')
                .width('100%')
                .textAlign(TextAlign.Center)
                .padding({ top: 8, bottom: 8 })
            } else {
              ForEach(this.moodStats, (item: MoodStatItem) => {
                this.buildProgressRow(item.label, item.percent, item.color)
              }, (item: MoodStatItem) => `${this.moodPeriod}-${item.mood}`)
            }
          }
          Text('翻开温情周报')
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .fontColor('#31534A')
            .onClick(() => this.openWeeklyReport())
        }
        .width('100%')
        .padding(18)
        .backgroundColor('#FFFFFF')
        .borderRadius(24)
      }

      if (this.showEditProfile) {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(0,0,0,0.35)')
          .onClick(() => {
            this.showEditProfile = false
          })

        Column() {
          this.buildEditProfilePanel()
        }
        .width('92%')
        .margin({ top: 48 })
      }
    }
    .width('100%')
  }
}
