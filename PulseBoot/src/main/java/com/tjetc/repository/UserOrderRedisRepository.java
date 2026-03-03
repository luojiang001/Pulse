package com.tjetc.repository;


import com.github.pagehelper.IPage;
import com.tjetc.domain.UserOrderCache;
import org.springframework.data.domain.Page;
import org.springframework.data.repository.CrudRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface UserOrderRedisRepository extends CrudRepository<UserOrderCache, Long> {
}