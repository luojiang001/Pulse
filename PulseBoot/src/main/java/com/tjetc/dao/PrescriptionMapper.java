package com.tjetc.dao;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.tjetc.domain.Prescription;
import com.tjetc.domain.PrescriptionMedicine;
import com.tjetc.vo.PrescriptionVO;
import org.apache.ibatis.annotations.*;
import org.apache.ibatis.mapping.FetchType;

import java.util.List;

@Mapper
public interface PrescriptionMapper extends BaseMapper<Prescription> {
    @Insert("insert into prescription (prescription_no, patient_id, doctor_id, msg,create_time) VALUES (#{prescriptionNo} ,#{patientId} ,#{doctorId} ,#{msg},#{createTime}  )")
    @Options(useGeneratedKeys = true, keyProperty = "id")
    int add(Prescription prescription);

    @Insert("insert into prescription_mediclie ( prescription_id, medicine_id, count) VALUES  (#{prescriptId} ,#{medicineId} ,#{count} )")
    int addMedicine(PrescriptionMedicine prescriptionMedicine);

    @Update("UPDATE prescription_mediclie SET used_count = IFNULL(used_count, 0) + #{quantity} WHERE prescription_id = #{prescriptionId} AND medicine_id = #{medicineId}")
    int updateUsedCount(@Param("prescriptionId") Integer prescriptionId, @Param("medicineId") Integer medicineId, @Param("quantity") Integer quantity);

    List<PrescriptionVO> selectByUserId(Integer userId);
}
