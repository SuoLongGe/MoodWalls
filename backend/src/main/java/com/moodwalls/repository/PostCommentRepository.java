package com.moodwalls.repository;

import com.moodwalls.entity.PostComment;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface PostCommentRepository extends JpaRepository<PostComment, Long> {

    Page<PostComment> findByPostIdAndStatusAndParentIdIsNullOrderByCreatedAtAsc(
            Long postId, Integer status, Pageable pageable);

    List<PostComment> findByPostIdAndStatusAndParentIdInOrderByCreatedAtAsc(
            Long postId, Integer status, List<Long> parentIds);

    List<PostComment> findByPostIdAndParentIdAndStatus(Long postId, Long parentId, Integer status);

    long countByPostIdAndStatusAndParentIdIsNull(Long postId, Integer status);

    @Modifying
    @Query("UPDATE PostComment c SET c.status = 0 WHERE c.postId = :postId AND c.parentId = :parentId AND c.status = 1")
    int softDeleteReplies(@Param("postId") Long postId, @Param("parentId") Long parentId);
}
