package com.tjetc.repository;

import com.tjetc.domain.Medicine;
import org.springframework.data.repository.CrudRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface MedicineRepository extends CrudRepository<Medicine,Integer> {
    List<Medicine> findByStatus(Integer status);
}
