package com.moodwalls.dto;

import com.moodwalls.entity.User;

public class UserProfile {

    private Long id;
    private String nickname;
    private String phone;
    private String studentId;

    public UserProfile() {
    }

    public UserProfile(Long id, String nickname, String phone, String studentId) {
        this.id = id;
        this.nickname = nickname;
        this.phone = phone;
        this.studentId = studentId;
    }

    public static UserProfile from(User user) {
        return new UserProfile(
                user.getId(),
                user.getNickname(),
                maskPhone(user.getPhone()),
                user.getStudentId()
        );
    }

    private static String maskPhone(String phone) {
        if (phone == null || phone.length() < 7) {
            return phone;
        }
        return phone.substring(0, 3) + "****" + phone.substring(phone.length() - 4);
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

    public String getStudentId() {
        return studentId;
    }

    public void setStudentId(String studentId) {
        this.studentId = studentId;
    }
}
