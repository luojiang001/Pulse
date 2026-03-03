package com.tjetc.vo;

import lombok.Data;

@Data
public class AvatarUploadBase64Request {
    private Integer userId;
    private String avatarBase64;
}
