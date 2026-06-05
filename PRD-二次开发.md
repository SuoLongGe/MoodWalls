# MoodWalls 校园心灵墙 · 二次开发需求文档


| 项目     | 说明                              |
| ------ | ------------------------------- |
| 文档版本   | V3.0（二次开发）                     |
| 状态     | 规划中                             |
| 前置基线   | PRD V2.0 核心功能已联调完成（见 1.2）      |
| 前端平台   | HarmonyOS NEXT · ArkTS · ArkUI  |
| 后端平台   | Spring Boot 3.2 · MySQL 8 · JWT |
| 新增模块   | 7 项明确需求 + 4 项建议增强              |
| 预计新增接口 | 约 12 个（含评论、搜索、帖子可见性）           |


---

## 1. 文档概述

### 1.1 文档目的

在 **V2.0 已完成功能** 基础上，规划体验升级与互动深化，形成可分工、可排期、可验收的二次开发规格，明确：

- 7 项用户提出的需求边界与实现方案（含降级路径）
- 前后端接口与页面改造清单
- **数据库表结构变更**（`ALTER` / 新索引 / 新字段，统一写入 `backend/sql/migrations/`）
- 建议增强项（非必须，可作为答辩加分）

### 1.2 V2.0 基线能力（二次开发起点）


| 维度        | 现状                                                                 |
| --------- | ------------------------------------------------------------------ |
| **认证与个人** | 登录注册、JWT、个人档案、情绪日历、我的帖子、心情分布统计、通知角标                               |
| **心墙 Feed** | 帖子列表、情绪筛选、点赞、下拉刷新、分页、接住心声                                        |
| **发帖**    | 8 种情绪、位置、AI 回信、持久化                                                 |
| **地图**    | 8 区域情绪气候卡片 + 区域帖子列表（**非真实地理地图**）                                |
| **数据表**   | `posts`、`post_likes`、`post_comments`（表已建，**评论 API 未实现**）等 |
| **前端结构**  | `FeedTab` / `MapTab` / `PostTab` / `ProfileTab` + `MoodWallHeader` |


> 本文档所有「⬜ 待开发」均指在以上基线之上的增量工作。

### 1.3 二次开发模块总览


| 编号       | 名称           | 优先级 | 难度  | 状态  |
| -------- | ------------ | --- | --- | --- |
| **R01**  | 本人帖子视觉区分     | P0  | 低   | ✅   |
| **R02**  | 微博/校园集市式卡片   | P0  | 中   | ✅   |
| **R03**  | 评论与回复        | P0  | 中   | ⬜   |
| **R04**  | 删帖 / 仅自己可见   | P0  | 低   | ⬜   |
| **R05**  | 真实校园地图（或替代）  | P1  | 高   | ⬜   |
| **R06**  | 页面切换动画       | P1  | 中   | ⬜   |
| **R07**  | 关键字搜索帖子      | P0  | 中   | ⬜   |
| **R08+** | 建议增强（见第 11 节） | P2  | 不一  | ⬜   |


---

## 2. 三人分工建议（二次开发）


| 成员  | 负责模块                         | 交付标准                                  |
| --- | ---------------------------- | ------------------------------------- |
| **A** | R04 帖子可见性、R07 搜索后端、个人页删帖入口   | 搜索准确、私密帖仅作者可见、删除后 Feed 不可见            |
| **B** | R01/R02 心墙 UI、R03 评论前后端、R06 动画 | 本人帖可识别、评论可发可删、Tab 切换有过渡               |
| **C** | R05 地图方案、评论通知、R08 帖子详情页      | 地图至少完成「方案 B」、评论触发 `comment` 类通知      |


协作约定沿用 PRD V2.0 第 2 节：统一 `ApiResponse`、JWT Header、SQL 变更提交至 `backend/sql/migrations/` 并同步更新 `init.sql`。

---

## 3. 全局技术规范（继承 + 增量）

### 3.1 接口基础

与 V2.0 一致：`Base URL`、`Authorization: Bearer <token>`、分页 `page/size`。

### 3.2 帖子列表统一字段扩展（`NoteItem` / `PostSummaryDto`）

