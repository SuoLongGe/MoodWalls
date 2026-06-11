-- 帖子单图配图
ALTER TABLE posts
  ADD COLUMN image_url VARCHAR(512) DEFAULT NULL COMMENT '配图相对路径，如 /uploads/posts/2026/06/05/xxx.jpg' AFTER content;
