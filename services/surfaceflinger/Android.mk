LOCAL_PATH := $(call my-dir)
include $(CLEAR_VARS)

LOCAL_CLANG := true

LOCAL_ADDITIONAL_DEPENDENCIES := $(LOCAL_PATH)/Android.mk
LOCAL_SRC_FILES := \
    Client.cpp \
    DisplayDevice.cpp \
    DispSync.cpp \
    EventControlThread.cpp \
    EventThread.cpp \
    FenceTracker.cpp \
    FrameTracker.cpp \
    GpuService.cpp \
    Layer.cpp \
    LayerDim.cpp \
    MessageQueue.cpp \
    MonitoredProducer.cpp \
    SurfaceFlingerConsumer.cpp \
    Transform.cpp \
    DisplayHardware/FramebufferSurface.cpp \
    DisplayHardware/HWC2.cpp \
    DisplayHardware/HWC2On1Adapter.cpp \
    DisplayHardware/PowerHAL.cpp \
    DisplayHardware/VirtualDisplaySurface.cpp \
    Effects/Daltonizer.cpp \
    EventLog/EventLogTags.logtags \
    EventLog/EventLog.cpp \
    RenderEngine/Description.cpp \
    RenderEngine/Mesh.cpp \
    RenderEngine/Program.cpp \
    RenderEngine/ProgramCache.cpp \
    RenderEngine/GLExtensions.cpp \
    RenderEngine/RenderEngine.cpp \
    RenderEngine/Texture.cpp \
    RenderEngine/GLES10RenderEngine.cpp \
    RenderEngine/GLES11RenderEngine.cpp \
    RenderEngine/GLES20RenderEngine.cpp \
    DisplayUtils.cpp \
    ExSurfaceFlinger/ExLayer.cpp \
    ExSurfaceFlinger/ExSurfaceFlinger.cpp \
    ExSurfaceFlinger/ExVirtualDisplaySurface.cpp \
    ExSurfaceFlinger/ExHWComposer.cpp

LOCAL_C_INCLUDES := \
	frameworks/native/vulkan/include \
	external/vulkan-validation-layers/libs/vkjson

LOCAL_CFLAGS := -DLOG_TAG=\"SurfaceFlinger\"

ifeq ($(TARGET_BUILD_VARIANT),userdebug)
LOCAL_CFLAGS += -DDEBUG_CONT_DUMPSYS
endif

LOCAL_CFLAGS += -DGL_GLEXT_PROTOTYPES -DEGL_EGLEXT_PROTOTYPES

ifeq ($(TARGET_USES_HWC2),true)
    LOCAL_CFLAGS += -DUSE_HWC2
    LOCAL_SRC_FILES += \
        SurfaceFlinger.cpp \
        DisplayHardware/HWComposer.cpp
else
    LOCAL_SRC_FILES += \
        SurfaceFlinger_hwc1.cpp \
        DisplayHardware/HWComposer_hwc1.cpp
endif

ifeq ($(TARGET_BOARD_PLATFORM),omap4)
    LOCAL_CFLAGS += -DHAS_CONTEXT_PRIORITY
endif
ifeq ($(TARGET_BOARD_PLATFORM),s5pc110)
    LOCAL_CFLAGS += -DHAS_CONTEXT_PRIORITY
endif

ifeq ($(TARGET_DISABLE_TRIPLE_BUFFERING),true)
    LOCAL_CFLAGS += -DTARGET_DISABLE_TRIPLE_BUFFERING
endif

ifeq ($(TARGET_FORCE_HWC_FOR_VIRTUAL_DISPLAYS),true)
    LOCAL_CFLAGS += -DFORCE_HWC_COPY_FOR_VIRTUAL_DISPLAYS
endif

ifneq ($(NUM_FRAMEBUFFER_SURFACE_BUFFERS),)
    LOCAL_CFLAGS += -DNUM_FRAMEBUFFER_SURFACE_BUFFERS=$(NUM_FRAMEBUFFER_SURFACE_BUFFERS)
endif

ifeq ($(TARGET_RUNNING_WITHOUT_SYNC_FRAMEWORK),true)
    LOCAL_CFLAGS += -DRUNNING_WITHOUT_SYNC_FRAMEWORK
endif

# The following two BoardConfig variables define (respectively):
#
#   - The phase offset between hardware vsync and when apps are woken up by the
#     Choreographer callback
#   - The phase offset between hardware vsync and when SurfaceFlinger wakes up
#     to consume input
#
# Their values can be tuned to trade off between display pipeline latency (both
# overall latency and the lengths of the app --> SF and SF --> display phases)
# and frame delivery jitter (which typically manifests as "jank" or "jerkiness"
# while interacting with the device). The default values should produce a
# relatively low amount of jitter at the expense of roughly two frames of
# app --> display latency, and unless significant testing is performed to avoid
# increased display jitter (both manual investigation using systrace [1] and
# automated testing using dumpsys gfxinfo [2] are recommended), they should not
# be modified.
#
# [1] https://developer.android.com/studio/profile/systrace.html
# [2] https://developer.android.com/training/testing/performance.html

# On HWC2, SurfaceFlinger races against hardware vsync on untuned video-mode
# panels, which can result in a significant number of dropped frames. HWC1
# does not have this issue, so set the offsets to 1ms on HWC2 and 0ms for HWC1.

ifneq ($(VSYNC_EVENT_PHASE_OFFSET_NS),)
    LOCAL_CFLAGS += -DVSYNC_EVENT_PHASE_OFFSET_NS=$(VSYNC_EVENT_PHASE_OFFSET_NS)
