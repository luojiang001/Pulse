package com.tjetc.service.Impl;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.tjetc.dao.ConsultationRoomMapper;
import com.tjetc.domain.ConsultationRoom;
import com.tjetc.service.ConsultationRoomService;
import com.tjetc.vo.Result;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@Transactional(rollbackFor = Exception.class)
public class ConsultationRoomServiceImpl extends ServiceImpl<ConsultationRoomMapper, ConsultationRoom> implements ConsultationRoomService {
    @Autowired
    private ConsultationRoomMapper consultationRoomMapper;
    @Override
    public ConsultationRoom findById(Integer id) {
        return consultationRoomMapper.findById(id);
    }
    @Override
    public Result list(Integer doctorId){
        List<ConsultationRoom> list;
        if (doctorId != null) {
            list = consultationRoomMapper.findByDoctorId(doctorId);
        } else {
            list = consultationRoomMapper.findAll();
        }
        return new Result().setCode(200).setMsg("success").setData(list);
    }
}
