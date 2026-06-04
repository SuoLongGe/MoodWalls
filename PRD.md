# MoodWalls 校园心灵墙 · 产品需求与开发文档


| 项目   | 说明                              |
| ---- | ------------------------------- |
| 文档版本 | V2.0                            |
| 状态   | 开发中                             |
| 前端平台 | HarmonyOS NEXT · ArkTS · ArkUI  |
| 后端平台 | Spring Boot 3.2 · MySQL 8 · JWT |
| 功能模块 | 6 个核心模块 + 1 个扩展模块               |
| 接口数量 | 22 个（含 5 个已实现）                  |


---

## 1. 文档概述

### 1.1 文档目的

本文档基于**当前已落地的代码**（登录注册、4 Tab 主界面、Spring Boot 后端）进行梳理与完善，明确：

- 功能模块边界与三人分工
- 各模块前后端待办与接口规范
- MySQL 数据库表结构（可直接建表）

### 1.2 当前实现状态（截至 V2.0）


| 维度           | 现状                                                                                                                 |
| ------------ | ------------------------------------------------------------------------------------------------------------------ |
| **已实现**      | 登录页 / 注册页（图形验证码）、JWT 鉴权、4 Tab 主界面 UI、Mock 数据驱动的心墙/地图/发帖/个人页、AI 回信弹窗 UI                                             |
| **后端已上线**    | `GET /api/auth/captcha`、`POST /api/auth/register`、`POST /api/auth/login`、`GET /api/auth/me`、`GET /api/auth/health` |
| **仍使用 Mock** | 帖子列表、发帖持久化、点赞、地图统计、个人档案、AI 真实调用、通知                                                                                 |
| **技术栈**      | 前端 `HttpClient` + `AuthApi`；后端 Spring Data JPA；个人配置见 `docs/本地配置注意事项.md`                                            |


### 1.3 模块总览


| 编号      | 模块名称     | 前端入口                         | 优先级 | 状态            |
| ------- | -------- | ---------------------------- | --- | ------------- |
| **M01** | 用户认证     | `Login.ets` / `Register.ets` | P0  | 基础已完成         |
| **M02** | 心情墙 Feed | `FeedTab.ets`                | P0  | 前端完成，待接口      |
| **M03** | 发帖       | `PostTab.ets`                | P0  | 前端完成，待接口      |
| **M04** | AI 情感回信  | `SupportDialog.ets`          | P0  | ✅ 已完成          |
| **M05** | 校园情绪地图   | `MapTab.ets`                 | P1  | ✅ 已完成（8 区域）    |
| **M06** | 个人情绪档案   | `ProfileTab.ets`             | P1  | 静态 Mock，待接口   |
| **M07** | 通知系统     | `MoodWallHeader.ets`         | P2  | ✅ 已完成          |


> **优先级**：P0 = 答辩核心路径；P1 = 体验完善；P2 = 加分项。

---

## 2. 三人分工方案

按**模块负责制**划分，每位成员对各自模块的前后端联调负责，交叉模块通过约定接口协作。

### 成员 A · 用户与档案（M01 + M06）


| 职责       | 内容                                           |
| -------- | -------------------------------------------- |
| **前端**   | 登录/注册页维护、退出登录、个人页数据对接、情绪日历、我的帖子列表            |
| **后端**   | 用户表扩展、`/api/auth/`* 完善、`/api/profile/`* 全部接口 |
| **数据库**  | `users`、`user_daily_moods`                   |
| **交付标准** | 注册→登录→个人页展示真实昵称/统计/日历                        |


### 成员 B · 内容与互动（M02 + M03）


| 职责       | 内容                                       |
| -------- | ---------------------------------------- |
| **前端**   | Feed 列表/筛选/分页/下拉刷新、发帖对接、点赞状态、Header 情绪占比 |
| **后端**   | `posts`、`post_likes` 表及 CRUD、点赞、今日统计接口   |
| **数据库**  | `posts`、`post_likes`                     |
| **交付标准** | 发帖后在心墙可见、点赞不重复、分页加载正常                    |


