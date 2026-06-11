package com.moodwalls.dto;

import java.util.ArrayList;
import java.util.List;

public class ZoneStoryResponseDto {

    private String zoneKey;
    private String title;
    private String subtitle;
    private String accent;
    private int postCount;
    private String dominantMood;
    private String dominantMoodLabel;
    private List<MoodBreakdownItemDto> moodBreakdown = new ArrayList<>();
    private String story;
    private String encouragement;

    public String getZoneKey() {
        return zoneKey;
    }

    public void setZoneKey(String zoneKey) {
        this.zoneKey = zoneKey;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getSubtitle() {
        return subtitle;
    }

    public void setSubtitle(String subtitle) {
        this.subtitle = subtitle;
    }

    public String getAccent() {
        return accent;
    }

    public void setAccent(String accent) {
        this.accent = accent;
    }

    public int getPostCount() {
        return postCount;
    }

    public void setPostCount(int postCount) {
        this.postCount = postCount;
    }

    public String getDominantMood() {
        return dominantMood;
    }

    public void setDominantMood(String dominantMood) {
        this.dominantMood = dominantMood;
    }

    public String getDominantMoodLabel() {
        return dominantMoodLabel;
    }

    public void setDominantMoodLabel(String dominantMoodLabel) {
        this.dominantMoodLabel = dominantMoodLabel;
    }

    public List<MoodBreakdownItemDto> getMoodBreakdown() {
        return moodBreakdown;
    }

    public void setMoodBreakdown(List<MoodBreakdownItemDto> moodBreakdown) {
        this.moodBreakdown = moodBreakdown;
    }

    public String getStory() {
        return story;
    }

    public void setStory(String story) {
        this.story = story;
    }

    public String getEncouragement() {
        return encouragement;
    }

    public void setEncouragement(String encouragement) {
        this.encouragement = encouragement;
    }
}
