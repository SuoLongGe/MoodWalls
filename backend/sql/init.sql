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
  avatar_url    VARCHAR(512) DEFAULT NULL COMMENT '头像URL（预留）',
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
-- 4. AI 互动记录（「接住心声」等）
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
-- 5. 校园区域配置表
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
-- 6. 位置与区域映射表
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
-- 7. 用户每日情绪统计（个人日历）
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
-- 8. 通知表
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
  ('lake',    '湖畔与咖啡角', '金色放空区', '适合散步、发呆、吹风，把脑子里的噪音放轻一点。', '#F6C445', 3)
ON DUPLICATE KEY UPDATE title = VALUES(title);

INSERT INTO location_zone_mappings (location_name, zone_key)
VALUES
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