### 成员 C · 智能与地图（M04 + M05 + M07）


| 职责       | 内容                                                                        |
| -------- | ------------------------------------------------------------------------- |
| **前端**   | 地图区域数据对接、区域帖子半屏、通知列表页、未读角标                                                |
| **后端**   | AI 服务集成、`/api/map/`*、`/api/notifications/`*、`ai_interactions`             |
| **数据库**  | `campus_zones`、`location_zone_mappings`、`ai_interactions`、`notifications` |
| **交付标准** | ✅ 发帖/接住心声有 AI 回信、✅ 地图显示 8 区域统计、✅ 通知可读写                                     |


### 协作约定

1. 统一响应格式、错误码、JWT Header（见第 3 节）。
2. 帖子相关字段与 `NoteItem` 对齐（见 M02 附录）。
3. 每周合并 `develop` 分支前，各模块至少完成 1 条端到端自测用例。
4. SQL 变更统一提交到 `backend/sql/init.sql`，禁止仅本地改表。

---

## 3. 全局技术规范

### 3.1 接口基础约定


| 项目           | 规范                                                                 |
| ------------ | ------------------------------------------------------------------ |
| Base URL     | `http://<局域网IP>:8080/api`（前端见 `ApiConfig.local.ets`）               |
| 鉴权           | `Authorization: Bearer <token>`（除 captcha/register/login/health 外） |
| Content-Type | `application/json`                                                 |
| 统一响应         | `{ "code": 200, "message": "success", "data": { ... } }`           |
| 业务失败         | HTTP 200 + `code != 200`，或 HTTP 4xx/5xx                            |
| 分页参数         | `page`（从 1 开始）、`size`（默认 20，最大 50）                                 |


### 3.2 常用错误码


| code | 含义                 |
| ---- | ------------------ |
| 200  | 成功                 |
| 400  | 参数错误 / 验证码错误       |
| 401  | 未登录 / Token 无效     |
| 403  | 无权限（如删他人帖子）        |
| 404  | 资源不存在              |
| 409  | 冲突（手机号/昵称已注册、重复点赞） |
| 500  | 服务器内部错误            |


### 3.3 情绪枚举（全模块统一）


| key     | label | color   |
| ------- | ----- | ------- |
| happy   | 开心    | #F6C445 |
| calm    | 平静    | #73C088 |
| moved   | 感动    | #B786F7 |
| tired   | 疲惫    | #92A0B0 |
| anxious | 焦虑    | #F08C62 |
| sad     | 低落    | #6CB1F0 |
| angry   | 生气    | #E17272 |
| lonely  | 孤单    | #8B7AD6 |


### 3.4 发帖位置（与前端 `LOCATION_OPTIONS` 一致）

- 主图书馆三楼 → zone: `library`
- 未名湖畔咖啡角 → zone: `lake`
- 第二食堂 → zone: `living`
- 五号宿舍楼 → zone: `living`
- 理科科研楼 B 座 → zone: `library`

---

## 4. M01 · 用户认证模块

### 4.1 功能描述

提供注册、登录、会话管理与基础用户信息查询。用户使用**昵称 + 手机号 + 密码**注册，登录时支持**昵称或手机号**。

### 4.2 当前进度


| 功能                  | 状态        |
| ------------------- | --------- |
| 注册（图形验证码）           | ✅ 已完成     |
| 登录（昵称/手机号）          | ✅ 已完成     |
| JWT 持久化（AppStorage） | ✅ 已完成     |
| 获取当前用户 `/auth/me`   | ✅ 已完成     |
| 退出登录                | ⬜ 待开发     |
| 修改昵称 / 头像           | ⬜ 待开发（P2） |


### 4.3 接口规范

#### 4.3.1 健康检查 ✅

```
GET /api/auth/health
```

**Response.data**

```json
{ "status": "ok", "service": "moodwalls-backend" }
```

#### 4.3.2 获取图形验证码 ✅

```
GET /api/auth/captcha
```

**Response.data**

```json
{
  "captchaId": "a1b2c3d4e5f6",
  "captchaText": "X7K9"
}
```

