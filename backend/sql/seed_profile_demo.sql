-- 个人情绪档案演示数据（在已有用户后执行）
-- mysql -u root -p moodwalls < sql/seed_profile_demo.sql

USE moodwalls;

SET @uid := (SELECT id FROM users ORDER BY id LIMIT 1);

INSERT INTO posts (user_id, mood, content, location, zone_key, like_count, created_at, updated_at)
SELECT @uid, 'calm', '今天在图书馆待了一下午，终于把作业推进了一点。', '潇湘校区图书馆', 'library', 12,
       DATE_SUB(NOW(), INTERVAL 1 DAY), NOW()
WHERE @uid IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM posts WHERE user_id = @uid LIMIT 1);

INSERT INTO posts (user_id, mood, content, location, zone_key, like_count, created_at, updated_at)
SELECT @uid, 'anxious', '期中周压力好大，但写下来好像轻松了一点。', '潇湘校区图书馆', 'library', 8,
       DATE_SUB(NOW(), INTERVAL 2 DAY), NOW()
WHERE @uid IS NOT NULL;

INSERT INTO posts (user_id, mood, content, location, zone_key, like_count, created_at, updated_at)
SELECT @uid, 'happy', '傍晚在观云池边散步，风很温柔。', '观云池', 'lake', 15,
       DATE_SUB(NOW(), INTERVAL 3 DAY), NOW()
WHERE @uid IS NOT NULL;

INSERT INTO posts (user_id, mood, content, location, zone_key, like_count, created_at, updated_at)
SELECT @uid, 'sad', '有点想家，但知道大家都在各自努力。', '升华学生公寓', 'living', 6,
       DATE_SUB(NOW(), INTERVAL 4 DAY), NOW()
WHERE @uid IS NOT NULL;

INSERT INTO posts (user_id, mood, content, location, zone_key, like_count, created_at, updated_at)
SELECT @uid, 'moved', '室友悄悄给我带了热饮，心里暖了一下。', '麓南校区二食堂', 'living', 20,
       DATE_SUB(NOW(), INTERVAL 5 DAY), NOW()
WHERE @uid IS NOT NULL;

INSERT INTO user_daily_moods (user_id, stat_date, dominant_mood, post_count, created_at, updated_at)
SELECT @uid, DATE_SUB(CURDATE(), INTERVAL 1 DAY), 'calm', 1, NOW(), NOW()
WHERE @uid IS NOT NULL
ON DUPLICATE KEY UPDATE dominant_mood = VALUES(dominant_mood), post_count = VALUES(post_count);

INSERT INTO user_daily_moods (user_id, stat_date, dominant_mood, post_count, created_at, updated_at)
SELECT @uid, DATE_SUB(CURDATE(), INTERVAL 2 DAY), 'anxious', 1, NOW(), NOW()
WHERE @uid IS NOT NULL
ON DUPLICATE KEY UPDATE dominant_mood = VALUES(dominant_mood), post_count = VALUES(post_count);
