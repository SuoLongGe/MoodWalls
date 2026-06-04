package com.moodwalls.service;

import com.moodwalls.dto.CreatePostDto;
import com.moodwalls.dto.LikeResponseDto;
import com.moodwalls.dto.PostListResponseDto;
import com.moodwalls.dto.PostSummaryDto;
import com.moodwalls.dto.PublishPostResponseDto;
import com.moodwalls.dto.TodayStatsDto;
import com.moodwalls.entity.Post;
import com.moodwalls.entity.PostLike;
import com.moodwalls.entity.User;
import com.moodwalls.exception.BusinessException;
import com.moodwalls.repository.PostLikeRepository;
import com.moodwalls.repository.PostRepository;
import com.moodwalls.repository.UserRepository;
import com.moodwalls.util.MoodHelper;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.stream.Collectors;

@Service
public class PostService {

    private static final DateTimeFormatter ISO_FORMATTER = DateTimeFormatter.ISO_LOCAL_DATE_TIME;

    private final PostRepository postRepository;
    private final PostLikeRepository postLikeRepository;
    private final UserRepository userRepository;
    private final AiService aiService;

    public PostService(PostRepository postRepository, PostLikeRepository postLikeRepository,
                       UserRepository userRepository, AiService aiService) {
        this.postRepository = postRepository;
        this.postLikeRepository = postLikeRepository;
        this.userRepository = userRepository;
        this.aiService = aiService;
    }

    public PostListResponseDto getPostList(int page, int size, String mood, Long currentUserId) {
        size = Math.min(size, 50);
        page = Math.max(page, 1);
        PageRequest pageRequest = PageRequest.of(page - 1, size);

        Page<Post> postPage;
        if (mood == null || mood.equals("all") || mood.isEmpty()) {
            postPage = postRepository.findByStatusOrderByCreatedAtDesc(1, pageRequest);
        } else {
            postPage = postRepository.findByStatusAndMoodOrderByCreatedAtDesc(1, mood, pageRequest);
        }

        List<Post> posts = postPage.getContent();
        List<PostSummaryDto> summaries = toSummaries(posts, currentUserId);

        PostListResponseDto response = new PostListResponseDto();
        response.setList(summaries);
        response.setTotal(postPage.getTotalElements());
        response.setPage(page);
        response.setSize(size);
        response.setHasMore(postPage.hasNext());
        return response;
    }

    public PostSummaryDto getPostDetail(Long postId, Long currentUserId) {
        Post post = postRepository.findById(postId)
                .filter(p -> p.getStatus() == 1)
                .orElseThrow(() -> new BusinessException(404, "帖子不存在"));
        return toSummary(post, currentUserId);
    }

    @Transactional
    public LikeResponseDto likePost(Long postId, Long userId) {
        Post post = postRepository.findById(postId)
                .filter(p -> p.getStatus() == 1)
                .orElseThrow(() -> new BusinessException(404, "帖子不存在"));

        Optional<PostLike> existing = postLikeRepository.findByUserIdAndPostId(userId, postId);
        if (existing.isPresent()) {
            postLikeRepository.delete(existing.get());
            post.setLikeCount(Math.max(0, post.getLikeCount() - 1));
            postRepository.save(post);
            return new LikeResponseDto(post.getLikeCount(), false);
        } else {
            PostLike like = new PostLike();
            like.setUserId(userId);
            like.setPostId(postId);
            postLikeRepository.save(like);
            post.setLikeCount(post.getLikeCount() + 1);
            postRepository.save(post);
            return new LikeResponseDto(post.getLikeCount(), true);
        }
    }

    @Transactional
    public PublishPostResponseDto createPostWithAi(CreatePostDto dto, Long userId) {
        if (dto.getMood() == null || dto.getMood().isBlank()) {
            throw new BusinessException(400, "请选择当前心情");
        }
        if (dto.getText() == null || dto.getText().isBlank()) {
            throw new BusinessException(400, "内容不能为空");
        }
        int len = dto.getText().trim().length();
        if (len < 10) {
            throw new BusinessException(400, "内容至少需要 10 个字");
        }
        if (len > 500) {
            throw new BusinessException(400, "内容不能超过 500 字");
        }

        Post post = new Post();
        post.setUserId(userId);
        post.setMood(dto.getMood());
        post.setContent(dto.getText().trim());
        post.setLocation(dto.getLocation() != null ? dto.getLocation() : "");
        if (dto.getZoneKey() != null && !dto.getZoneKey().isBlank()) {
            post.setZoneKey(dto.getZoneKey());
        } else {
            post.setZoneKey(mapLocationToZoneKey(dto.getLocation()));
        }
        post.setLikeCount(0);
        post.setStatus(1);

        Post saved = postRepository.save(post);

        var ai = aiService.generateOnPublish(saved, userId);
        saved.setAiResponse(ai.responseText());
        postRepository.save(saved);

        PostSummaryDto summary = toSummary(saved, userId);

        PublishPostResponseDto response = new PublishPostResponseDto();
        response.setPost(summary);
        response.setAiResponse(ai.responseText());
        return response;
    }

