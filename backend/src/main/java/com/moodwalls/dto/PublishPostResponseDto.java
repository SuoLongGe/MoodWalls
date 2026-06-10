package com.moodwalls.dto;

public class PublishPostResponseDto {

    private PostSummaryDto post;
    private String aiResponse;
    private int riskLevel;
    private String comfortNote;

    public PostSummaryDto getPost() { return post; }
    public void setPost(PostSummaryDto post) { this.post = post; }

    public String getAiResponse() { return aiResponse; }
    public void setAiResponse(String aiResponse) { this.aiResponse = aiResponse; }

    public int getRiskLevel() { return riskLevel; }
    public void setRiskLevel(int riskLevel) { this.riskLevel = riskLevel; }

    public String getComfortNote() { return comfortNote; }
    public void setComfortNote(String comfortNote) { this.comfortNote = comfortNote; }
}