> 前端展示 `captchaText`，注册时提交 `captchaId` + 用户输入的验证码。

#### 4.3.3 注册 ✅

```
POST /api/auth/register
```

**Request**

```json
{
  "nickname": "小暖",
  "phone": "13800138000",
  "captchaId": "a1b2c3d4e5f6",
  "captchaCode": "X7K9",
  "password": "abc12345"
}
```

**Response.data**

```json
{
  "token": "eyJhbGciOiJIUzI1NiJ9...",
  "user": {
    "id": 1,
    "nickname": "小暖",
    "phone": "138****8000",
    "studentId": null
  }
}
```

#### 4.3.4 登录 ✅

```
POST /api/auth/login
```

**Request**

```json
{
  "account": "小暖",
  "password": "abc12345"
}
```

> `account`：11 位手机号 **或** 昵称。

**Response.data**：同注册。

#### 4.3.5 获取当前用户 ✅

```
GET /api/auth/me
Header: Authorization: Bearer <token>
```

#### 4.3.6 退出登录 ⬜

```
POST /api/auth/logout
Header: Authorization: Bearer <token>
```

**说明**：JWT 无状态，后端可记录黑名单（P2）；前端清除 `AuthSession` 并跳转登录页即可。

### 4.4 前端待办（成员 A）

- `ProfileTab` 增加「退出登录」
- Token 过期时统一跳转登录页（401 拦截）

---

## 5. M02 · 心情墙 Feed 模块

### 5.1 功能描述

展示校园心情帖子流，支持按情绪筛选、分页加载、下拉刷新、点赞与「接住心声」入口。
在此基础上新增两项特色互动：**情绪反应**（抱抱/懂你/加油/为你开心/一起扛）与**心情共鸣评论**（共鸣/悄悄话双模式）。

### 5.2 接口规范

#### 5.2.1 帖子列表 ⬜

```
GET /api/posts?page=1&size=20&mood=anxious
Header: Authorization: Bearer <token>（可选，用于返回 isLiked）
```


| 参数   | 类型     | 必填  | 说明                   |
| ---- | ------ | --- | -------------------- |
| page | int    | 否   | 页码，默认 1              |
| size | int    | 否   | 每页条数，默认 20           |
| mood | string | 否   | 情绪 key，`all` 或不传表示全部 |


**Response.data**

```json
{
  "list": [
    {
      "id": 1,
      "userId": 2,
      "nickname": "小暖",
      "mood": "anxious",
      "moodLabel": "焦虑",
      "text": "期中周压力好大...",
      "location": "主图书馆三楼",
      "zoneKey": "library",
      "likes": 34,
      "isLiked": false,
      "color": "#F08C62",
      "createdAt": "2026-05-31T10:30:00",
      "timeText": "10 分钟前"
    }
  ],
  "total": 128,
  "page": 1,
  "size": 20,
  "hasMore": true
}
```

> `moodLabel`、`color`、`timeText` 可由后端生成，也可前端根据 `mood` + `createdAt` 计算。

#### 5.2.2 帖子详情 ⬜

```
GET /api/posts/{id}
```

#### 5.2.3 点赞 ⬜

```
POST /api/posts/{id}/like
Header: Authorization: Bearer <token>
```

**Response.data**

```json
{ "likes": 35, "isLiked": true }
```

**规则**：同一用户对同一帖子只能点赞一次；重复请求返回 409。

#### 5.2.4 取消点赞 ⬜（P2）

```
DELETE /api/posts/{id}/like
```

#### 5.2.5 今日情绪统计 ⬜

```
GET /api/stats/today
```

**Response.data**

```json
{
  "anxiousPercent": 32,
  "calmPercent": 41,
  "happyPercent": 18,
  "totalPosts": 156
}
```

> 供 `MoodWallHeader` 三个 chip 使用；统计口径为**今日全站**帖子。

#### 5.2.6 情绪反应（替代单一点赞，P1） ⬜

```
POST /api/posts/{id}/react
Header: Authorization: Bearer <token>
```

**Request**

```json
{ "reactionType": "hug" }
```

