package com.tjetc.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.tjetc.domain.ConsultationRoom;
import com.tjetc.vo.Result;

public interface ConsultationRoomService extends IService<ConsultationRoom> {
    Result list(Integer doctorId);

    ConsultationRoom findById(Integer roomId);
}
