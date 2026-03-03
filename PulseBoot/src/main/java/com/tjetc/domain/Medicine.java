package com.tjetc.domain;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.checkerframework.framework.qual.FieldIsExpression;
import org.springframework.data.annotation.Id;
import org.springframework.data.elasticsearch.annotations.Document;
import org.springframework.data.elasticsearch.annotations.Field;
import org.springframework.data.elasticsearch.annotations.FieldType;
import org.springframework.data.redis.core.RedisHash;

import java.io.Serializable;

@Document(indexName = "medicine")
@Data
@AllArgsConstructor
@NoArgsConstructor
@RedisHash("medicine")
public class Medicine implements Serializable {
    @Id
    @Field(type = FieldType.Integer,store = true,index = false)
    private Integer id;
    @Field(type = FieldType.Text,store = true,index = true,analyzer = "ik_max_word")
    private String name;
    @Field(type = FieldType.Text,store = true,index = false)
    private String image;
    @Field(type = FieldType.Text,store = true,index = false)
    private String manufacturer;
    @Field(type = FieldType.Double,store = true,index = false)
    private double price;
    @Field(type = FieldType.Text,store = true,index = false)
    private String unit;
    @Field(type = FieldType.Text,store = true,index = false)
    private String description;
    @Field(type = FieldType.Text,store = true,index = false)
    private String efficacy;
    @Field(type = FieldType.Integer,store = true,index = false)
    private Integer prescription;
    @Field(type = FieldType.Integer,store = true,index = false)
    private Integer categoryId;
    @Field(type = FieldType.Integer,store = true,index = false)
    private Integer stock;
    @Field(type = FieldType.Integer,store = true,index = false)
    private Integer status;

}
