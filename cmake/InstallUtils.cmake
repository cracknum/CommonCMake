# ============================================================
#  InstallUtils.cmake（CommonCMake 通用模块）
#  常用安装/导出基础设施，供各项目复用。
#
#  提供函数：
#    install_export_package(...)        一键生成并安装 CMake 包
#                                        （Targets + Config + Version 文件）
#    add_export_header(...)             生成动态库导出宏头文件
#    add_uninstall_target()             添加 uninstall 目标
#    add_windows_version_resource(...)  Windows DLL/EXE 注入 VERSIONINFO 资源
# ============================================================

# ------------------------------------------------------------
#  install_export_package —— 通用安装 + 导出 + 包配置
#
#  参数：
#    TARGETS <t1> <t2> ...     要安装/导出的目标（必填）
#    PACKAGE <name>            包名，如 GeneralStateMachine（必填）
#    NAMESPACE <ns>            导出命名空间，如 GeneralStateMachine::（必填）
#    CONFIG_TEMPLATE <file>    包配置模板 <PACKAGE>Config.cmake.in（必填，项目自备）
#    [COMPATIBILITY <mode>]    版本兼容策略，默认 SameMajorVersion
#    [VERSION <ver>]           包版本，默认 ${PROJECT_VERSION}
#    [INCLUDE_HEADERS <h...>]  可选：随包安装的头文件
#    [HEADER_DEST <dir>]       头文件安装目录，默认 ${CMAKE_INSTALL_INCLUDEDIR}
#
#  产物布局（find_package(<PACKAGE> CONFIG) 标准结构）：
#    bin/<exe/dll>；lib/<so/a>；lib/cmake/<PACKAGE>/{Targets,Config,ConfigVersion}.cmake
# ------------------------------------------------------------
function(install_export_package)
    cmake_parse_arguments(PKG
        ""
        "PACKAGE;NAMESPACE;CONFIG_TEMPLATE;COMPATIBILITY;VERSION;HEADER_DEST"
        "TARGETS;INCLUDE_HEADERS"
        ${ARGN}
    )

    if(NOT PKG_PACKAGE)
        message(FATAL_ERROR "install_export_package: PACKAGE <name> is required")
    endif()
    if(NOT PKG_NAMESPACE)
        message(FATAL_ERROR "install_export_package: NAMESPACE <ns> is required")
    endif()
    if(NOT PKG_CONFIG_TEMPLATE)
        message(FATAL_ERROR
            "install_export_package: CONFIG_TEMPLATE <${PKG_PACKAGE}Config.cmake.in> is required")
    endif()
    if(NOT PKG_TARGETS)
        message(FATAL_ERROR "install_export_package: TARGETS <t1 t2 ...> is required")
    endif()

    include(GNUInstallDirs)
    include(CMakePackageConfigHelpers)

    set(_pkg_dir "${CMAKE_INSTALL_LIBDIR}/cmake/${PKG_PACKAGE}")
    if(NOT PKG_COMPATIBILITY)
        set(PKG_COMPATIBILITY SameMajorVersion)
    endif()
    if(NOT PKG_VERSION)
        set(PKG_VERSION "${PROJECT_VERSION}")
    endif()

    # 1) 目标安装 + 导出
    install(TARGETS ${PKG_TARGETS}
        EXPORT ${PKG_PACKAGE}Targets
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
        LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
        ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
        INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
    )
    install(EXPORT ${PKG_PACKAGE}Targets
        NAMESPACE ${PKG_NAMESPACE}
        DESTINATION ${_pkg_dir}
    )

    # 2) Config + Version 文件
    configure_package_config_file(
        "${PKG_CONFIG_TEMPLATE}"
        "${CMAKE_CURRENT_BINARY_DIR}/${PKG_PACKAGE}Config.cmake"
        INSTALL_DESTINATION "${_pkg_dir}"
    )
    write_basic_package_version_file(
        "${CMAKE_CURRENT_BINARY_DIR}/${PKG_PACKAGE}ConfigVersion.cmake"
        VERSION ${PKG_VERSION}
        COMPATIBILITY ${PKG_COMPATIBILITY}
    )
    install(FILES
        "${CMAKE_CURRENT_BINARY_DIR}/${PKG_PACKAGE}Config.cmake"
        "${CMAKE_CURRENT_BINARY_DIR}/${PKG_PACKAGE}ConfigVersion.cmake"
        DESTINATION "${_pkg_dir}"
    )

    # 3) 可选头文件
    if(PKG_INCLUDE_HEADERS)
        if(NOT PKG_HEADER_DEST)
            set(PKG_HEADER_DEST "${CMAKE_INSTALL_INCLUDEDIR}")
        endif()
        install(FILES ${PKG_INCLUDE_HEADERS} DESTINATION "${PKG_HEADER_DEST}")
    endif()
endfunction()

# ------------------------------------------------------------
#  add_uninstall_target —— 添加 uninstall 自定义目标
#  用法：cmake --build <build_dir> --target uninstall
#  通过安装清单 install_manifest.txt 删除已安装文件。
#  已在构建树中时幂等（不重复添加）。
# ------------------------------------------------------------
function(add_uninstall_target)
    if(TARGET uninstall)
        return()
    endif()
    configure_file(
        "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/cmake_uninstall.cmake.in"
        "${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake"
        @ONLY
    )
    add_custom_target(uninstall
        COMMAND "${CMAKE_COMMAND}" -P "${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake"
        COMMENT "Uninstall the project (removes files listed in install_manifest.txt)"
        VERBATIM
    )
endfunction()

