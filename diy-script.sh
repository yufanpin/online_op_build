#!/bin/bash

### ========== 1. 添加 feed 源 ==========
echo 'src-git kiddin9 https://github.com/kiddin9/kwrt-packages.git' >>feeds.conf.default
# echo 'src-git smpackage https://github.com/kenzok8/small-package.git' >>feeds.conf.default

### ========== 2. 添加额外插件 ==========
git clone --depth=1 https://github.com/lwb1978/openwrt-gecoosac.git package/openwrt-gecoosac
git clone --depth=1 https://github.com/selfcan/luci-app-onliner.git package/luci-app-onliner
git clone --depth=1 https://github.com/sirpdboy/luci-app-netspeedtest.git package/luci-app-netspeedtest
git clone --depth=1 https://github.com/sirpdboy/luci-app-partexp.git package/luci-app-partexp
git clone --depth=1 https://github.com/destan19/OpenAppFilter.git package/OpenAppFilter



### ========== 3. 修改默认 IP、主机名、界面信息等 ==========
# 修改默认 IP 地址
sed -i 's/192.168.1.1/192.168.10.1/g' package/base-files/files/bin/config_generate

# 修改默认主机名
sed -i "s/hostname='.*'/hostname='HOMR'/g" package/base-files/files/bin/config_generate

# 添加 LuCI 状态页的构建信息  这行代码有问题，版本号会跟固件内核版本号对应不上
# sed -i "s/(\(luciversion || ''\))/(\1) + (' \/ Build by Superman')/g" feeds/luci/modules/luci-mod-status/htdocs/luci-static/resources/view/status/include/10_system.js

# TTYD 免登录
# sed -i 's|/bin/login|/bin/login -f root|g' feeds/packages/utils/ttyd/files/ttyd.config

# 修改本地时间格式显示
sed -i 's/os.date()/os.date("%a %Y-%m-%d %H:%M:%S")/g' package/lean/autocore/files/*/index.htm

# 修改版本号为编译日期 + 自定义名
date_version=$(date +"%y.%m.%d")
orig_version=$(grep "DISTRIB_REVISION=" package/lean/default-settings/files/zzz-default-settings | awk -F "'" '{print $2}')
sed -i "s/${orig_version}/R${date_version} by Superman/g" package/lean/default-settings/files/zzz-default-settings


### ========== 4. 修复兼容问题 ==========
# 修复 hostapd 报错
cp -f $GITHUB_WORKSPACE/scripts/011-fix-mbo-modules-build.patch package/network/services/hostapd/patches/011-fix-mbo-modules-build.patch

# 修复 armv8 平台 xfsprogs 报错
sed -i 's/TARGET_CFLAGS.*/TARGET_CFLAGS += -DHAVE_MAP_SYNC -D_LARGEFILE64_SOURCE/g' feeds/packages/utils/xfsprogs/Makefile

### ========== 5. 统一修正 Makefile 引用路径 ==========
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's|\.\./\.\./luci.mk|$(TOPDIR)/feeds/luci/luci.mk|g' {}
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's|\.\./\.\./lang/golang/golang-package.mk|$(TOPDIR)/feeds/packages/lang/golang/golang-package.mk|g' {}
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's|PKG_SOURCE_URL:=@GHREPO|PKG_SOURCE_URL:=https://github.com|g' {}
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's|PKG_SOURCE_URL:=@GHCODELOAD|PKG_SOURCE_URL:=https://codeload.github.com|g' {}



### ========== 6. 拉取 feeds ==========
./scripts/feeds update -a
./scripts/feeds install -a



### ========== 7. 应用 LED 补丁 ==========
#京东云太乙的led灯的补丁，设备正常运行亮绿灯
echo "Applying LED green status patch..."
PATCH_DIR="$GITHUB_WORKSPACE/patches/led"
[ -f "$PATCH_DIR/led_green_status_ipq60xx.patch" ] && patch -p1 < "$PATCH_DIR/led_green_status_ipq60xx.patch"
