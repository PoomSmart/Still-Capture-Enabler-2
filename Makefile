PACKAGE_VERSION = 1.9.6
TARGET = iphone:clang:latest:5.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = StillCapture2
SUBPROJECTS = StillCapture2iOS456 StillCapture2iOS789

StillCapture2_FILES = Tweak.xm

include $(THEOS_MAKE_PATH)/tweak.mk
include $(THEOS_MAKE_PATH)/aggregate.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp -R Resources $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/StillCapture$(ECHO_END)
	$(ECHO_NOTHING)find $(THEOS_STAGING_DIR) -name .DS_Store | xargs rm -rf$(ECHO_END)
