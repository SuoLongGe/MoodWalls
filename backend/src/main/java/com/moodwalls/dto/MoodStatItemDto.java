package com.moodwalls.dto;

public class MoodStatItemDto {

    private String mood;
    private String label;
    private String color;
    private int percent;
    private long count;

    public MoodStatItemDto() {
    }

    public MoodStatItemDto(String mood, String label, String color, int percent, long count) {
        this.mood = mood;
        this.label = label;
        this.color = color;
        this.percent = percent;
        this.count = count;
    }

    public String getMood() {
        return mood;
    }

    public void setMood(String mood) {
        this.mood = mood;
    }

    public String getLabel() {
        return label;
    }

    public void setLabel(String label) {
        this.label = label;
    }

    public String getColor() {
        return color;
    }

    public void setColor(String color) {
        this.color = color;
    }

    public int getPercent() {
        return percent;
    }

    public void setPercent(int percent) {
        this.percent = percent;
    }

    public long getCount() {
        return count;
    }

    public void setCount(long count) {
        this.count = count;
    }
}
