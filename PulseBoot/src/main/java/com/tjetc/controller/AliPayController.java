package com.tjetc.controller;

import com.alibaba.fastjson.JSONObject;
import com.alipay.api.AlipayClient;
import com.alipay.api.DefaultAlipayClient;
import com.alipay.api.request.AlipayTradePagePayRequest;
import com.tjetc.config.AliPayConfig;
import com.tjetc.domain.Orders;
import com.tjetc.service.OrderService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.io.IOException;
import java.util.Date;

@RestController
@RequestMapping("/alipay")
public class AliPayController {
    @Autowired
    private AliPayConfig aliPayConfig;
    @Autowired
    private OrderService orderService;

    @RequestMapping("/pay")
    public void pay(
            @RequestParam("orderId") String orderId,
            HttpServletResponse response) throws IOException {
        Orders orders=orderService.findById(orderId);
        if (orders==null){
            return;
        }
        // 获得初始化的AlipayClient
        AlipayClient alipayClient = new DefaultAlipayClient(
                aliPayConfig.getGatewayUrl(),
                aliPayConfig.getAppId(),
                aliPayConfig.getAppPrivateKey(),
                aliPayConfig.getFormat(),
                aliPayConfig.getCharset(),
                aliPayConfig.getAlipayPublicKey(),
                aliPayConfig.getSignType());
        // 设置请求参数
        AlipayTradePagePayRequest request = new AlipayTradePagePayRequest();
//        request.setReturnUrl(aliPayConfig.getReturnUrl());
        request.setNotifyUrl(aliPayConfig.getNotifyUrl());
        JSONObject bizContent = new JSONObject();
        bizContent.put("out_trade_no", orders.getId());//订单编号
        bizContent.put("total_amount",orders.getTotalAmount());//订单总金额
        bizContent.put("subject","医疗订单");
        bizContent.put("product_code","FAST_INSTANT_TRADE_PAY");
        request.setBizContent(bizContent.toString());
        // 修改为指向本机后端的同步回调接口，用于演示环境更新状态
        request.setReturnUrl("http://192.168.140.198:8080/alipay/return");

        String form="";
        try {
            form = alipayClient.pageExecute(request).getBody();
        } catch (Exception e) {
            e.printStackTrace();
        }
        response.setContentType("text/html;charset=utf-8");
        response.getWriter().write(form);// 直接将完整的表单html输出到页面
        response.getWriter().flush();
        response.getWriter().close();
    }
    @RequestMapping("/return")
    public void returnUrl(HttpServletRequest request, HttpServletResponse response) throws IOException {
        String outTradeNo = request.getParameter("out_trade_no");
        // 更新订单状态
        if (outTradeNo != null) {
            Orders orders = orderService.findById(outTradeNo);
            if (orders != null) {
                // 演示环境：同步回调直接更新状态
                orders.setStatus("paid");
                orders.setPayTime(new Date());
                orderService.update(orders);
            }
        }
        
        response.setContentType("text/html;charset=utf-8");
        response.getWriter().write("<html><body style='text-align:center; padding-top:50px;'>");
        response.getWriter().write("<h1 style='color:#007fff;'>支付成功</h1>");
        response.getWriter().write("<p>订单状态已更新</p>");
        response.getWriter().write("<p>请点击左上角 < 返回按钮回到应用查看</p>");
        response.getWriter().write("</body></html>");
        response.getWriter().flush();
        response.getWriter().close();
    }

    @PostMapping("/notify")
    public void payNotify(HttpServletRequest request){
        if (request.getParameter("trade_status").equals("TRADE_SUCCESS")){
            System.out.println("支付成功");
            System.out.println(request.getParameter("subject"));//交易名称
            System.out.println(request.getParameter("trade_status"));//交易状态
            System.out.println(request.getParameter("trade_no"));//支付宝交易凭证号
            System.out.println(request.getParameter("out_trade_no"));//商户订单号
            System.out.println(request.getParameter("total_amount"));//交易金额
            System.out.println(request.getParameter("buyer_id"));//买家在支付宝唯一id
            System.out.println(request.getParameter("gmt_payment"));//买家付款时间
            System.out.println(request.getParameter("buyer_pay_amount"));//买家付款金额

            String tradeNo = request.getParameter("out_trade_no");
            String gmtPayment = request.getParameter("gmt_payment");
            String alipayTradeNo = request.getParameter("trade_no");
            //更新订单状态为已支付
            Orders orders = orderService.findById(tradeNo);
            orders.setStatus("paid");
            orders.setPayTime(new Date());
            orderService.update(orders);
        }

    }
}