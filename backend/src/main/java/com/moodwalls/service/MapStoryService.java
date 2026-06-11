package com.moodwalls.service;

import com.moodwalls.dto.MoodBreakdownItemDto;
import com.moodwalls.dto.ZoneStoryResponseDto;
import com.moodwalls.entity.CampusZone;
import com.moodwalls.exception.BusinessException;
import com.moodwalls.repository.CampusZoneRepository;
import com.moodwalls.repository.PostRepository;
import com.moodwalls.util.MoodHelper;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ThreadLocalRandom;

@Service
public class MapStoryService {

    private static final long STORY_WINDOW_HOURS = 24;

    private static final Map<String, List<String>> ENCOURAGEMENTS = Map.of(
            "anxious", List.of(
                    "期末周会过去的，今晚也值得好好休息。",
                    "紧张的时候，深呼吸三次，你已经很努力了。",
                    "焦虑是身体在提醒你照顾自己，慢慢来。"
            ),
            "calm", List.of(
                    "平静的日子也值得被记住。",
                    "慢下来走一走，校园的风会帮你松一口气。",
                    "安静不是空白，是给自己留出的空间。"
            ),
            "happy", List.of(
                    "把这份开心多留一会儿，它值得被珍藏。",
                    "明亮的心情会像小灯，照亮接下来的一天。",
                    "开心不必很大，小小的好事也很珍贵。"
            ),
            "sad", List.of(
                    "低落的时候，允许自己休息一会儿。",
                    "说出来已经很勇敢，你并不孤单。",
                    "阴天也会过去，温柔正在路上。"
            ),
            "tired", List.of(
                    "累了就歇一歇，身体比成绩更需要你。",
                    "疲惫是信号，不是软弱。",
                    "今晚早点睡，明天会轻一点。"
            ),
            "lonely", List.of(
                    "孤单的时候，心墙上也总有人路过。",
                    "你不需要一个人扛下所有情绪。",
                    "在这里写下心情，就已经在向温暖靠近。"
            ),
            "angry", List.of(
                    "委屈和不爽都值得被看见。",
                    "先照顾好自己，再处理那些让你生气的事。",
                    "把情绪写下来，会比憋在心里轻松一些。"
            ),
            "moved", List.of(
                    "被触动的瞬间，说明你的心依然柔软。",
                    "感动是生活里难得的光，好好收下它。",
                    "愿这份温暖在你心里多停留一会儿。"
            )
    );

    private final CampusZoneRepository campusZoneRepository;
    private final PostRepository postRepository;

    public MapStoryService(CampusZoneRepository campusZoneRepository, PostRepository postRepository) {
        this.campusZoneRepository = campusZoneRepository;
        this.postRepository = postRepository;
    }

    public ZoneStoryResponseDto buildZoneStory(String zoneKey) {
        CampusZone zone = campusZoneRepository.findByZoneKey(zoneKey)
                .filter(z -> z.getStatus() != null && z.getStatus() == 1)
                .orElseThrow(() -> new BusinessException(404, "区域不存在"));

        LocalDateTime since = LocalDateTime.now().minusHours(STORY_WINDOW_HOURS);
        long postCount = postRepository.countByZoneKeySince(zoneKey, since);

        Map<String, Long> moodCounts = new HashMap<>();
        for (Object[] row : postRepository.countMoodByZoneSince(zoneKey, since)) {
            moodCounts.put((String) row[0], (Long) row[1]);
        }

        String dominantMood = MoodHelper.pickDominantMood(moodCounts);
        List<MoodBreakdownItemDto> breakdown = buildBreakdown(moodCounts, postCount);

        ZoneStoryResponseDto dto = new ZoneStoryResponseDto();
        dto.setZoneKey(zone.getZoneKey());
        dto.setTitle(zone.getTitle());
        dto.setSubtitle(zone.getSubtitle());
        dto.setAccent(zone.getAccent() != null ? zone.getAccent() : MoodHelper.colorOf("calm"));
        dto.setPostCount((int) postCount);
        dto.setDominantMood(dominantMood);
        dto.setDominantMoodLabel(dominantMood != null ? MoodHelper.labelOf(dominantMood) : null);
        dto.setMoodBreakdown(breakdown);
        dto.setStory(buildStory(zone.getTitle(), postCount, dominantMood));
        dto.setEncouragement(pickEncouragement(dominantMood, postCount));
        return dto;
    }

    private List<MoodBreakdownItemDto> buildBreakdown(Map<String, Long> moodCounts, long postCount) {
        List<MoodBreakdownItemDto> items = new ArrayList<>();
        if (postCount <= 0) {
            return items;
        }
        moodCounts.entrySet().stream()
                .sorted(Map.Entry.<String, Long>comparingByValue().reversed())
                .forEach(entry -> {
                    MoodBreakdownItemDto item = new MoodBreakdownItemDto();
                    item.setMood(entry.getKey());
                    item.setLabel(MoodHelper.labelOf(entry.getKey()));
                    item.setCount(entry.getValue().intValue());
                    item.setPercent(MoodHelper.percent(entry.getValue(), postCount));
                    items.add(item);
                });
        return items;
    }

    private String buildStory(String title, long postCount, String dominantMood) {
        if (postCount <= 0) {
            return "今天的" + title + "还很安静。如果你正好路过，可以留下第一张心情纸条。";
        }
        if ("anxious".equals(dominantMood)) {
            return "今天的" + title + "有些紧绷，" + postCount + " 位同学在这里留下了心情。焦虑偏多，但也有人正在互相打气。";
        }
        if ("calm".equals(dominantMood)) {
            return "今天的" + title + "比较安静，" + postCount + " 条心情里，平静是主旋律。适合慢下来走一走。";
        }
        if ("happy".equals(dominantMood)) {
            return "今天的" + title + "有不少亮色，" + postCount + " 条心情里开心居多。愿这份轻盈多停留一会儿。";
        }
        if ("sad".equals(dominantMood)) {
            return "今天的" + title + "有人悄悄倾诉低落，" + postCount + " 位同学在这里留下了心情。你并不孤单。";
        }
        if ("tired".equals(dominantMood)) {
            return "今天的" + title + "透着疲惫，" + postCount + " 条心情里不少人正放慢脚步。累了就歇一歇。";
        }
        if ("lonely".equals(dominantMood)) {
            return "今天的" + title + "有些孤单的气息，" + postCount + " 位同学在这里留下了心情。写下来，就已经在向温暖靠近。";
        }
        if ("angry".equals(dominantMood)) {
            return "今天的" + title + "积攒了一些火气，" + postCount + " 条心情里委屈与不满被轻轻放下。说出来会好受些。";
        }
        if ("moved".equals(dominantMood)) {
            return "今天的" + title + "藏着柔软瞬间，" + postCount + " 条心情里感动居多。愿这份触动在你心里多留一会儿。";
        }
        return "今天的" + title + "留下了 " + postCount + " 条心情，校园的角落也在静静倾听。";
    }

    private String pickEncouragement(String dominantMood, long postCount) {
        if (postCount <= 0) {
            return "如果你正好路过，不妨留下第一张心情纸条。";
        }
        String moodKey = dominantMood != null ? dominantMood : "calm";
        List<String> lines = ENCOURAGEMENTS.getOrDefault(moodKey, ENCOURAGEMENTS.get("calm"));
        int index = ThreadLocalRandom.current().nextInt(lines.size());
        return lines.get(index);
    }
}