**reactionType 枚举**：`hug`（抱抱）| `understand`（懂你）| `cheer`（加油）| `happy_for_you`（为你开心）| `with_you`（一起扛）

**Response.data**

```json
{
  "totalReactions": 19,
  "myReaction": "hug",
  "reactionStats": {
    "hug": 8,
    "understand": 4,
    "cheer": 3,
    "happy_for_you": 2,
    "with_you": 2
  }
}
```

**规则**：同一用户对同一帖子同一时刻仅保留 1 条反应；再次提交视为切换反应。

#### 5.2.7 取消情绪反应（P1） ⬜

```
DELETE /api/posts/{id}/react
Header: Authorization: Bearer <token>
```

#### 5.2.8 共鸣评论列表（P1） ⬜

```
GET /api/posts/{id}/comments?page=1&size=20
Header: Authorization: Bearer <token>（可选；登录后返回 mineOnly 字段）
```

**Response.data**

```json
{
  "list": [
    {
      "id": 101,
      "postId": 1,
      "authorNickname": "星夜",
      "content": "我也在经历类似阶段，抱抱你。",
      "commentType": "resonance",
      "mineOnly": false,
      "createdAt": "2026-06-02T14:02:00",
      "timeText": "3 分钟前"
    }
  ],
  "total": 12,
  "page": 1,
  "size": 20,
  "hasMore": false
}
```

#### 5.2.9 发布共鸣评论（P1） ⬜

```
POST /api/posts/{id}/comments
Header: Authorization: Bearer <token>
```

**Request**

```json
{
  "content": "我也有过同样的焦虑，先慢慢来。",
  "commentType": "resonance"
}
```

**commentType 枚举**：`resonance`（公开共鸣）| `whisper`（悄悄话，仅作者可见）

**规则**：

- `content` 长度 1~200，命中攻击性词汇/辱骂词返回 422
- `whisper` 仅帖子作者与评论者本人可见
- 作者可删除自己帖子下任意评论；评论者可删除自己评论

#### 5.2.10 删除评论（P1） ⬜

```
DELETE /api/posts/{postId}/comments/{commentId}
Header: Authorization: Bearer <token>
```

### 5.3 前端待办（成员 B）

- `FeedTab` 对接列表接口，替换 `INITIAL_NOTES`
- 筛选 chip 触发带 `mood` 参数请求
- 下拉刷新 + 触底分页
- 点赞对接，维护 `isLiked` 状态
- 情绪反应面板（5 种 reaction）+ 我的反应高亮
- 评论入口 + 评论列表弹层（共鸣/悄悄话）
- 发布评论输入框与审核失败提示（422 文案提示）
- Header 统计对接 `/stats/today`

---

## 6. M03 · 发帖模块

### 6.1 功能描述

用户选择情绪标签、填写正文、选择位置后发布心情帖，发布成功后跳转心墙并触发 AI 回信弹窗。

### 6.2 业务规则


| 规则  | 说明                      |
| --- | ----------------------- |
| 字数  | 10 ~ 500 字              |
| 情绪  | 8 选 1，必填                |
| 位置  | 从预设列表选择，后端映射 `zone_key` |
| 登录  | 必须登录                    |


### 6.3 接口规范

#### 6.3.1 发布帖子 ⬜

```
POST /api/posts
Header: Authorization: Bearer <token>
```

**Request**

```json
{
  "mood": "calm",
  "text": "刚刚在湖边坐了一会儿，感觉安静了很多。",
  "location": "未名湖畔咖啡角"
}
```

**Response.data**

```json
{
  "post": { "...NoteItem 字段..." },
  "aiResponse": "你已经很努力了。先把这份情绪放在这里，慢慢呼吸一下。"
}
```

> 后端发布成功后同步调用 AI（成员 C 提供），将 `aiResponse` 写入 `posts.ai_response` 并返回。

#### 6.3.2 删除自己的帖子 ⬜

```
DELETE /api/posts/{id}
Header: Authorization: Bearer <token>
```

**规则**：仅作者可删；软删除（`status=0`）。

### 6.4 前端待办（成员 B）

