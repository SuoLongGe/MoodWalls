package com.moodwalls.dto;

import java.util.ArrayList;
import java.util.List;

public class MoodCurveResponseDto {

    private int days;
    private List<MoodCurvePointDto> points = new ArrayList<>();
    private String summary;

    public int getDays() {
        return days;
    }

    public void setDays(int days) {
        this.days = days;
    }

    public List<MoodCurvePointDto> getPoints() {
        return points;
    }

    public void setPoints(List<MoodCurvePointDto> points) {
        this.points = points;
    }

    public String getSummary() {
        return summary;
    }

    public void setSummary(String summary) {
        this.summary = summary;
    }
}
