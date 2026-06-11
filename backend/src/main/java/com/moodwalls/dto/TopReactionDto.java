package com.moodwalls.dto;

public class TopReactionDto {

    private String type;
    private String label;
    private int count;

    public TopReactionDto() {
    }

    public TopReactionDto(String type, String label, int count) {
        this.type = type;
        this.label = label;
        this.count = count;
    }

    public String getType() {
        return type;
    }

    public void setType(String type) {
        this.type = type;
    }

    public String getLabel() {
        return label;
    }

    public void setLabel(String label) {
        this.label = label;
    }

    public int getCount() {
        return count;
    }

    public void setCount(int count) {
        this.count = count;
    }
}