    public PostSummaryDto createPost(CreatePostDto dto, Long userId) {
        return createPostWithAi(dto, userId).getPost();
    }

    @Transactional
    public void deletePost(Long postId, Long userId) {
        Post post = postRepository.findById(postId)
                .filter(p -> p.getStatus() == 1)
                .orElseThrow(() -> new BusinessException(404, "帖子不存在"));
        if (!post.getUserId().equals(userId)) {
            throw new BusinessException(403, "无权删除他人的帖子");
        }
        post.setStatus(0);
        postRepository.save(post);
    }

    private String mapLocationToZoneKey(String location) {
        if (location == null || location.isBlank()) {
            return null;
        }
        return switch (location) {
            case "主图书馆三楼", "理科科研楼 B 座" -> "library";
            case "未名湖畔咖啡角" -> "lake";
            case "第二食堂", "五号宿舍楼" -> "living";
            default -> {
                List<Object[]> mappings = postRepository.findLocationToZoneMappings(location);
                if (!mappings.isEmpty()) {
                    yield (String) mappings.get(0)[0];
                }
                yield null;
            }
        };
    }

    public TodayStatsDto getTodayStats() {
        LocalDateTime startOfDay = LocalDateTime.of(LocalDate.now(ZoneId.of("Asia/Shanghai")), LocalTime.MIN);

        List<Object[]> moodCounts = postRepository.countByMoodSince(startOfDay);
        long total = postRepository.countActiveSince(startOfDay);

        long anxious = 0, calm = 0, happy = 0;
        for (Object[] row : moodCounts) {
            String m = (String) row[0];
            long cnt = ((Number) row[1]).longValue();
            if (MoodHelper.isAnxiousGroup(m)) anxious += cnt;
            else if (MoodHelper.isCalmGroup(m)) calm += cnt;
            else if (MoodHelper.isHappyGroup(m)) happy += cnt;
        }

        TodayStatsDto dto = new TodayStatsDto();
        dto.setAnxiousPercent(MoodHelper.percent(anxious, total));
        dto.setCalmPercent(MoodHelper.percent(calm, total));
        dto.setHappyPercent(MoodHelper.percent(happy, total));
        dto.setTotalPosts(total);
        return dto;
    }

    private List<PostSummaryDto> toSummaries(List<Post> posts, Long currentUserId) {
        if (posts.isEmpty()) return List.of();

        List<Long> postIds = posts.stream().map(Post::getId).collect(Collectors.toList());
        final Set<Long> likedIds;
        if (currentUserId != null) {
            List<PostLike> likes = postLikeRepository.findByUserIdAndPostIdIn(currentUserId, postIds);
            likedIds = likes.stream().map(PostLike::getPostId).collect(Collectors.toSet());
        } else {
            likedIds = Set.of();
        }

        Map<Long, User> userMap = posts.stream()
                .map(Post::getUserId)
                .distinct()
                .collect(Collectors.toMap(id -> id, id ->
                        userRepository.findById(id).orElse(null)));

        return posts.stream()
                .map(p -> toSummary(p, likedIds, userMap))
                .collect(Collectors.toList());
    }

    private PostSummaryDto toSummary(Post post, Long currentUserId) {
        final Set<Long> likedIds;
        if (currentUserId != null) {
            likedIds = postLikeRepository.existsByUserIdAndPostId(currentUserId, post.getId())
                    ? Set.of(post.getId())
                    : Set.of();
        } else {
            likedIds = Set.of();
        }
        User user = userRepository.findById(post.getUserId()).orElse(null);
        Map<Long, User> userMap = user == null ? Map.of() : Map.of(post.getUserId(), user);
        return toSummary(post, likedIds, userMap);
    }

    private PostSummaryDto toSummary(Post post, Set<Long> likedIds, Map<Long, User> userMap) {
        PostSummaryDto dto = new PostSummaryDto();
        dto.setId(post.getId());
        dto.setUserId(post.getUserId());
        dto.setMood(post.getMood());
        dto.setMoodLabel(MoodHelper.labelOf(post.getMood()));
        dto.setText(post.getContent());
        dto.setLocation(post.getLocation());
        dto.setZoneKey(post.getZoneKey());
        dto.setLikes(post.getLikeCount());
        dto.setColor(MoodHelper.colorOf(post.getMood()));
        dto.setLiked(likedIds.contains(post.getId()));
        dto.setCreatedAt(post.getCreatedAt().format(ISO_FORMATTER));
        dto.setTimeText(MoodHelper.formatTimeText(post.getCreatedAt()));

        User user = userMap.get(post.getUserId());
        dto.setNickname(user != null ? user.getNickname() : "匿名用户");

        return dto;
    }
}
