-- 用户邮箱（用于注册验证与邮箱验证码登录）
ALTER TABLE users
    ADD COLUMN email VARCHAR(128) DEFAULT NULL AFTER phone;

ALTER TABLE users
    ADD UNIQUE KEY uk_users_email (email);

-- 允许仅邮箱注册的用户不填写手机号
ALTER TABLE users
    MODIFY COLUMN phone VARCHAR(20) DEFAULT NULL;
