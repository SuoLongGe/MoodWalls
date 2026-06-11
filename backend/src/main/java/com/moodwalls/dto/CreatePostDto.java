package com.moodwalls.dto;

public class CreatePostDto {

    private String mood;
    private String text;
    private String location;
    private String zoneKey;
    private String imageBase64;

    public String getMood() { return mood; }
    public void setMood(String mood) { this.mood = mood; }

    public String getText() { return text; }
    public void setText(String text) { this.text = text; }

    public String getLocation() { return location; }
    public void setLocation(String location) { this.location = location; }

    public String getZoneKey() { return zoneKey; }
    public void setZoneKey(String zoneKey) { this.zoneKey = zoneKey; }

    public String getImageBase64() { return imageBase64; }
    public void setImageBase64(String imageBase64) { this.imageBase64 = imageBase64; }
}
