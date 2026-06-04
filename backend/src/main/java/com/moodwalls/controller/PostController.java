package com.moodwalls.controller;

import com.moodwalls.dto.ApiResponse;
import com.moodwalls.dto.CreatePostDto;
import com.moodwalls.dto.LikeResponseDto;
import com.moodwalls.dto.PostListResponseDto;
import com.moodwalls.dto.PostSummaryDto;
import com.moodwalls.dto.PublishPostResponseDto;
import com.moodwalls.dto.MoodStatsDto;
import com.moodwalls.dto.TodayStatsDto;
import com.moodwalls.security.TokenUtil;
import com.moodwalls.service.PostService;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api")
public class PostController {

    private final PostService postService;
    private final TokenUtil tokenUtil;

    public PostController(PostService postService, TokenUtil tokenUtil) {
        this.postService = postService;
        this.tokenUtil = tokenUtil;
    }

    @GetMapping("/posts")
    public ApiResponse<PostListResponseDto> getPostList(
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(required = false) String mood,
            @RequestHeader(value = "Authorization", required = false) String authorization) {
        Long userId = tokenUtil.extractUserIdOrNull(authorization);
        PostListResponseDto result = postService.getPostList(page, size, mood, userId);
        return ApiResponse.ok(result);
    }

    @GetMapping("/posts/{id}")
    public ApiResponse<PostSummaryDto> getPostDetail(
            @PathVariable("id") Long id,
            @RequestHeader(value = "Authorization", required = false) String authorization) {
        Long userId = tokenUtil.extractUserIdOrNull(authorization);
        PostSummaryDto result = postService.getPostDetail(id, userId);
        return ApiResponse.ok(result);
    }

    @PostMapping("/posts/{id}/like")
    public ApiResponse<LikeResponseDto> likePost(
            @PathVariable("id") Long id,
            @RequestHeader(value = "Authorization", required = false) String authorization) {
        Long userId = tokenUtil.extractUserId(authorization);
        LikeResponseDto result = postService.likePost(id, userId);
        return ApiResponse.ok(result);
    }

    @GetMapping("/stats/today")
    public ApiResponse<TodayStatsDto> getTodayStats() {
        TodayStatsDto result = postService.getTodayStats();
        return ApiResponse.ok(result);
    }

    /**
     * 校园心墙情绪占比：按时间段统计各 mood 发帖占比，仅返回有帖子的情绪类型。
     * period: today | week | month
     */
    @GetMapping("/stats/moods")
    public ApiResponse<MoodStatsDto> getMoodStats(
            @RequestParam(value = "period", defaultValue = "today") String period) {
        MoodStatsDto result = postService.getMoodStats(period);
        return ApiResponse.ok(result);
    }

    @PostMapping("/posts")
    public ApiResponse<PublishPostResponseDto> createPost(
            @RequestBody CreatePostDto dto,
            @RequestHeader(value = "Authorization", required = false) String authorization) {
        Long userId = tokenUtil.extractUserId(authorization);
        PublishPostResponseDto result = postService.createPostWithAi(dto, userId);
        return ApiResponse.ok(result);
    }

    @DeleteMapping("/posts/{id}")
    public ApiResponse<Void> deletePost(
            @PathVariable("id") Long id,
            @RequestHeader(value = "Authorization", required = false) String authorization) {
        Long userId = tokenUtil.extractUserId(authorization);
        postService.deletePost(id, userId);
        return ApiResponse.ok(null);
    }
}
