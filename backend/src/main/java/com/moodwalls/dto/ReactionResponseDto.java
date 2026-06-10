package com.moodwalls.dto;

import com.fasterxml.jackson.annotation.JsonProperty;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public class ReactionResponseDto {

    private int totalReactions;
 
    @JsonProperty("myReaction")
    private String myReaction;

    private Map<String, Integer> reactionStats = new LinkedHashMap<>();
    private List<TopReactionDto> topReactions;

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

    public Map<String, Integer> getReactionStats() {
        return reactionStats;
    }

    public void setReactionStats(Map<String, Integer> reactionStats) {
        this.reactionStats = reactionStats;
    }

    public List<TopReactionDto> getTopReactions() {
        return topReactions;
    }

    public void setTopReactions(List<TopReactionDto> topReactions) {
        this.topReactions = topReactions;
    }
}
