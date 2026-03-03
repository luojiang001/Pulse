package com.tjetc.controller;

import com.tjetc.domain.Departments;
import com.tjetc.service.DepartmentsService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/department")
public class DepartmentsController {
@Autowired
DepartmentsService departmentsService;
    @RequestMapping("/list")
    public List<Departments> getlist(){
        return departmentsService.getList();
    }
}
