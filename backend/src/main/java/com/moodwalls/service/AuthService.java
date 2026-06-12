package com.moodwalls.service;



import com.moodwalls.dto.AuthResponse;

import com.moodwalls.dto.CaptchaResponse;

import com.moodwalls.dto.ChangePasswordRequest;

import com.moodwalls.dto.EmailCodeResponse;

import com.moodwalls.dto.EmailLoginRequest;

import com.moodwalls.dto.LoginRequest;

import com.moodwalls.dto.RegisterRequest;

import com.moodwalls.dto.SendEmailCodeRequest;

import com.moodwalls.dto.UpdateProfileRequest;

import com.moodwalls.dto.UserProfile;

import com.moodwalls.entity.User;

import com.moodwalls.exception.BusinessException;

import com.moodwalls.repository.UserRepository;

import com.moodwalls.security.JwtTokenProvider;

import org.springframework.security.crypto.password.PasswordEncoder;

import org.springframework.stereotype.Service;

import org.springframework.transaction.annotation.Transactional;



import java.util.Optional;

import java.util.regex.Pattern;



@Service

public class AuthService {



    private static final Pattern PHONE_PATTERN = Pattern.compile("^1\\d{10}$");

    private static final Pattern EMAIL_PATTERN =

            Pattern.compile("^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$");



    private final UserRepository userRepository;

    private final PasswordEncoder passwordEncoder;

    private final JwtTokenProvider jwtTokenProvider;

    private final CaptchaService captchaService;

    private final EmailVerificationService emailVerificationService;

    private final PostImageStorageService postImageStorageService;



    private static final Pattern AVATAR_KEY_PATTERN = Pattern.compile("^avatar_\\d{2}$");



    public AuthService(

            UserRepository userRepository,

            PasswordEncoder passwordEncoder,

            JwtTokenProvider jwtTokenProvider,

            CaptchaService captchaService,

            EmailVerificationService emailVerificationService,

            PostImageStorageService postImageStorageService) {

        this.userRepository = userRepository;

        this.passwordEncoder = passwordEncoder;

        this.jwtTokenProvider = jwtTokenProvider;

        this.captchaService = captchaService;

        this.emailVerificationService = emailVerificationService;

        this.postImageStorageService = postImageStorageService;

    }



    public CaptchaResponse createCaptcha() {

        return captchaService.createCaptcha();

    }



    public EmailCodeResponse sendEmailCode(SendEmailCodeRequest request) {

        return emailVerificationService.sendCode(request.getEmail(), request.getScene());

    }



    @Transactional

    public AuthResponse register(RegisterRequest request) {

        String email = EmailVerificationService.normalizeEmail(request.getEmail());

        if (userRepository.existsByEmail(email)) {

            throw new BusinessException(409, "该邮箱已注册");

        }

        if (userRepository.existsByNickname(request.getNickname().trim())) {

            throw new BusinessException(409, "该昵称已被使用");

        }

        String phone = request.getPhone().trim();

        if (!PHONE_PATTERN.matcher(phone).matches()) {

            throw new BusinessException(400, "手机号格式不正确");

        }

        if (userRepository.existsByPhone(phone)) {

            throw new BusinessException(409, "该手机号已注册");

        }

        emailVerificationService.verify(

                request.getEmailCodeId(),

                email,

                request.getEmailCode(),

                "register"

        );



        User user = new User();

        user.setNickname(request.getNickname().trim());

        user.setPhone(phone);

        user.setEmail(email);

        user.setPasswordHash(passwordEncoder.encode(request.getPassword()));

        String avatarKey = request.getAvatarKey();

        user.setAvatarKey(avatarKey == null || avatarKey.isBlank() ? "avatar_01" : avatarKey.trim());

        if (request.getAvatarBase64() != null && !request.getAvatarBase64().isBlank()) {

            user.setAvatarUrl(postImageStorageService.saveBase64Avatar(request.getAvatarBase64()));

        }



        User saved = userRepository.save(user);

        String token = jwtTokenProvider.generateToken(saved.getId(), resolveTokenSubject(saved));

        return new AuthResponse(token, UserProfile.from(saved));

    }



    public AuthResponse login(LoginRequest request) {

        User user = findUserByAccount(request.getAccount())

                .orElseThrow(() -> new BusinessException(401, "账号或密码错误"));



        if (!passwordEncoder.matches(request.getPassword(), user.getPasswordHash())) {

            throw new BusinessException(401, "账号或密码错误");

        }



        String token = jwtTokenProvider.generateToken(user.getId(), resolveTokenSubject(user));

        return new AuthResponse(token, UserProfile.from(user));

    }



