package com.moodwalls.service;

import com.moodwalls.dto.AuthResponse;
import com.moodwalls.dto.CaptchaResponse;
import com.moodwalls.dto.LoginRequest;
import com.moodwalls.dto.RegisterRequest;
import com.moodwalls.dto.UserProfile;
import com.moodwalls.entity.User;
import com.moodwalls.exception.BusinessException;
import com.moodwalls.repository.UserRepository;
import com.moodwalls.security.JwtTokenProvider;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Optional;
import java.util.regex.Pattern;

@Service
public class AuthService {

    private static final Pattern PHONE_PATTERN = Pattern.compile("^1\\d{10}$");

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider jwtTokenProvider;
    private final CaptchaService captchaService;

    public AuthService(
            UserRepository userRepository,
            PasswordEncoder passwordEncoder,
            JwtTokenProvider jwtTokenProvider,
            CaptchaService captchaService) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtTokenProvider = jwtTokenProvider;
        this.captchaService = captchaService;
    }

    public CaptchaResponse createCaptcha() {
        return captchaService.createCaptcha();
    }

    @Transactional
    public AuthResponse register(RegisterRequest request) {
        if (userRepository.existsByPhone(request.getPhone())) {
            throw new BusinessException(409, "该手机号已注册");
        }
        if (userRepository.existsByNickname(request.getNickname().trim())) {
            throw new BusinessException(409, "该昵称已被使用");
        }
        if (!captchaService.verify(request.getCaptchaId(), request.getCaptchaCode())) {
            throw new BusinessException(400, "验证码错误或已过期");
        }

        User user = new User();
        user.setNickname(request.getNickname().trim());
        user.setPhone(request.getPhone());
        user.setPasswordHash(passwordEncoder.encode(request.getPassword()));

        User saved = userRepository.save(user);
        String token = jwtTokenProvider.generateToken(saved.getId(), saved.getPhone());
        return new AuthResponse(token, UserProfile.from(saved));
    }

    public AuthResponse login(LoginRequest request) {
        User user = findUserByAccount(request.getAccount())
                .orElseThrow(() -> new BusinessException(401, "账号或密码错误"));

        if (!passwordEncoder.matches(request.getPassword(), user.getPasswordHash())) {
            throw new BusinessException(401, "账号或密码错误");
        }

        String token = jwtTokenProvider.generateToken(user.getId(), user.getPhone());
        return new AuthResponse(token, UserProfile.from(user));
    }

    public UserProfile getProfile(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new BusinessException(404, "用户不存在"));
        return UserProfile.from(user);
    }

    private Optional<User> findUserByAccount(String account) {
        String trimmed = account.trim();
        if (PHONE_PATTERN.matcher(trimmed).matches()) {
            return userRepository.findByPhone(trimmed);
        }
        return userRepository.findByNickname(trimmed);
    }
}
