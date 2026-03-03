package com.tjetc.controller;

import com.github.pagehelper.PageInfo;
import com.tjetc.domain.Category;
import com.tjetc.domain.Medicine;
import com.tjetc.service.MedicineService;
import com.tjetc.vo.Result;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/medicine")
public class MedicineController {
    @Autowired
    private MedicineService medicineService;
    @RequestMapping("/categoryList")
    public List<Category> categoryList(){
        return medicineService.categoryList();
    }
    @RequestMapping("/medicineList")
    public List<Medicine> medicineList(){
        return medicineService.medicineList();
    }

    @RequestMapping("/list")
    public PageInfo<Medicine> list(
            @RequestParam(value = "name",defaultValue = "") String name,
            @RequestParam(value = "pageNum",defaultValue = "1") Integer pageNum,
            @RequestParam(value = "pageSize",defaultValue = "2") Integer pageSize
    ) {
        return medicineService.list(name, pageNum, pageSize);
    }
    @RequestMapping("/save")
    public Result add(@RequestBody Medicine medicine){
        if (medicine.getId()==-1){
            return medicineService.add(medicine);
        }else {
            return medicineService.update(medicine);
        }
    }
    @RequestMapping("/del/{id}")
    public Result delete(@PathVariable Integer id){
        return medicineService.del(id);
    }

    @RequestMapping("/syncEs")
    public Result syncEs(){
        try {
            medicineService.syncEs();
            return new Result().setCode(200).setMsg("ES Data Sync Completed");
        } catch (Exception e) {
            return new Result().setCode(500).setMsg("ES Sync Failed: " + e.getMessage());
        }
    }



}
