# 构建 Android 安装包

## 1.生成 Keystore
### 1.1 找到 keytool 位置
Keytool的位置在`JDK`里的`bin`文件夹，如果你不知道你的`JDK`在哪，可以使用下面的命令查看位置
```shell
flutter doctor -v  # 找到 Java binary at 位置
# 然后 cd 到对应文件夹
```
> 注：如果你已经配置了 JAVA_HOME 和 Path 环境变量，可以直接在任何目录下运行 keytool

### 1.2 创建 Keystore
```shell
.\keytool.exe -genkey -v -keystore icy_easy_send_key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias icyeasysend
```

## 2.修改配置
将生成的`icy_easy_send_key.jks`文件移动到 Flutter 项目的`android/app/`目录下

然后在项目根目录的`android`文件夹里创建`key.properties`文件，内容如下：
```shell
storePassword=你的秘钥
keyPassword=你的密码
keyAlias=icyeasysend
storeFile=../app/icy_easy_send_key.jks
```

## 3. 构建
```shell
flutter build apk --release
```