二次开发后，帖子摘要**必须**增加以下字段：


| 字段            | 类型      | 说明                                    |
| ------------- | ------- | ------------------------------------- |
| `isMine`      | boolean | 是否当前登录用户发布                            |
| `visibility`  | string  | `public` \| `private`（仅自己可见）         |
| `commentCount`| number  | 评论数（公开共鸣，不含悄悄话计数或单独字段见 R03）          |
| `canDelete`   | boolean | 是否可删除（作者且未物理删除）                       |
| `canEditVisibility` | boolean | 是否可切换可见性（仅作者）                    |


### 3.3 帖子 `status` 与 `visibility` 语义


| posts.status | 含义                    |
| ------------ | --------------------- |
| 1            | 正常                    |
| 0            | 用户删除（软删，列表不可见）        |
| 2            | 平台屏蔽（管理预留）            |


| posts.visibility | 含义                          |
| ---------------- | --------------------------- |
| 1                | 公开（默认，Feed/搜索/地图可见）        |
| 2                | 仅自己可见（他人接口不可见，作者在个人页可见）   |


---

## 4. R01 · 本人帖子视觉区分

### 4.1 功能描述

心墙列表中，**当前用户自己发布的帖子**在样式上与他人帖子有明显区分，无需额外点击即可识别「这是我的」。

### 4.2 交互与视觉规范

参考微博「我的微博」与校园集市「本人帖」做法，建议组合使用（至少满足 2 项）：


| 元素     | 他人帖              | 本人帖                                      |
| ------ | ---------------- | ---------------------------------------- |
| 卡片左边框  | 无                | 3px 主题色竖条（`#73C088`）                     |
| 卡片背景   | `#FFFFFF`        | `#F7FBF8` 浅绿底                             |
| 角标     | 无                | 右上角「我的」胶囊标签                               |
| 昵称区    | 显示发帖昵称           | 显示「我」或昵称 + 「（我）」                         |
| 操作区    | 点赞 / 接住 / 评论     | 同上 + **更多**（删帖、改可见性，见 R04）                |


### 4.3 后端

- `GET /api/posts`、`GET /api/posts/{id}` 在登录态下计算 `isMine = (userId == currentUserId)`
- 未登录：`isMine` 恒为 `false`

### 4.4 前端待办

- `FeedTab.ets`：`item.isMine === true` 时应用 `buildMyNoteCard` / 条件样式
- `NoteItem` 类型增加 `isMine`、`visibility`
- 区域帖子列表、搜索结果列表**复用同一卡片组件** `PostCard.ets`（新建，供 R02 共用）

---

## 5. R02 · 微博 / 校园集市式帖子卡片

### 5.1 功能描述

将现有便签式列表改为更接近 **微博时间线 / 校园集市信息流** 的卡片结构，信息层次更清晰。

### 5.2 卡片结构（自上而下）


```
┌─────────────────────────────────────┐
│ [头像] 昵称 · 情绪标签     3 分钟前    │  ← 顶栏
│ 📍 潇湘校区图书馆                      │  ← 位置（可选）
├─────────────────────────────────────┤
│ 正文内容，最多 500 字，支持换行展示…      │  ← 正文区（15~16sp）
├─────────────────────────────────────┤
│ ❤ 12   💬 5   🤝 接住                │  ← 互动栏
└─────────────────────────────────────┘
```

### 5.3 设计 Token


| 项目   | 值                                      |
| ---- | -------------------------------------- |
| 卡片圆角 | 12vp                                   |
| 卡片阴影 | 轻阴影 `rgba(0,0,0,0.06)` offsetY=2       |
| 头像   | 36×36，圆形                               |
| 情绪标签 | 使用 `MOOD_OPTIONS` 色块胶囊                |
| 正文字号 | 15sp，行高 22sp                           |
| 互动图标 | 点赞红心、评论气泡、接住心声（沿用现有逻辑）                 |


### 5.4 前端待办

