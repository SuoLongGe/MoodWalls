package com.moodwalls.service;

import com.moodwalls.dto.EmailCodeResponse;
import com.moodwalls.exception.BusinessException;
import com.moodwalls.repository.UserRepository;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.security.SecureRandom;
import java.time.Instant;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import java.util.regex.Pattern;

@Service
public class EmailVerificationService {

    private static final Pattern EMAIL_PATTERN =
            Pattern.compile("^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$");

    private final EmailService emailService;
    private final UserRepository userRepository;
    private final long codeTtlSeconds;
    private final long resendIntervalSeconds;
    private final SecureRandom random = new SecureRandom();
    private final Map<String, EmailCodeEntry> codeStore = new ConcurrentHashMap<>();
    private final Map<String, Long> lastSentAtByEmailScene = new ConcurrentHashMap<>();

    public EmailVerificationService(
            EmailService emailService,
            UserRepository userRepository,
            @Value("${moodwalls.mail.code-ttl-seconds:300}") long codeTtlSeconds,
            @Value("${moodwalls.mail.resend-interval-seconds:60}") long resendIntervalSeconds) {
        this.emailService = emailService;
        this.userRepository = userRepository;
        this.codeTtlSeconds = codeTtlSeconds;
        this.resendIntervalSeconds = resendIntervalSeconds;
    }

    public EmailCodeResponse sendCode(String email, String scene) {
        String normalized = normalizeEmail(email);
        validateScene(normalized, scene);
        enforceResendInterval(normalized, scene);

        String code = generateCode();
        String codeId = UUID.randomUUID().toString().replace("-", "");
        long expireAt = Instant.now().getEpochSecond() + codeTtlSeconds;
        codeStore.put(codeId, new EmailCodeEntry(normalized, code, scene, expireAt));

        emailService.sendVerificationCode(normalized, code, scene);
        lastSentAtByEmailScene.put(buildResendKey(normalized, scene), Instant.now().getEpochSecond());

        return new EmailCodeResponse(codeId, (int) codeTtlSeconds);
    }

    public void verify(String codeId, String email, String code, String scene) {
        if (codeId == null || codeId.isBlank() || code == null || code.isBlank()) {
            throw new BusinessException(400, "验证码不能为空");
        }
        String normalized = normalizeEmail(email);
        EmailCodeEntry entry = codeStore.get(codeId);
        if (entry == null || entry.expireAt < Instant.now().getEpochSecond()) {
            codeStore.remove(codeId);
            throw new BusinessException(400, "验证码错误或已过期");
        }
        if (!entry.email.equals(normalized) || !entry.scene.equals(scene)) {
            throw new BusinessException(400, "验证码不匹配");
        }
        if (!entry.code.equals(code.trim())) {
            throw new BusinessException(400, "验证码错误或已过期");
        }
        codeStore.remove(codeId);
    }

    private void validateScene(String email, String scene) {
        if ("register".equals(scene)) {
            if (userRepository.existsByEmail(email)) {
                throw new BusinessException(409, "该邮箱已注册");
            }
            return;
        }
        if ("login".equals(scene)) {
            if (!userRepository.existsByEmail(email)) {
                throw new BusinessException(404, "该邮箱尚未注册");
            }
            return;
        }
        if ("bind_email".equals(scene)) {
            if (userRepository.existsByEmail(email)) {
                throw new BusinessException(409, "该邮箱已被其他账号使用");
            }
            return;
        }
        throw new BusinessException(400, "验证码场景不合法");
    }

    private void enforceResendInterval(String email, String scene) {
        String key = buildResendKey(email, scene);
        Long lastSentAt = lastSentAtByEmailScene.get(key);
        if (lastSentAt == null) {
            return;
        }
        long elapsed = Instant.now().getEpochSecond() - lastSentAt;
        if (elapsed < resendIntervalSeconds) {
            long waitSeconds = resendIntervalSeconds - elapsed;
            throw new BusinessException(429, "发送过于频繁，请 " + waitSeconds + " 秒后再试");
        }
    }

    private String buildResendKey(String email, String scene) {
        return email + ":" + scene;
    }

    private String generateCode() {
        int value = 100000 + random.nextInt(900000);
        return String.valueOf(value);
    }

    public static String normalizeEmail(String email) {
        if (email == null) {
            throw new BusinessException(400, "邮箱不能为空");
        }
        String normalized = email.trim().toLowerCase();
        if (!EMAIL_PATTERN.matcher(normalized).matches()) {
            throw new BusinessException(400, "邮箱格式不正确");
        }
        return normalized;
    }

    private record EmailCodeEntry(String email, String code, String scene, long expireAt) {
    }
}
