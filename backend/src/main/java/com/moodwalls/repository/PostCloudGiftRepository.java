package com.moodwalls.repository;

import com.moodwalls.entity.PostCloudGift;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface PostCloudGiftRepository extends JpaRepository<PostCloudGift, Long> {

    long countByPostId(Long postId);

    boolean existsByUserIdAndPostIdAndCreatedAtAfter(Long userId, Long postId, LocalDateTime since);

    @Query("SELECT g.postId, COUNT(g) FROM PostCloudGift g WHERE g.postId IN :postIds GROUP BY g.postId")
    List<Object[]> countGroupedByPostIds(@Param("postIds") List<Long> postIds);
}
