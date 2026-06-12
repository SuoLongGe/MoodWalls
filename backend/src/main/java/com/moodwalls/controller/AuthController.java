package com.moodwalls.controller;

import com.moodwalls.dto.ApiResponse;
import com.moodwalls.dto.AuthResponse;
import com.moodwalls.dto.CaptchaResponse;
import com.moodwalls.dto.ChangePasswordRequest;
import com.moodwalls.dto.EmailCodeResponse;
import com.moodwalls.dto.EmailLoginRequest;
import com.moodwalls.dto.LoginRequest;
import com.moodwalls.dto.RegisterRequest;
import com.moodwalls.dto.SendEmailCodeRequest;
import com.moodwalls.dto.UpdateProfileRequest;
import com.moodwalls.dto.UserProfile;
import com.moodwalls.security.JwtAuthSupport;
import com.moodwalls.service.AuthService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
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
    private final JwtAuthSupport jwtAuthSupport;

    public AuthController(AuthService authService, JwtAuthSupport jwtAuthSupport) {
        this.authService = authService;
        this.jwtAuthSupport = jwtAuthSupport;
    }

    @GetMapping("/health")
    public ApiResponse<Map<String, String>> health() {
        Map<String, String> info = new HashMap<>();
        info.put("status", "ok");
        info.put("service", "moodwalls-backend");
        return ApiResponse.ok(info);
    }

    /**
     * 获取注册用验证码（旧版文本验证码，保留兼容）
     */
    @GetMapping("/captcha")
    public ApiResponse<CaptchaResponse> captcha() {
        CaptchaResponse response = authService.createCaptcha();
        return ApiResponse.ok(response);
    }

    /**
     * 发送邮箱验证码（scene: register | login）
     */
    @PostMapping("/email/code")
    public ApiResponse<EmailCodeResponse> sendEmailCode(@Valid @RequestBody SendEmailCodeRequest request) {
        EmailCodeResponse response = authService.sendEmailCode(request);
        return ApiResponse.ok("验证码已发送", response);
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

    @PostMapping("/login/email")
    public ApiResponse<AuthResponse> loginByEmail(@Valid @RequestBody EmailLoginRequest request) {
        AuthResponse response = authService.loginByEmail(request);
        return ApiResponse.ok("登录成功", response);
    }

    @GetMapping("/me")
    public ApiResponse<UserProfile> me(@RequestHeader(value = "Authorization", required = false) String authorization) {
        Long userId = jwtAuthSupport.requireUserId(authorization);
        UserProfile profile = authService.getProfile(userId);
        return ApiResponse.ok(profile);
    }

    @PutMapping("/profile")
    public ApiResponse<UserProfile> updateProfile(
            @RequestHeader(value = "Authorization", required = false) String authorization,
            @Valid @RequestBody UpdateProfileRequest request) {
        Long userId = jwtAuthSupport.requireUserId(authorization);
        UserProfile profile = authService.updateProfile(userId, request);
        return ApiResponse.ok("资料已更新", profile);
    }

    @PutMapping("/password")
    public ApiResponse<Void> changePassword(
            @RequestHeader(value = "Authorization", required = false) String authorization,
            @Valid @RequestBody ChangePasswordRequest request) {
        Long userId = jwtAuthSupport.requireUserId(authorization);
        authService.changePassword(userId, request);
        return ApiResponse.ok("密码已修改", null);
    }

    @PostMapping("/logout")
    public ApiResponse<Void> logout() {
        return ApiResponse.ok("已退出登录", null);
    }

}
