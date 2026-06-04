package com.moodwalls.dto;

import java.util.ArrayList;
import java.util.List;

public class MoodStatsDto {

    private String period;
    private long totalPosts;
    private List<MoodStatItemDto> items = new ArrayList<>();

    public String getPeriod() {
        return period;
    }

    public void setPeriod(String period) {
        this.period = period;
    }

    public long getTotalPosts() {
        return totalPosts;
    }

    public void setTotalPosts(long totalPosts) {
        this.totalPosts = totalPosts;
    }

    public List<MoodStatItemDto> getItems() {
        return items;
    }

    public void setItems(List<MoodStatItemDto> items) {
        this.items = items;
    }
}
