package com.moodwalls.dto;

public class PublishPostResponseDto {

    private PostSummaryDto post;
    private String aiResponse;

    public PostSummaryDto getPost() { return post; }
    public void setPost(PostSummaryDto post) { this.post = post; }

    public String getAiResponse() { return aiResponse; }
    public void setAiResponse(String aiResponse) { this.aiResponse = aiResponse; }
}
