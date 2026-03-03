package com.tjetc.service.Impl;

import com.alipay.api.domain.Article;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.github.pagehelper.PageHelper;
import com.github.pagehelper.PageInfo;
import com.tjetc.dao.MedicineMapper;
import com.tjetc.document.MedicineDoc;
import com.tjetc.domain.Category;
import com.tjetc.domain.Medicine;
import com.tjetc.repository.CategoryRepository;
import com.tjetc.repository.MedicineEsRepository;
import com.tjetc.repository.MedicineRepository;
import com.tjetc.service.MedicineService;
import com.tjetc.vo.Result;
import co.elastic.clients.elasticsearch.ElasticsearchClient;
import co.elastic.clients.elasticsearch.core.SearchResponse;
import co.elastic.clients.elasticsearch.core.search.Hit;
import org.springframework.beans.BeanUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.elasticsearch.core.SearchHit;
import org.springframework.data.elasticsearch.core.SearchHits;
import org.springframework.data.elasticsearch.core.SearchPage;
import org.springframework.data.querydsl.QPageRequest;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.concurrent.TimeUnit;
//https://code-with-me.jetbrains.com.cn/Tmp9i0M1hBaCr88Qwa13Ow
@Service
@Transactional(rollbackFor = Exception.class)
public class MedicineServiceImpl extends ServiceImpl<MedicineMapper, Medicine> implements MedicineService {
    @Autowired
    private MedicineMapper medicineMapper;
    @Autowired
    private MedicineRepository medicineRepository;
    @Autowired
    private MedicineEsRepository medicineEsRepository;
    @Autowired
    private CategoryRepository categoryRepository;
    @Autowired
    private RedisTemplate<String, Object> redisTemplate;
    @Autowired
    private ElasticsearchClient elasticsearchClient;

    private static final String medicineKey = "medicine:list:";
    private static final long live = 1;

    @Override
    public Result del(Integer id){
        Result result = new Result();
        int rows=medicineMapper.del(id);
        if(rows>0){
            medicineRepository.deleteById(id);
            // ES Sync
            try {
                medicineEsRepository.deleteById(id);
            } catch (Exception e) {
                System.err.println("ES sync failed: " + e.getMessage());
            }
            clearMedicineListCache();
            result.setCode(200).setMsg("删除成功");
        }else {
            result.setCode(500).setMsg("删除失败");
        }
        return result;
    }

    @Override
    public Result add(Medicine medicine) {
        Result result = new Result();
        if (medicine == null || !StringUtils.hasText(medicine.getName())) {
            return result.setCode(400).setMsg("添加失败：药品信息不能为空，名称必填");
        }
        int rows =medicineMapper.add(medicine);
        if (rows > 0) {
            medicineRepository.save(medicine);
            // ES Sync
            try {
                medicineEsRepository.save(convertToDoc(medicine));
            } catch (Exception e) {
                System.err.println("ES sync failed: " + e.getMessage());
            }
            clearMedicineListCache();
            result.setCode(200).setMsg("添加成功");
        }else {
            result.setCode(500).setMsg("添加失败");
        }
        return result;
    }
    @Override
    public Result update(Medicine medicine) {
        Result result = new Result();
        if (medicine == null || medicine.getId() == null||medicine.getId()<=0) {
            return result.setCode(400).setMsg("修改失败：药品ID不能为空");
        }
        if (!StringUtils.hasText(medicine.getName())) {
            return result.setCode(400).setMsg("修改失败：药品名称不能为空");
        }
        int rows =medicineMapper.update(medicine);
        if (rows > 0) {

            medicineRepository.save(medicine);
            // ES Sync
            try {
                medicineEsRepository.save(convertToDoc(medicine));
            } catch (Exception e) {
                System.err.println("ES sync failed: " + e.getMessage());
            }
            clearMedicineListCache();
            result.setCode(200).setMsg("修改成功");
        }else {
            result.setCode(500).setMsg("修改失败");
        }
        return result;
    }


