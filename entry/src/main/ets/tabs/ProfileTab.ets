import { AuthTheme } from '../common/AuthTheme'
import { AuthSession } from '../common/AuthSession'
import { AVATAR_KEYS, getAvatarResource } from '../common/AvatarResources'
import { UiHelper } from '../common/UiHelper'
import { AuthInput } from '../components/auth/AuthInput'
import { CalendarCell, CalendarDay, ProfileOverview } from '../model/ProfileApiTypes'
import { AuthApi } from '../service/AuthApi'
import { ProfileApi } from '../service/ProfileApi'

@Component
export struct ProfileTab {
  @StorageLink('userNickname') userNickname: string = '同学'
  @StorageLink('userAccount') userAccount: string = ''
  @StorageLink('userAvatarKey') userAvatarKey: string = 'avatar_01'
  onOpenReport: (report: string) => void = () => {}

  @State showEditProfile: boolean = false
  @State editNickname: string = ''
  @State editAvatarKey: string = 'avatar_01'
  @State oldPassword: string = ''
  @State newPassword: string = ''
  @State confirmPassword: string = ''
  @State saving: boolean = false

  @State loadingProfile: boolean = true
  @State postCount: number = 0
  @State totalLikes: number = 0
  @State streakDays: number = 0
  @State moodClimate: string = '暂无记录'
  @State calmPercent: number = 0
  @State anxiousPercent: number = 0
  @State happyPercent: number = 0

  @State calendarMonth: string = ''
  @State calendarCells: Array<CalendarCell> = []
  @State calendarTitle: string = ''

  aboutToAppear(): void {
    this.calendarMonth = ProfileTab.formatMonthKey(new Date())
    this.refreshProfile()
    this.loadArchive()
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

  loadArchive(): void {
    if (!AuthSession.isLoggedIn()) {
      return
    }
    this.loadingProfile = true
    ProfileApi.getOverview().then((overview: ProfileOverview) => {
      this.applyOverview(overview)
      return ProfileApi.getCalendar(this.calendarMonth)
    }).then((calendar) => {
      this.calendarMonth = calendar.month
      this.calendarTitle = ProfileTab.formatMonthTitle(this.calendarMonth)
      this.calendarCells = ProfileTab.buildCalendarCells(this.calendarMonth, calendar.days)
    }).catch((err: Error) => {
      UiHelper.showToast(err.message)
    }).finally(() => {
      this.loadingProfile = false
    })
  }

  applyOverview(overview: ProfileOverview): void {
    this.postCount = overview.postCount
    this.totalLikes = overview.totalLikes
    this.streakDays = overview.streakDays
    this.moodClimate = overview.moodClimate
    this.calmPercent = overview.weekStats.calmPercent
    this.anxiousPercent = overview.weekStats.anxiousPercent
    this.happyPercent = overview.weekStats.happyPercent
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
      this.calendarMonth = calendar.month
      this.calendarTitle = ProfileTab.formatMonthTitle(this.calendarMonth)
      this.calendarCells = ProfileTab.buildCalendarCells(this.calendarMonth, calendar.days)
    }).catch((err: Error) => {
      UiHelper.showToast(err.message)
    })
  }

  openWeeklyReport(): void {
    ProfileApi.getWeeklyReport().then((result) => {
      this.onOpenReport(result.report)
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
    AuthSession.clear()
    UiHelper.showToast('已退出登录')
    UiHelper.replaceTo('pages/Login')
  }

  @Builder
  buildStatChip(label: string, value: string) {
    Column({ space: 4 }) {
      Text(value)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#31534A')
      Text(label)
        .fontSize(11)
        .fontColor('#6E7C79')
    }
    .layoutWeight(1)
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
        .fontColor('#6E7C79')
      Stack({ alignContent: Alignment.Start }) {
        Row()
          .width('100%')
          .height(28)
          .backgroundColor('#F4F7F6')
          .borderRadius(14)
        Row() {
          Text(`${percent}%`)
            .fontSize(11)
            .fontWeight(FontWeight.Bold)
            .fontColor('#284138')
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
        .fontColor('#31534A')
      Text('>')
        .fontSize(14)
        .fontColor('#9AA8B5')
    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceBetween)
    .padding({ top: 14, bottom: 14 })
    .onClick(() => onTap())
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

  build() {
    Stack({ alignContent: Alignment.Top }) {
      Column({ space: 16 }) {
        Column({ space: 12 }) {
          Image(getAvatarResource(this.userAvatarKey))
            .width(72)
            .height(72)
            .borderRadius(36)
            .objectFit(ImageFit.Cover)

          Text(this.userNickname)
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#31534A')

          Text(`账号：${this.userAccount}`)
            .fontSize(12)
            .fontColor('#6E7C79')

          Text(`心情气候：${this.moodClimate}`)
            .fontSize(12)
            .fontColor('#2F7C49')
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .backgroundColor('#E8F6EC')
            .borderRadius(18)

          Row({ space: 8 }) {
            this.buildStatChip('发帖', `${this.postCount}`)
            this.buildStatChip('获赞', `${this.totalLikes}`)
            this.buildStatChip('连续活跃', `${this.streakDays}天`)
          }
          .width('100%')
          .padding({ top: 4 })
        }
        .width('100%')
        .padding(20)
        .backgroundColor('#FFFFFF')
        .borderRadius(24)

        Column({ space: 0 }) {
          this.buildSettingRow('编辑个人信息', () => this.openEditProfile())
          Divider().color('#F0F4F8')
          this.buildSettingRow('我的帖子', () => UiHelper.pushTo('pages/MyPostsPage'))
          Divider().color('#F0F4F8')
          this.buildSettingRow('退出登录', () => this.handleLogout())
        }
        .width('100%')
        .padding({ left: 18, right: 18 })
        .backgroundColor('#FFFFFF')
        .borderRadius(24)

        Column({ space: 12 }) {
          Row() {
            Text('情绪日历')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#25332F')
            Blank()
            Text('<')
              .fontSize(16)
              .fontColor('#6E7C79')
              .padding(8)
              .onClick(() => this.shiftCalendarMonth(-1))
            Text(this.calendarTitle.length > 0 ? this.calendarTitle : '本月')
              .fontSize(13)
              .fontColor('#31534A')
            Text('>')
              .fontSize(16)
              .fontColor('#6E7C79')
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
          Text('这一周，走过的情绪')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#25332F')
          if (this.loadingProfile) {
            LoadingProgress()
              .width(28)
              .height(28)
              .color(AuthTheme.PRIMARY)
          } else {
            this.buildProgressRow('平静', this.calmPercent, '#73C088')
            this.buildProgressRow('焦虑', this.anxiousPercent, '#F08C62')
            this.buildProgressRow('开心', this.happyPercent, '#F6C445')
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
