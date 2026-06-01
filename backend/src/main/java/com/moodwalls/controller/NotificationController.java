package com.moodwalls.controller;

import com.moodwalls.dto.ApiResponse;
import com.moodwalls.entity.Notification;
import com.moodwalls.exception.BusinessException;
import com.moodwalls.repository.NotificationRepository;
import com.moodwalls.security.TokenUtil;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/notifications")
public class NotificationController {

    private final NotificationRepository notificationRepository;
    private final TokenUtil tokenUtil;

    public NotificationController(NotificationRepository notificationRepository, TokenUtil tokenUtil) {
        this.notificationRepository = notificationRepository;
        this.tokenUtil = tokenUtil;
    }

    @GetMapping
    public ApiResponse<Map<String, Object>> list(
            @RequestHeader("Authorization") String authorization,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int size) {
        Long userId = tokenUtil.extractUserId(authorization);

        Page<Notification> pageResult = notificationRepository.findByUserIdOrderByCreatedAtDesc(
                userId, PageRequest.of(page - 1, size));

        List<Map<String, Object>> list = pageResult.getContent().stream().map(n -> {
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("id", n.getId());
            item.put("type", n.getType());
            item.put("title", n.getTitle());
            item.put("content", n.getContent());
            item.put("refType", n.getRefType());
            item.put("refId", n.getRefId());
            item.put("isRead", n.getIsRead() == 1);
            item.put("createdAt", n.getCreatedAt() != null ? n.getCreatedAt().toString() : null);
            return item;
        }).collect(Collectors.toList());

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("list", list);
        result.put("total", pageResult.getTotalElements());
        result.put("page", page);
        result.put("size", size);
        result.put("hasMore", pageResult.hasNext());

        return ApiResponse.ok(result);
    }

    @GetMapping("/unread-count")
    public ApiResponse<Map<String, Object>> unreadCount(
            @RequestHeader("Authorization") String authorization) {
        Long userId = tokenUtil.extractUserId(authorization);

        long count = notificationRepository.countUnreadByUserId(userId);

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("count", count);

        return ApiResponse.ok(result);
    }

    @PostMapping("/read-all")
    @Transactional
    public ApiResponse<Map<String, Object>> readAll(
            @RequestHeader("Authorization") String authorization) {
        Long userId = tokenUtil.extractUserId(authorization);

        int updated = notificationRepository.markAllReadByUserId(userId);

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("updated", updated);

        return ApiResponse.ok("已全部标记为已读", result);
    }

    @PostMapping("/{id}/read")
    @Transactional
    public ApiResponse<Map<String, Object>> readOne(
            @PathVariable Long id,
            @RequestHeader("Authorization") String authorization) {
        Long userId = tokenUtil.extractUserId(authorization);

        Notification notification = notificationRepository.findById(id)
                .orElseThrow(() -> new BusinessException(404, "通知不存在"));

        if (!notification.getUserId().equals(userId)) {
            throw new BusinessException(403, "无权操作此通知");
        }

        notification.setIsRead(1);
        notificationRepository.save(notification);

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("id", id);
        result.put("isRead", true);

        return ApiResponse.ok(result);
    }
}
