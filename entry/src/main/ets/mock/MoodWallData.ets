import { MoodOption, NoteItem, ZoneCard } from '../model/MoodWallTypes'

export const MOOD_OPTIONS: Array<MoodOption> = [
  { key: 'happy', label: '开心', color: '#F6C445', hint: '分享今天的小确幸。' },
  { key: 'calm', label: '平静', color: '#73C088', hint: '把此刻的安静留在心墙里。' },
  { key: 'moved', label: '感动', color: '#B786F7', hint: '是什么触动了你？' },
  { key: 'tired', label: '疲惫', color: '#92A0B0', hint: '辛苦了，写下来会轻一点。' },
  { key: 'anxious', label: '焦虑', color: '#F08C62', hint: '把压力拆成一句句说出来。' },
  { key: 'sad', label: '低落', color: '#6CB1F0', hint: '难过的时候也值得被接住。' },
  { key: 'angry', label: '生气', color: '#E17272', hint: '先把委屈和不爽放下来。' },
  { key: 'lonely', label: '孤单', color: '#8B7AD6', hint: '这里一直有人在听。' }
]

export const LOCATION_OPTIONS: Array<string> = [
  '主图书馆三楼',
  '未名湖畔咖啡角',
  '第二食堂',
  '五号宿舍楼',
  '理科科研楼 B 座'
]

export const ZONE_CARDS: Array<ZoneCard> = [
  {
    key: 'library',
    title: '图书馆',
    subtitle: '橙色压力区',
    summary: '临近期中考试，这里更容易积攒紧张和压力，很多同学都在默默坚持。',
    accent: '#F08C62'
  },
  {
    key: 'living',
    title: '生活区',
    subtitle: '绿色治愈区',
    summary: '宿舍和食堂一带更松弛一些，晚饭后的校园情绪会慢慢柔和下来。',
    accent: '#73C088'
  },
  {
    key: 'lake',
    title: '湖畔与咖啡角',
    subtitle: '金色放空区',
    summary: '适合散步、发呆、吹风，把脑子里的噪音放轻一点。',
    accent: '#F6C445'
  }
]

export const INITIAL_NOTES: Array<NoteItem> = [
  {
    id: 1,
    mood: 'anxious',
    moodLabel: '压力山大',
    text: '期中周的图书馆像在无声倒计时，看着大家都在奋笔疾书，我也开始担心自己是不是还不够好。',
    location: '主图书馆三楼',
    timeText: '10 分钟前',
    likes: 34,
    color: '#F08C62'
  },
  {
    id: 2,
    mood: 'calm',
    moodLabel: '放空一下',
    text: '刚刚在湖边坐了一会儿，看风吹过水面的样子，感觉脑子里的噪音也跟着散开了。',
    location: '未名湖畔',
    timeText: '30 分钟前',
    likes: 56,
    color: '#73C088'
  },
  {
    id: 3,
    mood: 'happy',
    moodLabel: '今日小确幸',
    text: '食堂阿姨多给了一块红烧肉，这一口热乎气瞬间把今天点亮了。',
    location: '第二食堂',
    timeText: '2 小时前',
    likes: 88,
    color: '#F6C445'
  },
  {
    id: 4,
    mood: 'moved',
    moodLabel: '夜归也踏实',
    text: '实验做到很晚，回宿舍的路很安静，虽然累，但那种一步一步靠近目标的感觉很真实。',
    location: '理科科研楼',
    timeText: '昨晚',
    likes: 122,
    color: '#B786F7'
  }
]
