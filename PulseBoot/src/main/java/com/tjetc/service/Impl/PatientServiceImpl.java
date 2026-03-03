package com.tjetc.service.Impl;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.tjetc.dao.PatientMapper;
import com.tjetc.domain.Patient;

import com.tjetc.service.PatientService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;

@Service
public class PatientServiceImpl extends ServiceImpl<PatientMapper, Patient> implements PatientService {

    @Autowired
    private PatientMapper patientMapper;

    //获取用户的就诊人列表
    public List<Patient> getListByUserId(Integer userId) {
        return patientMapper.selectByUserId(userId);
    }

    //添加就诊人
    @Transactional
    public boolean addPatient(Patient patient) {
        // 如果新添加的是默认就诊人，先将该用户下其他就诊人设为非默认
        if (Boolean.TRUE.equals(patient.getIsDefault())) {
            patientMapper.clearDefault(patient.getUserId());
        }
        return patientMapper.insert(patient) > 0;
    }
}