package com.moodwalls.repository;

import com.moodwalls.entity.EncouragementNote;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface EncouragementNoteRepository extends JpaRepository<EncouragementNote, Long> {

    @Query("""
            SELECT n FROM EncouragementNote n
            WHERE n.status = 1
              AND n.userId <> :userId
              AND LENGTH(n.content) >= 8
            ORDER BY n.createdAt DESC
            """)
    List<EncouragementNote> findDrawableNotes(@Param("userId") Long userId, Pageable pageable);

    long countByUserIdAndStatus(Long userId, Integer status);
}