- `PostTab.publishNote()` 对接 `POST /api/posts`
- 字数计数 10/500，不足禁用发布按钮
- 位置选择改为 ActionSheet（可选）
- 发布 Loading 态，防重复提交

---

## 7. M04 · AI 情感回信模块

### 7.1 功能描述

在三种场景提供温暖、简短的 AI 陪伴文案：

1. **发帖后**：发布成功自动弹窗
2. **接住心声**：点击心墙卡片按钮，针对该帖生成回应
3. **温情周报**：个人页打开本周情绪摘要

### 7.2 接口规范

> 发帖场景的 AI 回信已合并进 `POST /api/posts` 的 `aiResponse` 字段。

#### 7.2.1 接住心声 ⬜

```
POST /api/posts/{id}/support
Header: Authorization: Bearer <token>
```

**Response.data**

```json
{
  "response": "难过的时候也值得被接住。你并不孤单。",
  "isCrisis": false
}
```

#### 7.2.2 温情周报 ⬜

```
GET /api/profile/weekly-report
Header: Authorization: Bearer <token>
```

**Response.data**

```json
{
  "report": "这周你的情绪底色更偏平静...",
  "moodSummary": {
    "calm": 3,
    "anxious": 2,
    "happy": 1
  },
  "postCount": 6
}
```

### 7.3 AI 接入规范（成员 C）


| 项目            | 说明                                                        |
| ------------- | --------------------------------------------------------- |
| 推荐方案          | 通义千问 / 文心 / Claude API（Spring `RestTemplate` 或 WebClient） |
| System Prompt | 「你是校园心理关怀助手『校园倾听树洞』，用温暖、简短、口语化中文回应，不说教，80 字以内。」           |
| 危机检测          | 命中自伤/极端关键词时 `isCrisis=true`，追加心理咨询中心文案                    |
| 存储            | 写入 `ai_interactions` 表，便于审计与复现                            |
| 兜底            | AI 超时返回固定文案，不阻塞发帖主流程                                      |


### 7.4 前端待办（成员 C + B 协作）

- ✅ `SupportDialog` 使用接口返回的 `aiResponse` / `response` / `report`
- ✅ 「接住心声」Loading 态「正在倾听...」
- ✅ 发帖后 AI 回信记录到 `ai_interactions` 表
- ✅ 温情周报生成通知 + 记录

> **AI 配置**：使用硅基流动 API（Qwen2.5-7B-Instruct），System Prompt 为校园倾听树洞。危机关键词检测命中时 `isCrisis=true`。API 超时/失败返回固定兜底文案，不阻塞主流程。

---

## 8. M05 · 校园情绪地图模块

### 8.1 功能描述

按图书馆、生活区、湖畔等区域展示「情绪气候」：主导情绪、帖子数量、描述文案；支持查看区域内近期帖子。

### 8.2 接口规范

#### 8.2.1 区域概览 ⬜

```
GET /api/map/zones
```

**Response.data**

```json
{
  "summary": "整体偏多云转温柔。图书馆附近压力偏高，生活区和湖边更适合慢下来。",
  "zones": [
    {
      "key": "library",
      "title": "图书馆",
      "subtitle": "橙色压力区",
      "summary": "临近期中...",
      "accent": "#F08C62",
      "postCount": 42,
      "dominantMood": "anxious"
    }
  ]
}
```

> 统计数据来自 `posts` 表按 `zone_key` + 今日/近 24h 聚合。

#### 8.2.2 区域帖子列表 ⬜

```
GET /api/map/zones/{key}/posts?page=1&size=10
```

### 8.3 前端待办（成员 C）

- ✅ `MapTab` 对接 `/map/zones`（8 区域自动加载 + Loading 态）
- ✅ 「查看」弹出区域帖子 Sheet（含昵称、点赞数）
- ✅ 「去写一张纸条」跳转发帖 Tab
- ✅ 24h 内按区域分组统计主导情绪，气候摘要动态生成

---

## 9. M06 · 个人情绪档案模块

### 9.1 功能描述

