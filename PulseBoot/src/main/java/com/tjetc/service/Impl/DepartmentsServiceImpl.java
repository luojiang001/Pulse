package com.tjetc.service.Impl;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.tjetc.dao.DepartmentsMapper;
import com.tjetc.domain.Departments;
import com.tjetc.domain.Medicine;
import com.tjetc.repository.DepartmentsRepository;
import com.tjetc.service.DepartmentsService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;

@Service
@Transactional(rollbackFor = Exception.class)
public class DepartmentsServiceImpl extends ServiceImpl<DepartmentsMapper, Departments> implements DepartmentsService {
    @Autowired
    private DepartmentsRepository departmentsRepository;
    @Autowired
    private DepartmentsMapper departmentsMapper;
    @Override
    public List<Departments> getList() {
        Iterable<Departments> departmentsIterable = departmentsRepository.findAll();
        List<Departments> departmentList = new ArrayList<>();
        for (Departments department : departmentsIterable) {
            departmentList.add(department);
        }

        if (!departmentList.isEmpty()) {
            return departmentList;
        }
        departmentList = departmentsMapper.departmentList();
        if (departmentList == null || departmentList.isEmpty()) {
            return List.of();
        }
        departmentsRepository.saveAll(departmentList);
        return departmentList;
    }
}
