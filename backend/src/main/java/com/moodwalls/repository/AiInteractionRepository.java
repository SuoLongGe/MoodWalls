package com.moodwalls.repository;

import com.moodwalls.entity.AiInteraction;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface AiInteractionRepository extends JpaRepository<AiInteraction, Long> {

    List<AiInteraction> findByUserIdOrderByCreatedAtDesc(Long userId);

    List<AiInteraction> findByPostIdOrderByCreatedAtDesc(Long postId);
}
