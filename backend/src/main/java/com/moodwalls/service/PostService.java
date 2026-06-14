package com.moodwalls.service;

import com.moodwalls.dto.CreatePostDto;
import com.moodwalls.dto.LikeResponseDto;
import com.moodwalls.dto.PostListResponseDto;
import com.moodwalls.dto.PostSummaryDto;
import com.moodwalls.dto.ReactionResponseDto;
import com.moodwalls.dto.PublishPostResponseDto;
import com.moodwalls.dto.MoodStatItemDto;
import com.moodwalls.dto.MoodStatsDto;
import com.moodwalls.dto.TodayStatsDto;
import com.moodwalls.dto.UpdateVisibilityDto;
import com.moodwalls.entity.Post;
import com.moodwalls.entity.PostLike;
import com.moodwalls.entity.User;
import com.moodwalls.exception.BusinessException;
import com.moodwalls.repository.PostCommentRepository;
import com.moodwalls.repository.PostLikeRepository;
import com.moodwalls.repository.PostRepository;
import com.moodwalls.repository.UserRepository;
import com.moodwalls.util.MoodHelper;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.ZoneId;
import java.time.temporal.TemporalAdjusters;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
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
    private final PostCommentRepository commentRepository;
    private final UserRepository userRepository;
    private final NotificationService notificationService;
    private final AiService aiService;
    private final ReactionService reactionService;
    private final CloudGiftService cloudGiftService;
    private final PostImageStorageService postImageStorageService;

    public PostService(PostRepository postRepository, PostLikeRepository postLikeRepository,
                       PostCommentRepository commentRepository,
                       UserRepository userRepository, NotificationService notificationService,
                       AiService aiService, ReactionService reactionService,
                       CloudGiftService cloudGiftService,
                       PostImageStorageService postImageStorageService) {
        this.postRepository = postRepository;
        this.postLikeRepository = postLikeRepository;
        this.commentRepository = commentRepository;
        this.userRepository = userRepository;
        this.notificationService = notificationService;
        this.aiService = aiService;
        this.reactionService = reactionService;
        this.cloudGiftService = cloudGiftService;
        this.postImageStorageService = postImageStorageService;
    }

    public PostListResponseDto getPostList(int page, int size, String mood, Long currentUserId) {
        size = Math.min(size, 50);
        page = Math.max(page, 1);
        PageRequest pageRequest = PageRequest.of(page - 1, size);

        Page<Post> postPage;
        if (mood == null || mood.equals("all") || mood.isEmpty()) {
            postPage = postRepository.findPublicFeed(pageRequest);
        } else {
            postPage = postRepository.findPublicFeedByMood(mood, pageRequest);
        }

        List<Post> posts = postPage.getContent();
        List<PostSummaryDto> summaries = toSummaries(posts, currentUserId);
        enrichReactionFields(summaries, currentUserId);
        enrichCloudCounts(summaries);

        PostListResponseDto response = new PostListResponseDto();
        response.setList(summaries);
        response.setTotal(postPage.getTotalElements());
        response.setPage(page);
        response.setSize(size);
        response.setHasMore(postPage.hasNext());
        return response;
    }

    public PostListResponseDto searchPosts(String keyword, int page, int size, String mood, String period,
                                           Long currentUserId) {
        String trimmed = keyword == null ? "" : keyword.trim();
        if (trimmed.isEmpty()) {
            throw new BusinessException(400, "请输入搜索关键词");
        }
        if (trimmed.length() > 32) {
            throw new BusinessException(400, "关键词不能超过 32 字");
        }

        size = Math.min(Math.max(size, 1), 50);
        page = Math.max(page, 1);
        PageRequest pageRequest = PageRequest.of(page - 1, size);

        String moodFilter = mood == null || mood.isBlank() ? "all" : mood.trim();
        LocalDateTime since = resolveSearchPeriodStart(period);

        Page<Post> postPage = postRepository.searchPublicPosts(trimmed, moodFilter, since, pageRequest);
        List<PostSummaryDto> summaries = toSummaries(postPage.getContent(), currentUserId);
        enrichReactionFields(summaries, currentUserId);
        enrichCloudCounts(summaries);

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
        if (isPrivate(post) && (currentUserId == null || !currentUserId.equals(post.getUserId()))) {
            throw new BusinessException(403, "该帖子仅作者可见");
        }
        PostSummaryDto summary = toSummary(post, currentUserId);
        enrichReactionFields(List.of(summary), currentUserId);
        summary.setCloudCount(cloudGiftService.countForPost(post.getId()));
        if (currentUserId != null && currentUserId.equals(post.getUserId())) {
            long whisperCount = commentRepository.countByPostIdAndStatusAndCommentTypeAndParentIdIsNull(
                    post.getId(), 1, "whisper");
            summary.setWhisperCount((int) whisperCount);
        }
        return summary;
    }

    private boolean isPrivate(Post post) {
        Integer visibility = post.getVisibility();
        return visibility != null && visibility == 2;
    }

    private String visibilityLabel(Post post) {
        return isPrivate(post) ? "private" : "public";
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
            notificationService.notifyPostLiked(post, userId);
            return new LikeResponseDto(post.getLikeCount(), true);
        }
    }

    @Transactional
    public PublishPostResponseDto createPostWithAi(CreatePostDto dto, Long userId) {
        return createPostWithAi(dto, userId, null);
    }

    @Transactional
    public PublishPostResponseDto createPostWithAi(CreatePostDto dto, Long userId, MultipartFile image) {
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
        if (image != null && !image.isEmpty()) {
            post.setImageUrl(postImageStorageService.savePostImage(image));
        } else if (dto.getImageBase64() != null && !dto.getImageBase64().isBlank()) {
            post.setImageUrl(postImageStorageService.saveBase64Image(dto.getImageBase64()));
        }
        post.setLikeCount(0);
        post.setCommentCount(0);
        post.setVisibility(1);
        post.setStatus(1);

        Post saved = postRepository.save(post);

        var ai = aiService.generateOnPublish(saved, userId);
        saved.setAiResponse(ai.responseText());
        postRepository.save(saved);

        PostSummaryDto summary = toSummary(saved, userId);

        PublishPostResponseDto response = new PublishPostResponseDto();
        response.setPost(summary);
        response.setAiResponse(ai.responseText());
        response.setRiskLevel(ai.riskLevel());
        response.setComfortNote(aiService.getComfortNote(ai.riskLevel()));
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

    @Transactional
    public PostSummaryDto updateVisibility(Long postId, Long userId, UpdateVisibilityDto dto) {
        if (dto == null || dto.getVisibility() == null || dto.getVisibility().isBlank()) {
            throw new BusinessException(400, "请指定可见性");
        }
        Post post = postRepository.findById(postId)
                .filter(p -> p.getStatus() == 1)
                .orElseThrow(() -> new BusinessException(404, "帖子不存在"));
        if (!post.getUserId().equals(userId)) {
            throw new BusinessException(403, "无权修改他人的帖子");
        }

        String visibility = dto.getVisibility().trim().toLowerCase();
        if ("private".equals(visibility)) {
            post.setVisibility(2);
        } else if ("public".equals(visibility)) {
            post.setVisibility(1);
        } else {
            throw new BusinessException(400, "可见性仅支持 public 或 private");
        }
        postRepository.save(post);
        return toSummary(post, userId);
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

    public TodayStatsDto getTodayStats(Long userId) {
        MoodStatsDto stats = getMoodStatsForUser("today", userId);
        long anxious = 0;
        long calm = 0;
        long happy = 0;
        for (MoodStatItemDto item : stats.getItems()) {
            if (MoodHelper.isAnxiousGroup(item.getMood())) {
                anxious += item.getCount();
            } else if (MoodHelper.isCalmGroup(item.getMood())) {
                calm += item.getCount();
            } else if (MoodHelper.isHappyGroup(item.getMood())) {
                happy += item.getCount();
            }
        }
        long total = stats.getTotalPosts();
        TodayStatsDto dto = new TodayStatsDto();
        dto.setAnxiousPercent(MoodHelper.percent(anxious, total));
        dto.setCalmPercent(MoodHelper.percent(calm, total));
        dto.setHappyPercent(MoodHelper.percent(happy, total));
        dto.setTotalPosts(total);
        return dto;
    }

    public MoodStatsDto getMoodStats(String periodParam) {
        return getMoodStatsForUser(periodParam, null);
    }

    public MoodStatsDto getMoodStatsForUser(String periodParam, Long userId) {
        String period = normalizeStatsPeriod(periodParam);
        LocalDateTime since = resolveStatsPeriodStart(period);
        final boolean filterUser = userId != null;
        List<Object[]> moodCounts = filterUser
                ? postRepository.countByMoodForUserSince(userId, since)
                : postRepository.countByMoodSince(since);
        long total = filterUser
                ? postRepository.countActiveByUserSince(userId, since)
                : postRepository.countActiveSince(since);

        List<MoodStatItemDto> items = new ArrayList<>();
        for (Object[] row : moodCounts) {
            String mood = (String) row[0];
            long count = ((Number) row[1]).longValue();
            if (count <= 0 || mood == null || mood.isBlank()) {
                continue;
            }
            items.add(new MoodStatItemDto(
                    mood,
                    MoodHelper.labelOf(mood),
                    MoodHelper.colorOf(mood),
                    MoodHelper.percent(count, total),
                    count
            ));
        }
        items.sort((a, b) -> Long.compare(b.getCount(), a.getCount()));

        MoodStatsDto dto = new MoodStatsDto();
        dto.setPeriod(period);
        dto.setTotalPosts(total);
        dto.setItems(items);
        return dto;
    }

    private String normalizeStatsPeriod(String periodParam) {
        if (periodParam == null) {
            return "today";
        }
        String period = periodParam.trim().toLowerCase();
        if ("today".equals(period) || "week".equals(period) || "month".equals(period)) {
            return period;
        }
        return "today";
    }

    private LocalDateTime resolveStatsPeriodStart(String period) {
        ZoneId zone = ZoneId.of("Asia/Shanghai");
        LocalDate today = LocalDate.now(zone);
        return switch (period) {
            case "week" -> today.with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY)).atStartOfDay();
            case "month" -> today.withDayOfMonth(1).atStartOfDay();
            default -> LocalDateTime.of(today, LocalTime.MIN);
        };
    }

    private LocalDateTime resolveSearchPeriodStart(String periodParam) {
        if (periodParam == null || periodParam.isBlank() || "all".equalsIgnoreCase(periodParam.trim())) {
            return LocalDateTime.of(2000, 1, 1, 0, 0);
        }
        return resolveStatsPeriodStart(normalizeStatsPeriod(periodParam));
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
                .map(p -> toSummary(p, likedIds, userMap, currentUserId))
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
        return toSummary(post, likedIds, userMap, currentUserId);
    }

    private PostSummaryDto toSummary(Post post, Set<Long> likedIds, Map<Long, User> userMap, Long currentUserId) {
        PostSummaryDto dto = new PostSummaryDto();
        dto.setId(post.getId());
        dto.setUserId(post.getUserId());
        dto.setMood(post.getMood());
        dto.setMoodLabel(MoodHelper.labelOf(post.getMood()));
        dto.setText(post.getContent());
        // 返回相对路径，由客户端按 ApiConfig 中的服务器地址拼接完整 URL
        dto.setImageUrl(post.getImageUrl());
        dto.setLocation(post.getLocation());
        dto.setZoneKey(post.getZoneKey());
        dto.setLikes(post.getLikeCount());
        dto.setColor(MoodHelper.colorOf(post.getMood()));
        dto.setLiked(likedIds.contains(post.getId()));
        dto.setCreatedAt(post.getCreatedAt().format(ISO_FORMATTER));
        dto.setTimeText(MoodHelper.formatTimeText(post.getCreatedAt()));

        User user = userMap.get(post.getUserId());
        dto.setNickname(user != null ? user.getNickname() : "匿名用户");
        dto.setAvatarKey(user != null && user.getAvatarKey() != null ? user.getAvatarKey() : "avatar_01");
        dto.setAvatarUrl(user != null ? user.getAvatarUrl() : null);
        boolean mine = currentUserId != null && currentUserId.equals(post.getUserId());
        dto.setMine(mine);
        dto.setCommentCount(post.getCommentCount() != null ? post.getCommentCount() : 0);
        dto.setVisibility(visibilityLabel(post));
        dto.setCanDelete(mine);

        return dto;
    }

    private void enrichReactionFields(List<PostSummaryDto> summaries, Long currentUserId) {
        if (summaries == null || summaries.isEmpty()) {
            return;
        }
        List<Long> postIds = summaries.stream().map(PostSummaryDto::getId).collect(Collectors.toList());
        Map<Long, ReactionResponseDto> reactionMap = reactionService.buildResponsesForPosts(postIds, currentUserId);
        for (PostSummaryDto summary : summaries) {
            ReactionResponseDto reaction = reactionMap.get(summary.getId());
            if (reaction == null) {
                continue;
            }
            summary.setTotalReactions(reaction.getTotalReactions());
            summary.setMyReaction(reaction.getMyReaction());
            summary.setTopReactions(reaction.getTopReactions());
            summary.setReactionStats(reaction.getReactionStats());
        }
    }

    private void enrichCloudCounts(List<PostSummaryDto> summaries) {
        if (summaries == null || summaries.isEmpty()) {
            return;
        }
        List<Long> postIds = summaries.stream().map(PostSummaryDto::getId).collect(Collectors.toList());
        Map<Long, Integer> cloudMap = cloudGiftService.countByPostIds(postIds);
        for (PostSummaryDto summary : summaries) {
            summary.setCloudCount(cloudMap.getOrDefault(summary.getId(), 0));
        }
    }
}
