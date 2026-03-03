package com.tjetc.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.tjetc.domain.Departments;

import java.util.List;

public interface DepartmentsService extends IService<Departments> {
    List<Departments> getList();
}
