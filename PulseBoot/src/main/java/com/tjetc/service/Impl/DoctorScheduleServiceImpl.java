package com.tjetc.service.Impl;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.tjetc.dao.ConsultationRoomMapper;
import com.tjetc.dao.DoctorScheduleMapper;
import com.tjetc.dao.RegistrationMapper;
import com.tjetc.domain.ConsultationRoom;
import com.tjetc.domain.DoctorScheduleCache;
import com.tjetc.domain.DoctorScheduleSlot;
import com.tjetc.repository.DoctorScheduleRedisRepository;
import com.tjetc.service.DoctorScheduleService;
import com.tjetc.service.RegistrationRecordService;
import com.tjetc.vo.Result;
import com.tjetc.vo.ScheduleItemDTO;
import com.tjetc.vo.TimeSlotDTO;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.data.redis.core.ScanOptions;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.format.TextStyle;
import java.util.*;
import java.util.stream.Collectors;

@Service
@Transactional(rollbackFor = Exception.class)
public class DoctorScheduleServiceImpl extends ServiceImpl<DoctorScheduleMapper, DoctorScheduleSlot> implements DoctorScheduleService {
    @Autowired
    private DoctorScheduleMapper doctorScheduleMapper;
    @Autowired
    private RegistrationMapper registrationMapper;
    @Autowired
    private RegistrationRecordService registrationRecordService;
    @Autowired
    private ConsultationRoomMapper consultationRoomMapper;
    @Autowired
    private DoctorScheduleRedisRepository redisRepository;
    @Autowired
    private RedisTemplate<String, Object> redisTemplate;
    @Override
    public List<ScheduleItemDTO> getDoctorSchedule(Integer doctorId) {
        // 从Redis获取
        Optional<DoctorScheduleCache> cacheOpt = redisRepository.findById(doctorId);
        if (cacheOpt.isPresent()) {
            return cacheOpt.get().getScheduleList();
        }

        // 查询数据库 (查询未来所有排班)
        List<DoctorScheduleSlot> rawSlots = doctorScheduleMapper.selectFutureSchedules(doctorId, LocalDate.now());
        List<ScheduleItemDTO> result = convertToDTO(doctorId, rawSlots);

        // 存入Redis
        if (!result.isEmpty()) {
            DoctorScheduleCache cache = new DoctorScheduleCache();
            cache.setDoctorId(doctorId);
            cache.setScheduleList(result);
            redisRepository.save(cache);
        }

        return result;
    }

    @Override
    public List<ScheduleItemDTO> getDoctorScheduleByDateRange(Integer doctorId, LocalDate startDate, LocalDate endDate) {
        // 优化：如果查询范围完全在未来（含今天），则复用 getDoctorSchedule 的缓存逻辑
        if (!startDate.isBefore(LocalDate.now())) {
            List<ScheduleItemDTO> allFuture = getDoctorSchedule(doctorId);
            return allFuture.stream()
                    .filter(item -> {
                        LocalDate itemDate = LocalDate.parse(item.getDate());
                        return !itemDate.isBefore(startDate) && !itemDate.isAfter(endDate);
                    })
                    .collect(Collectors.toList());
        }

        // 如果查询包含过去的时间，则直接查数据库（不走缓存）
        List<DoctorScheduleSlot> rawSlots = doctorScheduleMapper.selectSchedulesByDateRange(doctorId, startDate, endDate);
        return convertToDTO(doctorId, rawSlots);
    }

    /**
     * 通用转换方法：将 DB 实体转换为 DTO，并填充诊室信息
     */
    private List<ScheduleItemDTO> convertToDTO(Integer doctorId, List<DoctorScheduleSlot> rawSlots) {
        // 查询默认诊室信息（作为兜底）
        List<ConsultationRoom> rooms = consultationRoomMapper.findByDoctorId(doctorId);
        String defaultRoomName = (rooms != null && !rooms.isEmpty()) ? rooms.get(0).getRoomNo() : "";

        Map<LocalDate, List<DoctorScheduleSlot>> groupedByDate = rawSlots.stream()
                .collect(Collectors.groupingBy(
                        DoctorScheduleSlot::getWorkDate,
                        LinkedHashMap::new,
                        Collectors.toList()
                ));

        List<ScheduleItemDTO> result = new ArrayList<>();
        for (Map.Entry<LocalDate, List<DoctorScheduleSlot>> entry : groupedByDate.entrySet()) {
            LocalDate date = entry.getKey();
            List<DoctorScheduleSlot> slots = entry.getValue();

            ScheduleItemDTO scheduleItem = new ScheduleItemDTO();
            scheduleItem.setDate(date.toString());
            scheduleItem.setWeek("周" + date.getDayOfWeek().getDisplayName(TextStyle.NARROW, Locale.CHINA));

            // 确定该天的主诊室（优先显示排班中出现的第一个特定诊室）
            String currentRoom = defaultRoomName;
            for (DoctorScheduleSlot slot : slots) {
                if (slot.getRoomName() != null && !slot.getRoomName().isEmpty()) {
                    currentRoom = slot.getRoomName();
                    break;
                }
            }
            scheduleItem.setRoom(currentRoom);

            List<TimeSlotDTO> timeSlots = slots.stream()
                    .map(slot -> new TimeSlotDTO(
                            slot.getTimePeriod(),
                            slot.getIsAvailable(),
                            (slot.getRoomName() != null && !slot.getRoomName().isEmpty()) ? slot.getRoomName() : defaultRoomName
                    ))
                    .collect(Collectors.toList());

            scheduleItem.setTimes(timeSlots);
            result.add(scheduleItem);
        }
        return result;
    }

