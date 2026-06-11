package com.moodwalls.repository;

import com.moodwalls.entity.PostReaction;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface PostReactionRepository extends JpaRepository<PostReaction, Long> {

    Optional<PostReaction> findByUserIdAndPostId(Long userId, Long postId);

    List<PostReaction> findByUserIdAndPostIdIn(Long userId, List<Long> postIds);

    List<PostReaction> findByPostId(Long postId);

    List<PostReaction> findByPostIdIn(List<Long> postIds);

    long countByPostId(Long postId);

    @Query("SELECT r.reactionType, COUNT(r) FROM PostReaction r WHERE r.postId = :postId GROUP BY r.reactionType")
    List<Object[]> countGroupedByType(@Param("postId") Long postId);
}
