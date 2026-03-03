package com.tjetc.controller;

import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

@RestController
public class UpLoadController {

    @RequestMapping("/upload")
    public String upload(MultipartFile photo) {
        System.out.println("photo = " + photo);
        return "upload success";
    }
}