展示用户昵称、发帖数、获赞数、连续活跃天数、本周情绪占比、情绪日历、我的帖子与温情周报入口。

### 9.2 接口规范

#### 9.2.1 个人概览 ⬜

```
GET /api/profile
Header: Authorization: Bearer <token>
```

**Response.data**

```json
{
  "id": 1,
  "nickname": "小暖",
  "phone": "138****8000",
  "postCount": 12,
  "totalLikes": 88,
  "streakDays": 5,
  "moodClimate": "平静多云",
  "weekStats": {
    "calmPercent": 45,
    "anxiousPercent": 30,
    "happyPercent": 25
  }
}
```

#### 9.2.2 情绪日历 ⬜

```
GET /api/profile/calendar?month=2026-05
Header: Authorization: Bearer <token>
```

**Response.data**

```json
{
  "days": [
    { "date": "2026-05-01", "dominantMood": "calm", "color": "#73C088", "postCount": 2 }
  ]
}
```

#### 9.2.3 我的帖子 ⬜

```
GET /api/profile/posts?page=1&size=20
Header: Authorization: Bearer <token>
```

### 9.3 前端待办（成员 A）

- `ProfileTab` 对接 `/profile`
- 情绪日历 Grid 改造
- 「我的帖子」列表页
- 「翻开温情周报」对接 M04 接口

---

## 10. M07 · 通知系统（P2 扩展）

### 10.1 功能描述

Header「通知」按钮展示未读角标；通知列表包含被点赞、被接住、系统关怀、周报生成等类型。

### 10.2 接口规范


| 接口                                | 方法   | 说明   |
| --------------------------------- | ---- | ---- |
| `/api/notifications`              | GET  | 分页列表 |
| `/api/notifications/unread-count` | GET  | 未读数  |
| `/api/notifications/read-all`     | POST | 全部已读 |
| `/api/notifications/{id}/read`    | POST | 单条已读 |


**通知类型 `type`**：`like` | `support` | `system` | `weekly_report`

### 10.3 前端待办（成员 C）

- ✅ 新建 `NotificationPage.ets`（分类型标签/未读标记/全部已读）
- ✅ Header 未读角标（红点数字，99+ 显示）
- ✅ support 触发通知自动写入 `notifications` 表
- ✅ 周报生成触发通知

---

## 11. 接口总清单


| 编号  | 方法     | 路径                              | 模块  | 负责人 | 状态  |
| --- | ------ | ------------------------------- | --- | --- | --- |
| 01  | GET    | /api/auth/health                | M01 | A   | ✅   |
| 02  | GET    | /api/auth/captcha               | M01 | A   | ✅   |
| 03  | POST   | /api/auth/register              | M01 | A   | ✅   |
| 04  | POST   | /api/auth/login                 | M01 | A   | ✅   |
| 05  | GET    | /api/auth/me                    | M01 | A   | ✅   |
| 06  | POST   | /api/auth/logout                | M01 | A   | ⬜   |
| 07  | GET    | /api/posts                      | M02 | B   | ⬜   |
| 08  | GET    | /api/posts/{id}                 | M02 | B   | ⬜   |
| 09  | POST   | /api/posts/{id}/like            | M02 | B   | ⬜   |
| 10  | GET    | /api/stats/today                | M02 | B   | ⬜   |
| 11  | POST   | /api/posts                      | M03 | B   | ⬜   |
| 12  | DELETE | /api/posts/{id}                 | M03 | B   | ⬜   |
| 13  | POST   | /api/posts/{id}/support         | M04 | C   | ✅   |
| 14  | GET    | /api/profile/weekly-report      | M04 | C   | ✅   |
| 15  | GET    | /api/map/zones                  | M05 | C   | ✅   |
| 16  | GET    | /api/map/zones/{key}/posts      | M05 | C   | ✅   |
| 17  | GET    | /api/profile                    | M06 | A   | ⬜   |
| 18  | GET    | /api/profile/calendar           | M06 | A   | ⬜   |
| 19  | GET    | /api/profile/posts              | M06 | A   | ⬜   |
| 20  | GET    | /api/notifications              | M07 | C   | ✅   |
| 21  | GET    | /api/notifications/unread-count | M07 | C   | ✅   |
| 22  | POST   | /api/notifications/read-all     | M07 | C   | ✅   |
| 23  | POST   | /api/notifications/{id}/read    | M07 | C   | ✅   |
| 24  | POST   | /api/posts/{id}/react           | M02 | B   | ⬜   |
| 25  | DELETE | /api/posts/{id}/react           | M02 | B   | ⬜   |
| 26  | GET    | /api/posts/{id}/comments        | M02 | B   | ⬜   |
| 27  | POST   | /api/posts/{id}/comments        | M02 | B   | ⬜   |
| 28  | DELETE | /api/posts/{postId}/comments/{commentId} | M02 | B   | ⬜   |


