package com.moodwalls.dto;

public class LikeResponseDto {

    private int likes;
    private boolean isLiked;

    public LikeResponseDto(int likes, boolean isLiked) {
        this.likes = likes;
        this.isLiked = isLiked;
    }

    public int getLikes() { return likes; }
    public void setLikes(int likes) { this.likes = likes; }

    public boolean isLiked() { return isLiked; }
    public void setLiked(boolean liked) { isLiked = liked; }
}
