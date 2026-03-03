package com.tjetc.repository;

import com.tjetc.vo.Registration;
import org.springframework.data.repository.CrudRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface RegistrationRepository extends CrudRepository<Registration,Integer> {

    void deleteByRegNo(String regNo);
}
