package com.tjetc.vo;

import lombok.Data;

@Data
public class AvatarUpdateRequest {
    private Integer userId;
    private String avatar;
}