- 新建 `components/PostCard.ets`（Props：`note`、`isMine`、回调）
- `FeedTab` / `MyPostsPage` / 搜索页 / 地图半屏帖列表统一引用
- 长按卡片：本人帖弹出「删除 / 仅自己可见 / 取消」ActionSheet（R04）

### 5.5 后端

无新增接口，依赖列表字段扩展（3.2 节）。

---

## 6. R03 · 评论与回复

### 6.1 功能描述

用户可对他人或自己的帖子进行 **公开评论**；支持 **回复某条评论**（一层嵌套，不做无限楼层）；帖子作者可删除自己帖下任意评论，评论者可删除自己的评论。

> V2.0 已在 `post_comments` 表预留 `resonance` / `whisper` 类型。二次开发 **优先实现公开评论 `resonance`**；`whisper`（悄悄话）可作为 P2 加分。

### 6.2 业务规则

1. 评论长度 1~200 字，敏感词命中返回 `422`
2. 私密帖（`visibility=2`）：**禁止他人评论**（仅作者自己可写备注型评论，可选 P2）
3. 回复：`parentId` 指向一级评论，仅支持 **二级**（回复评论，不再回复回复）
4. 列表默认按时间正序；热门帖可按时间倒序（配置项）
5. 评论成功：帖子 `comment_count +1`；删除评论：`-1`
6. 通知：帖子作者收到 `type=comment` 通知（见 12.3 节 `notifications` 扩展）

### 6.3 接口规范

#### 6.3.1 评论列表 ⬜

```
GET /api/posts/{id}/comments?page=1&size=20
Header: Authorization: Bearer <token>（可选）
```

**Response.data**

```json
{
  "list": [
    {
      "id": 101,
      "postId": 1,
      "userId": 8,
      "authorNickname": "星夜",
      "authorAvatarKey": "avatar_03",
      "content": "我也在经历类似阶段，抱抱你。",
      "commentType": "resonance",
      "parentId": null,
      "replyToNickname": null,
      "isMine": false,
      "canDelete": false,
      "createdAt": "2026-06-04T14:02:00",
      "timeText": "3 分钟前",
      "replies": [
        {
          "id": 102,
          "parentId": 101,
          "authorNickname": "小暖",
          "content": "谢谢你～",
          "replyToNickname": "星夜",
          "isMine": true,
          "canDelete": true,
          "timeText": "1 分钟前"
        }
      ]
    }
  ],
  "total": 12,
  "page": 1,
  "size": 20,
  "hasMore": false
}
```

#### 6.3.2 发表评论 / 回复 ⬜

```
POST /api/posts/{id}/comments
Header: Authorization: Bearer <token>
```

**Request**

```json
{
  "content": "我也有过同样的焦虑，先慢慢来。",
  "commentType": "resonance",
  "parentId": null,
  "replyToUserId": null
}
```

回复示例：

```json
{
  "content": "谢谢你的鼓励！",
  "commentType": "resonance",
  "parentId": 101,
  "replyToUserId": 8
}
```

#### 6.3.3 删除评论 ⬜

```
DELETE /api/posts/{postId}/comments/{commentId}
Header: Authorization: Bearer <token>
```

规则：评论者删自己的；帖子作者可删该帖下任意评论。

### 6.4 前端待办

- 新建 `pages/PostDetailPage.ets` 或底部半屏 `CommentSheet.ets`
- 心墙卡片点击评论图标 → 打开评论面板
- 输入框 + 发送；回复时展示「回复 @昵称」
- `PostApi` / `CommentApi` 封装上述三个接口

---

## 7. R04 · 删帖与仅自己可见

### 7.1 功能描述

作者对自己的帖子可：

1. **删除**：软删除，全站不可见，个人「我的帖子」中移至「已删除」或不再展示
2. **设为仅自己可见**：他人 Feed / 搜索 / 地图均不可见，作者在个人页仍可见并带「仅自己」标识

### 7.2 接口规范

#### 7.2.1 删除帖子（已有路由，需完善语义） ⬜

```
DELETE /api/posts/{id}
Header: Authorization: Bearer <token>
```

- 将 `status` 置为 `0`
- 仅作者可删

#### 7.2.2 修改可见性 ⬜

