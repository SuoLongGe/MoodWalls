export const AVATAR_KEYS: string[] = [
  'avatar_01', 'avatar_02', 'avatar_03', 'avatar_04', 'avatar_05',
  'avatar_06', 'avatar_07', 'avatar_08', 'avatar_09', 'avatar_10',
  'avatar_11', 'avatar_12', 'avatar_13', 'avatar_14', 'avatar_15',
  'avatar_16', 'avatar_17', 'avatar_18', 'avatar_19', 'avatar_20',
  'avatar_21'
]

export function getAvatarResource(avatarKey: string): Resource {
  if (avatarKey === 'avatar_01') {
    return $r('app.media.avatar_01')
  }
  if (avatarKey === 'avatar_02') {
    return $r('app.media.avatar_02')
  }
  if (avatarKey === 'avatar_03') {
    return $r('app.media.avatar_03')
  }
  if (avatarKey === 'avatar_04') {
    return $r('app.media.avatar_04')
  }
  if (avatarKey === 'avatar_05') {
    return $r('app.media.avatar_05')
  }
  if (avatarKey === 'avatar_06') {
    return $r('app.media.avatar_06')
  }
  if (avatarKey === 'avatar_07') {
    return $r('app.media.avatar_07')
  }
  if (avatarKey === 'avatar_08') {
    return $r('app.media.avatar_08')
  }
  if (avatarKey === 'avatar_09') {
    return $r('app.media.avatar_09')
  }
  if (avatarKey === 'avatar_10') {
    return $r('app.media.avatar_10')
  }
  if (avatarKey === 'avatar_11') {
    return $r('app.media.avatar_11')
  }
  if (avatarKey === 'avatar_12') {
    return $r('app.media.avatar_12')
  }
  if (avatarKey === 'avatar_13') {
    return $r('app.media.avatar_13')
  }
  if (avatarKey === 'avatar_14') {
    return $r('app.media.avatar_14')
  }
  if (avatarKey === 'avatar_15') {
    return $r('app.media.avatar_15')
  }
  if (avatarKey === 'avatar_16') {
    return $r('app.media.avatar_16')
  }
  if (avatarKey === 'avatar_17') {
    return $r('app.media.avatar_17')
  }
  if (avatarKey === 'avatar_18') {
    return $r('app.media.avatar_18')
  }
  if (avatarKey === 'avatar_19') {
    return $r('app.media.avatar_19')
  }
  if (avatarKey === 'avatar_20') {
    return $r('app.media.avatar_20')
  }
  if (avatarKey === 'avatar_21') {
    return $r('app.media.avatar_21')
  }
  return $r('app.media.app_logo')
}
