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

    List<Post> findByUserIdOrderByCreatedAtDesc(Long userId);

    List<Post> findByZoneKeyAndStatus(String zoneKey, Integer status);

    @Query("SELECT p FROM Post p WHERE p.zoneKey = :zoneKey AND p.status = 1 ORDER BY p.createdAt DESC")
    List<Post> findActiveByZoneKey(@Param("zoneKey") String zoneKey);

    @Query("SELECT COUNT(p) FROM Post p WHERE p.status = 1 AND p.createdAt >= :since")
    long countActiveSince(@Param("since") LocalDateTime since);

    @Query("SELECT p.zoneKey, COUNT(p) as cnt FROM Post p WHERE p.status = 1 AND p.createdAt >= :since GROUP BY p.zoneKey")
    List<Object[]> countByZoneSince(@Param("since") LocalDateTime since);

    @Query("SELECT p.mood, COUNT(p) as cnt FROM Post p WHERE p.status = 1 AND p.createdAt >= :since GROUP BY p.mood")
    List<Object[]> countByMoodSince(@Param("since") LocalDateTime since);

    @Query("SELECT p.zoneKey, p.mood, COUNT(p) FROM Post p WHERE p.status = 1 AND p.zoneKey IS NOT NULL AND p.createdAt >= :since GROUP BY p.zoneKey, p.mood")
    List<Object[]> countByZoneAndMoodSince(@Param("since") LocalDateTime since);

    @Query("SELECT p FROM Post p WHERE p.userId = :userId AND p.status = 1 AND p.createdAt >= :since ORDER BY p.createdAt DESC")
    List<Post> findUserPostsSince(@Param("userId") Long userId, @Param("since") LocalDateTime since);

    @Query("SELECT COUNT(p) FROM Post p WHERE p.userId = :userId AND p.status = 1 AND p.createdAt >= :since")
    long countUserPostsSince(@Param("userId") Long userId, @Param("since") LocalDateTime since);

    List<Post> findByUserIdAndStatus(Long userId, Integer status);
}
