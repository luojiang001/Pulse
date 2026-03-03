package com.tjetc.service.Impl;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.tjetc.dao.NotificationMapper;
import com.tjetc.dao.UsersMapper;
import com.tjetc.domain.Notification;
import com.tjetc.domain.Users;
import com.tjetc.service.NotificationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.Date;
import java.util.List;

@Service
public class NotificationServiceImpl extends ServiceImpl<NotificationMapper, Notification> implements NotificationService {

    @Autowired
    private NotificationMapper notificationMapper;

    @Autowired
    private UsersMapper usersMapper;

    @Override
    public void sendAnnouncement(String title, String content, String type, String nickname) {
        Notification notification = new Notification();
        notification.setTitle(title);
        notification.setContent(content);
        notification.setType(type);
        notification.setCreateTime(new Date());

        if ("USER".equals(type)) {
            if (nickname == null || nickname.isEmpty()) {
                throw new RuntimeException("Nickname is required for USER type announcement");
            }
            Users user = usersMapper.findByNickname(nickname);
            if (user == null) {
                throw new RuntimeException("User with nickname " + nickname + " not found");
            }
            notification.setTargetUserId(user.getId());
        }

        notificationMapper.insert(notification);
    }

    @Override
    public List<Notification> getMyNotifications(Integer userId) {
        return notificationMapper.listByUserId(userId);
    }

    @Override
    public List<String> getAllNicknames() {
        return usersMapper.findAllNicknames();
    }
}
