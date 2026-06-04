package com.moodwalls.dto;

public class ProfileOverviewDto {

    private Long id;
    private String nickname;
    private String phone;
    private String avatarKey;
    private long postCount;
    private long totalLikes;
    private int streakDays;
    private int activeDays;
    private String moodClimate;
    private WeekStatsDto weekStats;

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getNickname() {
        return nickname;
    }

    public void setNickname(String nickname) {
        this.nickname = nickname;
    }

    public String getPhone() {
        return phone;
    }

    public void setPhone(String phone) {
        this.phone = phone;
    }

    public String getAvatarKey() {
        return avatarKey;
    }

    public void setAvatarKey(String avatarKey) {
        this.avatarKey = avatarKey;
    }

    public long getPostCount() {
        return postCount;
    }

    public void setPostCount(long postCount) {
        this.postCount = postCount;
    }

    public long getTotalLikes() {
        return totalLikes;
    }

    public void setTotalLikes(long totalLikes) {
        this.totalLikes = totalLikes;
    }

    public int getStreakDays() {
        return streakDays;
    }

    public void setStreakDays(int streakDays) {
        this.streakDays = streakDays;
    }

    public int getActiveDays() {
        return activeDays;
    }

    public void setActiveDays(int activeDays) {
        this.activeDays = activeDays;
    }

    public String getMoodClimate() {
        return moodClimate;
    }

    public void setMoodClimate(String moodClimate) {
        this.moodClimate = moodClimate;
    }

    public WeekStatsDto getWeekStats() {
        return weekStats;
    }

    public void setWeekStats(WeekStatsDto weekStats) {
        this.weekStats = weekStats;
    }
}
