package com.tjetc.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.tjetc.domain.Prescription;
import com.tjetc.domain.PrescriptionMedicine;
import com.tjetc.vo.PrescriptionVO;
import com.tjetc.vo.Result;

import java.util.List;

public interface PrescriptionService extends IService<Prescription> {
    Result confirm(Integer doctorId, String name, Integer age, String gender, String msg);

    Result addPrescription(PrescriptionMedicine prescriptionMedicine);

    List<PrescriptionVO> getByUserId(Integer userId);
}
