package com.moodwalls.service;

import com.moodwalls.dto.ReactionResponseDto;
import com.moodwalls.dto.TopReactionDto;
import com.moodwalls.entity.Post;
import com.moodwalls.entity.PostReaction;
import com.moodwalls.exception.BusinessException;
import com.moodwalls.repository.PostReactionRepository;
import com.moodwalls.repository.PostRepository;
import com.moodwalls.util.ReactionHelper;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
public class ReactionService {

    private final PostRepository postRepository;
    private final PostReactionRepository reactionRepository;

    public ReactionService(PostRepository postRepository, PostReactionRepository reactionRepository) {
        this.postRepository = postRepository;
        this.reactionRepository = reactionRepository;
    }

    @Transactional
    public ReactionResponseDto react(Long postId, Long userId, String reactionTypeRaw) {
        Post post = loadReactablePost(postId, userId);
        String reactionType = ReactionHelper.normalizeType(reactionTypeRaw);

        Optional<PostReaction> existing = reactionRepository.findByUserIdAndPostId(userId, postId);
        if (existing.isPresent()) {
            PostReaction reaction = existing.get();
            if (reactionType.equals(reaction.getReactionType())) {
                return buildResponse(postId, userId);
            }
            reaction.setReactionType(reactionType);
            reactionRepository.save(reaction);
        } else {
            PostReaction reaction = new PostReaction();
            reaction.setUserId(userId);
            reaction.setPostId(postId);
            reaction.setReactionType(reactionType);
            reactionRepository.save(reaction);
        }
        return buildResponse(postId, userId);
    }

    @Transactional
    public ReactionResponseDto cancelReact(Long postId, Long userId) {
        loadReactablePost(postId, userId);
        reactionRepository.findByUserIdAndPostId(userId, postId)
                .ifPresent(reactionRepository::delete);
        return buildResponse(postId, userId);
    }

    public ReactionResponseDto buildResponse(Long postId, Long userId) {
        Map<String, Integer> stats = loadStatsForPost(postId);
        int total = stats.values().stream().mapToInt(Integer::intValue).sum();
        String myReaction = null;
        if (userId != null) {
            myReaction = reactionRepository.findByUserIdAndPostId(userId, postId)
                    .map(PostReaction::getReactionType)
                    .orElse(null);
        }

        ReactionResponseDto dto = new ReactionResponseDto();
        dto.setTotalReactions(total);
        dto.setMyReaction(myReaction);
        dto.setReactionStats(stats);
        dto.setTopReactions(buildTopReactions(stats));
        return dto;
    }

    public Map<Long, ReactionResponseDto> buildResponsesForPosts(List<Long> postIds, Long userId) {
        if (postIds == null || postIds.isEmpty()) {
            return Map.of();
        }

        List<PostReaction> allReactions = reactionRepository.findByPostIdIn(postIds);
        Map<Long, List<PostReaction>> grouped = allReactions.stream()
                .collect(Collectors.groupingBy(PostReaction::getPostId));

        Map<Long, String> myReactionMap = new HashMap<>();
        if (userId != null) {
            List<PostReaction> mine = reactionRepository.findByUserIdAndPostIdIn(userId, postIds);
            for (PostReaction reaction : mine) {
                myReactionMap.put(reaction.getPostId(), reaction.getReactionType());
            }
        }

        Map<Long, ReactionResponseDto> result = new HashMap<>();
        for (Long postId : postIds) {
            Map<String, Integer> stats = ReactionHelper.emptyStats();
            List<PostReaction> reactions = grouped.getOrDefault(postId, List.of());
            for (PostReaction reaction : reactions) {
                stats.merge(reaction.getReactionType(), 1, Integer::sum);
            }
            int total = stats.values().stream().mapToInt(Integer::intValue).sum();

            ReactionResponseDto dto = new ReactionResponseDto();
            dto.setTotalReactions(total);
            dto.setMyReaction(myReactionMap.get(postId));
            dto.setReactionStats(stats);
            dto.setTopReactions(buildTopReactions(stats));
            result.put(postId, dto);
        }
        return result;
    }

    private Map<String, Integer> loadStatsForPost(Long postId) {
        Map<String, Integer> stats = ReactionHelper.emptyStats();
        for (Object[] row : reactionRepository.countGroupedByType(postId)) {
            String type = (String) row[0];
            int count = ((Number) row[1]).intValue();
            if (stats.containsKey(type)) {
                stats.put(type, count);
            }
        }
        return stats;
    }

    private List<TopReactionDto> buildTopReactions(Map<String, Integer> stats) {
        List<TopReactionDto> tops = new ArrayList<>();
        for (Map.Entry<String, Integer> entry : stats.entrySet()) {
            if (entry.getValue() > 0) {
                tops.add(new TopReactionDto(entry.getKey(), ReactionHelper.labelOf(entry.getKey()), entry.getValue()));
            }
        }
        tops.sort(Comparator.comparingInt(TopReactionDto::getCount).reversed());
        if (tops.size() > 2) {
            return tops.subList(0, 2);
        }
        return tops;
    }

    private Post loadReactablePost(Long postId, Long userId) {
        Post post = postRepository.findById(postId)
                .filter(p -> p.getStatus() == 1)
                .orElseThrow(() -> new BusinessException(404, "帖子不存在"));
        Integer visibility = post.getVisibility();
        if (visibility != null && visibility == 2 && !post.getUserId().equals(userId)) {
            throw new BusinessException(403, "该帖子仅作者可见");
        }
        return post;
    }
}
