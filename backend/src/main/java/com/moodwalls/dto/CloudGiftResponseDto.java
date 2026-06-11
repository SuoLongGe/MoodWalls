package com.moodwalls.dto;

public class CloudGiftResponseDto {

    private int cloudCount;
    private boolean sent;

    public int getCloudCount() {
        return cloudCount;
    }

    public void setCloudCount(int cloudCount) {
        this.cloudCount = cloudCount;
    }

    public boolean isSent() {
        return sent;
    }

    public void setSent(boolean sent) {
        this.sent = sent;
    }
}