---

## 12. 数据库设计

> 完整建表 SQL 见 `**backend/sql/init.sql**`，可直接执行初始化。

### 12.1 ER 关系概览

```
users 1──N posts
users 1──N post_likes N──1 posts
users 1──N ai_interactions N──1 posts
users 1──N user_daily_moods
users 1──N notifications
campus_zones 1──N location_zone_mappings
posts.location ──映射──> location_zone_mappings.zone_key
```

### 12.2 表清单


| 表名                       | 说明            | 负责人 |
| ------------------------ | ------------- | --- |
| `users`                  | 用户账号          | A   |
| `posts`                  | 心情帖子          | B   |
| `post_likes`             | 点赞记录（唯一约束防重复） | B   |
| `post_reactions`         | 情绪反应记录（单人单帖唯一） | B   |
| `post_comments`          | 共鸣评论（含悄悄话）      | B   |
| `ai_interactions`        | AI 互动记录       | C   |
| `campus_zones`           | 校园区域配置        | C   |
| `location_zone_mappings` | 位置→区域映射       | C   |
| `user_daily_moods`       | 用户每日情绪统计      | A   |
| `notifications`          | 用户通知          | C   |


### 12.3 核心表字段说明

#### users


| 字段                      | 类型                 | 说明          |
| ----------------------- | ------------------ | ----------- |
| id                      | BIGINT PK          | 用户 ID       |
| nickname                | VARCHAR(64) UNIQUE | 昵称，可登录      |
| phone                   | VARCHAR(20) UNIQUE | 手机号，可登录     |
| password_hash           | VARCHAR(255)       | BCrypt      |
| avatar_url              | VARCHAR(512)       | 头像（预留）      |
| status                  | TINYINT            | 1 正常 / 0 禁用 |
| created_at / updated_at | DATETIME(6)        | 时间戳         |


#### posts


| 字段                      | 类型           | 说明                     |
| ----------------------- | ------------ | ---------------------- |
| id                      | BIGINT PK    | 帖子 ID                  |
| user_id                 | BIGINT FK    | 作者                     |
| mood                    | VARCHAR(32)  | 情绪 key                 |
| content                 | VARCHAR(500) | 正文                     |
| location                | VARCHAR(128) | 位置名称                   |
| zone_key                | VARCHAR(32)  | 区域 library/living/lake |
| like_count              | INT          | 点赞数冗余                  |
| ai_response             | TEXT         | 发帖 AI 回信               |
| status                  | TINYINT      | 1 正常 / 0 删除 / 2 屏蔽     |
| created_at / updated_at | DATETIME(6)  | 时间戳                    |


#### post_likes


| 字段         | 类型                 | 说明    |
| ---------- | ------------------ | ----- |
| id         | BIGINT PK          |       |
| user_id    | BIGINT FK          | 点赞用户  |
| post_id    | BIGINT FK          | 帖子    |
| created_at | DATETIME(6)        |       |
| **唯一约束**   | (user_id, post_id) | 防重复点赞 |

#### post_reactions


| 字段            | 类型           | 说明                                      |
| ------------- | ------------ | --------------------------------------- |
| id            | BIGINT PK    |                                         |
| user_id       | BIGINT FK    | 反应用户                                    |
| post_id       | BIGINT FK    | 帖子                                      |
| reaction_type | VARCHAR(32)  | hug / understand / cheer / happy_for_you / with_you |
| created_at    | DATETIME(6)  |                                         |
| updated_at    | DATETIME(6)  |                                         |
| **唯一约束**     | (user_id, post_id) | 单人单帖仅一条反应（可切换）                         |

