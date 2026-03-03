package com.tjetc.controller;

import com.github.pagehelper.PageInfo;
import com.tjetc.domain.Medicine;
import com.tjetc.service.RegistrationRecordService;
import com.tjetc.vo.Registration;
import com.tjetc.vo.RegistrationRecordVO;
import com.tjetc.vo.Result;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;


@RestController
@RequestMapping("registrationRecord")
public class RegistrationRecordController {
    @Autowired
    private RegistrationRecordService registrationRecordService;
    @RequestMapping("list")
    public PageInfo<Registration> list(
            @RequestParam(value = "name",defaultValue = "") String name,
            @RequestParam(value = "pageNum",defaultValue = "1") Integer pageNum,
            @RequestParam(value = "pageSize",defaultValue = "2") Integer pageSize,
            @RequestParam(value = "doctorId", required = false) Integer doctorId
    ) {
        return registrationRecordService.list(name,pageNum,pageSize, doctorId);
    }
    @RequestMapping("/findAll")
    public List<Registration> findAll(
            @RequestParam(value = "doctorId", required = false) Integer doctorId,
            @RequestParam(value = "date", required = false) String date
    ){
        return registrationRecordService.findAll(doctorId, date);
    }
    @RequestMapping("/updateVisitStatus")
    public Result updatesVisitStatus(
            @RequestParam(value = "regNo") String regNo,
            @RequestParam(value = "visitStatus")Integer visitStatus){
        return registrationRecordService.updateVisitStatus(regNo,visitStatus);
    }

    @RequestMapping("/save")
    public Result add(@RequestBody Registration registration){
        if (registration.getId()==null){
            return registrationRecordService.add(registration);
        }else {
            return registrationRecordService.update(registration);
        }
    }
    @RequestMapping("/del/{regNo}")
    public Result delete(@PathVariable("regNo") String regNo){
        return registrationRecordService.del(regNo);
    }

    @RequestMapping("/record/list")
    public Result recordList(@RequestParam("userId") long userId){
        List<RegistrationRecordVO> list = registrationRecordService.getRecordList(userId);
        Result result = new Result();
        result.setCode(200);
        result.setMsg("success");
        result.setData(list);
        return result;
    }
    @GetMapping("/detail/{regNo}")
    public Result detail(@PathVariable("regNo") String regNo) {
        return registrationRecordService.detail(regNo);
    }
}
