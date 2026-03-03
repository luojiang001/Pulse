package com.tjetc.utils;

import io.minio.MinioClient;
import io.minio.PutObjectOptions;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.multipart.MultipartFile;

import java.io.InputStream;
import java.util.UUID;

@Component
@Data
@NoArgsConstructor
@AllArgsConstructor
public class MinioUtils {
    @Value("${minio.endpoint}")
    private String endpoint;
    @Value("${minio.accessKey}")
    private String accessKey;
    @Value("${minio.secretKey}")
    private String secretKey;
    @Value("${minio.bucketName}")
    private String bucketName;

    public  String  upload(MultipartFile photo)  {
        try {
            // 使用MinIO服务的URL，端口，Access key和Secret key创建一个MinioClient对象
            MinioClient minioClient = new MinioClient(endpoint, accessKey, secretKey);

            // 检查存储桶是否已经存在
            boolean isExist = minioClient.bucketExists(bucketName);
            if (isExist) {
                System.out.println("Bucket already exists.");
            } else {
                // 创建一个名为asiatrip的存储桶，用于存储照片的zip文件。
                minioClient.makeBucket(bucketName);
            }

            InputStream inputStream = photo.getInputStream();
            String originalFilename = photo.getOriginalFilename();
            String extname = originalFilename.substring(originalFilename.lastIndexOf(".") + 1);
            String filename= UUID.randomUUID().toString()+'.'+extname;

            PutObjectOptions options = new PutObjectOptions(photo.getSize(), -1);
            //设置图片的contentType，如果不是PNG图片就自行修改对应的contentType,这样做的目的是为了上传之后访问图片时可以在浏览器预览而不用下载，当然也可以注释这行代码
            options.setContentType("image/"+extname);
            minioClient.putObject(bucketName, filename, inputStream, options);
            return endpoint+"/"+bucketName+"/"+filename;
            //http://127.0.0.1:9000/a02/2023/10/07/e952e1file01.jpg
        } catch (Exception e) {
            System.out.println("Error occurred: " + e);
        }
        return null;
    }}