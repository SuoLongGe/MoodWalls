package com.moodwalls.util;

import com.moodwalls.exception.BusinessException;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public final class ReactionHelper {

    private static final List<String> TYPES = List.of(
            "hug", "understand", "cheer", "happy_for_you", "with_you"
    );

    private static final Map<String, String> LABELS = Map.of(
            "hug", "抱抱",
            "understand", "懂你",
            "cheer", "加油",
            "happy_for_you", "为你开心",
            "with_you", "陪你"
    );

    private ReactionHelper() {
    }

    public static String normalizeType(String raw) {
        if (raw == null || raw.isBlank()) {
            throw new BusinessException(400, "请指定情绪反应类型");
        }
        String type = raw.trim().toLowerCase();
        if (!TYPES.contains(type)) {
            throw new BusinessException(400, "不支持的情绪反应类型");
        }
        return type;
    }

    public static String labelOf(String type) {
        return LABELS.getOrDefault(type, type);
    }

    public static List<String> allTypes() {
        return TYPES;
    }

    public static Map<String, Integer> emptyStats() {
        Map<String, Integer> stats = new LinkedHashMap<>();
        for (String type : TYPES) {
            stats.put(type, 0);
        }
        return stats;
    }
}
