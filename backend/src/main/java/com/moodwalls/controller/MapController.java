package com.moodwalls.controller;

import com.moodwalls.dto.ApiResponse;
import com.moodwalls.entity.CampusZone;
import com.moodwalls.entity.Post;
import com.moodwalls.entity.User;
import com.moodwalls.repository.CampusZoneRepository;
import com.moodwalls.repository.PostRepository;
import com.moodwalls.repository.UserRepository;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/map")
public class MapController {

    private final CampusZoneRepository campusZoneRepository;
    private final PostRepository postRepository;
    private final UserRepository userRepository;

    public MapController(CampusZoneRepository campusZoneRepository,
                         PostRepository postRepository,
                         UserRepository userRepository) {
        this.campusZoneRepository = campusZoneRepository;
        this.postRepository = postRepository;
        this.userRepository = userRepository;
    }

    @GetMapping("/zones")
    public ApiResponse<Map<String, Object>> getZones() {
        List<CampusZone> zones = campusZoneRepository.findByStatusOrderBySortOrderAsc(1);
        LocalDateTime since = LocalDateTime.now().minusHours(24);

        List<Object[]> zoneStats = postRepository.countByZoneSince(since);
        Map<String, Long> zonePostCounts = new LinkedHashMap<>();
        for (Object[] row : zoneStats) {
            zonePostCounts.put((String) row[0], (Long) row[1]);
        }

        List<Object[]> zoneMoodStats = postRepository.countByZoneAndMoodSince(since);
        Map<String, String> zoneDominantMoods = new LinkedHashMap<>();
        Map<String, Long> zoneMaxCounts = new LinkedHashMap<>();
        for (Object[] row : zoneMoodStats) {
            String zoneKey = (String) row[0];
            String mood = (String) row[1];
            long count = (Long) row[2];
            if (count > zoneMaxCounts.getOrDefault(zoneKey, 0L)) {
                zoneMaxCounts.put(zoneKey, count);
                zoneDominantMoods.put(zoneKey, mood);
            }
        }

        List<Map<String, Object>> zoneList = new ArrayList<>();
        for (CampusZone zone : zones) {
            Map<String, Object> zoneData = new LinkedHashMap<>();
            zoneData.put("key", zone.getZoneKey());
            zoneData.put("title", zone.getTitle());
            zoneData.put("subtitle", zone.getSubtitle());
            zoneData.put("summary", zone.getDescription());
            zoneData.put("accent", zone.getAccent());
            zoneData.put("postCount", zonePostCounts.getOrDefault(zone.getZoneKey(), 0L));
            zoneData.put("dominantMood", zoneDominantMoods.getOrDefault(zone.getZoneKey(), null));
            zoneList.add(zoneData);
        }

        String summary = buildClimateSummary(zoneList);
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("summary", summary);
        result.put("zones", zoneList);

        return ApiResponse.ok(result);
    }

    @GetMapping("/zones/{key}/posts")
    public ApiResponse<Map<String, Object>> getZonePosts(
            @PathVariable String key,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int size) {

        List<Post> posts = postRepository.findActiveByZoneKey(key);
        int total = posts.size();
        int fromIndex = (page - 1) * size;
        int toIndex = Math.min(fromIndex + size, total);
        List<Post> pagePosts = fromIndex < total ? posts.subList(fromIndex, toIndex) : List.of();

        List<Long> userIds = pagePosts.stream().map(Post::getUserId).distinct().collect(Collectors.toList());
        Map<Long, String> userNicknames = new LinkedHashMap<>();
        if (!userIds.isEmpty()) {
            List<User> users = userRepository.findAllById(userIds);
            for (User u : users) {
                userNicknames.put(u.getId(), u.getNickname());
            }
        }

        List<Map<String, Object>> list = pagePosts.stream().map(p -> {
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("id", p.getId());
            item.put("mood", p.getMood());
            item.put("content", p.getContent());
            item.put("location", p.getLocation());
            item.put("nickname", userNicknames.getOrDefault(p.getUserId(), "匿名"));
            item.put("likeCount", p.getLikeCount());
            item.put("createdAt", p.getCreatedAt() != null ? p.getCreatedAt().toString() : null);
            return item;
        }).collect(Collectors.toList());

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("list", list);
        result.put("total", total);
        result.put("page", page);
        result.put("size", size);
        result.put("hasMore", toIndex < total);

        return ApiResponse.ok(result);
    }

    private String buildClimateSummary(List<Map<String, Object>> zones) {
        if (zones.isEmpty()) {
            return "今天校园里还没有人留下心情。";
        }
        long totalPosts = 0;
        for (Map<String, Object> zone : zones) {
            totalPosts += (Long) zone.getOrDefault("postCount", 0L);
        }
        if (totalPosts == 0) {
            return "暂时还没有新心情。去贴一张纸条，成为今天的第一缕情绪吧。";
        }

        StringBuilder sb = new StringBuilder();
        for (Map<String, Object> zone : zones) {
            String title = (String) zone.get("title");
            long count = (Long) zone.getOrDefault("postCount", 0L);
            String mood = (String) zone.getOrDefault("dominantMood", null);
            if (count > 0 && mood != null) {
                sb.append(title).append("附近偏向").append(moodLabel(mood)).append("，");
            } else if (count > 0) {
                sb.append(title).append("附近有").append(count).append("条心情，");
            }
        }
        String s = sb.toString();
        if (!s.isEmpty() && s.endsWith("，")) {
            s = s.substring(0, s.length() - 1) + "。";
        }
        if (s.isEmpty()) {
            s = "校园各处都很安静，今天适合慢下来。";
        }
        return s;
    }

    private String moodLabel(String mood) {
        return switch (mood) {
            case "happy" -> "开心";
            case "calm" -> "平静";
            case "moved" -> "感动";
            case "tired" -> "疲惫";
            case "anxious" -> "焦虑";
            case "sad" -> "低落";
            case "angry" -> "生气";
            case "lonely" -> "孤单";
            default -> mood;
        };
    }
}
