package com.moodwalls.repository;

import com.moodwalls.entity.Post;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.List;

public interface PostRepository extends JpaRepository<Post, Long> {

    long countByUserIdAndStatus(Long userId, Integer status);

    Page<Post> findByUserIdAndStatusOrderByCreatedAtDesc(Long userId, Integer status, Pageable pageable);

    List<Post> findByUserIdAndStatusAndCreatedAtBetweenOrderByCreatedAtAsc(
            Long userId,
            Integer status,
            LocalDateTime start,
            LocalDateTime end
    );

    @Query("SELECT COALESCE(SUM(p.likeCount), 0) FROM Post p WHERE p.userId = :userId AND p.status = 1")
    long sumLikeCountByUserId(@Param("userId") Long userId);
}
