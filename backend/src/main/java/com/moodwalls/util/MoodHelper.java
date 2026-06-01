package com.moodwalls.util;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

public final class MoodHelper {

    private static final Map<String, String> LABELS = new HashMap<>();
    private static final Map<String, String> COLORS = new HashMap<>();

    static {
        LABELS.put("happy", "开心");
        LABELS.put("calm", "平静");
        LABELS.put("moved", "感动");
        LABELS.put("tired", "疲惫");
        LABELS.put("anxious", "焦虑");
        LABELS.put("sad", "低落");
        LABELS.put("angry", "生气");
        LABELS.put("lonely", "孤单");

        COLORS.put("happy", "#F6C445");
        COLORS.put("calm", "#73C088");
        COLORS.put("moved", "#B786F7");
        COLORS.put("tired", "#92A0B0");
        COLORS.put("anxious", "#F08C62");
        COLORS.put("sad", "#6CB1F0");
        COLORS.put("angry", "#E17272");
        COLORS.put("lonely", "#8B7AD6");
    }

    private MoodHelper() {
    }

    public static String labelOf(String mood) {
        return LABELS.getOrDefault(mood, "心情");
    }

    public static String colorOf(String mood) {
        return COLORS.getOrDefault(mood, "#D8DEDC");
    }

    public static String maskPhone(String phone) {
        if (phone == null || phone.length() < 7) {
            return phone;
        }
        return phone.substring(0, 3) + "****" + phone.substring(phone.length() - 4);
    }

    public static String buildClimate(int calmPercent, int anxiousPercent, int happyPercent) {
        if (calmPercent == 0 && anxiousPercent == 0 && happyPercent == 0) {
            return "暂无记录";
        }
        int max = Math.max(calmPercent, Math.max(anxiousPercent, happyPercent));
        if (max == calmPercent) {
            return "平静多云";
        }
        if (max == anxiousPercent) {
            return "略带焦虑";
        }
        return "晴朗温暖";
    }

    public static String dominantMoodFromCounts(Map<String, Long> moodCounts) {
        if (moodCounts == null || moodCounts.isEmpty()) {
            return "calm";
        }
        return moodCounts.entrySet().stream()
                .max(Map.Entry.comparingByValue())
                .map(Map.Entry::getKey)
                .orElse("calm");
    }

    public static int percent(long part, long total) {
        if (total <= 0) {
            return 0;
        }
        return (int) Math.round(part * 100.0 / total);
    }

    public static boolean isCalmGroup(String mood) {
        return "calm".equals(mood) || "moved".equals(mood);
    }

    public static boolean isAnxiousGroup(String mood) {
        return "anxious".equals(mood) || "sad".equals(mood) || "tired".equals(mood)
                || "angry".equals(mood) || "lonely".equals(mood);
    }

    public static boolean isHappyGroup(String mood) {
        return "happy".equals(mood);
    }

    public static String formatTimeText(java.time.LocalDateTime createdAt) {
        java.time.Duration duration = java.time.Duration.between(createdAt, java.time.LocalDateTime.now());
        long minutes = duration.toMinutes();
        if (minutes < 1) {
            return "刚刚";
        }
        if (minutes < 60) {
            return minutes + " 分钟前";
        }
        long hours = duration.toHours();
        if (hours < 24) {
            return hours + " 小时前";
        }
        long days = duration.toDays();
        if (days < 7) {
            return days + " 天前";
        }
        return createdAt.getMonthValue() + "月" + createdAt.getDayOfMonth() + "日";
    }

    public static String buildWeeklyReport(int calm, int anxious, int happy, int postCount) {
        if (postCount == 0) {
            return "这周你还没有在心墙上留下记录。哪怕只是一句「今天有点累」，也值得被温柔地接住。";
        }
        int max = Math.max(calm, Math.max(anxious, happy));
        if (max == calm) {
            return "这周你的情绪底色更偏平静，说明你在忙碌里依然保留了稳定自己的能力。"
                    + "焦虑并不代表脆弱，它只是提醒你最近真的很辛苦。";
        }
        if (max == anxious) {
            return "这周你更多写下了紧张、低落或疲惫的时刻。能说出来，本身就是一种勇气。"
                    + "校园里也有人和你一样，正在慢慢穿过这段情绪。";
        }
        return "这周开心与明亮的片段也不少，它们像小小的光点，提醒你生活不只有压力。"
                + "继续把心情留在心墙上，你会更容易看见自己的变化。";
    }
}