else
    ifeq ($(TARGET_USES_HWC2),true)
        LOCAL_CFLAGS += -DVSYNC_EVENT_PHASE_OFFSET_NS=1000000
    else
        LOCAL_CFLAGS += -DVSYNC_EVENT_PHASE_OFFSET_NS=0
    endif
endif

ifneq ($(SF_VSYNC_EVENT_PHASE_OFFSET_NS),)
    LOCAL_CFLAGS += -DSF_VSYNC_EVENT_PHASE_OFFSET_NS=$(SF_VSYNC_EVENT_PHASE_OFFSET_NS)
else
    ifeq ($(TARGET_USES_HWC2),true)
        LOCAL_CFLAGS += -DSF_VSYNC_EVENT_PHASE_OFFSET_NS=1000000
    else
        LOCAL_CFLAGS += -DSF_VSYNC_EVENT_PHASE_OFFSET_NS=0
    endif
endif

ifneq ($(PRESENT_TIME_OFFSET_FROM_VSYNC_NS),)
    LOCAL_CFLAGS += -DPRESENT_TIME_OFFSET_FROM_VSYNC_NS=$(PRESENT_TIME_OFFSET_FROM_VSYNC_NS)
else
    LOCAL_CFLAGS += -DPRESENT_TIME_OFFSET_FROM_VSYNC_NS=0
endif

ifneq ($(MAX_VIRTUAL_DISPLAY_DIMENSION),)
    LOCAL_CFLAGS += -DMAX_VIRTUAL_DISPLAY_DIMENSION=$(MAX_VIRTUAL_DISPLAY_DIMENSION)
else
    LOCAL_CFLAGS += -DMAX_VIRTUAL_DISPLAY_DIMENSION=0
endif

LOCAL_CFLAGS += -fvisibility=hidden -Werror=format
LOCAL_CFLAGS += -std=c++14

LOCAL_STATIC_LIBRARIES := libvkjson
LOCAL_SHARED_LIBRARIES := \
    libcutils \
    liblog \
    libdl \
    libhardware \
    libutils \
    libEGL \
    libGLESv1_CM \
    libGLESv2 \
    libbinder \
    libui \
    libgui \
    libpowermanager \
    libvulkan

ifeq ($(TARGET_USES_QCOM_BSP), true)
  ifeq ($(TARGET_SUPPORTS_WEARABLES),true)
    LOCAL_C_INCLUDES += $(BOARD_DISPLAY_HAL)/libgralloc
    LOCAL_C_INCLUDES += $(BOARD_DISPLAY_HAL)/libqdutils
  else
    LOCAL_C_INCLUDES += $(TARGET_OUT_HEADERS)/qcom/display
  endif
    LOCAL_SHARED_LIBRARIES += libqdutils
    LOCAL_SHARED_LIBRARIES += libqdMetaData
    LOCAL_CFLAGS += -DQTI_BSP

  ifeq ($(TARGET_SUPPORTS_COLOR_METADATA),)
    ifeq ($(call is-board-platform-in-list, msm8996), true)
      TARGET_SUPPORTS_COLOR_METADATA := true
    endif
  endif

  ifeq ($(TARGET_SUPPORTS_COLOR_METADATA), true)
      LOCAL_CFLAGS += -DUSE_COLOR_METADATA
  endif

endif

LOCAL_MODULE := libsurfaceflinger

LOCAL_CFLAGS += -Wall -Werror -Wunused -Wunreachable-code

LOCAL_SDCLANG_LTO := true

include $(BUILD_SHARED_LIBRARY)

###############################################################
# build surfaceflinger's executable
include $(CLEAR_VARS)

LOCAL_CLANG := true

LOCAL_LDFLAGS := -Wl,--version-script,art/sigchainlib/version-script.txt -Wl,--export-dynamic
LOCAL_CFLAGS := -DLOG_TAG=\"SurfaceFlinger\"
LOCAL_CPPFLAGS := -std=c++14

LOCAL_INIT_RC := surfaceflinger.rc

ifeq ($(TARGET_USES_HWC2),true)
    LOCAL_CFLAGS += -DUSE_HWC2
endif

LOCAL_SRC_FILES := \
    main_surfaceflinger.cpp

LOCAL_SHARED_LIBRARIES := \
    libsurfaceflinger \
    libcutils \
    liblog \
    libbinder \
    libutils \
    libdl

LOCAL_WHOLE_STATIC_LIBRARIES := libsigchain

LOCAL_MODULE := surfaceflinger

ifdef TARGET_32_BIT_SURFACEFLINGER
LOCAL_32_BIT_ONLY := true
endif

LOCAL_CFLAGS += -Wall -Werror -Wunused -Wunreachable-code

include $(BUILD_EXECUTABLE)

###############################################################
# uses jni which may not be available in PDK
ifneq ($(wildcard libnativehelper/include),)
include $(CLEAR_VARS)

LOCAL_CLANG := true

LOCAL_CFLAGS := -DLOG_TAG=\"SurfaceFlinger\"
LOCAL_CPPFLAGS := -std=c++14

LOCAL_SRC_FILES := \
    DdmConnection.cpp

LOCAL_SHARED_LIBRARIES := \
    libcutils \
    liblog \
    libdl

LOCAL_MODULE := libsurfaceflinger_ddmconnection

LOCAL_CFLAGS += -Wall -Werror -Wunused -Wunreachable-code

include $(BUILD_SHARED_LIBRARY)
endif # libnativehelper