```
PATCH /api/posts/{id}/visibility
Header: Authorization: Bearer <token>
```

**Request**

```json
{ "visibility": "private" }
```

或

```json
{ "visibility": "public" }
```

**Response.data**：更新后的 `PostSummaryDto`

### 7.3 列表过滤规则（后端）

| 场景                    | 规则                                      |
| --------------------- | --------------------------------------- |
| Feed `/api/posts`     | 仅 `status=1 AND visibility=1`           |
| 搜索                    | 同上                                      |
| 地图区域帖                 | 同上                                      |
| 个人页 `/api/profile/posts` | 作者本人：`status=1` 全部；可选参数 `includePrivate` |
| 帖子详情                  | 公开帖所有人可看；私密帖仅作者                       |


### 7.4 前端待办

- 本人帖「更多」菜单：删除（二次确认）、仅自己可见 / 恢复公开
- `MyPostsPage` 展示可见性角标
- 删除成功后从 Feed 列表移除或刷新

---

## 8. R05 · 校园真实地图（含降级方案）

### 8.1 需求说明

将现有 **8 区域卡片列表** 升级为更接近真实校园空间的展示，使用户感受到「情绪落在校园地图上」。

### 8.2 方案对比


| 方案                 | 描述                                        | 难度  | 推荐阶段               |
| ------------------ | ----------------------------------------- | --- | ------------------ |
| **A. HarmonyOS Map Kit** | 接入华为地图 SDK，标注 8 区域 POI、热力或标记点              | 高   | 有地图 Key + 真机调试资源时 |
| **B. 静态校园平面图 + 热点** | 使用中南大学校本部 **手绘/官方平面图** 作为底图，8 区域为可点击热点     | 中   | **推荐默认交付**         |
| **C. 增强版区域墙（现状++）** | 保留列表，增加 **横向校区示意图**、区域连线动画，不接入 GIS           | 低   | 时间不足时的保底           |


### 8.3 推荐实施路径（方案 B）

1. 资源：准备 `rawfile/campus_map.png`（校本部鸟瞰或简化平面图）
2. `MapTab` 上层 `Stack`：底图 + 8 个绝对定位热点按钮（坐标写死在配置 JSON）
3. 点击热点 → 与现有一致，弹出区域情绪摘要 + 帖子半屏列表
4. `campus_zones` 表增加字段存储热点坐标（见 12.1 节）

### 8.4 方案 A 前置条件（若要做真地图）

- 申请华为 AGC 地图服务 Key
- `module.json5` 声明定位权限 `ohos.permission.LOCATION`
- 后端 `campus_zones` 补充 `latitude`、`longitude`
- 评估模拟器对 Map 组件支持情况

### 8.5 接口增量

```
GET /api/map/layout
```

**Response.data**

```json
{
  "mode": "static_image",
  "imageUrl": "/assets/campus_map.png",
  "zones": [
    {
      "zoneKey": "library",
      "title": "图书馆",
      "xPercent": 42.5,
      "yPercent": 38.0,
      "postCount": 128,
      "dominantMood": "anxious",
      "accent": "#F08C62"
    }
  ]
}
```

`xPercent/yPercent` 为相对底图宽高百分比，方便不同屏幕适配。

### 8.6 交付标准

- **最低**：完成方案 C（现状 + 示意图）
- **达标**：完成方案 B（静态地图 + 热点）
- **加分**：完成方案 A 或 B+A 切换

---

## 9. R06 · 页面切换动画

### 9.1 功能描述

使 Tab 切换、二级页面跳转更接近商业 App，减少「硬切」感。

### 9.2 动画清单


| 场景              | 动画建议                                      | 实现要点                               |
| --------------- | ----------------------------------------- | ---------------------------------- |
| 底部 4 Tab 切换     | 内容区 **淡入 + 轻微上移**（200ms）                  | `Index.ets` 监听 `currentTab`，`animateTo` |
| 进入帖子详情 / 评论页    | 右侧 **滑入**（320ms）                           | `pageTransition` / `router` 自定义转场   |
| 进入通知 / 我的帖子 / 搜索 | 同上                                        | 统一 `UiHelper.pushTo` 封装动画          |
| 发帖成功跳回心墙        | Tab 切 0 + 列表顶部 **滚动 + 高亮** 新帖（可选）          | 提升反馈感                              |
| 下拉刷新            | 保持系统 Refresh 组件                           | 已有                                 |