#### post_comments


| 字段           | 类型           | 说明                                      |
| ------------ | ------------ | --------------------------------------- |
| id           | BIGINT PK    |                                         |
| post_id      | BIGINT FK    | 关联帖子                                    |
| user_id      | BIGINT FK    | 评论者                                     |
| content      | VARCHAR(200) | 评论内容                                    |
| comment_type | VARCHAR(16)  | resonance / whisper                     |
| status       | TINYINT      | 1 正常 / 0 删除 / 2 审核拦截                    |
| created_at   | DATETIME(6)  |                                         |
| updated_at   | DATETIME(6)  |                                         |


#### ai_interactions


| 字段            | 类型          | 说明                                          |
| ------------- | ----------- | ------------------------------------------- |
| scene         | VARCHAR(32) | post_publish / post_support / weekly_report |
| response_text | TEXT        | AI 回复                                       |
| is_crisis     | TINYINT     | 是否危机                                        |


#### user_daily_moods


| 字段                  | 类型          | 说明     |
| ------------------- | ----------- | ------ |
| user_id + stat_date | UNIQUE      | 每人每天一条 |
| dominant_mood       | VARCHAR(32) | 当日主导情绪 |
| post_count          | INT         | 当日发帖数  |


### 12.4 建表命令

```bash
mysql -u root -p < backend/sql/init.sql
```

> JPA `ddl-auto=update` 可辅助增量同步，**团队请以 `init.sql` 为准**。

---

## 13. 开发里程碑建议


| 阶段    | 目标                            | 负责人   |
| ----- | ----------------------------- | ----- |
| 第 1 周 | 执行建表；M01 退出登录；M02 列表 + M03 发帖 | A + B |
| 第 2 周 | 点赞、统计、个人概览；发帖联调端到端            | B + A |
| 第 3 周 | AI 回信（发帖 + 接住）；地图区域统计         | C + B |
| 第 4 周 | 情绪日历、周报、通知；全流程测试              | 全员    |
| 第 5 周 | Bug 修复、演示数据、答辩材料              | 全员    |


---

## 14. 附录

### 14.1 前端核心文件索引


| 路径                                           | 说明       |
| -------------------------------------------- | -------- |
| `entry/src/main/ets/pages/Login.ets`         | 登录页      |
| `entry/src/main/ets/pages/Register.ets`      | 注册页      |
| `entry/src/main/ets/pages/Index.ets`         | 主 Tab 容器 |
| `entry/src/main/ets/tabs/FeedTab.ets`        | 心墙       |
| `entry/src/main/ets/tabs/PostTab.ets`        | 发帖       |
| `entry/src/main/ets/tabs/MapTab.ets`         | 地图       |
| `entry/src/main/ets/tabs/ProfileTab.ets`     | 个人       |
| `entry/src/main/ets/service/AuthApi.ets`     | 认证 API   |
| `entry/src/main/ets/model/MoodWallTypes.ets` | 业务类型     |
| `backend/sql/init.sql`                       | 数据库初始化   |


### 14.2 本地配置

克隆仓库后请先阅读：`**docs/本地配置注意事项.md`**

### 14.3 V1.0 → V2.0 主要变更


| 变更项  | V1.0            | V2.0（当前）            |
| ---- | --------------- | ------------------- |
| 认证方式 | 学校邮箱 + 短信验证码    | 手机号 + 昵称 + 图形验证码    |
| 登录账号 | 邮箱              | 昵称或手机号              |
| 后端   | AGC CloudDB（规划） | Spring Boot + MySQL |
| 匿名昵称 | 后端随机生成          | 用户注册时自填昵称           |
| 数据库  | AGC 表结构         | MySQL 8 完整 8 表设计    |


---

*文档维护：随迭代更新接口状态列（✅ / ⬜）与 `init.sql` 保持同步。*