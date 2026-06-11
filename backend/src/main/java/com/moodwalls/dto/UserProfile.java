package com.moodwalls.dto;

import com.moodwalls.entity.User;
import com.moodwalls.util.MoodHelper;

public class UserProfile {

    private Long id;
    private String nickname;
    private String phone;
    private String email;
    private String studentId;
    private String avatarKey;
    private String avatarUrl;

    public UserProfile() {
    }

    public UserProfile(Long id, String nickname, String phone, String email, String studentId,
                       String avatarKey, String avatarUrl) {
        this.id = id;
        this.nickname = nickname;
        this.phone = phone;
        this.email = email;
        this.studentId = studentId;
        this.avatarKey = avatarKey;
        this.avatarUrl = avatarUrl;
    }

    public static UserProfile from(User user) {
        String key = user.getAvatarKey();
        if (key == null || key.isBlank()) {
            key = "avatar_01";
        }
        return new UserProfile(
                user.getId(),
                user.getNickname(),
                MoodHelper.maskPhone(user.getPhone()),
                MoodHelper.maskEmail(user.getEmail()),
                user.getStudentId(),
                key,
                user.getAvatarUrl()
        );
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getNickname() {
        return nickname;
    }

    public void setNickname(String nickname) {
        this.nickname = nickname;
    }

    public String getPhone() {
        return phone;
    }

    public void setPhone(String phone) {
        this.phone = phone;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getStudentId() {
        return studentId;
    }

    public void setStudentId(String studentId) {
        this.studentId = studentId;
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
}