### 9.3 前端待办

- `common/UiHelper.ets`：`pushTo` / `replaceTo` 增加 `NavigationMode` 或封装 `NavPathStack` 转场（视项目路由方案）
- `Index.ets`：Tab 内容切换用 `opacity` + `translate` 过渡，避免销毁重建导致的闪屏（ProfileTab 可保持懒加载）
- 注意：**性能优先**，低端机可降级为仅 Tab 淡入

### 9.4 后端

无。

---

## 10. R07 · 关键字搜索

### 10.1 功能描述

用户通过关键字搜索帖子，支持按 **正文模糊匹配**，可选按情绪、时间范围筛选。

### 10.2 交互

- 入口：心墙顶栏搜索图标 → `SearchPage.ets`
- 搜索框 + 历史记录（本地 `Preferences` 存最近 10 条）
- 结果列表复用 `PostCard.ets`
- 空状态：「没有找到相关心情，换个词试试」

### 10.3 接口规范 ⬜

```
GET /api/posts/search?keyword=期中&page=1&size=20&mood=all&period=month
Header: Authorization: Bearer <token>（可选）
```

| 参数        | 说明                                    |
| --------- | ------------------------------------- |
| `keyword` | 必填，1~32 字，前后 trim                    |
| `mood`    | 可选，情绪 key 或 `all`                     |
| `period`  | 可选，`today` \| `week` \| `month` \| `all` |
| `page/size` | 分页                                  |


**Response.data**：与 `GET /api/posts` 相同分页结构。

### 10.4 后端实现建议

**MySQL 方案（推荐课程项目）**

```sql
-- 见 12.1 migrations
ALTER TABLE posts ADD FULLTEXT INDEX ft_posts_content (content);
```

查询：

```sql
SELECT * FROM posts
WHERE status = 1 AND visibility = 1
  AND MATCH(content) AGAINST(:keyword IN NATURAL LANGUAGE MODE)
ORDER BY created_at DESC;
```

中文较短时可降级为 `LIKE %keyword%`（数据量 < 10 万足够）。

### 10.5 前端待办

- 新建 `pages/SearchPage.ets`、`SearchApi` 或 `PostApi.searchPosts`
- 防抖 300ms 发起请求
- 高亮关键字（可选 P2）

---

## 11. 建议增强项（可选）

以下不在用户 7 项硬性需求内，但对产品完整度有帮助，建议写入答辩「展望」或 P2 迭代：


| 编号      | 想法           | 说明                                       |
| ------- | ------------ | ---------------------------------------- |
| **R08** | 帖子详情独立页      | 评论、点赞、接住心声集中在一页，分享深链接（应用内路由）             |
| **R09** | 评论 / 回复通知    | `notifications.type` 增加 `comment`、`reply` |
| **R10** | 举报与拉黑        | `post_reports` 表，管理员后台预留                    |
| **R11** | 情绪反应（抱抱等）    | PRD V2.0 已设计 `post_reactions`，可替代单一「点赞」展示更丰富互动 |
| **R12** | 热门话题 / 今日情绪榜 | 搜索页增加「大家都在聊」标签云                          |
| **R13** | 夜间模式         | 跟随系统或手动切换，心墙深色卡片                          |
| **R14** | 发帖草稿箱        | 本地 `Preferences` 暂存未发布内容                 |


---

## 12. 数据库变更说明

> **规范**：增量 SQL 放在 `backend/sql/migrations/V3_001_xxx.sql`，并回写 `init.sql` 供新环境一键初始化。

### 12.1 `posts` 表变更 ⬜


