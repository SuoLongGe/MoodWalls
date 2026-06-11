-- 用户自定义头像（本地图片上传后的相对路径）
ALTER TABLE users
  ADD COLUMN avatar_url VARCHAR(512) DEFAULT NULL
  COMMENT '自定义头像相对路径，如 /uploads/avatars/2026/06/11/xxx.jpg'
  AFTER avatar_key;
