package com.tjetc.service.Impl;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.github.pagehelper.PageHelper;
import com.github.pagehelper.PageInfo;
import com.tjetc.dao.OrderItemMapper;
import com.tjetc.dao.OrdersMapper;
import com.tjetc.dao.PrescriptionMapper;
import com.tjetc.dao.UsersMapper;
import com.tjetc.domain.*;
import com.tjetc.repository.UserOrderRedisRepository;
import com.tjetc.service.MedicineService;
import com.tjetc.service.OrderService;
import com.tjetc.vo.OrderVo;
import com.tjetc.vo.Result;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.text.SimpleDateFormat;
import java.util.*;
import java.util.concurrent.TimeUnit;

@Service
@Transactional(rollbackFor = Exception.class)
public class OrderServiceImpl extends ServiceImpl<OrdersMapper, Orders> implements OrderService {
    @Autowired
    private OrdersMapper ordersMapper;
    @Autowired
    private OrderItemMapper orderItemMapper;
    @Autowired
    private PrescriptionMapper prescriptionMapper;
    @Autowired
    private UserOrderRedisRepository userOrderRedisRepository;
    @Autowired
    private MedicineService medicineService;
    @Autowired
    private RedisTemplate<String, Object> redisTemplate;
    @Autowired
    private UsersMapper usersMapper;

    private static final String orderVoKey = "orderVo:page:";
    private static final long live = 1;

    @Override
    public Orders findById(String orderId){
        return  ordersMapper.selectById(orderId);
    }

    @Override
    public void update(Orders orders) {
        ordersMapper.updateById(orders);
        redisTemplate.delete(redisTemplate.keys(orderVoKey + "*"));
        // 清除用户订单列表缓存，确保前端获取最新状态
        if (orders.getUserId() != null) {
            userOrderRedisRepository.deleteById(orders.getUserId());
        }
    }
    
    @Override
    public void createOrder(Orders order) {
        String orderId = UUID.randomUUID().toString().replace("-", "");
        order.setId(orderId);
        order.setStatus("pending");
        order.setCreateTime(System.currentTimeMillis());
        ordersMapper.insert(order);
        List<OrderItem> items = order.getItems();
        if (items != null && !items.isEmpty()) {
            for (OrderItem item : items) {
                item.setOrderId(orderId);
                // 扣减库存
                boolean success = medicineService.decreaseStock(item.getMedicineId(), item.getQuantity());
                if (!success) {
                    throw new RuntimeException("下单失败：库存不足，商品ID: " + item.getMedicineId());
                }

                // 更新处方已使用数量
                if (item.getPrescriptionId() != null) {
                    prescriptionMapper.updateUsedCount(item.getPrescriptionId(), item.getMedicineId(), item.getQuantity());
                }
            }
            orderItemMapper.insertBatch(items);
        }

        // 清除缓存
        userOrderRedisRepository.deleteById(order.getUserId());
        redisTemplate.delete(redisTemplate.keys(orderVoKey + "*"));

    }

    @Override
    public List<Orders> getOrderList(Long userId) {
        Optional<UserOrderCache> cacheOptional = userOrderRedisRepository.findById(userId);

        if (cacheOptional.isPresent()) {
            System.out.println("Hit Redis Cache via Repository");
            return cacheOptional.get().getOrders();
        }

        List<Orders> dbList = ordersMapper.selectByUserId(userId);

        if (dbList != null && !dbList.isEmpty()) {
            UserOrderCache cacheEntry = new UserOrderCache(userId, dbList);
            userOrderRedisRepository.save(cacheEntry);
        }

        return dbList;
    }

    @Override
    public PageInfo<OrderVo> page(String id, String status, Integer pageNum, Integer pageSize) {
        // 1. 入参兜底（优先级：Controller默认值 < Service兜底，保证参数合法）
        String searchId = StringUtils.hasText(id) ? id.trim() : "";
        String searchStatus = StringUtils.hasText(status) ? status.trim() : "";
        pageNum = (pageNum == null || pageNum < 1) ? 1 : pageNum;
        pageSize = (pageSize == null || pageSize < 1) ? 2 : pageSize; // 与Controller默认值保持一致


        PageHelper.startPage(pageNum, pageSize);
        // 打印参数，便于调试
        System.out.println("查询参数：searchId=" + searchId + ", searchStatus=" + searchStatus + ", pageNum=" + pageNum + ", pageSize=" + pageSize);
        List<Orders> ordersList = ordersMapper.page(searchId, searchStatus);
        // 打印查询结果数量，调试用
        System.out.println("数据库查询到订单数：" + (ordersList == null ? 0 : ordersList.size()));

        List<OrderVo> orderVoList = new ArrayList<>();
        if (ordersList != null && !ordersList.isEmpty()) {
            SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
            for (Orders order : ordersList) {
                OrderVo orderVo = new OrderVo();
                // 非空防护
                Users users = usersMapper.findById(order.getUserId());
                orderVo.setName(users != null ? users.getNickname() : "未知用户");

                orderVo.setId(order.getId());
                orderVo.setPayMethod(order.getPayMethod());
                orderVo.setPrice(order.getTotalAmount());
                orderVo.setStatus(order.getStatus());
                orderVo.setCreateTime(sdf.format(new Date(order.getCreateTime())));
                orderVoList.add(orderVo);
            }
        }

        PageInfo<OrderVo> pageInfo = new PageInfo<>(orderVoList);
        pageInfo.setPageNum(pageNum);
        pageInfo.setPageSize(pageSize);

        return pageInfo;
    }
    @Override
    public Result getOrderDetails(String orderId) {
        Orders order = ordersMapper.selectById(orderId);
        if (order != null) {
            return Result.success(order);
        } else {
            return Result.fail("订单不存在");
        }
    }
}