    public void evictCache(Integer doctorId) {
        try {
            redisRepository.deleteById(doctorId);
        } catch (Exception e) {
            System.err.println("Failed to evict Redis cache: " + e.getMessage());
        }
    }

    @Override
    public void askForLeave(Integer doctorId, LocalDate date, String periodType) {
        List<String> periods = getPeriodsByType(periodType);
        if (!periods.isEmpty()) {
            int rows = doctorScheduleMapper.updateScheduleStatus(doctorId, date, periods, 0);
            System.out.println("Updated " + rows + " rows for doctor " + doctorId + " on " + date);
            // 清除缓存
            evictCache(doctorId);
        }
    }

    @Override
    public void addShift(Integer doctorId, LocalDate date, String periodType, String roomName) {
        List<String> periods = getPeriodsByType(periodType);
        if (!periods.isEmpty()) {
            // 先删除已有的排班记录，防止重复（特别是当缺少唯一约束时）
            try {
                doctorScheduleMapper.deleteSchedules(doctorId, date, periods);
            } catch (Exception e) {
                System.err.println("Warning: failed to delete existing schedules: " + e.getMessage());
            }

            List<DoctorScheduleSlot> slots = new ArrayList<>();
            for (String period : periods) {
                DoctorScheduleSlot slot = new DoctorScheduleSlot();
                slot.setDoctorId(doctorId);
                slot.setWorkDate(date);
                slot.setTimePeriod(period);
                slot.setIsAvailable(true);
                slot.setAvailableCount(10); // 默认号源10
                slot.setRoomName(roomName); // 设置诊室
                slots.add(slot);
            }
            doctorScheduleMapper.batchInsertSchedules(slots);
            // 清除缓存
            evictCache(doctorId);
            deleteAllRedisCache();
        }
    }

    @Override
    public void exchangeShift(Integer fromDoctorId, LocalDate fromDate, String fromPeriodType,
                              Integer toDoctorId, LocalDate toDate, String toPeriodType) {
        List<String> fromPeriods = getPeriodsByType(fromPeriodType);
        List<String> toPeriods = getPeriodsByType(toPeriodType);

        // 1. 删除发起者原排班 (真正移除，使状态变为空)
        if (!fromPeriods.isEmpty()) {
            doctorScheduleMapper.deleteSchedules(fromDoctorId, fromDate, fromPeriods);
        }

        // 2. 发起者新时段设为可用
        addShift(fromDoctorId, toDate, toPeriodType, null);

        // 3. 删除目标医生原排班 (真正移除，使状态变为空)
        if (!toPeriods.isEmpty()) {
            doctorScheduleMapper.deleteSchedules(toDoctorId, toDate, toPeriods);
        }

        // 4. 目标医生新时段设为可用
        addShift(toDoctorId, fromDate, fromPeriodType, null);

        // 5. 转移患者
        if (!fromPeriods.isEmpty()) {
            int rows = registrationMapper.updateDoctorForSchedule(fromDoctorId, toDoctorId, fromDate.toString(), fromPeriods);
            System.out.println("Transferred " + rows + " patients from doctor " + fromDoctorId + " to " + toDoctorId);
        }

        if (!toPeriods.isEmpty()) {
            int rows = registrationMapper.updateDoctorForSchedule(toDoctorId, fromDoctorId, toDate.toString(), toPeriods);
            System.out.println("Transferred " + rows + " patients from doctor " + toDoctorId + " to " + fromDoctorId);
        }

        // 6. 清除缓存
        registrationRecordService.clearListCache();
        evictCache(fromDoctorId);
        evictCache(toDoctorId);
    }

    private List<String> getPeriodsByType(String periodType) {
        List<String> periods = new ArrayList<>();
        // 根据 periodType ("morning", "afternoon", "evening") 生成对应时间段
        if ("morning".equalsIgnoreCase(periodType)) {
            periods.add("08:00-09:00");
            periods.add("09:00-10:00");
            periods.add("10:00-11:00");
            periods.add("11:00-12:00");
        } else if ("afternoon".equalsIgnoreCase(periodType)) {
            periods.add("14:00-15:00");
            periods.add("15:00-16:00");
            periods.add("16:00-17:00");
            periods.add("17:00-18:00");
        } else if ("evening".equalsIgnoreCase(periodType)) {
            periods.add("19:00-20:00");
            periods.add("20:00-21:00");
            periods.add("21:00-22:00");
        }
        return periods;
    }
    public Result deleteAllRedisCache() {
        Result result = new Result();
        try {
            // 匹配所有key（*为通配符）
            ScanOptions scanOptions = ScanOptions.scanOptions()
                    .match("*")
                    .count(1000)
                    .build();

            Iterator<String> keyIterator = redisTemplate.opsForSet().getOperations().scan(scanOptions);
            List<String> delKeys = new ArrayList<>();
            while (keyIterator.hasNext()) {
                delKeys.add(keyIterator.next());
            }

            if (!delKeys.isEmpty()) {
                redisTemplate.delete(delKeys);
            }

            result.setCode(200).setMsg("Redis所有缓存删除成功，共清理" + delKeys.size() + "个缓存key");
        } catch (Exception e) {
            e.printStackTrace();
            result.setCode(500).setMsg("Redis所有缓存删除失败：" + e.getMessage());
        }
        return result;
    }
}