    @Override
    public PageInfo<Medicine> list(String name, Integer pageNum, Integer pageSize) {
//        System.out.println("name = " + name + ", pageNum = " + pageNum + ", pageSize = " + pageSize);
        if (StringUtils.hasText(name)) {
            try {

                SearchResponse<MedicineDoc> response = elasticsearchClient.search(s -> s
                        .index("medicine")
                        .query(q -> q
                            .bool(b -> b
                                .should(s1 -> s1
                                    .multiMatch(m -> m
                                        .query(name)
                                        .fields("name", "efficacy", "description", "manufacturer")
                                    )
                                )
                                .should(s2 -> s2
                                    .wildcard(w -> w
                                        .field("name")
                                        .value("*" + name + "*")
                                    )
                                )
                            )
                        )
                        .highlight(h -> h
                            .fields("name", f -> f
                                .preTags("<highlight>")
                                .postTags("</highlight>")
                            )
                        )
                        .from((pageNum - 1) * pageSize)
                        .size(pageSize),
                        MedicineDoc.class
                );

                long totalHits = response.hits().total().value();
                List<Medicine> list = new ArrayList<>();

                for (Hit<MedicineDoc> hit : response.hits().hits()) {
                    MedicineDoc doc = hit.source();
                    if (doc != null) {
                        Medicine medicine = convertDocToMedicine(doc);

                        // 解析高亮
                        Map<String, List<String>> highlight = hit.highlight();
                        if (highlight != null && highlight.containsKey("name")) {
                            List<String> fragments = highlight.get("name");
                            if (fragments != null && !fragments.isEmpty()) {
                                medicine.setName(fragments.get(0));
                            }
                        } else {
                            // 手动高亮
                            if (StringUtils.hasText(name) && medicine.getName() != null && medicine.getName().contains(name)) {
                                medicine.setName(medicine.getName().replace(name, "<highlight>" + name + "</highlight>"));
                            }
                        }
                        list.add(medicine);
                    }
                }

                // 封装PageInfo
                PageInfo<Medicine> pageInfo = new PageInfo<>(list);
                pageInfo.setTotal(totalHits);
                pageInfo.setPageNum(pageNum);
                pageInfo.setPageSize(pageSize);
                pageInfo.setPages((int) Math.ceil((double) totalHits / pageSize));
                return pageInfo;

            } catch (Exception e) {
                System.err.println("ES Search failed, falling back to DB: " + e.getMessage());
                e.printStackTrace();
            }
        }

        String cacheKey = medicineKey +
                (StringUtils.hasText(name) ? name : "null") + "_" +
                pageNum + "_" + pageSize;

        PageInfo<Medicine> pageInfo = (PageInfo<Medicine>) redisTemplate.opsForValue().get(cacheKey);

        if (pageInfo != null) {
            return pageInfo;
        }

        PageHelper.startPage(pageNum, pageSize);
        List<Medicine> list = medicineMapper.list(name);

        // 手动高亮 (DB fallback)
        if (StringUtils.hasText(name)) {
            for (Medicine medicine : list) {
                if (medicine.getName() != null && medicine.getName().contains(name)) {
                    medicine.setName(medicine.getName().replace(name, "<highlight>" + name + "</highlight>"));
                }
            }
        }

        pageInfo = new PageInfo<>(list);

        redisTemplate.opsForValue().set(cacheKey, pageInfo, live, TimeUnit.HOURS);

        return pageInfo;
    }

    public void clearMedicineListCache() {
        try {
            Set<String> cacheKeys = redisTemplate.keys(medicineKey + "*");
            if (cacheKeys != null && !cacheKeys.isEmpty()) {
                redisTemplate.delete(cacheKeys);
                System.out.println(("清空药品分页缓存，共删除{}个Key" + cacheKeys.size()));
            }
        } catch (Exception e) {
            System.out.println(("清空药品缓存失败" + e));
            // 缓存清理失败不影响主业务
        }
    }

    private MedicineDoc convertToDoc(Medicine medicine) {
        MedicineDoc doc = new MedicineDoc();
        BeanUtils.copyProperties(medicine, doc);
        return doc;
    }

    private Medicine convertDocToMedicine(MedicineDoc doc) {
        Medicine medicine = new Medicine();
        BeanUtils.copyProperties(doc, medicine);
        return medicine;
    }

    @Override
    public List<Category> categoryList() {
        Iterable<Category> categoryIterable = categoryRepository.findAll();
        List<Category> categoryList = new ArrayList<>();
        for (Category category : categoryIterable) {
            categoryList.add(category);
        }
        if (!categoryList.isEmpty()) {
            return categoryList;
        }
        categoryList = medicineMapper.categoryList();
        if (categoryList == null || categoryList.isEmpty()) {
            return List.of();
        }
        categoryRepository.saveAll(categoryList);


        return categoryList;
    }

    @Override
    public List<Medicine> medicineList() {
        Iterable<Medicine> medicineIterable = medicineRepository.findByStatus(1);
        List<Medicine> medicineList = new ArrayList<>();
        for (Medicine medicine : medicineIterable) {
            medicineList.add(medicine);
        }

        if (!medicineList.isEmpty()) {
            return medicineList;
        }
        medicineList = medicineMapper.medicineList();
        if (medicineList == null || medicineList.isEmpty()) {
            return List.of();
        }
        medicineRepository.saveAll(medicineList);
        return medicineList;
    }

    @Override
    public boolean decreaseStock(Integer id, Integer quantity) {
        int rows = medicineMapper.decreaseStock(id, quantity);
        if (rows > 0) {
            // 更新Redis缓存
            Optional<Medicine> optional = medicineRepository.findById(id);
            if (optional.isPresent()) {
                // 原逻辑似乎没写完，保留原样
            }
            return true;
        }
        return false;
    }

    @Override
    public void syncEs() {
        // 1. 从数据库查询所有药品
        List<Medicine> allMedicine = medicineMapper.selectList(null);
        if (allMedicine == null || allMedicine.isEmpty()) {
            System.out.println("数据库无药品数据，无需同步");
            return;
        }

        // 2. 转换为 Doc 对象
        List<MedicineDoc> docs = allMedicine.stream()
                .map(this::convertToDoc)
                .collect(java.util.stream.Collectors.toList());

        // 3. 写入 ES
        try {
            medicineEsRepository.saveAll(docs);
            System.out.println("成功同步 " + docs.size() + " 条药品数据到 Elasticsearch");
        } catch (Exception e) {
            System.err.println("同步 ES 失败: " + e.getMessage());
            e.printStackTrace();
        }
    }
}
