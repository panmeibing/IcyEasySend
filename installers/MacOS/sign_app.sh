#!/bin/bash

# 配置参数
APP_NAME="IcyEasySend"
SIGNING_IDENTITY="IcyHope"  # 修改为你的证书名称
APP_PATH="../../build/macos/Build/Products/Release/${APP_NAME}.app"
ENTITLEMENTS_PATH="../../macos/Runner/Release.entitlements"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}开始签名 ${APP_NAME}...${NC}"

# 检查应用是否存在
if [ ! -d "$APP_PATH" ]; then
    echo -e "${RED}错误: 应用不存在: $APP_PATH${NC}"
    echo "请先运行: flutter build macos --release"
    exit 1
fi

# 检查 entitlements 文件是否存在
if [ ! -f "$ENTITLEMENTS_PATH" ]; then
    echo -e "${RED}错误: Entitlements 文件不存在: $ENTITLEMENTS_PATH${NC}"
    exit 1
fi

# 检查证书是否存在
if ! security find-identity -v -p codesigning | grep -q "$SIGNING_IDENTITY"; then
    echo -e "${RED}错误: 找不到签名证书: $SIGNING_IDENTITY${NC}"
    echo "请在钥匙串访问中创建代码签名证书"
    exit 1
fi

echo -e "${GREEN}✓ 应用路径: $APP_PATH${NC}"
echo -e "${GREEN}✓ Entitlements: $ENTITLEMENTS_PATH${NC}"
echo -e "${GREEN}✓ 签名证书: $SIGNING_IDENTITY${NC}"

# 方法：使用 --deep 但不移除原有签名，只替换
echo -e "${YELLOW}使用 --deep 重新签名整个应用...${NC}"

# 直接使用 --deep 签名，让 codesign 处理所有内部组件
codesign --deep --force --sign "$SIGNING_IDENTITY" \
    --entitlements "$ENTITLEMENTS_PATH" \
    --options runtime \
    --timestamp \
    "$APP_PATH"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ 签名成功${NC}"
    
    # 验证签名
    echo -e "${YELLOW}验证签名...${NC}"
    codesign --verify --deep --strict --verbose=2 "$APP_PATH"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ 签名验证通过${NC}"
        
        # 检查 Gatekeeper 状态
        echo -e "${YELLOW}检查 Gatekeeper 状态...${NC}"
        spctl_result=$(spctl -a -v "$APP_PATH" 2>&1)
        if [[ $spctl_result == *"accepted"* ]]; then
            echo -e "${GREEN}✓ Gatekeeper 验证通过${NC}"
        else
            echo -e "${YELLOW}⚠ Gatekeeper 验证失败，但这对本地签名是正常的${NC}"
            echo -e "${YELLOW}  如果需要绕过 Gatekeeper，请运行:${NC}"
            echo -e "${YELLOW}  sudo spctl --master-disable${NC}"
            echo -e "${YELLOW}  或者右键点击应用选择"打开"${NC}"
        fi
        
        # 显示 entitlements
        echo -e "${YELLOW}应用权限配置:${NC}"
        codesign -d --entitlements - "$APP_PATH" 2>&1 | grep -A 20 "<dict>"
        
        echo -e "${GREEN}========================================${NC}"
        echo -e "${GREEN}签名完成！${NC}"
        echo -e "${GREEN}如果应用无法直接打开，请:${NC}"
        echo -e "${GREEN}1. 右键点击应用 -> 打开${NC}"
        echo -e "${GREEN}2. 或在终端运行: open \"$APP_PATH\"${NC}"
        echo -e "${GREEN}========================================${NC}"
    else
        echo -e "${RED}✗ 签名验证失败${NC}"
        
        # 尝试修复权限问题
        echo -e "${YELLOW}尝试修复权限问题...${NC}"
        chmod -R 755 "$APP_PATH"
        
        # 再次验证
        codesign --verify --verbose=2 "$APP_PATH"
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ 修复后验证通过${NC}"
        else
            echo -e "${RED}✗ 修复失败${NC}"
            exit 1
        fi
    fi
else
    echo -e "${RED}✗ 签名失败${NC}"
    exit 1
fi