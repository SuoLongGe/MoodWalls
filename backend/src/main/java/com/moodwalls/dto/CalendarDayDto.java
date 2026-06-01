package com.moodwalls.dto;

public class CalendarDayDto {

    private String date;
    private String dominantMood;
    private String color;
    private int postCount;

    public CalendarDayDto() {
    }

    public CalendarDayDto(String date, String dominantMood, String color, int postCount) {
        this.date = date;
        this.dominantMood = dominantMood;
        this.color = color;
        this.postCount = postCount;
    }

    public String getDate() {
        return date;
    }

    public void setDate(String date) {
        this.date = date;
    }

    public String getDominantMood() {
        return dominantMood;
    }

    public void setDominantMood(String dominantMood) {
        this.dominantMood = dominantMood;
    }

    public String getColor() {
        return color;
    }

    public void setColor(String color) {
        this.color = color;
    }

    public int getPostCount() {
        return postCount;
    }

    public void setPostCount(int postCount) {
        this.postCount = postCount;
    }
}
