# ============================================================
#  VersionConfig.cmake（CommonCMake 通用模块）
#  封装 version.json 解读逻辑，供各项目 CMakeLists.txt 复用。
#
#  用法：
#    include("${CommonCMake_MODULE_DIR}/VersionConfig.cmake")
#    read_version("${CMAKE_CURRENT_SOURCE_DIR}/cmake/version.json" MY_PROJECT)
#    project(MyProject VERSION ${MY_PROJECT_VERSION} LANGUAGES CXX)
#
#  参数：
#    json_file  version.json 的绝对/相对路径
#    prefix     输出变量名前缀（如 MY_PROJECT）
#
#  输出变量（PARENT_SCOPE）：
#    <prefix>_VERSION_MAJOR / _MINOR / _PATCH / _TWEAK
#    <prefix>_VERSION       固定四位版本号 x.y.z.w
#
#  依赖 CMake 3.19+ 的 string(JSON) 解析
# ============================================================
function(read_version json_file prefix)
    if(NOT EXISTS "${json_file}")
        message(FATAL_ERROR "Missing version config file: ${json_file}")
    endif()

    file(READ "${json_file}" _version_json)

    string(JSON _v_major GET "${_version_json}" version major)
    string(JSON _v_minor GET "${_version_json}" version minor)
    string(JSON _v_patch GET "${_version_json}" version patch)
    string(JSON _v_tweak GET "${_version_json}" version tweak)

    set(${prefix}_VERSION_MAJOR "${_v_major}" PARENT_SCOPE)
    set(${prefix}_VERSION_MINOR "${_v_minor}" PARENT_SCOPE)
    set(${prefix}_VERSION_PATCH "${_v_patch}" PARENT_SCOPE)
    set(${prefix}_VERSION_TWEAK "${_v_tweak}" PARENT_SCOPE)
    set(${prefix}_VERSION
        "${_v_major}.${_v_minor}.${_v_patch}.${_v_tweak}" PARENT_SCOPE)
endfunction()
