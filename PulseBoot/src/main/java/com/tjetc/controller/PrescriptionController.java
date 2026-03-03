package com.tjetc.controller;

import afu.org.checkerframework.checker.igj.qual.I;
import com.tjetc.domain.Prescription;
import com.tjetc.domain.PrescriptionMedicine;
import com.tjetc.service.PrescriptionService;
import com.tjetc.vo.PrescriptionVO;
import com.tjetc.vo.Result;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/prescription")
public class PrescriptionController {
    @Autowired
    private PrescriptionService prescriptionService;
    @RequestMapping("/confirm")
    public Result confirmPrescription(
            @RequestParam("doctorId") Integer doctorId,
            @RequestParam("name") String name,
            @RequestParam("age") Integer age,
            @RequestParam("gender") String gender,
            @RequestParam("msg") String msg
    ){
        return prescriptionService.confirm(doctorId, name,age,gender,msg);
    }
    @RequestMapping("/addPrescriptionMedicine")
    public Result addPrescription(@RequestBody PrescriptionMedicine prescriptionMedicine){
        return prescriptionService.addPrescription(prescriptionMedicine);
    }
    @RequestMapping("/list")
    public Result listPrescription(@RequestParam("userId") Integer userId){
        List<PrescriptionVO> prescriptions = prescriptionService.getByUserId(userId);
        System.out.println(prescriptions);
        return Result.success(prescriptions);
    }
    /*@RequestMapping("/listByPId")
    public Result listPrescription(@RequestParam("userId") Integer userId){
        List<PrescriptionVO> prescriptions = prescriptionService.getByUserId(userId);
        System.out.println(prescriptions);
        return Result.success(prescriptions);
    }*/
}
