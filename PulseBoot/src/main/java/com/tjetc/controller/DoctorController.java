package com.tjetc.controller;

import com.github.pagehelper.PageInfo;
import com.tjetc.dao.ConsultationRoomMapper;
import com.tjetc.domain.ConsultationRoom;
import com.tjetc.domain.Doctors;
import com.tjetc.domain.Medicine;
import com.tjetc.service.ConsultationRoomService;
import com.tjetc.service.DoctorScheduleService;
import com.tjetc.service.DoctorService;
import com.tjetc.vo.Result;
import com.tjetc.vo.ScheduleItemDTO;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/doctor")
public class DoctorController {
    @Autowired
    private DoctorService doctorService;
    @Autowired
    private DoctorScheduleService doctorScheduleService;
    @Autowired
    private ConsultationRoomService consultationRoomService;
    @RequestMapping("/list")
    public List<Doctors> list(@RequestParam(value = "department", required = false) String department) {
        // Sync doctor reserve status based on schedule
        doctorService.refreshDoctorReserveStatus();

        //如果 department 为空，返回所有医生
        if (department == null || department.isEmpty() || "全部".equals(department)) {
            return doctorService.list();
        }
        //如果 department 有值，按科室查询并返回 List
        return doctorService.findByDepartMentName(department);
    }
    @RequestMapping("/detail")
    public Doctors getDetailById(@RequestParam("id") Integer id) {
         return doctorService.getDetailById(id);
    }

    @GetMapping("/schedule")
    public Result getSchedule(
            @RequestParam("doctorId") Integer doctorId,
            @RequestParam(value = "startDate", required = false) @DateTimeFormat(pattern = "yyyy-MM-dd") LocalDate startDate,
            @RequestParam(value = "endDate", required = false) @DateTimeFormat(pattern = "yyyy-MM-dd") LocalDate endDate
    ) {
        List<ScheduleItemDTO> scheduleList;
        if (startDate != null && endDate != null) {
            scheduleList = doctorScheduleService.getDoctorScheduleByDateRange(doctorId, startDate, endDate);
        } else {
            // 保持原有逻辑，或者默认为未来所有
            scheduleList = doctorScheduleService.getDoctorSchedule(doctorId);
        }

        //封装 Result
        return new Result()
                .setCode(200)
                .setMsg("success")
                .setData(scheduleList);
    }
    @RequestMapping("/login")
    public Result login(@RequestParam("username") String username, @RequestParam("password") String password) {
        return doctorService.login(username,password);
    }
    @RequestMapping("/page")
    public PageInfo<Doctors> list(
            @RequestParam(value = "name",defaultValue = "") String name,
            @RequestParam(value = "pageNum",defaultValue = "1") Integer pageNum,
            @RequestParam(value = "pageSize",defaultValue = "2") Integer pageSize
    ) {
        return doctorService.page(name, pageNum, pageSize);
    }
    @PostMapping("/schedule/leave")
    public Result askForLeave(
            @RequestParam("doctorId") Integer doctorId,
            @RequestParam("date") @DateTimeFormat(pattern = "yyyy-MM-dd") LocalDate date,
            @RequestParam("periodType") String periodType
    ) {
        doctorScheduleService.askForLeave(doctorId, date, periodType);
        return new Result().setCode(200).setMsg("请假成功");
    }

    @PostMapping("/schedule/add")
    public Result addShift(
            @RequestParam("doctorId") Integer doctorId,
            @RequestParam("date") @DateTimeFormat(pattern = "yyyy-MM-dd") LocalDate date,
            @RequestParam("periodType") String periodType,
            @RequestParam(value = "roomId", required = false) Integer roomId
    ) {
        String roomName = null;
        if (roomId != null) {
            ConsultationRoom room = consultationRoomService.findById(roomId);
            if (room != null) {
                roomName = room.getRoomNo();
            }
        }
        doctorScheduleService.addShift(doctorId, date, periodType, roomName);
        return new Result().setCode(200).setMsg("排班成功");
    }

    @PostMapping("/schedule/exchange")
    public Result exchangeShift(
            @RequestParam("fromDoctorId") Integer fromDoctorId,
            @RequestParam("fromDate") @DateTimeFormat(pattern = "yyyy-MM-dd") LocalDate fromDate,
            @RequestParam("fromPeriodType") String fromPeriodType,
            @RequestParam("toDoctorId") Integer toDoctorId,
            @RequestParam(value = "toDate", required = false) @DateTimeFormat(pattern = "yyyy-MM-dd") LocalDate toDate,
            @RequestParam(value = "toPeriodType", required = false) String toPeriodType
    ) {
        doctorScheduleService.exchangeShift(fromDoctorId, fromDate, fromPeriodType, toDoctorId, toDate, toPeriodType);
        return new Result().setCode(200).setMsg("换班成功");
    }

    @GetMapping("/colleagues")
    public Result getColleagues(@RequestParam("doctorId") Integer doctorId) {
        Doctors currentDoctor = doctorService.getDetailById(doctorId);
        if (currentDoctor == null) {
            return new Result().setCode(404).setMsg("医生不存在");
        }
        List<Doctors> colleagues = doctorService.findByDepartMentName(currentDoctor.getDepartment());

        // 如果同科室没有其他医生（只有自己或者为空），则加载所有医生供演示/测试
        if (colleagues == null || colleagues.size() <= 1) {
            colleagues = doctorService.list();
        }

        // 过滤掉自己
        if (colleagues != null) {
            colleagues.removeIf(d -> d.getId().equals(doctorId));
        }

        return new Result().setCode(200).setData(colleagues);
    }
    @RequestMapping("/updatePassword")
    public Result updatePassword(
            @RequestParam("id") Integer id,
            @RequestParam("oldPassword") String oldPassword,
            @RequestParam("newPassword") String newPassword
    ){
        return doctorService.updatePassword(id,oldPassword,newPassword);
    }
    @RequestMapping("/save")
    public Result add(@RequestBody Doctors doctors){
        if (doctors.getId()==-1){
            return doctorService.add(doctors);
        }else {
            return doctorService.update(doctors);
        }
    }
    @RequestMapping("/del/{id}")
    public Result delete(@PathVariable Integer id){
        return doctorService.del(id);
    }

}
