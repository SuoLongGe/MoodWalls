package com.moodwalls.repository;

import com.moodwalls.entity.CampusZone;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface CampusZoneRepository extends JpaRepository<CampusZone, Long> {

    Optional<CampusZone> findByZoneKey(String zoneKey);

    List<CampusZone> findByStatusOrderBySortOrderAsc(Integer status);
}
