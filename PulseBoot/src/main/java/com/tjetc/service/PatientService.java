package com.tjetc.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.tjetc.domain.Patient;

import java.util.List;

public interface PatientService extends IService<Patient> {
    List<Patient> getListByUserId(Integer userId);
    boolean addPatient(Patient patient);
}
