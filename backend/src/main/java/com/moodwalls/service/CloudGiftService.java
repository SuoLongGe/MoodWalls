package com.moodwalls.service;

import com.moodwalls.dto.CloudGiftResponseDto;
import com.moodwalls.entity.Post;
import com.moodwalls.entity.PostCloudGift;
import com.moodwalls.exception.BusinessException;
import com.moodwalls.repository.PostCloudGiftRepository;
import com.moodwalls.repository.PostRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
public class CloudGiftService {

    private static final long COOLDOWN_SECONDS = 60;

    private final PostCloudGiftRepository cloudGiftRepository;
    private final PostRepository postRepository;
    private final NotificationService notificationService;

    public CloudGiftService(PostCloudGiftRepository cloudGiftRepository,
                            PostRepository postRepository,
                            NotificationService notificationService) {
        this.cloudGiftRepository = cloudGiftRepository;
        this.postRepository = postRepository;
        this.notificationService = notificationService;
    }

    @Transactional
    public CloudGiftResponseDto sendCloud(Long postId, Long userId) {
        Post post = postRepository.findById(postId)
                .filter(p -> p.getStatus() == 1)
                .orElseThrow(() -> new BusinessException(404, "帖子不存在"));

        if (post.getUserId().equals(userId)) {
            throw new BusinessException(400, "不能给自己的帖子送云");
        }
        Integer visibility = post.getVisibility();
        if (visibility != null && visibility == 2) {
            throw new BusinessException(403, "该帖子仅作者可见");
        }

        LocalDateTime since = LocalDateTime.now().minusSeconds(COOLDOWN_SECONDS);
        if (cloudGiftRepository.existsByUserIdAndPostIdAndCreatedAtAfter(userId, postId, since)) {
            throw new BusinessException(409, "稍后再送吧");
        }

        PostCloudGift gift = new PostCloudGift();
        gift.setUserId(userId);
        gift.setPostId(postId);
        cloudGiftRepository.save(gift);

        notificationService.notifyCloudGift(post, userId);

        CloudGiftResponseDto dto = new CloudGiftResponseDto();
        dto.setSent(true);
        dto.setCloudCount((int) cloudGiftRepository.countByPostId(postId));
        return dto;
    }

    public Map<Long, Integer> countByPostIds(List<Long> postIds) {
        if (postIds == null || postIds.isEmpty()) {
            return Map.of();
        }
        Map<Long, Integer> result = new HashMap<>();
        for (Object[] row : cloudGiftRepository.countGroupedByPostIds(postIds)) {
            Long postId = (Long) row[0];
            int count = ((Number) row[1]).intValue();
            result.put(postId, count);
        }
        return result;
    }

    public int countForPost(Long postId) {
        return (int) cloudGiftRepository.countByPostId(postId);
    }
}
