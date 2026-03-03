package com.tjetc.repository;

import com.tjetc.domain.Doctors;
import org.springframework.data.repository.CrudRepository;
import org.springframework.stereotype.Repository;

import java.util.List;


@Repository
public interface DoctorRepository extends CrudRepository<Doctors, Integer> {

    // 自定义方法：根据科室名称查询医生列表（Spring Data JPA自动实现，无需写SQL）
    // 命名规则：findBy + 实体类字段名（首字母大写）
    List<Doctors> findByDepartment(String department);
}