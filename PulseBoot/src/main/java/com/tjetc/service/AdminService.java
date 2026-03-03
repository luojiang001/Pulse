package com.tjetc.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.tjetc.domain.Admin;
import com.tjetc.vo.Result;

public interface AdminService extends IService<Admin> {
    Result login(String username, String password);
}
