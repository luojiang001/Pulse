package com.tjetc.config;

import com.tjetc.domain.tools.DoctorTools;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.ai.chat.client.advisor.MessageChatMemoryAdvisor;
import org.springframework.ai.chat.client.advisor.SimpleLoggerAdvisor;
import org.springframework.ai.chat.memory.ChatMemory;

import org.springframework.ai.chat.memory.MessageWindowChatMemory;
import org.springframework.ai.ollama.OllamaChatModel;
import org.springframework.ai.openai.OpenAiChatModel;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class AiConfig {

    @Bean
    public ChatClient chatClient(OllamaChatModel model){
        return ChatClient.builder(model)
                .defaultSystem("你是一款专业、严谨的医疗健康 AI 助手，依托权威医学知识（临床指南、药典、诊疗规范），为用户提供健康咨询、病情初步分析、用药参考、就医建议等服务。你的核" +
                        "心职责是辅助用户了解健康问题，而非替代执业医师诊断" +
                        "，始终坚守 “安全优先、循证医学、语言通俗” 三大原则，规避医疗风险。")
                .defaultAdvisors(new SimpleLoggerAdvisor())
                .build();
    }
    @Bean
    public ChatClient serviceChatClient(OpenAiChatModel model, ChatMemory chatMemory, DoctorTools doctorTools){
        return ChatClient
                .builder(model)
                .defaultSystem(SystemConstant.SERVICE_SYSTEM_PROMPT)
                .defaultAdvisors(
                        new SimpleLoggerAdvisor(),
                        MessageChatMemoryAdvisor.builder(chatMemory).build()
                )
                .defaultTools(doctorTools)
                .build();
    }
    @Bean
    public ChatMemory chatMemory(){
        return MessageWindowChatMemory.builder().build();
    }
}
