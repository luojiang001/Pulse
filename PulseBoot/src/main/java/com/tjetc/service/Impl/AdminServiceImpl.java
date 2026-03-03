package com.tjetc.service.Impl;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.tjetc.dao.AdminMapper;
import com.tjetc.domain.Admin;
import com.tjetc.service.AdminService;
import com.tjetc.vo.Result;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional(rollbackFor = Exception.class)
public class AdminServiceImpl extends ServiceImpl<AdminMapper, Admin> implements AdminService {
    @Autowired
    private AdminMapper adminMapper;
    @Override
    public Result login(String username, String password) {
        Result result = new Result();
        Admin admin=adminMapper.findByUsername(username);
        if(admin==null){
            result.setCode(500).setMsg("暂无此账号");
            return result;
        }
        if(!admin.getPassword().equals(password)){
            result.setCode(500).setMsg("密码错误");
            return result;
        }
        result.setCode(200).setMsg("登录成功").setData(admin);
        return result;
    }
}
