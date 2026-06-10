package com.moodwalls.service;

import com.moodwalls.dto.CommentDto;
import com.moodwalls.dto.CommentListResponseDto;
import com.moodwalls.dto.CommentReplyDto;
import com.moodwalls.dto.CreateCommentDto;
import com.moodwalls.entity.Notification;
import com.moodwalls.entity.Post;
import com.moodwalls.entity.PostComment;
import com.moodwalls.entity.User;
import com.moodwalls.exception.BusinessException;
import com.moodwalls.repository.NotificationRepository;
import com.moodwalls.repository.PostCommentRepository;
import com.moodwalls.repository.PostRepository;
import com.moodwalls.repository.UserRepository;
import com.moodwalls.util.ContentModerator;
import com.moodwalls.util.MoodHelper;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
public class CommentService {

    private static final int STATUS_ACTIVE = 1;
    private static final DateTimeFormatter ISO_FORMATTER = DateTimeFormatter.ISO_LOCAL_DATE_TIME;

    private final PostRepository postRepository;
    private final PostCommentRepository commentRepository;
    private final UserRepository userRepository;
    private final NotificationRepository notificationRepository;

    public CommentService(PostRepository postRepository,
                          PostCommentRepository commentRepository,
                          UserRepository userRepository,
                          NotificationRepository notificationRepository) {
        this.postRepository = postRepository;
        this.commentRepository = commentRepository;
        this.userRepository = userRepository;
        this.notificationRepository = notificationRepository;
    }

    public CommentListResponseDto getComments(Long postId, int page, int size, Long currentUserId) {
        Post post = loadReadablePost(postId, currentUserId);

        size = Math.min(Math.max(size, 1), 50);
        page = Math.max(page, 1);
        PageRequest pageRequest = PageRequest.of(page - 1, size);

        Long postAuthorId = post.getUserId();
        Page<PostComment> topPage = commentRepository.findVisibleTopComments(
                post.getId(), STATUS_ACTIVE, currentUserId, postAuthorId, pageRequest);
        List<PostComment> tops = topPage.getContent();

        List<Long> parentIds = tops.stream().map(PostComment::getId).collect(Collectors.toList());
        Map<Long, List<PostComment>> replyMap = new HashMap<>();
        if (!parentIds.isEmpty()) {
            List<PostComment> replies = commentRepository
                    .findByPostIdAndStatusAndParentIdInOrderByCreatedAtAsc(post.getId(), STATUS_ACTIVE, parentIds);
            for (PostComment reply : replies) {
                replyMap.computeIfAbsent(reply.getParentId(), key -> new ArrayList<>()).add(reply);
            }
        }

        Map<Long, User> userMap = loadUsers(tops, replyMap);
        boolean isPostAuthor = currentUserId != null && currentUserId.equals(post.getUserId());

        List<CommentDto> list = new ArrayList<>();
        for (PostComment top : tops) {
            CommentDto dto = toTopCommentDto(top, userMap, currentUserId, isPostAuthor);
            List<PostComment> replyList = replyMap.getOrDefault(top.getId(), List.of());
            List<CommentReplyDto> replyDtos = new ArrayList<>();
            for (PostComment reply : replyList) {
                replyDtos.add(toReplyDto(reply, userMap, currentUserId, isPostAuthor));
            }
            dto.setReplies(replyDtos);
            list.add(dto);
        }

        CommentListResponseDto response = new CommentListResponseDto();
        response.setList(list);
        response.setTotal(topPage.getTotalElements());
        response.setPage(page);
        response.setSize(size);
        response.setHasMore(topPage.hasNext());
        if (isPostAuthor) {
            long whisperCount = commentRepository.countByPostIdAndStatusAndCommentTypeAndParentIdIsNull(
                    post.getId(), STATUS_ACTIVE, "whisper");
            response.setWhisperCount((int) whisperCount);
        }
        return response;
    }

