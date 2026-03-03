package com.tjetc.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.github.pagehelper.PageInfo;
import com.tjetc.domain.DoctorScheduleSlot;
import com.tjetc.domain.Doctors;
import com.tjetc.domain.Medicine;
import com.tjetc.domain.query.DoctorsQuery;
import com.tjetc.vo.DoctorScheduleInfoVO;
import com.tjetc.vo.Result;

import java.time.LocalDate;
import java.util.List;

public interface DoctorService extends IService<Doctors> {
    List<Doctors> list();

    List<Doctors> findByDepartMentName(String department);

    Doctors getDetailById(Integer id);

    Result login(String username, String password);

    PageInfo<Doctors> page(String name, Integer pageNum, Integer pageSize);

    Result updatePassword(Integer id, String oldPassword, String newPassword);

    List<DoctorScheduleInfoVO> selectDoctorWithSchedule(DoctorsQuery query, LocalDate scheduleDate);

    void refreshDoctorReserveStatus();

    Result update(Doctors doctors);

    Result add(Doctors doctors);

    Result del(Integer id);
}
