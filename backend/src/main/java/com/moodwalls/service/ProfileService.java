package com.moodwalls.service;

import com.moodwalls.dto.CalendarDayDto;
import com.moodwalls.dto.CalendarResponseDto;
import com.moodwalls.dto.PostListResponseDto;
import com.moodwalls.dto.PostSummaryDto;
import com.moodwalls.dto.ProfileOverviewDto;
import com.moodwalls.dto.WeekStatsDto;
import com.moodwalls.entity.Post;
import com.moodwalls.entity.User;
import com.moodwalls.entity.UserDailyMood;
import com.moodwalls.exception.BusinessException;
import com.moodwalls.repository.PostRepository;
import com.moodwalls.repository.UserDailyMoodRepository;
import com.moodwalls.repository.UserRepository;
import com.moodwalls.util.MoodHelper;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.YearMonth;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeSet;
import java.util.stream.Collectors;

@Service
public class ProfileService {

    private static final int STATUS_ACTIVE = 1;

    private final UserRepository userRepository;
    private final PostRepository postRepository;
    private final UserDailyMoodRepository userDailyMoodRepository;

    public ProfileService(
            UserRepository userRepository,
            PostRepository postRepository,
            UserDailyMoodRepository userDailyMoodRepository) {
        this.userRepository = userRepository;
        this.postRepository = postRepository;
        this.userDailyMoodRepository = userDailyMoodRepository;
    }

    public ProfileOverviewDto getOverview(Long userId) {
        User user = requireUser(userId);
        long postCount = postRepository.countByUserIdAndStatus(userId, STATUS_ACTIVE);
        long totalLikes = postRepository.sumLikeCountByUserId(userId);
        int streakDays = calculateStreakDays(userId);
        WeekStatsDto weekStats = buildWeekStats(userId);
        String moodClimate = MoodHelper.buildClimate(
                weekStats.getCalmPercent(),
                weekStats.getAnxiousPercent(),
                weekStats.getHappyPercent()
        );

        ProfileOverviewDto dto = new ProfileOverviewDto();
        dto.setId(user.getId());
        dto.setNickname(user.getNickname());
        dto.setPhone(MoodHelper.maskPhone(user.getPhone()));
        dto.setAvatarKey(user.getAvatarKey() != null ? user.getAvatarKey() : "avatar_01");
        dto.setPostCount(postCount);
        dto.setTotalLikes(totalLikes);
        dto.setStreakDays(streakDays);
        dto.setMoodClimate(moodClimate);
        dto.setWeekStats(weekStats);
        return dto;
    }

    public CalendarResponseDto getCalendar(Long userId, String monthParam) {
        YearMonth yearMonth = parseMonth(monthParam);
        LocalDate start = yearMonth.atDay(1);
        LocalDate end = yearMonth.atEndOfMonth();

        List<UserDailyMood> stored = userDailyMoodRepository.findByUserIdAndStatDateBetweenOrderByStatDateAsc(
                userId, start, end);

        List<CalendarDayDto> days;
        if (!stored.isEmpty()) {
            days = stored.stream()
                    .map(row -> new CalendarDayDto(
                            row.getStatDate().toString(),
                            row.getDominantMood(),
                            MoodHelper.colorOf(row.getDominantMood()),
                            row.getPostCount()))
                    .collect(Collectors.toList());
        } else {
            days = buildCalendarFromPosts(userId, start, end);
        }

        CalendarResponseDto response = new CalendarResponseDto();
        response.setMonth(yearMonth.toString());
        response.setDays(days);
        return response;
    }

    public PostListResponseDto getMyPosts(Long userId, int page, int size) {
        User user = requireUser(userId);
        int safePage = Math.max(page, 1);
        int safeSize = Math.min(Math.max(size, 1), 50);
        Page<Post> result = postRepository.findByUserIdAndStatusOrderByCreatedAtDesc(
                userId,
                STATUS_ACTIVE,
                PageRequest.of(safePage - 1, safeSize)
        );

        List<PostSummaryDto> list = result.getContent().stream()
                .map(post -> toPostSummary(post, user.getNickname()))
                .collect(Collectors.toList());

        PostListResponseDto response = new PostListResponseDto();
        response.setList(list);
        response.setTotal(result.getTotalElements());
        response.setPage(safePage);
        response.setSize(safeSize);
        response.setHasMore(result.hasNext());
        return response;
    }

    private User requireUser(Long userId) {
        return userRepository.findById(userId)
                .orElseThrow(() -> new BusinessException(404, "用户不存在"));
    }

