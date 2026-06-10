package com.moodwalls.service;

import com.moodwalls.dto.CreateEncouragementNoteDto;
import com.moodwalls.dto.EncouragementNoteDto;
import com.moodwalls.entity.EncouragementNote;
import com.moodwalls.exception.BusinessException;
import com.moodwalls.repository.EncouragementNoteRepository;
import com.moodwalls.util.ContentModerator;
import com.moodwalls.util.MoodHelper;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Set;

@Service
public class EncouragementNoteService {

    private static final DateTimeFormatter ISO_FORMATTER = DateTimeFormatter.ISO_LOCAL_DATE_TIME;
    private static final int MIN_LEN = 8;
    private static final int MAX_LEN = 120;
    private static final Set<String> ALLOWED_MOODS = Set.of("happy", "calm", "moved");
    private static final List<String> BLOCKED_KEYWORDS = List.of(
            "自杀", "自残", "去死", "不想活了", "想死", "割腕", "跳楼", "结束生命", "活不下去", "没人在乎我"
    );

    private final EncouragementNoteRepository noteRepository;

    public EncouragementNoteService(EncouragementNoteRepository noteRepository) {
        this.noteRepository = noteRepository;
    }

    @Transactional
    public EncouragementNoteDto createNote(CreateEncouragementNoteDto dto, Long userId) {
        if (dto == null || dto.getContent() == null || dto.getContent().isBlank()) {
            throw new BusinessException(400, "请写下你想鼓励别人的话");
        }
        String content = dto.getContent().trim();
        if (content.length() < MIN_LEN) {
            throw new BusinessException(400, "小纸条至少需要 " + MIN_LEN + " 个字");
        }
        if (content.length() > MAX_LEN) {
            throw new BusinessException(400, "小纸条不能超过 " + MAX_LEN + " 字");
        }
        ContentModerator.checkComment(content);
        assertEncouragingContent(content);

        String mood = normalizeMood(dto.getMood());
        EncouragementNote note = new EncouragementNote();
        note.setUserId(userId);
        note.setContent(content);
        note.setMood(mood);
        note.setStatus(1);
        EncouragementNote saved = noteRepository.save(note);
        return toDto(saved);
    }

    public long countMyNotes(Long userId) {
        return noteRepository.countByUserIdAndStatus(userId, 1);
    }

    private String normalizeMood(String mood) {
        if (mood == null || mood.isBlank()) {
            return "calm";
        }
        String normalized = mood.trim().toLowerCase();
        if (ALLOWED_MOODS.contains(normalized)) {
            return normalized;
        }
        return "calm";
    }

    private void assertEncouragingContent(String content) {
        String normalized = content.toLowerCase();
        for (String word : BLOCKED_KEYWORDS) {
            if (normalized.contains(word.toLowerCase())) {
                throw new BusinessException(422, "小纸条请保持温暖正向，换种方式表达吧");
            }
        }
    }

    private EncouragementNoteDto toDto(EncouragementNote note) {
        EncouragementNoteDto dto = new EncouragementNoteDto();
        dto.setId(note.getId());
        dto.setContent(note.getContent());
        dto.setMood(note.getMood());
        dto.setMoodLabel(MoodHelper.labelOf(note.getMood()));
        dto.setMoodColor(MoodHelper.colorOf(note.getMood()));
        dto.setCreatedAt(note.getCreatedAt().format(ISO_FORMATTER));
        dto.setTimeText(MoodHelper.formatTimeText(note.getCreatedAt()));
        return dto;
    }
}
