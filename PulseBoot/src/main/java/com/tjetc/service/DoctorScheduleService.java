package com.tjetc.service;

import com.tjetc.vo.ScheduleItemDTO;
import com.baomidou.mybatisplus.extension.service.IService;
import com.tjetc.domain.DoctorScheduleSlot;

import java.time.LocalDate;
import java.util.List;

public interface DoctorScheduleService extends IService<DoctorScheduleSlot> {
    List<ScheduleItemDTO> getDoctorSchedule(Integer doctorId);
    List<ScheduleItemDTO> getDoctorScheduleByDateRange(Integer doctorId, LocalDate startDate, LocalDate endDate);

    void askForLeave(Integer doctorId, LocalDate date, String periodType);
    void addShift(Integer doctorId, LocalDate date, String periodType, String roomName);

    /**
     * 交换排班
     * @param fromDoctorId 发起交换的医生
     * @param fromDate 发起者的排班日期
     * @param fromPeriodType 发起者的排班时段
     * @param toDoctorId 目标医生
     * @param toDate 目标医生的排班日期
     * @param toPeriodType 目标医生的排班时段
     */
    void exchangeShift(Integer fromDoctorId, LocalDate fromDate, String fromPeriodType,
                       Integer toDoctorId, LocalDate toDate, String toPeriodType);
}