# ------------------------------------------------------------
#  add_windows_version_resource —— 给目标注入 Windows VERSIONINFO 资源
#
#  参数：
#    TARGET <t>                目标名（必填，第一个位置参数）
#    [PREFIX <prefix>]         版本变量名前缀，默认 PROJECT
#                              （即读取 ${prefix}_VERSION，例如 read_version 产生的
#                               GENERAL_STATE_MACHINE_VERSION）
#    [TEMPLATE <file>]         资源模板，默认 CommonCMake 自带的 version.rc.in
#    [COMPANY_NAME ...] / [FILE_DESCRIPTION ...] / [INTERNAL_NAME ...]
#    [LEGAL_COPYRIGHT ...] / [ORIGINAL_FILENAME ...] / [PRODUCT_NAME ...]
#
#  非 Windows 平台自动跳过；版本号须先就绪（project() 或 read_version()）。
# ------------------------------------------------------------
function(add_windows_version_resource TARGET)
    if(NOT WIN32)
        return()
    endif()

    cmake_parse_arguments(VR
        ""
        "PREFIX;TEMPLATE;COMPANY_NAME;FILE_DESCRIPTION;INTERNAL_NAME;LEGAL_COPYRIGHT;ORIGINAL_FILENAME;PRODUCT_NAME"
        ""
        ${ARGN}
    )

    if(NOT VR_PREFIX)
        set(VR_PREFIX PROJECT)
    endif()
    if(NOT VR_TEMPLATE)
        set(VR_TEMPLATE "${CommonCMake_MODULE_DIR}/version.rc.in")
    endif()

    set(_version "${${VR_PREFIX}_VERSION}")
    if(_version STREQUAL "")
        message(FATAL_ERROR
            "add_windows_version_resource: variable ${VR_PREFIX}_VERSION is not set. "
            "Call read_version() or project(... VERSION ...) before using this function.")
    endif()

    set(PROJECT_VERSION        "${_version}")
    string(REPLACE "." "," PROJECT_VERSION_COMMA "${_version}")
    set(PROJECT_COMPANY_NAME      "${VR_COMPANY_NAME}")
    set(PROJECT_FILE_DESCRIPTION  "${VR_FILE_DESCRIPTION}")
    set(PROJECT_INTERNAL_NAME     "${VR_INTERNAL_NAME}")
    set(PROJECT_LEGAL_COPYRIGHT   "${VR_LEGAL_COPYRIGHT}")
    set(PROJECT_ORIGINAL_FILENAME "${VR_ORIGINAL_FILENAME}")
    set(PROJECT_PRODUCT_NAME      "${VR_PRODUCT_NAME}")

    set(_rc_output "${CMAKE_CURRENT_BINARY_DIR}/${VR_PREFIX}_version.rc")
    configure_file("${VR_TEMPLATE}" "${_rc_output}" @ONLY)
    target_sources(${TARGET} PRIVATE "${_rc_output}")
endfunction()

# ------------------------------------------------------------
#  add_export_header —— 为动态库目标生成导出宏头文件
#
#  参数：
#    TARGET <t>               目标名（必填，第一个位置参数）
#    [PREFIX <prefix>]        宏前缀，默认目标名大写
#                             （如 PREFIX MYLIB → 生成 MYLIB_EXPORT）
#    [OUTPUT_NAME <file>]     输出头文件名，默认 <prefix 小写>_export.h
#    [STATIC_DEFINE <name>]   静态库置空宏的宏名，默认 <PREFIX>_STATIC_DEFINE
#
#  行为：
#    - 由 CommonCMake 自带模板 export.h.in 生成
#      ${CMAKE_CURRENT_BINARY_DIR}/<OUTPUT_NAME>
#    - 生成目录加入目标 PUBLIC include 路径（构建/安装双接口）
#    - 非 Windows 平台自动设置 CXX_VISIBILITY_PRESET=hidden、
#      VISIBILITY_INLINES_HIDDEN=ON，使 visibility("default") 生效
#
#  用法：
#    add_library(mylib SHARED ...)
#    add_export_header(mylib PREFIX MYLIB)
#    # 源码中：#include "mylib_export.h"
#    #         class MYLIB_EXPORT MyClass { ... };
# ------------------------------------------------------------
function(add_export_header TARGET)
    cmake_parse_arguments(EH "" "PREFIX;OUTPUT_NAME;STATIC_DEFINE" "" ${ARGN})

    if(NOT EH_PREFIX)
        string(TOUPPER "${TARGET}" EH_PREFIX)
    endif()
    if(NOT EH_OUTPUT_NAME)
        string(TOLOWER "${EH_PREFIX}" _prefix_lower)
        set(EH_OUTPUT_NAME "${_prefix_lower}_export.h")
    endif()
    if(NOT EH_STATIC_DEFINE)
        set(EH_STATIC_DEFINE "${EH_PREFIX}_STATIC_DEFINE")
    endif()

    # 构建 SHARED 库时 CMake 自动定义 <TARGET>_EXPORTS，模板据此区分
    # 构建态（dllexport）与消费态（dllimport）。
    set(TARGET_EXPORT_DEFINE "${TARGET}_EXPORTS")
    set(PREFIX "${EH_PREFIX}")
    configure_file(
        "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/export.h.in"
        "${CMAKE_CURRENT_BINARY_DIR}/${EH_OUTPUT_NAME}"
        @ONLY
    )

    target_sources(${TARGET} PRIVATE "${CMAKE_CURRENT_BINARY_DIR}/${EH_OUTPUT_NAME}")
    target_include_directories(${TARGET} PUBLIC
        "$<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}>"
        "$<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>"
    )

    # 非 Windows：默认隐藏符号，仅导出标了 @PREFIX@_EXPORT 的接口
    if(NOT WIN32)
        set_target_properties(${TARGET} PROPERTIES
            CXX_VISIBILITY_PRESET hidden
            VISIBILITY_INLINES_HIDDEN ON
        )
    endif()
endfunction()
