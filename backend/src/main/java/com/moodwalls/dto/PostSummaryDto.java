package com.moodwalls.dto;

import com.fasterxml.jackson.annotation.JsonProperty;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public class PostSummaryDto {

    private Long id;
    private Long userId;
    private String nickname;
    private String mood;
    private String moodLabel;
    private String text;
    private String imageUrl;
    private String location;
    private String zoneKey;
    private int likes;
    @JsonProperty("isLiked")
    private boolean isLiked;
    private String color;
    private String createdAt;
    private String timeText;
    private String avatarKey;
    private String avatarUrl;
    @JsonProperty("isMine")
    private boolean isMine;
    private int commentCount;
    private String visibility;
    @JsonProperty("canDelete")
    private boolean canDelete;
    private int totalReactions;
    @JsonProperty("myReaction")
    private String myReaction;
    private List<TopReactionDto> topReactions = new ArrayList<>();
    private Map<String, Integer> reactionStats = new LinkedHashMap<>();
    private int whisperCount;
    private int cloudCount;

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Long getUserId() {
        return userId;
    }

    public void setUserId(Long userId) {
        this.userId = userId;
    }

    public String getNickname() {
        return nickname;
    }

    public void setNickname(String nickname) {
        this.nickname = nickname;
    }

    public String getMood() {
        return mood;
    }

    public void setMood(String mood) {
        this.mood = mood;
    }

    public String getMoodLabel() {
        return moodLabel;
    }

    public void setMoodLabel(String moodLabel) {
        this.moodLabel = moodLabel;
    }

    public String getText() {
        return text;
    }

    public void setText(String text) {
        this.text = text;
    }

    public String getImageUrl() {
        return imageUrl;
    }

    public void setImageUrl(String imageUrl) {
        this.imageUrl = imageUrl;
    }

    public String getLocation() {
        return location;
    }

    public void setLocation(String location) {
        this.location = location;
    }

    public String getZoneKey() {
        return zoneKey;
    }

    public void setZoneKey(String zoneKey) {
        this.zoneKey = zoneKey;
    }

    public int getLikes() {
        return likes;
    }

    public void setLikes(int likes) {
        this.likes = likes;
    }

    public boolean isLiked() {
        return isLiked;
    }

    public void setLiked(boolean liked) {
        isLiked = liked;
    }

    public String getColor() {
        return color;
    }

    public void setColor(String color) {
        this.color = color;
    }

    public String getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(String createdAt) {
        this.createdAt = createdAt;
    }

    public String getTimeText() {
        return timeText;
    }

    public void setTimeText(String timeText) {
        this.timeText = timeText;
    }

    public String getAvatarKey() {
        return avatarKey;
    }

    public void setAvatarKey(String avatarKey) {
        this.avatarKey = avatarKey;
    }

    public String getAvatarUrl() {
        return avatarUrl;
    }

    public void setAvatarUrl(String avatarUrl) {
        this.avatarUrl = avatarUrl;
    }

    public boolean isMine() {
        return isMine;
    }

    public void setMine(boolean mine) {
        isMine = mine;
    }

    public int getCommentCount() {
        return commentCount;
    }

    public void setCommentCount(int commentCount) {
        this.commentCount = commentCount;
    }

    public String getVisibility() {
        return visibility;
    }

    public void setVisibility(String visibility) {
        this.visibility = visibility;
    }

    public boolean isCanDelete() {
        return canDelete;
    }

    public void setCanDelete(boolean canDelete) {
        this.canDelete = canDelete;
    }

    public int getTotalReactions() {
        return totalReactions;
    }

    public void setTotalReactions(int totalReactions) {
        this.totalReactions = totalReactions;
    }

    public String getMyReaction() {
        return myReaction;
    }

    public void setMyReaction(String myReaction) {
        this.myReaction = myReaction;
    }

    public List<TopReactionDto> getTopReactions() {
        return topReactions;
    }

    public void setTopReactions(List<TopReactionDto> topReactions) {
        this.topReactions = topReactions;
    }

    public Map<String, Integer> getReactionStats() {
        return reactionStats;
    }

    public void setReactionStats(Map<String, Integer> reactionStats) {
        this.reactionStats = reactionStats;
    }

    public int getWhisperCount() {
        return whisperCount;
    }

    public void setWhisperCount(int whisperCount) {
        this.whisperCount = whisperCount;
    }

    public int getCloudCount() {
        return cloudCount;
    }

    public void setCloudCount(int cloudCount) {
        this.cloudCount = cloudCount;
    }
}
