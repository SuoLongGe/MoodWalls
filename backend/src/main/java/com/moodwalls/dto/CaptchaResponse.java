package com.moodwalls.dto;

public class CaptchaResponse {

    private String captchaId;
    private String captchaText;

    public CaptchaResponse() {
    }

    public CaptchaResponse(String captchaId, String captchaText) {
        this.captchaId = captchaId;
        this.captchaText = captchaText;
    }

    public String getCaptchaId() {
        return captchaId;
    }

    public void setCaptchaId(String captchaId) {
        this.captchaId = captchaId;
    }

    public String getCaptchaText() {
        return captchaText;
    }

    public void setCaptchaText(String captchaText) {
        this.captchaText = captchaText;
    }
}
