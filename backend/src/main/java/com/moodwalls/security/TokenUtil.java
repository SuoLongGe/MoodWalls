package com.moodwalls.security;

import com.moodwalls.exception.BusinessException;
import org.springframework.stereotype.Component;

@Component
public class TokenUtil {

    private final JwtTokenProvider jwtTokenProvider;

    public TokenUtil(JwtTokenProvider jwtTokenProvider) {
        this.jwtTokenProvider = jwtTokenProvider;
    }

    public Long extractUserId(String authorization) {
        if (authorization == null || !authorization.startsWith("Bearer ")) {
            throw new BusinessException(401, "未登录或 Token 无效");
        }
        String token = authorization.substring(7);
        if (!jwtTokenProvider.validateToken(token)) {
            throw new BusinessException(401, "Token 已过期或无效");
        }
        return jwtTokenProvider.getUserIdFromToken(token);
    }

    public Long extractUserIdOrNull(String authorization) {
        try {
            return extractUserId(authorization);
        } catch (BusinessException e) {
            return null;
        }
    }
}
