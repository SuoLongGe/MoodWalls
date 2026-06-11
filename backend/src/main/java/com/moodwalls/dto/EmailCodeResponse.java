package com.moodwalls.dto;

public class EmailCodeResponse {

    private String codeId;
    private int expireSeconds;

    public EmailCodeResponse() {
    }

    public EmailCodeResponse(String codeId, int expireSeconds) {
        this.codeId = codeId;
        this.expireSeconds = expireSeconds;
    }

    public String getCodeId() {
        return codeId;
    }

    public void setCodeId(String codeId) {
        this.codeId = codeId;
    }

    public int getExpireSeconds() {
        return expireSeconds;
    }

    public void setExpireSeconds(int expireSeconds) {
        this.expireSeconds = expireSeconds;
    }
}
