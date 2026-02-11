#!/usr/bin/env python3
"""
修改 Xcode 项目文件，使用预生成的 icns 文件而不是 Assets Catalog
"""

import re

project_file = "/Users/liepin/Documents/github/voxa-feature/Voxa.xcodeproj/project.pbxproj"

# 读取项目文件
with open(project_file, 'r') as f:
    content = f.read()

# 1. 添加新的文件引用 (PBXFileReference)
# 在 Assets.xcassets 的引用后面添加 AppIcon.icns 的引用
assets_ref_line = 'A100000000000000000006 /* Assets.xcassets */ = {isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Assets.xcassets; sourceTree = "<group>"; };'
new_icns_ref = 'A100000000000000000006 /* Assets.xcassets */ = {isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Assets.xcassets; sourceTree = "<group>"; };\n\t\tA10000000000000000000C /* AppIcon.icns */ = {isa = PBXFileReference; lastKnownFileType = image.icns; path = AppIcon.icns; sourceTree = "<group>"; };'
content = content.replace(assets_ref_line, new_icns_ref)

# 2. 添加到 Resources 组
# 找到 Resources 组并添加 AppIcon.icns
resources_group_pattern = r'(C100000000000000000008 /\* Resources \* = \{[^}]*children = \(\s*)A100000000000000000006 /\* Assets\.xcassets \*/,'
resources_group_replacement = r'\1A100000000000000000006 /* Assets.xcassets */,\n\t\t\t\tA10000000000000000000C /* AppIcon.icns */,'
content = re.sub(resources_group_pattern, resources_group_replacement, content)

# 3. 添加到 Resources 构建阶段 (PBXResourcesBuildPhase)
# 在 Assets.xcassets 后添加 AppIcon.icns
resources_build_pattern = r'(B100000000000000000006 /\* Assets\.xcassets in Resources \*/,)'
resources_build_replacement = r'\1\n\t\t\t\tB10000000000000000000C /* AppIcon.icns in Resources */,'
content = re.sub(resources_build_pattern, resources_build_replacement, content)

# 4. 添加 PBXBuildFile 条目
# 在 Assets.xcassets 的 PBXBuildFile 后添加 AppIcon.icns 的 PBXBuildFile
build_file_line = 'B100000000000000000006 /* Assets.xcassets in Resources */ = {isa = PBXBuildFile; fileRef = A100000000000000000006 /* Assets.xcassets */; };'
new_build_file = 'B100000000000000000006 /* Assets.xcassets in Resources */ = {isa = PBXBuildFile; fileRef = A100000000000000000006 /* Assets.xcassets */; };\n\t\tB10000000000000000000C /* AppIcon.icns in Resources */ = {isa = PBXBuildFile; fileRef = A10000000000000000000C /* AppIcon.icns */; };'
content = content.replace(build_file_line, new_build_file)

# 5. 移除 ASSETCATALOG_COMPILER_APPICON_NAME 设置
# 这会让 Xcode 使用 Info.plist 中的 CFBundleIconFile 设置
content = content.replace('\n\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;', '')

# 写回文件
with open(project_file, 'w') as f:
    f.write(content)

print("Xcode project file updated successfully!")
