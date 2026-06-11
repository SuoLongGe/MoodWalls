package com.moodwalls.dto;

import com.fasterxml.jackson.annotation.JsonProperty;

public class InspirationDrawDto {

    @JsonProperty("alreadyDrawn")
    private boolean alreadyDrawn;
    private String content;
    private String mood;
    private String moodLabel;
    private String moodColor;
    private String source;
    private String drawnAt;
    private int remainingToday;

    public boolean isAlreadyDrawn() {
        return alreadyDrawn;
    }

    public void setAlreadyDrawn(boolean alreadyDrawn) {
        this.alreadyDrawn = alreadyDrawn;
    }

    public String getContent() {
        return content;
    }

    public void setContent(String content) {
        this.content = content;
    }

    public String getMood() {
        return mood;
    }

    public void setMood(String mood) {
        this.mood = mood;
    }

    public String getMoodLabel() {
        return moodLabel;
    }

    public void setMoodLabel(String moodLabel) {
        this.moodLabel = moodLabel;
    }

    public String getMoodColor() {
        return moodColor;
    }

    public void setMoodColor(String moodColor) {
        this.moodColor = moodColor;
    }

    public String getSource() {
        return source;
    }

    public void setSource(String source) {
        this.source = source;
    }

    public String getDrawnAt() {
        return drawnAt;
    }

    public void setDrawnAt(String drawnAt) {
        this.drawnAt = drawnAt;
    }

    public int getRemainingToday() {
        return remainingToday;
    }

    public void setRemainingToday(int remainingToday) {
        this.remainingToday = remainingToday;
    }
}
