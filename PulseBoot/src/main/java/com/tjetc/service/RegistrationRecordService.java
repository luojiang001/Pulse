package com.tjetc.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.github.pagehelper.PageInfo;
import com.tjetc.domain.RegistrationRecord;
import com.tjetc.vo.Registration;
import com.tjetc.vo.RegistrationRecordVO;
import com.tjetc.vo.Result;

import java.util.List;

public interface RegistrationRecordService {

//    PageInfo<Registration> list(String name, Integer pageNum, Integer pageSize);

    List<Registration> findAll(Integer doctorId, String date);

    Result updateVisitStatus(String regNo, Integer visitStatus);

    Result add(Registration registration);

    Result update(Registration registration);

    List<RegistrationRecordVO> getRecordList(long userId);

    Result del(String regNo);

    void clearListCache();

    Result detail(String regNo);

    PageInfo<Registration> list(String name, Integer pageNum, Integer pageSize, Integer doctorId);
}
