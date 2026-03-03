package com.tjetc.service;

import com.github.pagehelper.PageInfo;
import com.tjetc.domain.Medicine;
import com.tjetc.domain.Users;
import com.tjetc.vo.AvatarUpdateRequest;
import com.tjetc.vo.AvatarUploadBase64Request;
import com.tjetc.vo.ProfileUpdateRequest;
import com.tjetc.vo.Result;
import org.springframework.web.multipart.MultipartFile;

public interface UserLoginService {
   Users getById(Integer id);

   Result UserLogin(String username, String password);

   void handleRandomCode(String username, String code);

   Result loginByCode(String username, String code);

   Result register(String username, String password, String code);

   Result updateProfile(ProfileUpdateRequest req);

   Result updateAvatar(MultipartFile photo);

   Result uploadAvatarBase64(AvatarUploadBase64Request req);

   Result add(Users users);

   Result update(Users users);

   Result del(Integer id);

   PageInfo<Users> list(String name, Integer pageNum, Integer pageSize);
}
