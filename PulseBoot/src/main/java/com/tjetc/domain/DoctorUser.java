package com.tjetc.domain;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;
@Data
@NoArgsConstructor
@AllArgsConstructor
public class DoctorUser implements Serializable {
    private Integer id;
    private String username;
    private String password;
    private Integer doctorsId;
}
