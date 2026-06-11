package com.moodwalls.repository;

import com.moodwalls.entity.InspirationDraw;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface InspirationDrawRepository extends JpaRepository<InspirationDraw, Long> {

    Optional<InspirationDraw> findByUserIdAndDrawDate(Long userId, LocalDate drawDate);

    List<InspirationDraw> findByUserIdAndNoteIdIsNotNullAndCreatedAtAfter(Long userId, LocalDateTime since);
}
