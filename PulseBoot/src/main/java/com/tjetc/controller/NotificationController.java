package com.tjetc.controller;

import com.tjetc.domain.Notification;
import com.tjetc.service.NotificationService;
import com.tjetc.vo.Result;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/notification")
@CrossOrigin
public class NotificationController {

    @Autowired
    private NotificationService notificationService;

    @PostMapping("/send")
    public Result send(@RequestBody Map<String, String> params) {
        String title = params.get("title");
        String content = params.get("content");
        String type = params.get("type");
        String nickname = params.get("nickname");

        try {
            notificationService.sendAnnouncement(title, content, type, nickname);
            return Result.success();
        } catch (Exception e) {
            return Result.fail(e.getMessage());
        }
    }

    @GetMapping("/list/{userId}")
    public Result list(@PathVariable Integer userId) {
        List<Notification> list = notificationService.getMyNotifications(userId);
        return Result.success(list);
    }

    @GetMapping("/nicknames")
    public Result getNicknames() {
        return Result.success(notificationService.getAllNicknames());
    }
}
