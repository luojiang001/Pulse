package com.tjetc.repository;
import com.tjetc.domain.DoctorScheduleCache;
import org.springframework.data.repository.CrudRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface DoctorScheduleRedisRepository extends CrudRepository<DoctorScheduleCache, Integer> {
}