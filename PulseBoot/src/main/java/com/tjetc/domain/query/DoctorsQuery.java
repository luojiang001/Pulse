package com.tjetc.domain.query;

import lombok.Data;
import org.springframework.ai.tool.annotation.ToolParam;

@Data
public class DoctorsQuery {

    @ToolParam(description = "医生姓名",required = false )
    private String name;

    @ToolParam(description = "医生职称:主治医师、副主任医师、主任医师",required = false )
    private String title;

    @ToolParam(description = "医生专业",required = false )
    private String specialty;

     @ToolParam(description = "医生科室",required = false )
    private String department;
}
