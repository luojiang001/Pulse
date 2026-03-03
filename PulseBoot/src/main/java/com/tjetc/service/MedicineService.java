package com.tjetc.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.github.pagehelper.PageInfo;
import com.tjetc.domain.Category;
import com.tjetc.domain.Medicine;
import com.tjetc.vo.Result;

import java.util.List;

public interface MedicineService extends IService<Medicine> {
    List<Category> categoryList();

    List<Medicine> medicineList();

    PageInfo<Medicine> list(String name, Integer pageNum, Integer pageSize);

    Result add(Medicine medicine);

    Result update(Medicine medicine);

    Result del(Integer id);

    boolean decreaseStock(Integer id, Integer quantity);

    void syncEs();
}
