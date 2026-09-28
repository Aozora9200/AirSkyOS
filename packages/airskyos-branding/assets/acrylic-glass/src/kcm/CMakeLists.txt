set(kwin_aozoraglass_config_SRCS
    config.cpp
    config.h
)

ki18n_wrap_ui(kwin_aozoraglass_config_SRCS config.ui)
kconfig_add_kcfg_files(kwin_aozoraglass_config_SRCS ../glassconfig.kcfgc)

# This will only work as long as KWin and KWin X11 have the same interface
qt_add_dbus_interface(kwin_aozoraglass_config_SRCS ${KWIN_EFFECTS_INTERFACE} kwineffects_interface)

add_library(kwin_aozoraglass_config MODULE ${kwin_aozoraglass_config_SRCS})
target_link_libraries(kwin_aozoraglass_config
    KF6::KCMUtils
    KF6::CoreAddons
    KF6::I18n
    Qt6::DBus
)

if(GLASS_WAYLAND)
    install(TARGETS kwin_aozoraglass_config DESTINATION ${KDE_INSTALL_PLUGINDIR}/kwin/effects/configs)
endif()
if(GLASS_X11)
    install(TARGETS kwin_aozoraglass_config DESTINATION ${KDE_INSTALL_PLUGINDIR}/kwin-x11/effects/configs)
endif()
