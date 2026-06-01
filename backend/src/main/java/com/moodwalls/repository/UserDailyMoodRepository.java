package com.moodwalls.repository;

import com.moodwalls.entity.UserDailyMood;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDate;
import java.util.List;

public interface UserDailyMoodRepository extends JpaRepository<UserDailyMood, Long> {

    List<UserDailyMood> findByUserIdAndStatDateBetweenOrderByStatDateAsc(
            Long userId,
            LocalDate start,
            LocalDate end
    );
}
