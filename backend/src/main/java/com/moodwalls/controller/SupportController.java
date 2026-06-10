package com.moodwalls.controller;

import com.moodwalls.dto.ApiResponse;
import com.moodwalls.entity.Notification;
import com.moodwalls.entity.Post;
import com.moodwalls.entity.User;
import com.moodwalls.exception.BusinessException;
import com.moodwalls.repository.NotificationRepository;
import com.moodwalls.repository.PostRepository;
import com.moodwalls.repository.UserRepository;
import com.moodwalls.security.TokenUtil;
import com.moodwalls.service.AiService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.temporal.TemporalAdjusters;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api")
public class SupportController {

    private final PostRepository postRepository;
    private final UserRepository userRepository;
    private final NotificationRepository notificationRepository;
    private final AiService aiService;
    private final TokenUtil tokenUtil;

    public SupportController(PostRepository postRepository, UserRepository userRepository,
                             NotificationRepository notificationRepository,
                             AiService aiService, TokenUtil tokenUtil) {
        this.postRepository = postRepository;
        this.userRepository = userRepository;
        this.notificationRepository = notificationRepository;
        this.aiService = aiService;
        this.tokenUtil = tokenUtil;
    }

    @PostMapping("/posts/{id}/support")
    public ApiResponse<Map<String, Object>> supportPost(
            @PathVariable Long id,
            @RequestHeader("Authorization") String authorization) {
        Long userId = tokenUtil.extractUserId(authorization);

        Post post = postRepository.findById(id)
                .orElseThrow(() -> new BusinessException(404, "帖子不存在"));

        User supporter = userRepository.findById(userId)
                .orElseThrow(() -> new BusinessException(404, "用户不存在"));

        AiService.AiResponse aiResponse = aiService.supportPost(post, userId);
        String comfortNote = aiService.getComfortNote(aiResponse.riskLevel());

        Notification notif = new Notification();
        notif.setUserId(post.getUserId());
        notif.setType("support");
        notif.setTitle(supporter.getNickname() + " 接住了你的心声");
        notif.setContent(aiResponse.responseText());
        notif.setRefType("ai");
        notif.setRefId(post.getId());
        notif.setIsRead(0);
        notificationRepository.save(notif);

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("response", aiResponse.responseText());
        result.put("riskLevel", aiResponse.riskLevel());
        result.put("isCrisis", aiResponse.riskLevel() >= 2);
        result.put("comfortNote", comfortNote);

        return ApiResponse.ok(result);
    }

    @GetMapping("/profile/weekly-report")
    public ApiResponse<Map<String, Object>> getWeeklyReport(
            @RequestHeader("Authorization") String authorization) {
        Long userId = tokenUtil.extractUserId(authorization);

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new BusinessException(404, "用户不存在"));

        LocalDateTime weekStart = LocalDate.now()
                .with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY))
                .atStartOfDay();

        List<Post> recentPosts = postRepository.findUserPostsSince(userId, weekStart);
        long postCount = postRepository.countUserPostsSince(userId, weekStart);

        Map<String, Long> moodCounts = recentPosts.stream()
                .collect(Collectors.groupingBy(Post::getMood, Collectors.counting()));

        AiService.WeeklyReportResponse report = aiService.generateWeeklyReport(
                userId, user.getNickname(), recentPosts, moodCounts, postCount);

        Notification notif = new Notification();
        notif.setUserId(userId);
        notif.setType("weekly_report");
        notif.setTitle("本周情绪周报已生成");
        notif.setContent(report.report().substring(0, Math.min(report.report().length(), 128)));
        notif.setRefType("report");
        notif.setRefId(null);
        notif.setIsRead(0);
        notificationRepository.save(notif);

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("report", report.report());
        result.put("moodSummary", report.moodSummary());
        result.put("postCount", report.postCount());

        return ApiResponse.ok(result);
    }

    @GetMapping("/posts/{id}/support/stream")
    public SseEmitter supportPostStream(
            @PathVariable Long id,
            @RequestHeader("Authorization") String authorization) {
        Long userId = tokenUtil.extractUserId(authorization);
        Post post = postRepository.findById(id)
                .orElseThrow(() -> new BusinessException(404, "帖子不存在"));

        String prompt = aiService.buildSupportPromptForStream(post);
        SseEmitter emitter = new SseEmitter(60000L);

        ExecutorService executor = Executors.newSingleThreadExecutor();
        executor.execute(() -> {
            try {
                aiService.streamCallAi(prompt, AiService.getSystemPrompt(), 200, token -> {
                    try {
                        emitter.send(SseEmitter.event().data(token));
                    } catch (Exception ignored) {
                    }
                });
                emitter.complete();
            } catch (Exception e) {
                emitter.completeWithError(e);
            }
        });
        executor.shutdown();

        emitter.onCompletion(() -> executor.shutdownNow());
        emitter.onTimeout(() -> executor.shutdownNow());

        return emitter;
    }
}
