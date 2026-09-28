if(GLASS_WAYLAND OR GLASS_X11)
    add_subdirectory(kcm)
endif()

set(AOZORAGLASS_SHADER_INCLUDES
    sdf.glsl
    blur.glsl
    distort.glsl
    highlight.glsl
)

function(preprocess_shader_includes input output)
    file(READ "${input}" SHADER_SOURCE)
    foreach(include_file IN LISTS AOZORAGLASS_SHADER_INCLUDES)
        file(READ "shaders/${include_file}" INCLUDE_SOURCE)
        string(REPLACE "#include \"${include_file}\"" "${INCLUDE_SOURCE}" SHADER_SOURCE "${SHADER_SOURCE}")
    endforeach()
    file(WRITE "${output}" "${SHADER_SOURCE}")
endfunction()

preprocess_shader_includes(shaders/glass.glsl shaders/glass.frag)
preprocess_shader_includes(shaders/glass_core.glsl shaders/glass_core.frag)

set(aozoraglass_SOURCES
    effect.cpp
    aozoraglass.qrc
    main.cpp
)

kconfig_add_kcfg_files(aozoraglass_SOURCES
    glassconfig.kcfgc
)

if(GLASS_WAYLAND)
    add_library(aozoraglass MODULE ${aozoraglass_SOURCES})
    target_link_libraries(aozoraglass PRIVATE
        KDecoration3::KDecoration
        KF6::ConfigGui
        KWin::kwin
    )
    # GLASS_KWIN_67 drives the 6.6-vs-6.7 ABI gating in kwin_version_compat.h.
    if(GLASS_KWIN_67_WAYLAND)
        target_compile_definitions(aozoraglass PRIVATE GLASS_KWIN_67)
    endif()
    install(TARGETS aozoraglass DESTINATION ${KDE_INSTALL_PLUGINDIR}/kwin/effects/plugins)
endif()
if(GLASS_X11)
    add_library(aozoraglass_x11 MODULE ${aozoraglass_SOURCES})
    target_link_libraries(aozoraglass_x11 PRIVATE
        KDecoration3::KDecoration
        KF6::ConfigGui
        KWinX11::kwin
        XCB::XCB
    )
    target_compile_definitions(aozoraglass_x11 PRIVATE GLASS_X11)
    if(GLASS_KWIN_67_X11)
        target_compile_definitions(aozoraglass_x11 PRIVATE GLASS_KWIN_67)
    endif()
    install(TARGETS aozoraglass_x11 DESTINATION ${KDE_INSTALL_PLUGINDIR}/kwin-x11/effects/plugins)
endif()
