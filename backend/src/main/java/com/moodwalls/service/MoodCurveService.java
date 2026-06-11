package com.moodwalls.service;

import com.moodwalls.dto.MoodCurvePointDto;
import com.moodwalls.dto.MoodCurveResponseDto;
import com.moodwalls.repository.PostRepository;
import com.moodwalls.util.MoodHelper;
import org.springframework.stereotype.Service;

import java.sql.Date;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class MoodCurveService {

    private static final ZoneId ZONE_SHANGHAI = ZoneId.of("Asia/Shanghai");
    private static final DateTimeFormatter DATE_FMT = DateTimeFormatter.ISO_LOCAL_DATE;

    private final PostRepository postRepository;

    public MoodCurveService(PostRepository postRepository) {
        this.postRepository = postRepository;
    }

    public MoodCurveResponseDto buildCurve(Long userId, int days) {
        int safeDays = Math.min(Math.max(days, 1), 30);
        LocalDate today = LocalDate.now(ZONE_SHANGHAI);
        LocalDate startDate = today.minusDays(safeDays - 1L);
        java.time.LocalDateTime since = startDate.atStartOfDay();

        Map<LocalDate, Map<String, Long>> dailyMoodCounts = new HashMap<>();
        for (Object[] row : postRepository.countUserMoodByDateSince(userId, since)) {
            LocalDate date;
            Object dateObj = row[0];
            if (dateObj instanceof Date sqlDate) {
                date = sqlDate.toLocalDate();
            } else if (dateObj instanceof LocalDate localDate) {
                date = localDate;
            } else {
                date = LocalDate.parse(dateObj.toString());
            }
            String mood = (String) row[1];
            long count = row[2] instanceof Number number ? number.longValue() : Long.parseLong(row[2].toString());
            dailyMoodCounts.computeIfAbsent(date, ignored -> new HashMap<>())
                    .merge(mood, count, Long::sum);
        }

        List<MoodCurvePointDto> points = new ArrayList<>();
        for (int i = 0; i < safeDays; i++) {
            LocalDate date = startDate.plusDays(i);
            Map<String, Long> moodCounts = dailyMoodCounts.getOrDefault(date, Map.of());
            long dayTotal = moodCounts.values().stream().mapToLong(Long::longValue).sum();
            String dominantMood = dayTotal > 0 ? MoodHelper.pickDominantMood(moodCounts) : null;

            MoodCurvePointDto point = new MoodCurvePointDto();
            point.setDate(date.format(DATE_FMT));
            point.setWeekday(MoodHelper.weekdayLabel(date));
            point.setPostCount((int) dayTotal);
            point.setDominantMood(dominantMood);
            if (dominantMood != null) {
                point.setLabel(MoodHelper.labelOf(dominantMood));
                point.setColor(MoodHelper.colorOf(dominantMood));
            }
            points.add(point);
        }

        MoodCurveResponseDto response = new MoodCurveResponseDto();
        response.setDays(safeDays);
        response.setPoints(points);
        response.setSummary(MoodHelper.buildCurveSummary(points));
        return response;
    }
}
