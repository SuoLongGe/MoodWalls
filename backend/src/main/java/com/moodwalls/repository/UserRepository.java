package com.moodwalls.repository;

import com.moodwalls.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface UserRepository extends JpaRepository<User, Long> {

    Optional<User> findByPhone(String phone);

    Optional<User> findByNickname(String nickname);

    boolean existsByPhone(String phone);

    boolean existsByNickname(String nickname);
}