    @Transactional
    public CommentDto createComment(Long postId, CreateCommentDto dto, Long userId) {
        if (dto.getContent() == null || dto.getContent().isBlank()) {
            throw new BusinessException(400, "评论内容不能为空");
        }
        String content = dto.getContent().trim();
        if (content.length() > 200) {
            throw new BusinessException(400, "评论不能超过 200 字");
        }
        ContentModerator.checkComment(content);

        Post post = postRepository.findById(postId)
                .filter(p -> p.getStatus() == STATUS_ACTIVE)
                .orElseThrow(() -> new BusinessException(404, "帖子不存在"));

        assertCanComment(post, userId);

        String commentType = dto.getCommentType() != null && !dto.getCommentType().isBlank()
                ? dto.getCommentType() : "resonance";
        if (!"resonance".equals(commentType) && !"whisper".equals(commentType)) {
            commentType = "resonance";
        }

        Long parentId = dto.getParentId();
        Long replyToUserId = dto.getReplyToUserId();
        if ("whisper".equals(commentType)) {
            if (parentId != null) {
                throw new BusinessException(400, "悄悄话不支持回复");
            }
            if (userId.equals(post.getUserId())) {
                throw new BusinessException(400, "不能给自己的帖子发悄悄话");
            }
        }
        if (parentId != null) {
            PostComment parent = commentRepository.findById(parentId)
                    .filter(c -> c.getStatus() == STATUS_ACTIVE && c.getPostId().equals(postId))
                    .orElseThrow(() -> new BusinessException(404, "父评论不存在"));
            if (parent.getParentId() != null) {
                throw new BusinessException(400, "仅支持回复一级评论");
            }
            if (replyToUserId == null) {
                replyToUserId = parent.getUserId();
            }
        } else {
            replyToUserId = null;
        }

        PostComment comment = new PostComment();
        comment.setPostId(postId);
        comment.setUserId(userId);
        comment.setContent(content);
        comment.setCommentType(commentType);
        comment.setParentId(parentId);
        comment.setReplyToUserId(replyToUserId);
        comment.setStatus(STATUS_ACTIVE);
        PostComment saved = commentRepository.save(comment);

        if ("resonance".equals(commentType)) {
            int count = post.getCommentCount() != null ? post.getCommentCount() : 0;
            post.setCommentCount(count + 1);
            postRepository.save(post);
        }

        sendCommentNotification(post, saved, userId);

        User author = userRepository.findById(userId).orElse(null);
        Map<Long, User> userMap = author == null ? Map.of() : Map.of(userId, author);
        boolean isPostAuthor = userId.equals(post.getUserId());

        if (parentId == null) {
            CommentDto result = toTopCommentDto(saved, userMap, userId, isPostAuthor);
            result.setReplies(new ArrayList<>());
            return result;
        }
        CommentDto wrapper = new CommentDto();
        CommentReplyDto replyDto = toReplyDto(saved, userMap, userId, isPostAuthor);
        wrapper.setId(replyDto.getId());
        wrapper.setPostId(replyDto.getPostId());
        wrapper.setUserId(replyDto.getUserId());
        wrapper.setParentId(replyDto.getParentId());
        wrapper.setAuthorNickname(replyDto.getAuthorNickname());
        wrapper.setAuthorAvatarKey(replyDto.getAuthorAvatarKey());
        wrapper.setContent(replyDto.getContent());
        wrapper.setCommentType(replyDto.getCommentType());
        wrapper.setReplyToNickname(replyDto.getReplyToNickname());
        wrapper.setMine(replyDto.isMine());
        wrapper.setCanDelete(replyDto.isCanDelete());
        wrapper.setCreatedAt(replyDto.getCreatedAt());
        wrapper.setTimeText(replyDto.getTimeText());
        wrapper.setReplies(new ArrayList<>());
        return wrapper;
    }

    @Transactional
    public void deleteComment(Long postId, Long commentId, Long userId) {
        Post post = postRepository.findById(postId)
                .filter(p -> p.getStatus() == STATUS_ACTIVE)
                .orElseThrow(() -> new BusinessException(404, "帖子不存在"));

        PostComment comment = commentRepository.findById(commentId)
                .filter(c -> c.getStatus() == STATUS_ACTIVE && c.getPostId().equals(postId))
                .orElseThrow(() -> new BusinessException(404, "评论不存在"));

        boolean isCommentAuthor = userId.equals(comment.getUserId());
        boolean isPostAuthor = userId.equals(post.getUserId());
        if (!isCommentAuthor && !isPostAuthor) {
            throw new BusinessException(403, "无权删除该评论");
        }

        int removedResonance = 0;
        comment.setStatus(0);
        commentRepository.save(comment);

        if (comment.getParentId() == null) {
            List<PostComment> replies = commentRepository.findByPostIdAndParentIdAndStatus(postId, commentId, STATUS_ACTIVE);
            for (PostComment reply : replies) {
                reply.setStatus(0);
                commentRepository.save(reply);
                if ("resonance".equals(reply.getCommentType())) {
                    removedResonance++;
                }
            }
            if ("resonance".equals(comment.getCommentType())) {
                removedResonance++;
            }
        } else if ("resonance".equals(comment.getCommentType())) {
            removedResonance = 1;
        }

        if (removedResonance > 0) {
            int count = post.getCommentCount() != null ? post.getCommentCount() : 0;
            post.setCommentCount(Math.max(0, count - removedResonance));
            postRepository.save(post);
        }
    }

    private Post loadReadablePost(Long postId, Long currentUserId) {
        Post post = postRepository.findById(postId)
                .filter(p -> p.getStatus() == STATUS_ACTIVE)
                .orElseThrow(() -> new BusinessException(404, "帖子不存在"));
        if (isPrivate(post) && (currentUserId == null || !currentUserId.equals(post.getUserId()))) {
            throw new BusinessException(403, "该帖子仅作者可见");
        }
        return post;
    }

    private void assertCanComment(Post post, Long userId) {
        if (isPrivate(post) && !userId.equals(post.getUserId())) {
            throw new BusinessException(403, "私密帖子暂不支持他人评论");
        }
    }

