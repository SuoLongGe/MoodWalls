package com.moodwalls.controller;

import com.moodwalls.dto.ApiResponse;
import com.moodwalls.dto.AuthResponse;
import com.moodwalls.dto.CaptchaResponse;
import com.moodwalls.dto.LoginRequest;
import com.moodwalls.dto.RegisterRequest;
import com.moodwalls.dto.UserProfile;
import com.moodwalls.exception.BusinessException;
import com.moodwalls.security.JwtTokenProvider;
import com.moodwalls.service.AuthService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final AuthService authService;
    private final JwtTokenProvider jwtTokenProvider;

    public AuthController(AuthService authService, JwtTokenProvider jwtTokenProvider) {
        this.authService = authService;
        this.jwtTokenProvider = jwtTokenProvider;
    }

    @GetMapping("/health")
    public ApiResponse<Map<String, String>> health() {
        Map<String, String> info = new HashMap<>();
        info.put("status", "ok");
        info.put("service", "moodwalls-backend");
        return ApiResponse.ok(info);
    }

    /**
     * 获取注册用验证码（服务端生成，前端展示 captchaText 供用户填写）
     */
    @GetMapping("/captcha")
    public ApiResponse<CaptchaResponse> captcha() {
        CaptchaResponse response = authService.createCaptcha();
        return ApiResponse.ok(response);
    }

    @PostMapping("/register")
    public ApiResponse<AuthResponse> register(@Valid @RequestBody RegisterRequest request) {
        AuthResponse response = authService.register(request);
        return ApiResponse.ok("注册成功", response);
    }

    @PostMapping("/login")
    public ApiResponse<AuthResponse> login(@Valid @RequestBody LoginRequest request) {
        AuthResponse response = authService.login(request);
        return ApiResponse.ok("登录成功", response);
    }

    @GetMapping("/me")
    public ApiResponse<UserProfile> me(@RequestHeader(value = "Authorization", required = false) String authorization) {
        Long userId = extractUserId(authorization);
        UserProfile profile = authService.getProfile(userId);
        return ApiResponse.ok(profile);
    }

    private Long extractUserId(String authorization) {
        if (authorization == null || !authorization.startsWith("Bearer ")) {
            throw new BusinessException(401, "未登录或 Token 无效");
        }
        String token = authorization.substring(7);
        if (!jwtTokenProvider.validateToken(token)) {
            throw new BusinessException(401, "Token 已过期或无效");
        }
        return jwtTokenProvider.getUserIdFromToken(token);
    }
}
