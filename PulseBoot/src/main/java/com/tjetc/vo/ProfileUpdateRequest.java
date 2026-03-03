package com.tjetc.vo;

import lombok.Data;
import java.util.Date;

@Data
public class ProfileUpdateRequest {
    private String nickname;
    private String phone;
    private Integer gender;
    private Integer userId;
    private Date birth;
    private String intro;
    private String avatar;
}
