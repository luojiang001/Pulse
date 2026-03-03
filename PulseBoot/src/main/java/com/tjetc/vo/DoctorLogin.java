package com.tjetc.vo;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;
@Data
@NoArgsConstructor
@AllArgsConstructor
public class DoctorLogin implements Serializable {
    private Integer doctorId;
    private String name;
}
