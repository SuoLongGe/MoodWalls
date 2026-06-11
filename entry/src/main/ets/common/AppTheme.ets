export class AppTheme {
  static readonly THEME_KEY: string = 'themeMode'
  static readonly THEME_LIGHT: string = 'light'
  static readonly THEME_DARK: string = 'dark'

  private static get mode(): string {
    const m: string | undefined = AppStorage.get<string>(AppTheme.THEME_KEY)
    if (m === AppTheme.THEME_DARK) {
      return AppTheme.THEME_DARK
    }
    return AppTheme.THEME_LIGHT
  }

  // ---- Light palette ----
  private static readonly L_PRIMARY: string = '#31534A'
  private static readonly L_PRIMARY_DARK: string = '#153A31'
  private static readonly L_PRIMARY_LIGHT: string = '#73A18F'
  private static readonly L_PRIMARY_SOFT: string = '#CBEADF'
  private static readonly L_ACCENT: string = '#73C088'
  private static readonly L_ACCENT_BORDER: string = '#E8F6EC'
  private static readonly L_BG: string = '#F4F7F6'
  private static readonly L_BG_WARM: string = '#F9FBFA'
  private static readonly L_CARD: string = '#FFFFFF'
  private static readonly L_CARD_MINE: string = '#F7FBF8'
  private static readonly L_SURFACE: string = '#F3F6F5'
  private static readonly L_TEXT_PRIMARY: string = '#22352F'
  private static readonly L_TEXT_TITLE: string = '#25332F'
  private static readonly L_TEXT_SECONDARY: string = '#6B7C78'
  private static readonly L_TEXT_HINT: string = '#7C8A87'
  private static readonly L_TEXT_MUTED: string = '#B0B8B6'
  private static readonly L_BADGE: string = '#E17272'
  private static readonly L_LIKE: string = '#E85A5A'
  private static readonly L_HEADER_BG: string = '#F9FBFA'
  private static readonly L_SHADOW: string = 'rgba(49, 83, 74, 0.10)'
  private static readonly L_SHADOW_LIGHT: string = 'rgba(49, 83, 74, 0.06)'
  private static readonly L_OUTLINE: string = '#E7ECEB'
  private static readonly L_OVERLAY: string = 'rgba(26, 39, 36, 0.38)'

  // ---- Dark palette ----
  private static readonly D_PRIMARY: string = '#2F6F58'
  private static readonly D_PRIMARY_DARK: string = '#D2F1E0'
  private static readonly D_PRIMARY_LIGHT: string = '#7ED6B6'
  private static readonly D_PRIMARY_SOFT: string = '#22463D'
  private static readonly D_ACCENT: string = '#73C088'
  private static readonly D_ACCENT_BORDER: string = '#2E5F50'
  private static readonly D_BG: string = '#0F1513'
  private static readonly D_BG_WARM: string = '#111A18'
  private static readonly D_CARD: string = '#121B19'
  private static readonly D_CARD_MINE: string = '#17221F'
  private static readonly D_SURFACE: string = '#151F1D'
  private static readonly D_TEXT_PRIMARY: string = '#EAF5F0'
  private static readonly D_TEXT_TITLE: string = '#EAF5F0'
  private static readonly D_TEXT_SECONDARY: string = '#A9B7B1'
  private static readonly D_TEXT_HINT: string = '#8A9A94'
  private static readonly D_TEXT_MUTED: string = '#6D7D78'
  private static readonly D_BADGE: string = '#E17272'
  private static readonly D_LIKE: string = '#FF6B6B'
  private static readonly D_HEADER_BG: string = '#111A18'
  private static readonly D_SHADOW: string = 'rgba(0, 0, 0, 0.35)'
  private static readonly D_SHADOW_LIGHT: string = 'rgba(0, 0, 0, 0.22)'
  private static readonly D_OUTLINE: string = '#23312C'
  private static readonly D_OVERLAY: string = 'rgba(0, 0, 0, 0.55)'

  // ---- Dynamic tokens ----
  static get PRIMARY(): string {
    return AppTheme.mode === AppTheme.THEME_DARK ? AppTheme.D_PRIMARY : AppTheme.L_PRIMARY
  }
  static get PRIMARY_DARK(): string {
    return AppTheme.mode === AppTheme.THEME_DARK ? AppTheme.D_PRIMARY_DARK : AppTheme.L_PRIMARY_DARK
  }
  static get PRIMARY_LIGHT(): string {
    return AppTheme.mode === AppTheme.THEME_DARK ? AppTheme.D_PRIMARY_LIGHT : AppTheme.L_PRIMARY_LIGHT
  }
  static get PRIMARY_SOFT(): string {
    return AppTheme.mode === AppTheme.THEME_DARK ? AppTheme.D_PRIMARY_SOFT : AppTheme.L_PRIMARY_SOFT
  }
  static get ACCENT(): string {
    return AppTheme.mode === AppTheme.THEME_DARK ? AppTheme.D_ACCENT : AppTheme.L_ACCENT
  }
  static get ACCENT_BORDER(): string {
    return AppTheme.mode === AppTheme.THEME_DARK ? AppTheme.D_ACCENT_BORDER : AppTheme.L_ACCENT_BORDER
  }
  static get BG(): string {
    return AppTheme.mode === AppTheme.THEME_DARK ? AppTheme.D_BG : AppTheme.L_BG
  }
  static get BG_WARM(): string {
    return AppTheme.mode === AppTheme.THEME_DARK ? AppTheme.D_BG_WARM : AppTheme.L_BG_WARM
  }
  static get CARD(): string {
    return AppTheme.mode === AppTheme.THEME_DARK ? AppTheme.D_CARD : AppTheme.L_CARD
  }
  static get CARD_MINE(): string {
    return AppTheme.mode === AppTheme.THEME_DARK ? AppTheme.D_CARD_MINE : AppTheme.L_CARD_MINE
  }
  static get SURFACE(): string {
    return AppTheme.mode === AppTheme.THEME_DARK ? AppTheme.D_SURFACE : AppTheme.L_SURFACE
  }
  static get TEXT_PRIMARY(): string {
    return AppTheme.mode === AppTheme.THEME_DARK ? AppTheme.D_TEXT_PRIMARY : AppTheme.L_TEXT_PRIMARY
  }
  static get TEXT_TITLE(): string {
    return AppTheme.mode === AppTheme.THEME_DARK ? AppTheme.D_TEXT_TITLE : AppTheme.L_TEXT_TITLE
  }
  static get TEXT_SECONDARY(): string {
    return AppTheme.mode === AppTheme.THEME_DARK ? AppTheme.D_TEXT_SECONDARY : AppTheme.L_TEXT_SECONDARY
  }
  static get TEXT_HINT(): string {
    return AppTheme.mode === AppTheme.THEME_DARK ? AppTheme.D_TEXT_HINT : AppTheme.L_TEXT_HINT
  }
  static get TEXT_MUTED(): string {
    return AppTheme.mode === AppTheme.THEME_DARK ? AppTheme.D_TEXT_MUTED : AppTheme.L_TEXT_MUTED
  }
  static get BADGE(): string {
    return AppTheme.mode === AppTheme.THEME_DARK ? AppTheme.D_BADGE : AppTheme.L_BADGE
  }
  static get LIKE(): string {
    return AppTheme.mode === AppTheme.THEME_DARK ? AppTheme.D_LIKE : AppTheme.L_LIKE
  }
  static get HEADER_BG(): string {
    return AppTheme.mode === AppTheme.THEME_DARK ? AppTheme.D_HEADER_BG : AppTheme.L_HEADER_BG
  }
  static get SHADOW(): string {
    return AppTheme.mode === AppTheme.THEME_DARK ? AppTheme.D_SHADOW : AppTheme.L_SHADOW
  }
  static get SHADOW_LIGHT(): string {
    return AppTheme.mode === AppTheme.THEME_DARK ? AppTheme.D_SHADOW_LIGHT : AppTheme.L_SHADOW_LIGHT
  }
  static get OUTLINE(): string {
    return AppTheme.mode === AppTheme.THEME_DARK ? AppTheme.D_OUTLINE : AppTheme.L_OUTLINE
  }
  static get OVERLAY(): string {
    return AppTheme.mode === AppTheme.THEME_DARK ? AppTheme.D_OVERLAY : AppTheme.L_OVERLAY
  }

  static readonly RADIUS_SM: number = 12
  static readonly RADIUS_MD: number = 16
  static readonly RADIUS_LG: number = 20
  static readonly RADIUS_PILL: number = 24
  static readonly TAB_ENTER_MS: number = 380
  static readonly PAGE_PUSH_MS: number = 480
  static readonly PAGE_POP_MS: number = 420
  static readonly PAGE_FADE_ENTER_MS: number = 450
  static readonly PAGE_FADE_EXIT_MS: number = 320
  static readonly DIALOG_ENTER_MS: number = 380
}
