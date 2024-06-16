INSTALL_TARGET_PROCESSES = Swifile
TARGET = iphone:clang:15.5:15.0

include $(THEOS)/makefiles/common.mk

export SYSROOT
export ARCHS

XCODEPROJ_NAME = Swifile

ifeq ($(USE_FPC), 1)
	TARGET_ROOTHELPER = PascalRootHelper
else
	TARGET_ROOTHELPER = RootHelper
endif

Swifile_CODESIGN_FLAGS = -SSwifile/Swifile.entitlements

after-stage::
	make -C $(TARGET_ROOTHELPER)
	cp RootHelper/RootHelper $(THEOS_STAGING_DIR)/Applications/Swifile.app/RootHelper

include $(THEOS_MAKE_PATH)/xcodeproj.mk
