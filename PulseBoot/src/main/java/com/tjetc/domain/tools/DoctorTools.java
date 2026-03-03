package com.tjetc.domain.tools;

import com.baomidou.mybatisplus.extension.conditions.query.QueryChainWrapper;
import com.tjetc.domain.DoctorScheduleSlot;
import com.tjetc.domain.Doctors;
import com.tjetc.domain.query.DoctorsQuery;
import com.tjetc.service.DoctorService;
import com.tjetc.vo.DoctorScheduleInfoVO;
import lombok.RequiredArgsConstructor;
import org.springframework.ai.tool.annotation.Tool;
import org.springframework.ai.tool.annotation.ToolParam;
import org.springframework.stereotype.Component;


import java.time.LocalDate;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;

@RequiredArgsConstructor
@Component
public class DoctorTools {

    private final DoctorService doctorService;

    @Tool(description = "根据查询条件查询医生列表")
    public List<Doctors> queryDoctors(@ToolParam(description = "查询条件",required = false) DoctorsQuery query){
        if (query == null){
            return List.of();
        }
        QueryChainWrapper<Doctors> eq = doctorService.query().eq(query.getName() != null, "name", query.getName())
                .eq(query.getDepartment() != null, "department", query.getDepartment())
                .eq(query.getSpecialty() != null, "specialty", query.getSpecialty())
                .eq(query.getTitle() != null, "title", query.getTitle());
        return eq.list();
    }

    @Tool(description = "查询医生及其可预约时段和剩余号源，支持按姓名/科室/专业/职称筛选，可指定日期")
    public List<DoctorScheduleInfoVO> queryDoctorWithSchedule(
            @ToolParam(description = "医生查询条件（姓名/科室/专业/职称）", required = false) DoctorsQuery query,
            @ToolParam(description = "预约日期（可选，格式：yyyy-MM-dd）", required = false) LocalDate scheduleDate
    ) {
        return doctorService.selectDoctorWithSchedule(query, scheduleDate);
    }

    @Tool(description = "获取某位医生的可预约号源详情")
    public String getAvailableAppointments(@ToolParam(description = "医生姓名") String doctorName) {
        DoctorsQuery query = new DoctorsQuery();
        query.setName(doctorName);

        List<DoctorScheduleInfoVO> slots = doctorService.selectDoctorWithSchedule(query, null);

        if (slots.isEmpty()) {
            return "未找到该医生或暂无可预约时段。";
        }

        StringBuilder sb = new StringBuilder();
        sb.append(String.format("%s是%s的%s，目前可以预约。具体可预约时间如下：\n",
                slots.get(0).getName(),
                slots.get(0).getDepartment(),
                slots.get(0).getTitle()));

        for (int i = 0; i < slots.size(); i++) {
            DoctorScheduleInfoVO slot = slots.get(i);
            if (slot.getAvailableCount() > 0) {
                sb.append(String.format("%d. %s（剩余号源：%d）\n", i+1, slot.getTimePeriod(), slot.getAvailableCount()));
            }
        }

        sb.append("请根据自己的时间选择合适的预约时段。");
        return sb.toString();
    }

}
