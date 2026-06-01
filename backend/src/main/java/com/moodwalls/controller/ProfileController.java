package com.moodwalls.controller;

import com.moodwalls.dto.ApiResponse;
import com.moodwalls.dto.CalendarResponseDto;
import com.moodwalls.dto.PostListResponseDto;
import com.moodwalls.dto.ProfileOverviewDto;
import com.moodwalls.dto.WeeklyReportDto;
import com.moodwalls.security.JwtAuthSupport;
import com.moodwalls.service.ProfileService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/profile")
public class ProfileController {

    private final ProfileService profileService;
    private final JwtAuthSupport jwtAuthSupport;

    public ProfileController(ProfileService profileService, JwtAuthSupport jwtAuthSupport) {
        this.profileService = profileService;
        this.jwtAuthSupport = jwtAuthSupport;
    }

    @GetMapping
    public ApiResponse<ProfileOverviewDto> overview(
            @RequestHeader(value = "Authorization", required = false) String authorization) {
        Long userId = jwtAuthSupport.requireUserId(authorization);
        return ApiResponse.ok(profileService.getOverview(userId));
    }

    @GetMapping("/calendar")
    public ApiResponse<CalendarResponseDto> calendar(
            @RequestHeader(value = "Authorization", required = false) String authorization,
            @RequestParam(value = "month", required = false) String month) {
        Long userId = jwtAuthSupport.requireUserId(authorization);
        return ApiResponse.ok(profileService.getCalendar(userId, month));
    }

    @GetMapping("/posts")
    public ApiResponse<PostListResponseDto> myPosts(
            @RequestHeader(value = "Authorization", required = false) String authorization,
            @RequestParam(value = "page", defaultValue = "1") int page,
            @RequestParam(value = "size", defaultValue = "20") int size) {
        Long userId = jwtAuthSupport.requireUserId(authorization);
        return ApiResponse.ok(profileService.getMyPosts(userId, page, size));
    }

    @GetMapping("/weekly-report")
    public ApiResponse<WeeklyReportDto> weeklyReport(
            @RequestHeader(value = "Authorization", required = false) String authorization) {
        Long userId = jwtAuthSupport.requireUserId(authorization);
        return ApiResponse.ok(profileService.getWeeklyReport(userId));
    }
}
