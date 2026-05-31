# MoodWalls Backend

校园心灵墙（MoodWalls）Spring Boot 后端，提供登录、注册、JWT 鉴权等基础能力。

## 技术栈

- Java 17
- Spring Boot 3.2
- Spring Data JPA
- MySQL 8
- JWT (jjwt)
- BCrypt 密码加密

## 环境要求

- JDK 17+
- Maven 3.8+
- MySQL 8（本地运行）

## 数据库配置

默认连接本地 MySQL（`localhost:3306`，库名 `moodwalls`）。

**用户名、密码、JWT 密钥** 请在个人配置文件 `src/main/resources/application-local.yml` 中设置（从 `application-local.yml.example` 复制）。

详细说明见项目根目录 [docs/本地配置注意事项.md](../docs/本地配置注意事项.md)。

### 初始化数据库

```bash
mysql -u root -p < sql/init.sql
```

或在 MySQL 客户端中手动执行 `sql/init.sql`。JPA 配置了 `ddl-auto: update`，首次启动也会自动建表。

## 启动服务

```bash
cd backend
mvn spring-boot:run
```

服务监听 **`0.0.0.0:8080`**，局域网内可通过你的电脑 IP 访问（IP 见 `application-local.yml` 中的 `moodwalls.server-host`）。

HarmonyOS 前端在 `ApiConfig.local.ets` 中配置 Base URL，格式：`http://<你的局域网IP>:8080/api`。

> 请确保防火墙已放行 **8080** 端口，且手机/模拟器与电脑在同一网络。

## API 接口

统一响应格式：

```json
{
  "code": 200,
  "message": "success",
  "data": { }
}
```

### 1. 健康检查

```
GET /api/auth/health
```

### 2. 获取注册验证码

```
GET /api/auth/captcha
```

响应示例：

```json
{
  "code": 200,
  "message": "success",
  "data": {
    "captchaId": "a1b2c3d4...",
    "captchaText": "X7K9"
  }
}
```

前端将 `captchaText` 展示给用户，注册时提交 `captchaId` + 用户填写的 `captchaCode`。

### 3. 注册

```
POST /api/auth/register
Content-Type: application/json

{
  "nickname": "小暖",
  "phone": "13800138000",
  "captchaId": "a1b2c3d4...",
  "captchaCode": "X7K9",
  "password": "abc12345"
}
```

### 4. 登录

```
POST /api/auth/login
Content-Type: application/json

{
  "account": "13800138000",
  "password": "abc12345"
}
```

`account` 支持 **手机号** 或 **昵称**。

成功响应 `data` 示例：

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

### 5. 获取当前用户

```
GET /api/auth/me
Authorization: Bearer <token>
```

## 项目结构

```
backend/
├── pom.xml
├── sql/
│   └── init.sql                 # MySQL 初始化脚本
└── src/main/
    ├── java/com/moodwalls/
    │   ├── MoodWallsApplication.java
    │   ├── config/              # CORS、密码加密
    │   ├── controller/          # REST 接口
    │   ├── dto/                 # 请求/响应对象
    │   ├── entity/              # JPA 实体
    │   ├── exception/           # 全局异常处理
    │   ├── repository/          # 数据访问层
    │   ├── security/            # JWT
    │   └── service/             # 业务逻辑
    └── resources/
        └── application.yml      # 配置文件
```

## 安全说明

- 密码使用 BCrypt 哈希存储，明文不落库
- 登录成功后返回 JWT，有效期默认 7 天
- `application.yml` 中的数据库密码和 JWT 密钥仅适用于本地开发；**请勿将真实密码提交到公开仓库**

## 联调示例（curl）

```bash
# 将 BASE 改为你的地址，例如 http://localhost:8080
BASE=http://localhost:8080

curl $BASE/api/auth/health
curl $BASE/api/auth/captcha
```
