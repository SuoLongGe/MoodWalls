-- MoodWalls 校园心灵墙 - MySQL 初始化脚本
-- 执行：mysql -u root -p < sql/init.sql

CREATE DATABASE IF NOT EXISTS moodwalls
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_unicode_ci;

USE moodwalls;

-- ============================================================
-- 1. 用户表
-- ============================================================
CREATE TABLE IF NOT EXISTS users (
  id            BIGINT       NOT NULL AUTO_INCREMENT COMMENT '用户ID',
  nickname      VARCHAR(64)  NOT NULL COMMENT '昵称（唯一，可用于登录）',
  phone         VARCHAR(20)  NOT NULL COMMENT '手机号（唯一，可用于登录）',
  password_hash VARCHAR(255) NOT NULL COMMENT 'BCrypt 密码哈希',
  avatar_key    VARCHAR(32)  DEFAULT 'avatar_01' COMMENT '头像资源名 avatar_01~avatar_21',
  status        TINYINT      NOT NULL DEFAULT 1 COMMENT '状态：1正常 0禁用',
  created_at    DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at    DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  UNIQUE KEY uk_users_phone (phone),
  UNIQUE KEY uk_users_nickname (nickname),
  KEY idx_users_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户表';

-- ============================================================
-- 2. 心情帖子表
-- ============================================================
CREATE TABLE IF NOT EXISTS posts (
  id          BIGINT       NOT NULL AUTO_INCREMENT COMMENT '帖子ID',
  user_id     BIGINT       NOT NULL COMMENT '发帖用户ID',
  mood        VARCHAR(32)  NOT NULL COMMENT '情绪key：happy/calm/moved/tired/anxious/sad/angry/lonely',
  content     VARCHAR(500) NOT NULL COMMENT '帖子正文（最多500字）',
  location    VARCHAR(128) NOT NULL COMMENT '发帖位置标签',
  zone_key    VARCHAR(32)  DEFAULT NULL COMMENT '所属校园区域：library/living/lake',
  like_count  INT          NOT NULL DEFAULT 0 COMMENT '点赞数（冗余字段）',
  ai_response TEXT         DEFAULT NULL COMMENT '发帖时AI回信（可为空）',
  status      TINYINT      NOT NULL DEFAULT 1 COMMENT '状态：1正常 0用户删除 2屏蔽',
  created_at  DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at  DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  KEY idx_posts_user_id (user_id),
  KEY idx_posts_mood (mood),
  KEY idx_posts_zone_key (zone_key),
  KEY idx_posts_created_at (created_at),
  KEY idx_posts_status_created (status, created_at),
  CONSTRAINT fk_posts_user FOREIGN KEY (user_id) REFERENCES users (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='心情帖子表';

-- ============================================================
-- 3. 帖子点赞表（防重复点赞）
-- ============================================================
CREATE TABLE IF NOT EXISTS post_likes (
  id         BIGINT      NOT NULL AUTO_INCREMENT,
  user_id    BIGINT      NOT NULL COMMENT '点赞用户ID',
  post_id    BIGINT      NOT NULL COMMENT '帖子ID',
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  UNIQUE KEY uk_post_likes_user_post (user_id, post_id),
  KEY idx_post_likes_post_id (post_id),
  CONSTRAINT fk_post_likes_user FOREIGN KEY (user_id) REFERENCES users (id),
  CONSTRAINT fk_post_likes_post FOREIGN KEY (post_id) REFERENCES posts (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='帖子点赞记录';

-- ============================================================
-- 4. 帖子情绪反应表（单人单帖唯一）
-- ============================================================
CREATE TABLE IF NOT EXISTS post_reactions (
  id            BIGINT      NOT NULL AUTO_INCREMENT,
  user_id       BIGINT      NOT NULL COMMENT '反应用户ID',
  post_id       BIGINT      NOT NULL COMMENT '帖子ID',
  reaction_type VARCHAR(32) NOT NULL COMMENT '反应类型：hug/understand/cheer/happy_for_you/with_you',
  created_at    DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at    DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  UNIQUE KEY uk_post_reactions_user_post (user_id, post_id),
  KEY idx_post_reactions_post_id (post_id),
  KEY idx_post_reactions_type (reaction_type),
  CONSTRAINT fk_post_reactions_user FOREIGN KEY (user_id) REFERENCES users (id),
  CONSTRAINT fk_post_reactions_post FOREIGN KEY (post_id) REFERENCES posts (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='帖子情绪反应记录';

-- ============================================================
-- 5. 帖子评论表（共鸣/悄悄话）
-- ============================================================
CREATE TABLE IF NOT EXISTS post_comments (
  id           BIGINT       NOT NULL AUTO_INCREMENT,
  post_id      BIGINT       NOT NULL COMMENT '关联帖子ID',
  user_id      BIGINT       NOT NULL COMMENT '评论用户ID',
  content      VARCHAR(200) NOT NULL COMMENT '评论内容',
  comment_type VARCHAR(16)  NOT NULL COMMENT '评论类型：resonance/whisper',
  status       TINYINT      NOT NULL DEFAULT 1 COMMENT '状态：1正常 0删除 2审核拦截',
  created_at   DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at   DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  KEY idx_post_comments_post_id (post_id),
  KEY idx_post_comments_user_id (user_id),
  KEY idx_post_comments_type (comment_type),
  KEY idx_post_comments_status_created (status, created_at),
  CONSTRAINT fk_post_comments_post FOREIGN KEY (post_id) REFERENCES posts (id),
  CONSTRAINT fk_post_comments_user FOREIGN KEY (user_id) REFERENCES users (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='帖子评论记录';

-- ============================================================
-- 6. AI 互动记录（「接住心声」等）
-- ============================================================
CREATE TABLE IF NOT EXISTS ai_interactions (
  id            BIGINT      NOT NULL AUTO_INCREMENT,
  user_id       BIGINT      NOT NULL COMMENT '触发用户ID',
  post_id       BIGINT      DEFAULT NULL COMMENT '关联帖子ID（可为空，如周报）',
  scene         VARCHAR(32) NOT NULL COMMENT '场景：post_publish/post_support/weekly_report',
  prompt_snapshot TEXT      DEFAULT NULL COMMENT 'Prompt快照（调试用，可选）',
  response_text TEXT        NOT NULL COMMENT 'AI 回复正文',
  is_crisis     TINYINT     NOT NULL DEFAULT 0 COMMENT '是否触发危机关怀：0否 1是',
  created_at    DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  KEY idx_ai_interactions_user_id (user_id),
  KEY idx_ai_interactions_post_id (post_id),
  KEY idx_ai_interactions_scene (scene),
  CONSTRAINT fk_ai_interactions_user FOREIGN KEY (user_id) REFERENCES users (id),
  CONSTRAINT fk_ai_interactions_post FOREIGN KEY (post_id) REFERENCES posts (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='AI互动记录';

-- ============================================================
-- 7. 校园区域配置表
-- ============================================================
CREATE TABLE IF NOT EXISTS campus_zones (
  id          BIGINT       NOT NULL AUTO_INCREMENT,
  zone_key    VARCHAR(32)  NOT NULL COMMENT '区域标识：library/living/lake',
  title       VARCHAR(64)  NOT NULL COMMENT '区域名称',
  subtitle    VARCHAR(64)  DEFAULT NULL COMMENT '情绪标签副标题',
  description VARCHAR(512) DEFAULT NULL COMMENT '区域描述模板',
  accent      VARCHAR(16)  DEFAULT NULL COMMENT '默认主题色',
  sort_order  INT          NOT NULL DEFAULT 0,
  status      TINYINT      NOT NULL DEFAULT 1,
  created_at  DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at  DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  UNIQUE KEY uk_campus_zones_key (zone_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='校园区域配置';

-- ============================================================
-- 8. 位置与区域映射表
-- ============================================================
CREATE TABLE IF NOT EXISTS location_zone_mappings (
  id            BIGINT       NOT NULL AUTO_INCREMENT,
  location_name VARCHAR(128) NOT NULL COMMENT '发帖位置名称',
  zone_key      VARCHAR(32)  NOT NULL COMMENT '所属区域',
  PRIMARY KEY (id),
  UNIQUE KEY uk_location_name (location_name),
  KEY idx_location_zone_key (zone_key),
  CONSTRAINT fk_location_zone FOREIGN KEY (zone_key) REFERENCES campus_zones (zone_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='发帖位置与区域映射';

-- ============================================================
-- 9. 用户每日情绪统计（个人日历）
-- ============================================================
CREATE TABLE IF NOT EXISTS user_daily_moods (
  id             BIGINT      NOT NULL AUTO_INCREMENT,
  user_id        BIGINT      NOT NULL,
  stat_date      DATE        NOT NULL COMMENT '统计日期',
  dominant_mood  VARCHAR(32) NOT NULL COMMENT '当日主导情绪',
  post_count     INT         NOT NULL DEFAULT 0 COMMENT '当日发帖数',
  mood_score     INT         DEFAULT NULL COMMENT '情绪分数（可选，用于趋势）',
  created_at     DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at     DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  UNIQUE KEY uk_user_daily_moods (user_id, stat_date),
  KEY idx_user_daily_moods_date (stat_date),
  CONSTRAINT fk_user_daily_moods_user FOREIGN KEY (user_id) REFERENCES users (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户每日情绪统计';

-- ============================================================
-- 10. 通知表
-- ============================================================
CREATE TABLE IF NOT EXISTS notifications (
  id         BIGINT       NOT NULL AUTO_INCREMENT,
  user_id    BIGINT       NOT NULL COMMENT '接收用户ID',
  type       VARCHAR(32)  NOT NULL COMMENT '类型：like/support/system/weekly_report',
  title      VARCHAR(128) NOT NULL COMMENT '通知标题',
  content    VARCHAR(512) NOT NULL COMMENT '通知内容',
  ref_type   VARCHAR(32)  DEFAULT NULL COMMENT '关联类型：post/ai/report',
  ref_id     BIGINT       DEFAULT NULL COMMENT '关联ID',
  is_read    TINYINT      NOT NULL DEFAULT 0 COMMENT '0未读 1已读',
  created_at DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  KEY idx_notifications_user_read (user_id, is_read),
  KEY idx_notifications_created_at (created_at),
  CONSTRAINT fk_notifications_user FOREIGN KEY (user_id) REFERENCES users (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户通知';

-- ============================================================
-- 初始化数据：校园区域
-- ============================================================
INSERT INTO campus_zones (zone_key, title, subtitle, description, accent, sort_order)
VALUES
  ('library', '图书馆', '橙色压力区', '临近期中考试，这里更容易积攒紧张和压力，很多同学都在默默坚持。', '#F08C62', 1),
  ('living',  '生活区', '绿色治愈区', '宿舍和食堂一带更松弛一些，晚饭后的校园情绪会慢慢柔和下来。', '#73C088', 2),
  ('lake',    '湖畔与咖啡角', '金色放空区', '适合散步、发呆、吹风，把脑子里的噪音放轻一点。', '#F6C445', 3),
  ('activity', '活动与交流区', '活力缤纷区', '讲座、社团、活动聚集，这里情绪更活跃多元。', '#B786F7', 4),
  ('sports', '体育运动区', '蓝色活力区', '操场和体育馆释放着汗水和压力，跑完一圈又是新的自己。', '#6CB1F0', 5),
  ('history', '校史人文区', '沉淀怀旧区', '老建筑见证岁月，安静而厚重。', '#E17272', 6),
  ('medical', '医学文化区', '白色关怀区', '湘雅红楼承载着医学的温暖与理性。', '#8B7AD6', 7),
  ('railway', '铁道特色区', '铁色记忆区', '铁路园的铁轨延伸向远方，就像未来的路一样长。', '#92A0B0', 8)
ON DUPLICATE KEY UPDATE title = VALUES(title);

INSERT INTO location_zone_mappings (location_name, zone_key)
VALUES
  -- PRD 预设位置
  ('主图书馆三楼', 'library'),
  ('未名湖畔咖啡角', 'lake'),
  ('第二食堂', 'living'),
  ('五号宿舍楼', 'living'),
  ('理科科研楼 B 座', 'library'),

  -- 学习与安静表达区域
  ('潇湘校区图书馆', 'library'),
  ('中南讲堂', 'library'),
  ('毓秀楼', 'library'),

  ('观云池', 'lake'),
  ('荷花池', 'lake'),

  ('升华学生生活服务广场', 'living'),
  ('升华学生公寓', 'living'),
  ('麓南校区二食堂', 'living'),
  ('麓南校区八食堂', 'living')
ON DUPLICATE KEY UPDATE
  zone_key = VALUES(zone_key);

-- ============================================================
-- 帖子送云记录（D06）
-- ============================================================
CREATE TABLE IF NOT EXISTS post_cloud_gifts (
  id         BIGINT      NOT NULL AUTO_INCREMENT,
  user_id    BIGINT      NOT NULL COMMENT '送云用户ID',
  post_id    BIGINT      NOT NULL COMMENT '目标帖子ID',
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  KEY idx_post_cloud_gifts_post_id (post_id),
  KEY idx_post_cloud_gifts_user_post_created (user_id, post_id, created_at),
  CONSTRAINT fk_post_cloud_gifts_user FOREIGN KEY (user_id) REFERENCES users (id),
  CONSTRAINT fk_post_cloud_gifts_post FOREIGN KEY (post_id) REFERENCES posts (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='帖子送云记录';

-- ============================================================
-- 鼓励小纸条池（H05 · 与帖子独立）
-- ============================================================
CREATE TABLE IF NOT EXISTS encouragement_notes (
  id         BIGINT       NOT NULL AUTO_INCREMENT,
  user_id    BIGINT       NOT NULL COMMENT '作者用户ID（抽取时不展示）',
  content    VARCHAR(200) NOT NULL COMMENT '鼓励内容，8~120字',
  mood       VARCHAR(32)  NOT NULL DEFAULT 'calm' COMMENT '情绪语气：happy/calm/moved',
  status     TINYINT      NOT NULL DEFAULT 1 COMMENT '1正常 0删除',
  created_at DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  KEY idx_encouragement_notes_user_id (user_id),
  KEY idx_encouragement_notes_status_created (status, created_at),
  CONSTRAINT fk_encouragement_notes_user FOREIGN KEY (user_id) REFERENCES users (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='鼓励小纸条';

-- ============================================================
-- 每日陌生人小纸条抽取记录（H05）
-- ============================================================
CREATE TABLE IF NOT EXISTS inspiration_draws (
  id         BIGINT       NOT NULL AUTO_INCREMENT,
  user_id    BIGINT       NOT NULL COMMENT '抽取用户ID',
  note_id    BIGINT       DEFAULT NULL COMMENT '来源小纸条ID，种子句为空',
  content    VARCHAR(200) NOT NULL COMMENT '展示摘句快照',
  mood       VARCHAR(16)  DEFAULT NULL COMMENT '情绪key',
  draw_date  DATE         NOT NULL COMMENT '抽取日期（上海时区）',
  created_at DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  UNIQUE KEY uk_inspiration_user_date (user_id, draw_date),
  KEY idx_inspiration_user_note (user_id, note_id),
  CONSTRAINT fk_inspiration_user FOREIGN KEY (user_id) REFERENCES users (id),
  CONSTRAINT fk_inspiration_note FOREIGN KEY (note_id) REFERENCES encouragement_notes (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='每日小纸条抽取记录';
