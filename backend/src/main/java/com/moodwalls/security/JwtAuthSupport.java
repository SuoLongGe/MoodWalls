package com.moodwalls.security;

import com.moodwalls.exception.BusinessException;
import org.springframework.stereotype.Component;

@Component
public class JwtAuthSupport {

    private final JwtTokenProvider jwtTokenProvider;

    public JwtAuthSupport(JwtTokenProvider jwtTokenProvider) {
        this.jwtTokenProvider = jwtTokenProvider;
    }

    public Long requireUserId(String authorization) {
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
