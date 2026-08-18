cmake_minimum_required(VERSION 3.21)

# ============================================================
#  CommonCMake —— 通用 CMake 模块集合（独立仓库，供多项目复用）
#
#  提供模块（cmake/ 目录）：
#    VersionConfig.cmake   : read_version() 读取 version.json 单一版本来源
#    InstallUtils.cmake    : install_export_package() / add_uninstall_target()
#                            / add_windows_version_resource()
#    version.rc.in         : Windows VERSIONINFO 资源模板（参数化）
#    export.h.in           : 动态库导出宏头文件模板（add_export_header 使用）
#
#  消费方式（三选一）：
#    1. add_subdirectory(CommonCMake)             # 源码同级/子目录
#    2. FetchContent_Declare + FetchContent_MakeAvailable
#    3. cmake --install 安装后 find_package(CommonCMake CONFIG REQUIRED)
#
#  之后通过 CommonCMake_MODULE_DIR 引用模块，例如：
#    include("${CommonCMake_MODULE_DIR}/VersionConfig.cmake")
#    include("${CommonCMake_MODULE_DIR}/InstallUtils.cmake")
# ============================================================
project(CommonCMake VERSION 1.0.0 LANGUAGES NONE)

# 模块目录：add_subdirectory / FetchContent 消费方通过该变量引用模块；
# find_package 消费方由 CommonCMakeConfig.cmake 在安装目录设置同名变量。
set(CommonCMake_MODULE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/cmake" CACHE INTERNAL
    "Directory containing the CommonCMake modules")

# LANGUAGES NONE 时 GNUInstallDirs 无法探测目标架构（lib vs lib64），
# 显式固定为 lib；CommonCMake 只安装 cmake 配置文件，与消费项目保持一致。
if(NOT DEFINED CMAKE_INSTALL_LIBDIR)
    set(CMAKE_INSTALL_LIBDIR "lib")
endif()
include(GNUInstallDirs)
include(CMakePackageConfigHelpers)

# ---- 安装模块文件（含 .in 模板，find_package 消费方仍需使用）----
install(DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/cmake/"
    DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/CommonCMake"
)

# ---- 生成并安装 Config 包：find_package(CommonCMake CONFIG) ----
configure_package_config_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/cmake/CommonCMakeConfig.cmake.in"
    "${CMAKE_CURRENT_BINARY_DIR}/CommonCMakeConfig.cmake"
    INSTALL_DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/CommonCMake"
)
write_basic_package_version_file(
    "${CMAKE_CURRENT_BINARY_DIR}/CommonCMakeConfigVersion.cmake"
    VERSION ${PROJECT_VERSION}
    COMPATIBILITY AnyNewerVersion
)
install(FILES
    "${CMAKE_CURRENT_BINARY_DIR}/CommonCMakeConfig.cmake"
    "${CMAKE_CURRENT_BINARY_DIR}/CommonCMakeConfigVersion.cmake"
    DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/CommonCMake"
)

# ---- 自用：uninstall 目标（cmake --build . --target uninstall）----
include("${CMAKE_CURRENT_SOURCE_DIR}/cmake/InstallUtils.cmake")
add_uninstall_target()
