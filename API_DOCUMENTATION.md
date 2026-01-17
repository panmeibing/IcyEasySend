# Icy Easy Send API 文档

## 概述

Icy Easy Send 提供了一套 RESTful API 用于局域网内的文件传输。

## 基础信息

- **协议**: HTTP
- **默认端口**: 8080
- **内容类型**: application/json (除文件传输外)

## API 端点

### 1. 健康检查

检查服务是否正常运行。

**端点**: `GET /health`

**请求参数**: 无

**响应示例**:
```json
{
  "status": "ok",
  "timestamp": "2024-01-15T10:30:00Z"
}
```

**状态码**:
- `200 OK`: 服务正常运行

---

### 2. 确认接收文件

在文件传输前，询问接收方是否愿意接收文件。

**端点**: `GET /confirm-receive`

**请求参数** (Query Parameters):
| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| fileName | string | 是 | 文件名 |
| fileSize | integer | 是 | 文件大小（字节） |
| senderIP | string | 是 | 发送方 IP 地址 |

**请求示例**:
```
GET /confirm-receive?fileName=document.pdf&fileSize=1048576&senderIP=192.168.1.100
```

**成功响应示例**:
```json
{
  "accepted": true,
  "transferId": "192.168.1.100_document.pdf_1705315800000",
  "message": "用户已确认接收文件"
}
```

**拒绝响应示例**:
```json
{
  "accepted": false,
  "message": "用户拒绝接收文件"
}
```

**状态码**:
- `200 OK`: 用户确认接收
- `403 Forbidden`: 用户拒绝接收
- `400 Bad Request`: 参数错误
- `500 Internal Server Error`: 服务器错误

---

### 3. 传输文件

传输文件数据到接收方。必须先调用 `/confirm-receive` 获取 `transferId`。

**端点**: `POST /transfer`

**请求参数** (Query Parameters):
| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| fileName | string | 是 | 文件名 |
| fileSize | integer | 是 | 文件大小（字节） |
| senderIP | string | 是 | 发送方 IP 地址 |
| transferId | string | 是 | 从 `/confirm-receive` 获取的传输 ID |

**请求头**:
- `Content-Type: application/octet-stream`
- `Content-Length: <文件大小>`

**请求体**: 文件的二进制数据流

**请求示例**:
```
POST /transfer?fileName=document.pdf&fileSize=1048576&senderIP=192.168.1.100&transferId=192.168.1.100_document.pdf_1705315800000
Content-Type: application/octet-stream
Content-Length: 1048576

<文件二进制数据>
```

**成功响应示例**:
```json
{
  "success": true,
  "message": "文件接收成功",
  "savedPath": "/storage/emulated/0/Download/document.pdf"
}
```

**失败响应示例**:
```json
{
  "success": false,
  "message": "存储空间不足"
}
```

**状态码**:
- `200 OK`: 文件传输成功
- `400 Bad Request`: 参数错误或缺少 transferId
- `403 Forbidden`: transferId 无效或未找到确认记录
- `413 Payload Too Large`: 文件过大或存储空间不足
- `500 Internal Server Error`: 服务器错误

---

## 完整传输流程

### 发送方流程

1. **健康检查** (可选但推荐)
   ```
   GET http://192.168.1.200:8080/health
   ```

2. **请求确认接收**
   ```
   GET http://192.168.1.200:8080/confirm-receive?fileName=test.pdf&fileSize=1024&senderIP=192.168.1.100
   ```
   
3. **等待接收方确认**
   - 如果返回 `accepted: true`，继续下一步
   - 如果返回 `accepted: false`，停止传输

4. **传输文件**
   ```
   POST http://192.168.1.200:8080/transfer?fileName=test.pdf&fileSize=1024&senderIP=192.168.1.100&transferId=<从步骤2获取>
   Content-Type: application/octet-stream
   
   <文件数据>
   ```

### 接收方流程

1. **接收确认请求**
   - 弹窗询问用户是否接收文件
   - 显示文件名、大小、发送方 IP

2. **用户确认**
   - 如果用户点击"接收"，返回 `accepted: true` 和 `transferId`
   - 如果用户点击"拒绝"，返回 `accepted: false`

3. **接收文件数据**
   - 验证 `transferId` 是否有效
   - 保存文件到下载目录
   - 返回保存路径

---

## 错误处理

所有错误响应都遵循以下格式：

```json
{
  "success": false,  // 或 "accepted": false
  "message": "错误描述信息"
}
```

### 常见错误信息

| 错误信息 | 说明 | 解决方法 |
|---------|------|---------|
| 缺少文件名参数 | fileName 参数未提供 | 检查请求参数 |
| 缺少文件大小参数 | fileSize 参数未提供 | 检查请求参数 |
| 文件大小参数格式错误 | fileSize 不是有效的整数 | 确保 fileSize 是数字 |
| 缺少发送者 IP 参数 | senderIP 参数未提供 | 检查请求参数 |
| 缺少传输 ID 参数 | transferId 参数未提供 | 先调用 /confirm-receive |
| 未找到确认记录 | transferId 无效或已过期 | 重新调用 /confirm-receive |
| 用户拒绝接收文件 | 用户点击了拒绝按钮 | 通知用户传输被拒绝 |
| 存储空间不足 | 设备存储空间不足 | 清理存储空间 |
| 文件大小不匹配 | 实际接收的文件大小与声明不符 | 检查网络连接，重试 |

---

## 安全考虑

1. **局域网限制**: 此 API 仅设计用于局域网环境，不应暴露到公网
2. **无认证**: 当前版本不包含认证机制，任何能访问的设备都可以发送文件
3. **用户确认**: 所有文件接收都需要用户手动确认
4. **文件大小限制**: 最大文件大小为 2GB
5. **一次性 transferId**: 每个 transferId 只能使用一次，使用后自动失效

---

## 示例代码

### 使用 curl 发送文件

```bash
# 1. 健康检查
curl http://192.168.1.200:8080/health

# 2. 请求确认
RESPONSE=$(curl -s "http://192.168.1.200:8080/confirm-receive?fileName=test.txt&fileSize=1024&senderIP=192.168.1.100")
TRANSFER_ID=$(echo $RESPONSE | jq -r '.transferId')

# 3. 传输文件
curl -X POST \
  -H "Content-Type: application/octet-stream" \
  --data-binary @test.txt \
  "http://192.168.1.200:8080/transfer?fileName=test.txt&fileSize=1024&senderIP=192.168.1.100&transferId=$TRANSFER_ID"
```

### 使用 Dart/Flutter

```dart
// 1. 请求确认
final confirmUri = Uri.parse('http://192.168.1.200:8080/confirm-receive')
  .replace(queryParameters: {
    'fileName': 'test.txt',
    'fileSize': '1024',
    'senderIP': '192.168.1.100',
  });

final confirmResponse = await http.get(confirmUri);
final confirmData = jsonDecode(confirmResponse.body);

if (confirmData['accepted'] == true) {
  final transferId = confirmData['transferId'];
  
  // 2. 传输文件
  final transferUri = Uri.parse('http://192.168.1.200:8080/transfer')
    .replace(queryParameters: {
      'fileName': 'test.txt',
      'fileSize': '1024',
      'senderIP': '192.168.1.100',
      'transferId': transferId,
    });
  
  final request = http.Request('POST', transferUri);
  request.headers['Content-Type'] = 'application/octet-stream';
  request.bodyBytes = await file.readAsBytes();
  
  final response = await request.send();
  // 处理响应...
}
```
