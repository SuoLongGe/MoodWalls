package com.moodwalls.dto;

public class TodayStatsDto {

    private int anxiousPercent;
    private int calmPercent;
    private int happyPercent;
    private long totalPosts;

    public int getAnxiousPercent() { return anxiousPercent; }
    public void setAnxiousPercent(int anxiousPercent) { this.anxiousPercent = anxiousPercent; }

    public int getCalmPercent() { return calmPercent; }
    public void setCalmPercent(int calmPercent) { this.calmPercent = calmPercent; }

    public int getHappyPercent() { return happyPercent; }
    public void setHappyPercent(int happyPercent) { this.happyPercent = happyPercent; }

    public long getTotalPosts() { return totalPosts; }
    public void setTotalPosts(long totalPosts) { this.totalPosts = totalPosts; }
}
