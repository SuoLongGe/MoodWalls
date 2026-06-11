package com.moodwalls.service;

import com.moodwalls.dto.InspirationDrawDto;
import com.moodwalls.entity.EncouragementNote;
import com.moodwalls.entity.InspirationDraw;
import com.moodwalls.repository.EncouragementNoteRepository;
import com.moodwalls.repository.InspirationDrawRepository;
import com.moodwalls.util.MoodHelper;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Optional;
import java.util.Random;
import java.util.Set;

@Service
public class InspirationService {

    private static final ZoneId ZONE = ZoneId.of("Asia/Shanghai");
    private static final DateTimeFormatter ISO_FORMATTER = DateTimeFormatter.ISO_LOCAL_DATE_TIME;
    private static final List<String> BLOCKED_KEYWORDS = List.of(
            "自杀", "自残", "去死", "不想活了", "想死", "割腕", "跳楼", "结束生命", "活不下去", "没人在乎我"
    );

    private final InspirationDrawRepository drawRepository;
    private final EncouragementNoteRepository noteRepository;
    private final Random random = new Random();

    public InspirationService(InspirationDrawRepository drawRepository,
                              EncouragementNoteRepository noteRepository) {
        this.drawRepository = drawRepository;
        this.noteRepository = noteRepository;
    }

    public InspirationDrawDto getToday(Long userId) {
        LocalDate today = LocalDate.now(ZONE);
        Optional<InspirationDraw> existing = drawRepository.findByUserIdAndDrawDate(userId, today);
        if (existing.isPresent()) {
            return toDto(existing.get(), true);
        }
        InspirationDrawDto empty = new InspirationDrawDto();
        empty.setAlreadyDrawn(false);
        empty.setRemainingToday(1);
        return empty;
    }

    @Transactional
    public InspirationDrawDto draw(Long userId) {
        LocalDate today = LocalDate.now(ZONE);
        Optional<InspirationDraw> existing = drawRepository.findByUserIdAndDrawDate(userId, today);
        if (existing.isPresent()) {
            return toDto(existing.get(), true);
        }

        NotePick pick = pickRandomNote(userId);
        InspirationDraw draw = new InspirationDraw();
        draw.setUserId(userId);
        draw.setNoteId(pick.noteId());
        draw.setContent(pick.content());
        draw.setMood(pick.mood());
        draw.setDrawDate(today);
        InspirationDraw saved = drawRepository.save(draw);
        return toDto(saved, false);
    }

    private NotePick pickRandomNote(Long userId) {
        LocalDateTime weekAgo = LocalDateTime.now(ZONE).minusDays(7);
        Set<Long> excludedNoteIds = new HashSet<>();
        drawRepository.findByUserIdAndNoteIdIsNotNullAndCreatedAtAfter(userId, weekAgo)
                .forEach(row -> {
                    if (row.getNoteId() != null) {
                        excludedNoteIds.add(row.getNoteId());
                    }
                });

        List<EncouragementNote> candidates = noteRepository.findDrawableNotes(
                userId, PageRequest.of(0, 100));
        List<EncouragementNote> filtered = new ArrayList<>();
        for (EncouragementNote note : candidates) {
            if (excludedNoteIds.contains(note.getId())) {
                continue;
            }
            if (!isEligibleContent(note.getContent())) {
                continue;
            }
            filtered.add(note);
        }

        if (!filtered.isEmpty()) {
            EncouragementNote chosen = filtered.get(random.nextInt(filtered.size()));
            return new NotePick(chosen.getId(), chosen.getContent(), chosen.getMood(), "campus");
        }

        List<NotePick> seeds = buildSeedNotes();
        NotePick seed = seeds.get(random.nextInt(seeds.size()));
        return new NotePick(null, seed.content(), seed.mood(), "seed");
    }

    private boolean isEligibleContent(String content) {
        if (content == null || content.trim().length() < 8) {
            return false;
        }
        String normalized = content.toLowerCase();
        for (String word : BLOCKED_KEYWORDS) {
            if (normalized.contains(word.toLowerCase())) {
                return false;
            }
        }
        return true;
    }

    private InspirationDrawDto toDto(InspirationDraw draw, boolean alreadyDrawn) {
        InspirationDrawDto dto = new InspirationDrawDto();
        dto.setAlreadyDrawn(alreadyDrawn);
        dto.setContent(draw.getContent());
        dto.setMood(draw.getMood());
        dto.setMoodLabel(MoodHelper.labelOf(draw.getMood()));
        dto.setMoodColor(MoodHelper.colorOf(draw.getMood()));
        dto.setSource(draw.getNoteId() != null ? "campus" : "seed");
        dto.setDrawnAt(draw.getCreatedAt() != null ? draw.getCreatedAt().format(ISO_FORMATTER) : null);
        dto.setRemainingToday(0);
        return dto;
    }

    private List<NotePick> buildSeedNotes() {
        return List.of(
                new NotePick(null, "今天也要记得对自己温柔一点。", "calm", "seed"),
                new NotePick(null, "你已经很努力了，今晚也值得好好休息。", "calm", "seed"),
                new NotePick(null, "校园里的风经过你时，也在悄悄为你加油。", "happy", "seed"),
                new NotePick(null, "不必把所有情绪都解释清楚，先慢慢呼吸就好。", "calm", "seed"),
                new NotePick(null, "有人也在某个角落，和你一样认真地生活着。", "moved", "seed")
        );
    }

    private record NotePick(Long noteId, String content, String mood, String source) {}
}
