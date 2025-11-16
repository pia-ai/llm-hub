package com.aidoai.llmhub.biz.web.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Example controller
 */
@RestController
@RequestMapping("/api/hello")
public class HelloController {

    @GetMapping
    public String hello() {
        return "Hello from llm-hub";
    }
}

