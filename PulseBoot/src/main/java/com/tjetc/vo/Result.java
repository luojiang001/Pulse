package com.tjetc.vo;

import lombok.Data;
import lombok.experimental.Accessors;

import java.io.Serializable;

@Data
@Accessors(chain=true)
public class Result implements Serializable {
    private Integer code;
    private String msg;
    private Object data;
    // 方便使用的静态方法
    public static Result success() {
        return new Result().setCode(200).setMsg("success");
    }

    public static Result success(Object data) {
        return new Result().setCode(200).setMsg("success").setData(data);
    }

    public static Result fail(String msg) {
        return new Result().setCode(500).setMsg(msg);
    }
}
