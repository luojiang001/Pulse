package com.tjetc.controller;

import com.tjetc.dao.ConsultationRoomMapper;
import com.tjetc.domain.ConsultationRoom;
import com.tjetc.service.ConsultationRoomService;
import com.tjetc.vo.Result;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/consultation_room")
public class ConsultationRoomController {

    @Autowired
    private ConsultationRoomService consultationRoomService;

    @GetMapping("/list")
    public Result list(@RequestParam(value = "doctorId", required = false) Integer doctorId) {
        return consultationRoomService.list(doctorId);
    }
}
