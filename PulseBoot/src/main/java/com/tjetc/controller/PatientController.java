package com.tjetc.controller;

import com.tjetc.domain.Patient;
import com.tjetc.service.PatientService;
import com.tjetc.vo.Result;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/patient")
@CrossOrigin // 允许跨域
public class PatientController {

    @Autowired
    private PatientService patientService;

    /**
     * 列表接口
     * GET /patient/list?userId=1
     */
    @GetMapping("/list")
    public Result list(@RequestParam Integer userId) {
        if (userId == null) {
            return new Result().setCode(400).setMsg("用户ID不能为空");
        }
        List<Patient> list = patientService.getListByUserId(userId);
        return new Result().setCode(200).setMsg("查询成功").setData(list);
    }

    /**
     * 添加接口
     * POST /patient/add
     */
    @PostMapping("/add")
    public Result add(@RequestBody Patient patient) {
        // 简单校验
        if (patient.getUserId() == null || patient.getName() == null || patient.getPhone() == null) {
            return new Result().setCode(400).setMsg("参数不完整");
        }
        
        try {
            boolean success = patientService.addPatient(patient);
            if (success) {
                return new Result().setCode(200).setMsg("添加成功");
            } else {
                return new Result().setCode(500).setMsg("添加失败");
            }
        } catch (Exception e) {
            e.printStackTrace();
            return new Result().setCode(500).setMsg("系统异常: " + e.getMessage());
        }
    }

    /**
     * 删除接口
     * POST /patient/del/{id}
     */
    @PostMapping("/del/{id}")
    public Result del(@PathVariable Integer id) {
        if (id == null) {
            return new Result().setCode(400).setMsg("ID不能为空");
        }
        try {
            boolean success = patientService.removeById(id);
            if (success) {
                return new Result().setCode(200).setMsg("删除成功");
            } else {
                return new Result().setCode(500).setMsg("删除失败，ID可能不存在");
            }
        } catch (Exception e) {
            e.printStackTrace();
            return new Result().setCode(500).setMsg("系统异常: " + e.getMessage());
        }
    }
}