    private boolean isPrivate(Post post) {
        Integer visibility = post.getVisibility();
        return visibility != null && visibility == 2;
    }

    private void sendCommentNotification(Post post, PostComment comment, Long actorUserId) {
        User actor = userRepository.findById(actorUserId).orElse(null);
        String actorName = actor != null ? actor.getNickname() : "有人";

        Long targetUserId;
        String type;
        String title;
        String content;

        if (comment.getParentId() != null) {
            PostComment parent = commentRepository.findById(comment.getParentId()).orElse(null);
            if (parent == null) {
                return;
            }
            targetUserId = parent.getUserId();
            if (targetUserId.equals(actorUserId)) {
                return;
            }
            type = "reply";
            title = "收到新回复";
            content = actorName + " 回复了你的评论";
        } else {
            targetUserId = post.getUserId();
            if (targetUserId.equals(actorUserId)) {
                return;
            }
            if ("whisper".equals(comment.getCommentType())) {
                type = "whisper";
                title = "收到一句悄悄话";
                content = actorName + " 给你留了一句悄悄话";
            } else {
                type = "comment";
                title = "收到新评论";
                content = actorName + " 评论了你的帖子";
            }
        }

        Notification notification = new Notification();
        notification.setUserId(targetUserId);
        notification.setType(type);
        notification.setTitle(title);
        notification.setContent(content);
        notification.setRefType("post");
        notification.setRefId(post.getId());
        notification.setIsRead(0);
        notificationRepository.save(notification);
    }

    private Map<Long, User> loadUsers(List<PostComment> tops, Map<Long, List<PostComment>> replyMap) {
        List<Long> userIds = new ArrayList<>();
        for (PostComment top : tops) {
            userIds.add(top.getUserId());
            if (top.getReplyToUserId() != null) {
                userIds.add(top.getReplyToUserId());
            }
        }
        for (List<PostComment> replies : replyMap.values()) {
            for (PostComment reply : replies) {
                userIds.add(reply.getUserId());
                if (reply.getReplyToUserId() != null) {
                    userIds.add(reply.getReplyToUserId());
                }
            }
        }
        return userIds.stream().distinct().collect(Collectors.toMap(
                id -> id,
                id -> userRepository.findById(id).orElse(null),
                (a, b) -> a
        ));
    }

    private CommentDto toTopCommentDto(PostComment comment, Map<Long, User> userMap,
                                       Long currentUserId, boolean isPostAuthor) {
        CommentDto dto = new CommentDto();
        dto.setId(comment.getId());
        dto.setPostId(comment.getPostId());
        dto.setUserId(comment.getUserId());
        dto.setParentId(comment.getParentId());
        dto.setContent(comment.getContent());
        dto.setCommentType(comment.getCommentType());
        dto.setCreatedAt(comment.getCreatedAt().format(ISO_FORMATTER));
        dto.setTimeText(MoodHelper.formatTimeText(comment.getCreatedAt()));

        User author = userMap.get(comment.getUserId());
        dto.setAuthorNickname(author != null ? author.getNickname() : "匿名用户");
        dto.setAuthorAvatarKey(author != null && author.getAvatarKey() != null ? author.getAvatarKey() : "avatar_01");

        if (comment.getReplyToUserId() != null) {
            User replyTo = userMap.get(comment.getReplyToUserId());
            dto.setReplyToNickname(replyTo != null ? replyTo.getNickname() : null);
        }

        boolean mine = currentUserId != null && currentUserId.equals(comment.getUserId());
        dto.setMine(mine);
        dto.setCanDelete(mine || isPostAuthor);
        return dto;
    }

    private CommentReplyDto toReplyDto(PostComment comment, Map<Long, User> userMap,
                                       Long currentUserId, boolean isPostAuthor) {
        CommentReplyDto dto = new CommentReplyDto();
        dto.setId(comment.getId());
        dto.setPostId(comment.getPostId());
        dto.setUserId(comment.getUserId());
        dto.setParentId(comment.getParentId());
        dto.setContent(comment.getContent());
        dto.setCommentType(comment.getCommentType());
        dto.setCreatedAt(comment.getCreatedAt().format(ISO_FORMATTER));
        dto.setTimeText(MoodHelper.formatTimeText(comment.getCreatedAt()));

        User author = userMap.get(comment.getUserId());
        dto.setAuthorNickname(author != null ? author.getNickname() : "匿名用户");
        dto.setAuthorAvatarKey(author != null && author.getAvatarKey() != null ? author.getAvatarKey() : "avatar_01");

        if (comment.getReplyToUserId() != null) {
            User replyTo = userMap.get(comment.getReplyToUserId());
            dto.setReplyToNickname(replyTo != null ? replyTo.getNickname() : null);
        }

        boolean mine = currentUserId != null && currentUserId.equals(comment.getUserId());
        dto.setMine(mine);
        dto.setCanDelete(mine || isPostAuthor);
        return dto;
    }
}
