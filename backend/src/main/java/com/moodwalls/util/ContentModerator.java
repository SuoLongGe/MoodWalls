package com.moodwalls.util;

import java.util.List;

public final class ContentModerator {

    private static final List<String> SENSITIVE_WORDS = List.of(
            "自杀", "自残", "去死", "杀人", "毒品", "赌博", "色情"
    );

    private ContentModerator() {
    }

    public static void checkComment(String content) {
        if (content == null || content.isBlank()) {
            return;
        }
        String normalized = content.toLowerCase();
        for (String word : SENSITIVE_WORDS) {
            if (normalized.contains(word.toLowerCase())) {
                throw new com.moodwalls.exception.BusinessException(422, "评论包含敏感内容，请修改后重试");
            }
        }
    }
}
