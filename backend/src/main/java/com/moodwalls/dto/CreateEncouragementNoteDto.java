package com.moodwalls.dto;

public class CreateEncouragementNoteDto {

    private String content;
    private String mood;

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
}
