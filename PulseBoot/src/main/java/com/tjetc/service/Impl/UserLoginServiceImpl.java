package com.tjetc.service.Impl;

import com.github.pagehelper.PageHelper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.github.pagehelper.PageInfo;
import com.tjetc.dao.UsersMapper;
import com.tjetc.domain.Medicine;
import com.tjetc.domain.Users;
import com.tjetc.repository.CodeLoginRepository;
import com.tjetc.service.UserLoginService;
import com.tjetc.utils.MinioUtils;
import com.tjetc.vo.AvatarUploadBase64Request;
import com.tjetc.vo.ProfileUpdateRequest;
import com.tjetc.vo.Result;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;
import org.springframework.web.multipart.MultipartFile;

import java.util.Base64;
import java.util.Date;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.TimeUnit;

@Service
@Transactional(rollbackFor = Exception.class)
public class UserLoginServiceImpl extends ServiceImpl<UsersMapper, Users> implements UserLoginService {
    @Autowired
    UsersMapper usersMapper;
    @Autowired
    CodeLoginRepository codeLoginRepository;
    @Autowired
    private MinioUtils minioUtils;
    @Override
    public PageInfo<Users> list(String username, Integer pageNum, Integer pageSize) {
        PageHelper.startPage(pageNum, pageSize);
        List<Users> list = usersMapper.list(username);
        return new PageInfo<>(list);
    }
    @Override
    public Result del(Integer id){
        Result  result=new Result();
        int rows = usersMapper.deleteByPrimaryKey(id);
        if(rows>0){
            result.setCode(200).setMsg("删除成功");
        }else {
            result.setCode(500).setMsg("删除失败");
        }
        return result;
    }

    @Override
    public Result add(Users users){
        Result  result=new Result();
        int rows = usersMapper.insert(users);
        if(rows>0){
            result.setCode(200).setMsg("添加成功");
        }else {
            result.setCode(500).setMsg("添加失败");
        }
        return result;
    }
    @Override
    public Result update(Users users){
        Result  result=new Result();
        int  rows = usersMapper.updateByPrimaryKey(users);
        if(rows>0){
            result.setCode(200).setMsg("修改成功");
        }else {
            result.setCode(500).setMsg("修改失败");
        }
        return result;
    }


    @Override
    public Users getById(Integer id) {
        return usersMapper.selectByPrimaryKey(id);
    }

    @Override
    public Result UserLogin(String username, String password) {
        Result result = new Result();
        Users user=usersMapper.findByUsername(username);
        if(user==null){
            result.setCode(500).setMsg("该账户不存在");
        }else {
            String userPassword = user.getPassword();
            if(password.equals(userPassword)){
                result.setCode(200).setMsg("登录成功").setData(user);
            }
        }

        return result;
    }

    @Override
    public void handleRandomCode(String username, String code) {
        codeLoginRepository.save(username, code);
    }

    @Override
    public Result loginByCode(String username, String code) {
        Result result=new Result();
        String DataCode = codeLoginRepository.findById(username);
        if(DataCode==null){
            result.setCode(404).setMsg("验证码已过期！");
        }else {
            if(DataCode.equals(code)){
                result.setCode(200).setMsg("登陆成功").setData(usersMapper.findByUsername(username));
            }else {
                result.setCode(500).setMsg("验证码错误");
            }
        }
        return result;
    }

    @Override
    public Result register(String username, String password, String code) {
        Result result = new Result();
        Users users = new Users();
        String DataCode = codeLoginRepository.findById(username);
        if(DataCode==null){
            result.setCode(404).setMsg("验证码已过期！");
        }else {
            Users byUsername = usersMapper.findByUsername(username);
            if (byUsername!=null) {
                result.setCode(500).setMsg("该手机号已注册,请登录");
                return result;
            }
            if (DataCode.equals(code)) {
                users.setUsername(username);
                users.setPassword(password);
                users.setCreatedAt(new Date());
                usersMapper.insert(users);
                result.setCode(200).setMsg("注册成功,请登录");
            }else {
                result.setCode(500).setMsg("验证码错误");
            }
        }
          return result;
    }

    @Override
    public Result updateProfile(ProfileUpdateRequest req) {
        Users user = usersMapper.selectByPrimaryKey(req.getUserId());
        if (user == null) {
            return new Result().setCode(500).setMsg("User not found");
        }
        if (req.getNickname() != null) user.setNickname(req.getNickname());
        if (req.getGender() != null) user.setGender(req.getGender());
        if (req.getBirth() != null) user.setBirth(req.getBirth());
        if (req.getIntro() != null) user.setIntro(req.getIntro());
        if (req.getAvatar() != null) user.setAvatar(req.getAvatar());
        usersMapper.updateByPrimaryKeySelective(user);
        return new Result().setCode(200).setMsg("Update success");
    }

    @Override
    public Result updateAvatar(MultipartFile photo) {
//       String patrh=;
       //todo 把path存储到数据库表里
        return new Result().setCode(200).setMsg("Update success");
    }

    @Override
    public Result uploadAvatarBase64(AvatarUploadBase64Request req) {
        try {
            String base64 = req.getAvatarBase64();
            if (base64.contains(",")) {
                base64 = base64.split(",")[1];
            }
            byte[] decoded = Base64.getDecoder().decode(base64);
            
            String fileName = UUID.randomUUID().toString() + ".jpg";

            MockMultipartFile photo = new MockMultipartFile(
                    "file",
                    fileName,
                    "image/jpeg",
                    decoded
            );

            String path = minioUtils.upload(photo);
            System.out.println("path = " + path);


            Users user = usersMapper.selectByPrimaryKey(req.getUserId());
            if (user != null) {
                user.setAvatar(path);
                usersMapper.updateByPrimaryKeySelective(user);
            }
            
            return new Result().setCode(200).setMsg("Upload success");
        } catch (Exception e) {
            e.printStackTrace();
            return new Result().setCode(500).setMsg("Upload failed: " + e.getMessage());
        }
    }
}
