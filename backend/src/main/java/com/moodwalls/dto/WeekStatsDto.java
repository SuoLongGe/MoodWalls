package com.moodwalls.dto;

public class WeekStatsDto {

    private int calmPercent;
    private int anxiousPercent;
    private int happyPercent;

    public WeekStatsDto() {
    }

    public WeekStatsDto(int calmPercent, int anxiousPercent, int happyPercent) {
        this.calmPercent = calmPercent;
        this.anxiousPercent = anxiousPercent;
        this.happyPercent = happyPercent;
    }

    public int getCalmPercent() {
        return calmPercent;
    }

    public void setCalmPercent(int calmPercent) {
        this.calmPercent = calmPercent;
    }

    public int getAnxiousPercent() {
        return anxiousPercent;
    }

    public void setAnxiousPercent(int anxiousPercent) {
        this.anxiousPercent = anxiousPercent;
    }

    public int getHappyPercent() {
        return happyPercent;
    }

    public void setHappyPercent(int happyPercent) {
        this.happyPercent = happyPercent;
    }
}
