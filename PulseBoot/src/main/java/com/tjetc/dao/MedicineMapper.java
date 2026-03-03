package com.tjetc.dao;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.tjetc.domain.Category;
import com.tjetc.domain.Medicine;
import org.apache.ibatis.annotations.*;

import java.util.List;

@Mapper
public interface MedicineMapper extends BaseMapper<Medicine> {
    @Select("select * from category order by id")
    List<Category> categoryList();
    @Select("select * from medicine where status=1 order by id ")
    List<Medicine> medicineList();

    @Select("select * from medicine order by id")
    List<Medicine> findAll();

    @Select("select * from medicine where name like concat('%',#{name},'%') order by id")
    List<Medicine> list(String name);

    @Insert("insert into medicine (name, image, manufacturer, price, unit, description, efficacy, prescription, category_id, stock, status) values (#{name},#{image}, #{manufacturer}, #{price}, #{unit}, #{description}, #{efficacy}, #{prescription}, #{categoryId}, #{stock}, #{status})")
    int add(Medicine medicine);

    @Update("update medicine set name=#{name} , image=#{image} , manufacturer=#{manufacturer} , price=#{price} , unit=#{unit} , description=#{description} , efficacy=#{efficacy} , prescription=#{prescription} , category_id=#{categoryId} , stock=#{stock} , status=#{status} where id=#{id}")
    int update(Medicine medicine);

    @Update("update medicine set stock = stock - #{quantity} where id = #{id} and stock >= #{quantity}")
    int decreaseStock(@Param("id") Integer id, @Param("quantity") Integer quantity);

    @Delete("delete from medicine where id=#{id} ")
    int del(Integer id);
}
