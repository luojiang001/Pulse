package com.tjetc.controller;

import com.tjetc.service.AdminService;
import com.tjetc.vo.Result;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/admin")
public class AdminController {
    @Autowired
    private AdminService adminService;
    @RequestMapping("/login")
    public Result login(
            @RequestParam("username") String username,
            @RequestParam("password") String password) {
        return adminService.login(username,password);
    }
}
