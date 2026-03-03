package com.tjetc.controller;

import com.github.pagehelper.PageInfo;
import com.tjetc.domain.Medicine;
import com.tjetc.domain.Users;
import com.tjetc.service.UserLoginService;
import com.tjetc.vo.AvatarUpdateRequest;
import com.tjetc.vo.AvatarUploadBase64Request;
import com.tjetc.vo.ProfileUpdateRequest;
import com.tjetc.vo.Result;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/user")
public class UserLoginController {
   @Autowired
    private UserLoginService userLoginService;

   @RequestMapping("/login")
   public Result login(@RequestParam("username") String username,@RequestParam("password") String password){
       return userLoginService.UserLogin(username,password);
   }

    @RequestMapping("/login/randomCode")
    public void randomCode(@RequestParam("username") String username,@RequestParam("code") String code){
        userLoginService.handleRandomCode(username,code);
    }

   @RequestMapping("/login/loginByCode")
   public Result loginByCode(@RequestParam("username") String username,@RequestParam("code") String code){
       return userLoginService.loginByCode(username,code);
   }
   @RequestMapping("/register")
    public Result register(@RequestParam("username") String username,
                           @RequestParam("password") String password,
                           @RequestParam("code") String code
   ){
       Result result = userLoginService.register(username, password, code);
       return result;
   }

   @PostMapping("/updateProfile")
   public Result updateProfile(@RequestBody ProfileUpdateRequest req){
       return userLoginService.updateProfile(req);
   }

   @PostMapping("/updateAvatar")
   public Result updateAvatar(@RequestParam("photo") MultipartFile photo){
       return userLoginService.updateAvatar(photo);
   }

   @PostMapping("/uploadAvatarBase64")
   public Result uploadAvatarBase64(@RequestBody AvatarUploadBase64Request req){
       return userLoginService.uploadAvatarBase64(req);
   }
   @RequestMapping("/save")
    public Result save(@RequestBody Users users){
       if(users.getId()==-1){
           return userLoginService.add(users);
       }else {
           return userLoginService.update(users);
       }
   }
   @RequestMapping("/del/{id}")
    public Result delete(@PathVariable("id") Integer id){
       return userLoginService.del(id);
   }
    @RequestMapping("/list")
    public PageInfo<Users> list(
            @RequestParam(value = "username",defaultValue = "") String username,
            @RequestParam(value = "pageNum",defaultValue = "1") Integer pageNum,
            @RequestParam(value = "pageSize",defaultValue = "2") Integer pageSize
    ) {
        return userLoginService.list(username, pageNum, pageSize);
    }

    @GetMapping("/{id}")
    public Result getUserInfo(@PathVariable("id") Integer id) {
        Users user = userLoginService.getById(id);
        if (user != null) {
            return new Result().setCode(200).setMsg("Success").setData(user);
        }
        return new Result().setCode(404).setMsg("User not found");
    }







}
