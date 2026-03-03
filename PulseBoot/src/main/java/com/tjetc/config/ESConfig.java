package com.tjetc.config;

import co.elastic.clients.elasticsearch.ElasticsearchClient;
import co.elastic.clients.json.jackson.JacksonJsonpMapper;
import co.elastic.clients.transport.ElasticsearchTransport;
import co.elastic.clients.transport.rest_client.RestClientTransport;
import co.elastic.clients.util.ContentType;
import org.apache.http.HttpHost;
import org.apache.http.HttpResponseInterceptor;
import org.apache.http.impl.nio.reactor.IOReactorConfig;
import org.apache.http.message.BasicHeader;
import org.elasticsearch.client.RestClient;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpHeaders;

import java.io.IOException;
import java.util.Collections;
import java.util.concurrent.TimeUnit;
@Configuration
public class ESConfig {
    @Value("${spring.elasticsearch.uris}")
    private String uris;

    private RestClient restClient;
    private ElasticsearchClient client;

    private ElasticsearchTransport transport;

    @Bean(name = "elasticsearchClient")
    public ElasticsearchClient getElasticsearchClient() {
        //http://192.168.128.100:9200/
        String[] arr = uris.substring(uris.indexOf("//") + 2,uris.endsWith("/")?uris.lastIndexOf("/"):uris.length()).split(":");
        restClient = RestClient.builder(
                new HttpHost(arr[0], Integer.parseInt(arr[1]))
        ).setRequestConfigCallback(
                requestConfigBuilder -> requestConfigBuilder
                        .setConnectTimeout(90000000)//25hours
                        .setSocketTimeout(90000000)
        ).setHttpClientConfigCallback(httpClientBuilder -> httpClientBuilder
                //显式设置keepAliveStrategy
                .setKeepAliveStrategy((httpResponse, httpContext) -> TimeUnit.MINUTES.toMillis(3))
                //显式开启tcp keepalive
                .setDefaultIOReactorConfig(IOReactorConfig.custom().setSoKeepAlive(true).build())
                .setDefaultHeaders(
                        Collections.singletonList(new BasicHeader(HttpHeaders.CONTENT_TYPE, ContentType.APPLICATION_JSON.toString()))
                )
                //解决[es/indices.exists] Missing [X-Elastic-Product] header.
                .addInterceptorLast((HttpResponseInterceptor) (response, context)
                        -> response.addHeader("X-Elastic-Product", "Elasticsearch"))).build();
        // 使用Jackson映射器创建传输层
        transport = new RestClientTransport(
                restClient, new JacksonJsonpMapper()
        );
        // 创建API客户端
        client = new ElasticsearchClient(transport);
        return client;
    }


    public void close() {
        if (client != null) {
            try {
                transport.close();
                restClient.close();
            } catch (IOException e) {
                e.printStackTrace();
            }
        }
    }
}
