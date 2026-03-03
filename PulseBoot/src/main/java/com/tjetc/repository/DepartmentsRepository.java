package com.tjetc.repository;

import com.tjetc.domain.Departments;
import org.springframework.data.repository.CrudRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface DepartmentsRepository extends CrudRepository<Departments, Integer> {
}
