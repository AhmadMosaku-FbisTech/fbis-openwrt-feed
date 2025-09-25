include $(TOPDIR)/rules.mk

PKG_NAME:=fbis-firmware
PKG_VERSION:=1.0
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/fbis-firmware
  SECTION:=net
  CATEGORY:=Network
  TITLE:=FBIS Router Firmware (Carrier Gatekeeper + VPN + Key Updater)
  DEPENDS:=+iptables +kmod-usb-net +wireguard-tools +python3 +wget-ssl
endef

define Package/fbis-firmware/description
Firmware for router-to-central-server communication:
- IMSI carrier gatekeeper (carrier_check.sh)
- VPN setup (WireGuard)
- Digital twin synchronization daemon (fbisd.py)
- Automatic opkg feed GPG key updater
endef

define Build/Prepare
	# nothing to prepare (source compiled in src/c)
	mkdir -p $(PKG_BUILD_DIR)
	cp -r ../../src $(PKG_BUILD_DIR)/
endef

define Build/Compile
	$(MAKE) -C $(PKG_BUILD_DIR)/c CC="$(TARGET_CC)" CFLAGS="$(TARGET_CFLAGS)" all
	$(INSTALL_DIR) $(PKG_BUILD_DIR)/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/c/fbis_core $(PKG_BUILD_DIR)/bin/
endef

define Package/fbis-firmware/install
	# install scripts
	$(INSTALL_DIR) $(1)/etc/fbis
	$(INSTALL_BIN) ./files/etc/fbis/*.sh $(1)/etc/fbis/
	$(INSTALL_CONF) ./files/etc/fbis/fbis.conf $(1)/etc/fbis/

	# init script
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/etc/init.d/fbis $(1)/etc/init.d/

	# daemons / binaries
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) ./files/usr/sbin/*.py $(1)/usr/sbin/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/bin/fbis_core $(1)/usr/sbin/fbis_core

	# opkg key updater and uci-defaults patch
	$(INSTALL_DIR) $(1)/etc/opkg/keys
	$(INSTALL_BIN) ./files/etc/opkg/keys/update-keys.sh $(1)/etc/opkg/keys/update-keys.sh

	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) ./files/etc/uci-defaults/99-fbis-opkg-patch $(1)/etc/uci-defaults/99-fbis-opkg-patch
endef

$(eval $(call BuildPackage,fbis-firmware))