```sql
-- V3_001_posts_visibility_search.sql

ALTER TABLE posts
  ADD COLUMN visibility TINYINT NOT NULL DEFAULT 1
    COMMENT '可见性：1公开 2仅自己可见' AFTER status,
  ADD COLUMN comment_count INT NOT NULL DEFAULT 0
    COMMENT '公开评论数冗余' AFTER like_count;

-- 搜索索引（FULLTEXT 要求 InnoDB + utf8mb4）
ALTER TABLE posts ADD FULLTEXT INDEX ft_posts_content (content);

-- 列表查询组合索引
CREATE INDEX idx_posts_feed_list ON posts (status, visibility, created_at DESC);
```

**`status` 语义不变**；`visibility` 与 `status` 独立：

- 删除：`status=0`
- 仅自己可见：`status=1, visibility=2`

### 12.2 `post_comments` 表变更 ⬜

```sql
-- V3_002_post_comments_reply.sql

ALTER TABLE post_comments
  ADD COLUMN parent_id BIGINT DEFAULT NULL
    COMMENT '父评论ID，NULL为一级评论' AFTER comment_type,
  ADD COLUMN reply_to_user_id BIGINT DEFAULT NULL
    COMMENT '被回复用户ID' AFTER parent_id,
  ADD KEY idx_post_comments_parent (parent_id);

ALTER TABLE post_comments
  ADD CONSTRAINT fk_post_comments_parent
    FOREIGN KEY (parent_id) REFERENCES post_comments (id) ON DELETE CASCADE;
```

### 12.3 `campus_zones` 表变更（地图方案 B）⬜

```sql
-- V3_003_campus_zones_map_coords.sql

ALTER TABLE campus_zones
  ADD COLUMN map_x_percent DECIMAL(5,2) DEFAULT NULL
    COMMENT '静态地图热点 X 百分比 0~100' AFTER accent,
  ADD COLUMN map_y_percent DECIMAL(5,2) DEFAULT NULL
    COMMENT '静态地图热点 Y 百分比 0~100' AFTER map_x_percent,
  ADD COLUMN latitude DECIMAL(10,7) DEFAULT NULL
    COMMENT '纬度（真地图方案可选）' AFTER map_y_percent,
  ADD COLUMN longitude DECIMAL(10,7) DEFAULT NULL
    COMMENT '经度（真地图方案可选）' AFTER latitude;
```

初始化 8 区域热点坐标（示例，需按实际平面图调整）：

```sql
UPDATE campus_zones SET map_x_percent = 35.00, map_y_percent = 40.00 WHERE zone_key = 'library';
-- ... 其余 7 个区域
```

### 12.4 `notifications` 类型扩展 ⬜

无需改表结构，`type` 字段增加业务值即可：

| type 新增值    | 触发场景        |
| ----------- | ----------- |
| `comment`   | 帖子收到新评论     |
| `reply`     | 评论收到回复      |
| `reaction`  | 收到情绪反应（若做 R11） |


### 12.5 可选新表：搜索历史（服务端同步时使用，**默认本地存储可不建表**）

```sql
-- V3_004_search_history.sql（可选）

CREATE TABLE IF NOT EXISTS search_history (
  id         BIGINT      NOT NULL AUTO_INCREMENT,
  user_id    BIGINT      NOT NULL,
  keyword    VARCHAR(64) NOT NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  KEY idx_search_history_user (user_id, created_at),
  CONSTRAINT fk_search_history_user FOREIGN KEY (user_id) REFERENCES users (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户搜索历史（可选）';
```

### 12.6 变更后 ER 关系补充

```
posts 1──N post_comments
post_comments 1──N post_comments (parent_id，二级回复)
users 1──N post_comments
```

---

## 13. 接口总清单（二次开发增量）


| 编号  | 方法     | 路径                                   | 模块  | 状态  |
| --- | ------ | ------------------------------------ | --- | --- |
| 29  | GET    | /api/posts/search                    | R07 | ⬜   |
| 30  | PATCH  | /api/posts/{id}/visibility           | R04 | ⬜   |
| 31  | GET    | /api/posts/{id}/comments             | R03 | ⬜   |
| 32  | POST   | /api/posts/{id}/comments             | R03 | ⬜   |
| 33  | DELETE | /api/posts/{postId}/comments/{commentId} | R03 | ⬜   |
| 34  | GET    | /api/map/layout                      | R05 | ⬜   |
| —   | DELETE | /api/posts/{id}                      | R04 | 已有，需完善权限与软删 |
| —   | GET    | /api/posts                           | R01/R02 | 已有，需扩展字段 |


