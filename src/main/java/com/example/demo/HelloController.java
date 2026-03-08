package com.example.demo;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

// 关键注解：标记这是一个控制器，返回值直接输出到浏览器（不跳转页面）
@RestController
public class HelloController {

    // 关键注解：映射GET请求，访问路径为根路径（/）
    @GetMapping("/")
    public String sayHello() {
        // 返回"hello"，浏览器访问时就会显示这个内容
        return "hello this is springboot from aliyun k8s by lty";
    }
}
