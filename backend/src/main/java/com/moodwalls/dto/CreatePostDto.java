package com.moodwalls.dto;

public class CreatePostDto {

    private String mood;
    private String text;
    private String location;
    private String zoneKey;

    public String getMood() { return mood; }
    public void setMood(String mood) { this.mood = mood; }

    public String getText() { return text; }
    public void setText(String text) { this.text = text; }

    public String getLocation() { return location; }
    public void setLocation(String location) { this.location = location; }

    public String getZoneKey() { return zoneKey; }
    public void setZoneKey(String zoneKey) { this.zoneKey = zoneKey; }
}