    private YearMonth parseMonth(String monthParam) {
        if (monthParam == null || monthParam.isBlank()) {
            return YearMonth.now();
        }
        try {
            return YearMonth.parse(monthParam.trim());
        } catch (DateTimeParseException ex) {
            throw new BusinessException(400, "month 格式应为 yyyy-MM");
        }
    }

    private WeekStatsDto buildWeekStats(Long userId) {
        LocalDateTime weekStart = LocalDate.now().minusDays(6).atStartOfDay();
        LocalDateTime weekEnd = LocalDate.now().plusDays(1).atStartOfDay();
        List<Post> weekPosts = postRepository.findByUserIdAndStatusAndCreatedAtBetweenOrderByCreatedAtAsc(
                userId, STATUS_ACTIVE, weekStart, weekEnd);

        long calm = 0;
        long anxious = 0;
        long happy = 0;
        for (Post post : weekPosts) {
            if (MoodHelper.isCalmGroup(post.getMood())) {
                calm++;
            } else if (MoodHelper.isAnxiousGroup(post.getMood())) {
                anxious++;
            } else if (MoodHelper.isHappyGroup(post.getMood())) {
                happy++;
            }
        }
        long total = weekPosts.size();
        return new WeekStatsDto(
                MoodHelper.percent(calm, total),
                MoodHelper.percent(anxious, total),
                MoodHelper.percent(happy, total)
        );
    }

    private int calculateStreakDays(Long userId) {
        List<Post> posts = postRepository.findByUserIdAndStatusOrderByCreatedAtDesc(
                userId, STATUS_ACTIVE, PageRequest.of(0, 500)).getContent();
        if (posts.isEmpty()) {
            return 0;
        }

        Set<LocalDate> activeDates = new TreeSet<>(Comparator.reverseOrder());
        for (Post post : posts) {
            activeDates.add(post.getCreatedAt().toLocalDate());
        }

        LocalDate cursor = LocalDate.now();
        if (!activeDates.contains(cursor) && !activeDates.contains(cursor.minusDays(1))) {
            return 0;
        }
        if (!activeDates.contains(cursor)) {
            cursor = cursor.minusDays(1);
        }

        int streak = 0;
        while (activeDates.contains(cursor)) {
            streak++;
            cursor = cursor.minusDays(1);
        }
        return streak;
    }

    private List<CalendarDayDto> buildCalendarFromPosts(Long userId, LocalDate start, LocalDate end) {
        LocalDateTime rangeStart = start.atStartOfDay();
        LocalDateTime rangeEnd = end.plusDays(1).atStartOfDay();
        List<Post> posts = postRepository.findByUserIdAndStatusAndCreatedAtBetweenOrderByCreatedAtAsc(
                userId, STATUS_ACTIVE, rangeStart, rangeEnd);

        Map<LocalDate, List<Post>> byDate = new HashMap<>();
        for (Post post : posts) {
            LocalDate day = post.getCreatedAt().toLocalDate();
            byDate.computeIfAbsent(day, ignored -> new ArrayList<>()).add(post);
        }

        List<CalendarDayDto> days = new ArrayList<>();
        for (Map.Entry<LocalDate, List<Post>> entry : byDate.entrySet()) {
            Map<String, Long> moodCounts = entry.getValue().stream()
                    .collect(Collectors.groupingBy(Post::getMood, Collectors.counting()));
            String dominant = MoodHelper.dominantMoodFromCounts(moodCounts);
            days.add(new CalendarDayDto(
                    entry.getKey().toString(),
                    dominant,
                    MoodHelper.colorOf(dominant),
                    entry.getValue().size()
            ));
        }
        days.sort(Comparator.comparing(CalendarDayDto::getDate));
        return days;
    }

    private PostSummaryDto toPostSummary(Post post, String nickname) {
        PostSummaryDto dto = new PostSummaryDto();
        dto.setId(post.getId());
        dto.setUserId(post.getUserId());
        dto.setNickname(nickname);
        dto.setMood(post.getMood());
        dto.setMoodLabel(MoodHelper.labelOf(post.getMood()));
        dto.setText(post.getContent());
        dto.setLocation(post.getLocation());
        dto.setZoneKey(post.getZoneKey());
        dto.setLikes(post.getLikeCount() != null ? post.getLikeCount() : 0);
        dto.setLiked(false);
        dto.setColor(MoodHelper.colorOf(post.getMood()));
        dto.setCreatedAt(post.getCreatedAt().toString());
        dto.setTimeText(MoodHelper.formatTimeText(post.getCreatedAt()));
        return dto;
    }
}
