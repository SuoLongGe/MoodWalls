package com.moodwalls.controller;

import com.moodwalls.dto.ApiResponse;
import com.moodwalls.dto.CreateEncouragementNoteDto;
import com.moodwalls.dto.EncouragementNoteDto;
import com.moodwalls.dto.InspirationDrawDto;
import com.moodwalls.security.TokenUtil;
import com.moodwalls.service.EncouragementNoteService;
import com.moodwalls.service.InspirationService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/inspiration")
public class InspirationController {

    private final InspirationService inspirationService;
    private final EncouragementNoteService encouragementNoteService;
    private final TokenUtil tokenUtil;

    public InspirationController(InspirationService inspirationService,
                                EncouragementNoteService encouragementNoteService,
                                TokenUtil tokenUtil) {
        this.inspirationService = inspirationService;
        this.encouragementNoteService = encouragementNoteService;
        this.tokenUtil = tokenUtil;
    }

    @PostMapping("/notes")
    public ApiResponse<EncouragementNoteDto> createNote(
            @RequestBody CreateEncouragementNoteDto dto,
            @RequestHeader(value = "Authorization", required = false) String authorization) {
        Long userId = tokenUtil.extractUserId(authorization);
        return ApiResponse.ok(encouragementNoteService.createNote(dto, userId));
    }

    @GetMapping("/today")
    public ApiResponse<InspirationDrawDto> getToday(
            @RequestHeader(value = "Authorization", required = false) String authorization) {
        Long userId = tokenUtil.extractUserId(authorization);
        return ApiResponse.ok(inspirationService.getToday(userId));
    }

    @PostMapping("/draw")
    public ApiResponse<InspirationDrawDto> draw(
            @RequestHeader(value = "Authorization", required = false) String authorization) {
        Long userId = tokenUtil.extractUserId(authorization);
        return ApiResponse.ok(inspirationService.draw(userId));
    }
}