    public AuthResponse loginByEmail(EmailLoginRequest request) {

        String email = EmailVerificationService.normalizeEmail(request.getEmail());

        emailVerificationService.verify(request.getCodeId(), email, request.getCode(), "login");

        User user = userRepository.findByEmail(email)

                .orElseThrow(() -> new BusinessException(404, "该邮箱尚未注册"));



        String token = jwtTokenProvider.generateToken(user.getId(), resolveTokenSubject(user));

        return new AuthResponse(token, UserProfile.from(user));

    }



    public UserProfile getProfile(Long userId) {

        User user = userRepository.findById(userId)

                .orElseThrow(() -> new BusinessException(404, "用户不存在"));

        return UserProfile.from(user);

    }



    @Transactional

    public UserProfile updateProfile(Long userId, UpdateProfileRequest request) {

        User user = userRepository.findById(userId)

                .orElseThrow(() -> new BusinessException(404, "用户不存在"));

        String nickname = request.getNickname().trim();

        if (userRepository.existsByNicknameAndIdNot(nickname, userId)) {

            throw new BusinessException(409, "该昵称已被使用");

        }

        user.setNickname(nickname);

        applyPhoneUpdate(user, userId, request.getPhone());

        applyEmailUpdate(user, userId, request.getEmail(), request.getEmailCodeId(), request.getEmailCode());

        if (request.getAvatarBase64() != null && !request.getAvatarBase64().isBlank()) {

            user.setAvatarUrl(postImageStorageService.saveBase64Avatar(request.getAvatarBase64()));

        } else if (request.getAvatarKey() != null && !request.getAvatarKey().isBlank()) {

            String avatarKey = request.getAvatarKey().trim();

            if (!AVATAR_KEY_PATTERN.matcher(avatarKey).matches()) {

                throw new BusinessException(400, "头像标识不合法");

            }

            user.setAvatarKey(avatarKey);

            user.setAvatarUrl(null);

        }

        return UserProfile.from(userRepository.save(user));

    }



    @Transactional

    public void changePassword(Long userId, ChangePasswordRequest request) {

        User user = userRepository.findById(userId)

                .orElseThrow(() -> new BusinessException(404, "用户不存在"));

        if (!passwordEncoder.matches(request.getOldPassword(), user.getPasswordHash())) {

            throw new BusinessException(400, "原密码不正确");

        }

        user.setPasswordHash(passwordEncoder.encode(request.getNewPassword()));

        userRepository.save(user);

    }



    private Optional<User> findUserByAccount(String account) {

        String trimmed = account.trim();

        if (EMAIL_PATTERN.matcher(trimmed).matches()) {

            return userRepository.findByEmail(trimmed.toLowerCase());

        }

        if (PHONE_PATTERN.matcher(trimmed).matches()) {

            return userRepository.findByPhone(trimmed);

        }

        return userRepository.findByNickname(trimmed);

    }



    private String resolveTokenSubject(User user) {

        if (user.getEmail() != null && !user.getEmail().isBlank()) {

            return user.getEmail();

        }

        if (user.getPhone() != null && !user.getPhone().isBlank()) {

            return user.getPhone();

        }

        return String.valueOf(user.getId());

    }

    private void applyPhoneUpdate(User user, Long userId, String phone) {

        if (phone == null || phone.isBlank()) {

            return;

        }

        String normalized = phone.trim();

        if (!PHONE_PATTERN.matcher(normalized).matches()) {

            throw new BusinessException(400, "手机号格式不正确");

        }

        String current = user.getPhone();

        if (current != null && current.equals(normalized)) {

            return;

        }

        if (userRepository.existsByPhoneAndIdNot(normalized, userId)) {

            throw new BusinessException(409, "该手机号已被其他账号使用");

        }

        user.setPhone(normalized);

    }

    private void applyEmailUpdate(User user, Long userId, String email, String emailCodeId, String emailCode) {

        if (email == null || email.isBlank()) {

            return;

        }

        String normalized = EmailVerificationService.normalizeEmail(email);

        String current = user.getEmail();

        if (current != null && current.equalsIgnoreCase(normalized)) {

            return;

        }

        if (userRepository.existsByEmailAndIdNot(normalized, userId)) {

            throw new BusinessException(409, "该邮箱已被其他账号使用");

        }

        if (emailCodeId == null || emailCodeId.isBlank() || emailCode == null || emailCode.isBlank()) {

            throw new BusinessException(400, "更换邮箱请先获取并填写验证码");

        }

        emailVerificationService.verify(emailCodeId, normalized, emailCode, "bind_email");

        user.setEmail(normalized);

    }

}


