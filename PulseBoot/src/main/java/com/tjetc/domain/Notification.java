package com.tjetc.domain;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;
import java.util.Date;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class Notification implements Serializable {
    private Integer id;
    private String title;
    private String content;
    private String type; // "ALL" or "USER"
    private Integer targetUserId;
    private Date createTime;
}
