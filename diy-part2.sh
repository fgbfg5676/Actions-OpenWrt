#!/bin/bash

# 1. 创建 DTS 目录（适配 lede 源码结构）
mkdir -p target/linux/ipq40xx/dts

# 2. 写入 CM520-79F 的 DTS 文件（包含 OpBoot 适配配置）
cat > target/linux/ipq40xx/dts/qcom-ipq4019-cm520-79f.dts << 'EOF'
/dts-v1/;
#include "qcom-ipq4019.dtsi"
#include <dt-bindings/gpio/gpio.h>
#include <dt-bindings/input/input.h>

/ {
    model = "MobiPromo CM520-79F";
    compatible = "mobipromo,cm520-79f", "qcom,ipq4019";

    chosen {
        bootargs-append = " ubi.block=0,1 root=/dev/ubiblock0_1";
    };

    leds {
        compatible = "gpio-leds";
        status {
            label = "cm520-79f:blue:status";
            gpios = <&gpio 5 GPIO_ACTIVE_LOW>;
        };
    };
};

&nand {
    pinctrl-0 = <&nand_pins>;
    pinctrl-names = "default";
    status = "okay";

    nand@0 {
        partitions {
            compatible = "fixed-partitions";
            #address-cells = <1>;
            #size-cells = <1>;

            partition@0 {
                label = "Bootloader";
                reg = <0x0 0xb00000>;
                read-only;
            };

            art: partition@b00000 {
                label = "ART";
                reg = <0xb00000 0x80000>;
                read-only;
            };

            partition@b80000 {
                label = "rootfs";
                reg = <0xb80000 0x7480000>;
            };
        };
    };
};

&gmac0 { status = "okay"; };
&gmac1 { status = "okay"; };
&wlan0 { status = "okay"; };
&wlan1 { status = "okay"; };
EOF

# 3. 修改设备定义文件（generic.mk），添加 CM520-79F 配置
# 找到 ipq40xx 的 generic.mk 并追加设备定义
cat >> target/linux/ipq40xx/image/generic.mk << 'EOF'
define Device/mobipromo_cm520-79f
  $(call Device/FitImage)
  $(call Device/UbiFit)
  DEVICE_VENDOR := MobiPromo
  DEVICE_MODEL := CM520-79F
  DEVICE_DTS := qcom-ipq4019-cm520-79f
  IMAGE_SIZE := 116000k  # 与 DTS 中 rootfs 分区大小匹配（116MB）
  # 生成 OpBoot 兼容的 TRX 固件（头部标识 0x27051956）
  IMAGE/sysupgrade.bin := append-kernel | append-rootfs | trx -H 0x27051956 | pad-rootfs | check-size $$(IMAGE_SIZE)
  SUPPORTED_DEVICES += cm520-79f
endef
TARGET_DEVICES += mobipromo_cm520-79f
EOF

# 4. 可选：修改默认配置（如默认 IP、主题等）
# sed -i 's/192.168.1.1/192.168.5.1/g' package/base-files/files/bin/config_generate
