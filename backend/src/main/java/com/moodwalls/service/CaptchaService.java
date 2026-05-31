package com.moodwalls.service;

import com.moodwalls.dto.CaptchaResponse;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

/**
 * 图形/文本验证码服务：服务端生成验证码并返回给前端展示，注册时校验。
 */
@Service
public class CaptchaService {

    private static final long CAPTCHA_TTL_SECONDS = 300;
    private static final String CHARS = "23456789ABCDEFGHJKLMNPQRSTUVWXYZ";

    private final Map<String, CaptchaEntry> captchaStore = new ConcurrentHashMap<>();

    public CaptchaResponse createCaptcha() {
        String captchaId = UUID.randomUUID().toString().replace("-", "");
        String code = randomCode(4);
        captchaStore.put(captchaId, new CaptchaEntry(code, Instant.now().getEpochSecond() + CAPTCHA_TTL_SECONDS));
        return new CaptchaResponse(captchaId, code);
    }

    public boolean verify(String captchaId, String captchaCode) {
        if (captchaId == null || captchaId.isBlank() || captchaCode == null || captchaCode.isBlank()) {
            return false;
        }
        CaptchaEntry entry = captchaStore.get(captchaId);
        if (entry == null) {
            return false;
        }
        if (Instant.now().getEpochSecond() > entry.expireAt) {
            captchaStore.remove(captchaId);
            return false;
        }
        boolean matched = entry.code.equalsIgnoreCase(captchaCode.trim());
        captchaStore.remove(captchaId);
        return matched;
    }

    private String randomCode(int length) {
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < length; i++) {
            int index = (int) (Math.random() * CHARS.length());
            sb.append(CHARS.charAt(index));
        }
        return sb.toString();
    }

    private record CaptchaEntry(String code, long expireAt) {
    }
}
