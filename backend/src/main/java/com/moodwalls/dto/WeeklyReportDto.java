package com.moodwalls.dto;

import java.util.LinkedHashMap;
import java.util.Map;

public class WeeklyReportDto {

    private String report;
    private Map<String, Integer> moodSummary = new LinkedHashMap<>();
    private int postCount;

    public String getReport() {
        return report;
    }

    public void setReport(String report) {
        this.report = report;
    }

    public Map<String, Integer> getMoodSummary() {
        return moodSummary;
    }

    public void setMoodSummary(Map<String, Integer> moodSummary) {
        this.moodSummary = moodSummary;
    }

    public int getPostCount() {
        return postCount;
    }

    public void setPostCount(int postCount) {
        this.postCount = postCount;
    }
}
