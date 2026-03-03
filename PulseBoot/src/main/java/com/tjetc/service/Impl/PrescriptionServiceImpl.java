package com.tjetc.service.Impl;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.tjetc.dao.PatientMapper;
import com.tjetc.dao.PrescriptionMapper;
import com.tjetc.domain.Patient;
import com.tjetc.domain.Prescription;
import com.tjetc.domain.PrescriptionMedicine;
import com.tjetc.service.PrescriptionService;
import com.tjetc.utils.SnowflakeIdGenerator;
import com.tjetc.vo.PrescriptionVO;
import com.tjetc.vo.Result;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.xml.crypto.Data;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.Date;
import java.util.List;

@Service
@Transactional(rollbackFor = Exception.class)
public class PrescriptionServiceImpl extends ServiceImpl<PrescriptionMapper, Prescription> implements PrescriptionService {
    private static final DateTimeFormatter DATE_FORMATTER = DateTimeFormatter.ofPattern("yyyyMMdd");
    @Autowired
    private PrescriptionMapper prescriptionMapper;
    @Autowired
    private PatientMapper patientMapper;
    private final SnowflakeIdGenerator snowflakeIdGenerator;
    @Override
    public Result addPrescription(PrescriptionMedicine prescriptionMedicine){
        Result result = new Result();
        int rows= prescriptionMapper.addMedicine(prescriptionMedicine);
        if(rows>0){
            result.setCode(200).setMsg("添加成功");
        }else {
            result.setCode(500).setMsg("添加失败");
        }
        return result;
    }

    @Override
    public List<PrescriptionVO> getByUserId(Integer userId) {
        return prescriptionMapper.selectByUserId(userId);
    }

    @Autowired
    public PrescriptionServiceImpl(SnowflakeIdGenerator snowflakeIdGenerator) {
        if (snowflakeIdGenerator == null) {
            throw new RuntimeException("SnowflakeIdGenerator 注入失败，请检查Spring配置");
        }
        this.snowflakeIdGenerator = snowflakeIdGenerator;
    }

    @Override
    public Result confirm(Integer doctorId, String name, Integer age, String gender, String msg){
        Result result = new Result();
        Patient patient=patientMapper.findByMore(name,age,gender);
        if(patient==null){
            result.setCode(500).setMsg("该患者不存在");
        }
        String patientNo;
        try {
            String datePrefix = LocalDate.now().format(DATE_FORMATTER);
            long uniqueId = snowflakeIdGenerator.nextId();
            patientNo = "PN" + datePrefix + uniqueId;
        } catch (Exception e) {
            throw new RuntimeException("生成挂号单号失败", e);
        }
        Prescription prescription=new Prescription(null,patientNo,patient.getId(),doctorId,msg,new Date());

        int rows =prescriptionMapper.add(prescription);
        if (rows>0){
            result.setCode(200).setMsg("成功").setData(prescription);
        }
        return result;
    }
}
