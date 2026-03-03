package com.tjetc.domain;

import java.io.Serializable;
import java.util.Date;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * 用户信息表
 */
@Data
@AllArgsConstructor
@NoArgsConstructor
public class Users implements Serializable {
    /**
    * 用户ID
    */
    private Integer id;

    /**
    * 用户名
    */
    private String username;

    /**
    * 密码
    */
    private String password;

    /**
    * 昵称
    */
    private String nickname;

    /**
    * 头像URL
    */
    private String avatar;


    /**
     * 性别 0:男 1:女 2:保密
     */
    private Integer gender;

    /**
     * 出生日期
     */
    private Date birth;

    /**
     * 个人简介
     */
    private String intro;

    private Date createdAt;
}