package com.moodwalls.repository;

import com.moodwalls.entity.LocationZoneMapping;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface LocationZoneMappingRepository extends JpaRepository<LocationZoneMapping, Long> {

    Optional<LocationZoneMapping> findByLocationName(String locationName);
}
