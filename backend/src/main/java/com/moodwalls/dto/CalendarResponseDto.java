package com.moodwalls.dto;

import java.util.ArrayList;
import java.util.List;

public class CalendarResponseDto {

    private String month;
    private List<CalendarDayDto> days = new ArrayList<>();

    public String getMonth() {
        return month;
    }

    public void setMonth(String month) {
        this.month = month;
    }

    public List<CalendarDayDto> getDays() {
        return days;
    }

    public void setDays(List<CalendarDayDto> days) {
        this.days = days;
    }
}
