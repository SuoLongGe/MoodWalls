package com.moodwalls.service;

import com.moodwalls.exception.BusinessException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

@Service
public class EmailService {

    private static final Logger log = LoggerFactory.getLogger(EmailService.class);

    private final JavaMailSender mailSender;
    private final String fromAddress;
    private final boolean enabled;

    public EmailService(
            JavaMailSender mailSender,
            @Value("${moodwalls.mail.from}") String fromAddress,
            @Value("${moodwalls.mail.enabled:true}") boolean enabled) {
        this.mailSender = mailSender;
        this.fromAddress = fromAddress;
        this.enabled = enabled;
    }

    public void sendVerificationCode(String toEmail, String code, String scene) {
        if (!enabled) {
            throw new BusinessException(503, "邮件服务未配置，请联系管理员");
        }
        String sceneText = "register".equals(scene) ? "注册"
                : ("bind_email".equals(scene) ? "绑定邮箱" : "登录");
        SimpleMailMessage message = new SimpleMailMessage();
        message.setFrom(fromAddress);
        message.setTo(toEmail);
        message.setSubject("【校园心灵墙 MoodWalls】邮箱验证码");
        message.setText(
                "您好！\n\n"
                        + "您正在进行" + sceneText + "验证，验证码为：" + code + "\n"
                        + "验证码 5 分钟内有效，请勿泄露给他人。\n\n"
                        + "如非本人操作，请忽略本邮件。\n"
                        + "—— 校园心灵墙 MoodWalls"
        );
        try {
            mailSender.send(message);
            log.info("Verification email sent to {}", maskEmail(toEmail));
        } catch (Exception ex) {
            log.error("Failed to send verification email to {}", maskEmail(toEmail), ex);
            throw new BusinessException(500, "验证码邮件发送失败，请稍后重试");
        }
    }

    private String maskEmail(String email) {
        if (email == null || !email.contains("@")) {
            return "***";
        }
        int at = email.indexOf('@');
        if (at <= 1) {
            return "*" + email.substring(at);
        }
        return email.charAt(0) + "***" + email.substring(at);
    }
}
