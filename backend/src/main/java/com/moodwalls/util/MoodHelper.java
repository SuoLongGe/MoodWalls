package com.moodwalls.util;

import com.moodwalls.dto.MoodCurvePointDto;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public final class MoodHelper {

    private static final Map<String, String> LABELS = new HashMap<>();
    private static final Map<String, String> COLORS = new HashMap<>();
    private static final List<String> CARE_PRIORITY = List.of(
            "sad", "anxious", "lonely", "tired", "angry", "moved", "calm", "happy"
    );
    private static final String[] WEEKDAY_CN = {"日", "一", "二", "三", "四", "五", "六"};

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
        String picked = pickDominantMood(moodCounts);
        return picked != null ? picked : "calm";
    }

    public static String pickDominantMood(Map<String, Long> moodCounts) {
        if (moodCounts == null || moodCounts.isEmpty()) {
            return null;
        }
        long max = moodCounts.values().stream().mapToLong(Long::longValue).max().orElse(0L);
        if (max <= 0) {
            return null;
        }
        for (String mood : CARE_PRIORITY) {
            if (moodCounts.getOrDefault(mood, 0L) == max) {
                return mood;
            }
        }
        return moodCounts.entrySet().stream()
                .filter(e -> e.getValue() == max)
                .map(Map.Entry::getKey)
                .findFirst()
                .orElse(null);
    }

    public static int moodIndex(String mood) {
        if (mood == null) {
            return -1;
        }
        return switch (mood) {
            case "sad" -> 0;
            case "anxious" -> 1;
            case "lonely" -> 2;
            case "tired" -> 3;
            case "angry" -> 4;
            case "moved" -> 5;
            case "calm" -> 6;
            case "happy" -> 7;
            default -> 4;
        };
    }

    public static String weekdayLabel(LocalDate date) {
        DayOfWeek dayOfWeek = date.getDayOfWeek();
        int index = dayOfWeek.getValue() % 7;
        return WEEKDAY_CN[index];
    }

    public static String buildCurveSummary(List<MoodCurvePointDto> points) {
        if (points == null || points.isEmpty()) {
            return "还没有足够的心情记录，去贴第一张吧。";
        }
        String first = null;
        String last = null;
        int totalPosts = 0;
        for (MoodCurvePointDto point : points) {
            totalPosts += point.getPostCount();
            if (point.getDominantMood() != null) {
                if (first == null) {
                    first = point.getDominantMood();
                }
                last = point.getDominantMood();
            }
        }
        if (totalPosts == 0) {
            return "还没有足够的心情记录，去贴第一张吧。";
        }
        if (first == null || last == null) {
            return "这一周你留下了心情记录，继续写下来，会更容易看见自己的变化。";
        }
        if (first.equals(last)) {
            return "这一周你的情绪基调比较稳定，" + labelOf(first) + "陪伴了你大多数日子。";
        }
        int firstIdx = moodIndex(first);
        int lastIdx = moodIndex(last);
        if (lastIdx > firstIdx) {
            return "这一周你经历了起伏，但后半段似乎更轻松了一些。";
        }
        if (lastIdx < firstIdx) {
            return "这一周你经历了起伏，记得在忙碌里留一点温柔给自己。";
        }
        return "这一周你经历了起伏，但平静的日子也在慢慢增多。";
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
        java.time.Duration duration = java.time.Duration.between(createdAt, java.time.LocalDateTime.now(java.time.ZoneId.of("Asia/Shanghai")));
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
