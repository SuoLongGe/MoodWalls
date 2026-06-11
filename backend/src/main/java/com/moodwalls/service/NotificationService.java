package com.moodwalls.service;

import com.moodwalls.entity.Notification;
import com.moodwalls.entity.Post;
import com.moodwalls.entity.User;
import com.moodwalls.repository.NotificationRepository;
import com.moodwalls.repository.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.util.Objects;

@Service
public class NotificationService {

    private static final Logger log = LoggerFactory.getLogger(NotificationService.class);

    private final NotificationRepository notificationRepository;
    private final UserRepository userRepository;

    public NotificationService(NotificationRepository notificationRepository, UserRepository userRepository) {
        this.notificationRepository = notificationRepository;
        this.userRepository = userRepository;
    }

    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void notifyPostLiked(Post post, Long likerUserId) {
        if (post == null || post.getId() == null || post.getUserId() == null || likerUserId == null) {
            log.warn("Skip like notification: invalid post or liker. postId={}, likerUserId={}",
                    post != null ? post.getId() : null, likerUserId);
            return;
        }
        if (Objects.equals(post.getUserId(), likerUserId)) {
            log.debug("Skip like notification: self-like. postId={}, userId={}", post.getId(), likerUserId);
            return;
        }

        try {
            User liker = userRepository.findById(likerUserId).orElse(null);
            String nickname = liker != null ? liker.getNickname() : "有人";

            Notification notification = new Notification();
            notification.setUserId(post.getUserId());
            notification.setType("like");
            notification.setTitle("收到新点赞");
            notification.setContent(nickname + " 赞了你的帖子");
            notification.setRefType("post");
            notification.setRefId(post.getId());
            notification.setIsRead(0);
            notificationRepository.saveAndFlush(notification);
            log.info("Like notification created. postId={}, authorId={}, likerId={}",
                    post.getId(), post.getUserId(), likerUserId);
        } catch (Exception ex) {
            log.error("Failed to create like notification. postId={}, likerId={}, error={}",
                    post.getId(), likerUserId, ex.getMessage(), ex);
        }
    }

    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void notifyCloudGift(Post post, Long senderUserId) {
        if (post == null || post.getId() == null || post.getUserId() == null || senderUserId == null) {
            return;
        }
        if (Objects.equals(post.getUserId(), senderUserId)) {
            return;
        }

        try {
            User sender = userRepository.findById(senderUserId).orElse(null);
            String nickname = sender != null ? sender.getNickname() : "有人";

            Notification notification = new Notification();
            notification.setUserId(post.getUserId());
            notification.setType("cloud");
            notification.setTitle("收到一朵云");
            notification.setContent(nickname + " 给你的心情送了一朵云");
            notification.setRefType("post");
            notification.setRefId(post.getId());
            notification.setIsRead(0);
            notificationRepository.saveAndFlush(notification);
        } catch (Exception ex) {
            log.error("Failed to create cloud notification. postId={}, senderId={}, error={}",
                    post.getId(), senderUserId, ex.getMessage(), ex);
        }
    }
}