**已有接口需修改响应字段**：`GET /api/posts`、`GET /api/posts/{id}`、`GET /api/profile/posts`、`GET /api/map/zones/{key}/posts` 增加 `isMine`、`visibility`、`commentCount`。

---

## 14. 前端文件改造清单


| 文件                               | 改造内容                           |
| -------------------------------- | ------------------------------ |
| `components/PostCard.ets`        | **新建**，微博式卡片，支持本人样式、评论数、更多菜单   |
| `components/CommentSheet.ets`    | **新建**，评论列表 + 输入            |
| `components/MoodWallHeader.ets`  | 增加搜索入口图标                       |
| `tabs/FeedTab.ets`               | 使用 PostCard，接评论、本人帖样式          |
| `tabs/MapTab.ets`                | 方案 B/C 地图底图 + 热点               |
| `pages/SearchPage.ets`           | **新建**                         |
| `pages/PostDetailPage.ets`       | **新建**（R08，可与评论合并）             |
| `pages/Index.ets`              | Tab 切换动画、`headerStats` 已迁出，保持 |
| `common/UiHelper.ets`            | 路由转场动画                         |
| `service/PostApi.ets`          | search、visibility、comments     |
| `model/MoodWallTypes.ets`      | 扩展 NoteItem、CommentItem        |
| `resources/base/profile/main_pages.json` | 注册 SearchPage、PostDetailPage |


---

## 15. 实施排期建议（4 周参考）


| 周次  | 目标                                       |
| --- | ---------------------------------------- |
| 第 1 周 | R01 + R02 卡片组件；R04 可见性/删帖后端 + 前端菜单；数据库 migration |
| 第 2 周 | R03 评论全链路 + 评论通知；R07 搜索前后端                 |
| 第 3 周 | R05 地图方案 B；R06 动画；联调与自测                   |
| 第 4 周 | Bug 修复、R08 详情页（可选）、答辩演示脚本、文档截图            |


---

## 16. 验收用例（抽样）


| 编号  | 步骤                  | 期望结果                    |
| --- | ------------------- | ----------------------- |
| T01 | A 用户发帖，A 在心墙查看      | 卡片有「我的」样式，左侧色条          |
| T02 | B 用户看 A 的帖          | 无「我的」样式，可评论             |
| T03 | A 将帖设为仅自己可见，B 刷 Feed | B 看不到；A 在「我的帖子」可见并带角标  |
| T04 | A 删除帖子              | 全站列表消失                  |
| T05 | 搜索关键字「图书馆」          | 命中含该词的公开帖               |
| T06 | 切换本日/本周 Tab         | 有淡入动画，无明显卡顿              |
| T07 | 打开地图页               | 显示校区示意图 + 可点区域（方案 B 达标） |


---

## 17. 风险与降级


| 风险               | 降级策略                          |
| ---------------- | ----------------------------- |
| 华为 Map Kit 权限/Key | 改用方案 B 静态平面图                  |
| FULLTEXT 中文分词不佳  | 搜索改用 `LIKE`，数据量大时再引入 ES      |
| 评论审核成本高          | 先做关键词黑名单 + 422，不做人工审核         |
| 动画低端机卡顿          | 系统设置关闭「过渡动画」或仅保留 Tab 淡入       |
| 二级回复层级膨胀         | 限制仅二级，UI 不展示「回复的回复」按钮         |


---

## 18. 文档修订记录


| 版本       | 日期         | 说明                    |
| -------- | ---------- | --------------------- |
| V3.0-draft | 2026-06-04 | 基于用户 7 项需求整理二次开发规格初稿 |


---

> 完整 V2.0 基线说明见 `PRD.md`。SQL 初始化见 `backend/sql/init.sql`；本次变更脚本建议目录 `backend/sql/migrations/`。
