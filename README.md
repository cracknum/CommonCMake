# CommonCMake

通用 CMake 模块集合（独立仓库），供多个项目复用的常见 CMake 功能：
版本管理、安装/导出、Windows 版本资源、卸载目标。

## 模块一览

| 模块文件 | 内容 |
|---|---|
| `cmake/VersionConfig.cmake` | `read_version()` —— 从 `version.json` 读取版本号（单一来源） |
| `cmake/InstallUtils.cmake` | `install_export_package()`、`add_uninstall_target()`、`add_windows_version_resource()` |
| `cmake/version.rc.in` | Windows VERSIONINFO 资源模板（参数化，随目标编译） |
| `cmake/cmake_uninstall.cmake.in` | 卸载脚本模板 |

## 消费方式（三选一）

### 1. `add_subdirectory`（源码同级 / 子目录）

```cmake
add_subdirectory(../CommonCMake "${CMAKE_CURRENT_BINARY_DIR}/CommonCMake")
include("${CommonCMake_MODULE_DIR}/VersionConfig.cmake")
include("${CommonCMake_MODULE_DIR}/InstallUtils.cmake")
```

### 2. `FetchContent`

```cmake
include(FetchContent)
FetchContent_Declare(CommonCMake
    GIT_REPOSITORY https://github.com/<owner>/CommonCMake.git
    GIT_TAG        v1.0.0
)
FetchContent_MakeAvailable(CommonCMake)
include("${CommonCMake_MODULE_DIR}/VersionConfig.cmake")
include("${CommonCMake_MODULE_DIR}/InstallUtils.cmake")
```

### 3. `find_package`（安装后）

```bash
cmake --install <CommonCMake_build> --prefix <prefix>
```

```cmake
find_package(CommonCMake CONFIG REQUIRED)
include("${CommonCMake_MODULE_DIR}/VersionConfig.cmake")
include("${CommonCMake_MODULE_DIR}/InstallUtils.cmake")
```

三种方式均设置变量 `CommonCMake_MODULE_DIR` 指向模块所在目录。

## 用法示例

### 版本号单一来源（`version.json`）

项目根目录 `cmake/version.json`：

```json
{
  "name": "MyProject",
  "version": { "major": 1, "minor": 0, "patch": 0, "tweak": 0 }
}
```

`CMakeLists.txt`：

```cmake
include("${CommonCMake_MODULE_DIR}/VersionConfig.cmake")
read_version("${CMAKE_CURRENT_SOURCE_DIR}/cmake/version.json" MY_PROJECT)
project(MyProject VERSION ${MY_PROJECT_VERSION} LANGUAGES CXX)
# 输出变量：MY_PROJECT_VERSION（1.0.0.0）、MY_PROJECT_VERSION_MAJOR 等
```

### 安装 / 导出（标准 CMake 包）

项目自备 `<PACKAGE>Config.cmake.in`（含 `@PACKAGE_INIT@` 与 `find_dependency`），随后：

```cmake
install_export_package(
    TARGETS ${PROJECT_NAME}
    PACKAGE MyProject
    NAMESPACE MyProject::
    CONFIG_TEMPLATE "${CMAKE_CURRENT_SOURCE_DIR}/cmake/MyProjectConfig.cmake.in"
)
# 消费方：find_package(MyProject CONFIG REQUIRED)
```

### Windows 版本资源

```cmake
if(WIN32)
    add_windows_version_resource(${PROJECT_NAME}
        PREFIX MY_PROJECT                     # 读取 MY_PROJECT_VERSION（read_version 产物）
        COMPANY_NAME      "My Company"
        FILE_DESCRIPTION  "MyProject library"
        INTERNAL_NAME     "MyProject"
        LEGAL_COPYRIGHT   "Copyright (C) 2026 My Company"
        ORIGINAL_FILENAME "MyProject.dll"
        PRODUCT_NAME      "MyProject"
    )
endif()
# 非 Windows 平台自动跳过
```

### 卸载目标

```cmake
add_uninstall_target()
# cmake --build <build_dir> --target uninstall
```
