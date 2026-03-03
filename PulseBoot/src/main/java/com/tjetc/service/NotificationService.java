package com.tjetc.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.tjetc.domain.Notification;
import java.util.List;

public interface NotificationService extends IService<Notification> {
    void sendAnnouncement(String title, String content, String type, String nickname);
    List<Notification> getMyNotifications(Integer userId);
    List<String> getAllNicknames();
}
