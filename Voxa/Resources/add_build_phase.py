#!/usr/bin/env python3
"""
在 Xcode 项目中添加一个构建后脚本来复制 AppIcon.icns
"""

import re

project_file = "/Users/liepin/Documents/github/voxa-feature/Voxa.xcodeproj/project.pbxproj"

# 读取项目文件
with open(project_file, 'r') as f:
    content = f.read()

# 1. 在 PBXResourcesBuildPhase section 之前添加 PBXShellScriptBuildPhase
resources_phase_marker = "/* Begin PBXResourcesBuildPhase section */"
shell_script_section = '''/* Begin PBXShellScriptBuildPhase section */
\t\tE100000000000000000006 /* Copy AppIcon.icns */ = {
\t\t\tisa = PBXShellScriptBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t);
\t\t\tinputFileListPaths = (
\t\t\t);
\t\t\tinputPaths = (
\t\t\t\t"$(SRCROOT)/Voxa/Resources/AppIcon.icns",
\t\t\t);
\t\t\toutputFileListPaths = (
\t\t\t);
\t\t\toutputPaths = (
\t\t\t\t"$(BUILT_PRODUCTS_DIR)/$(UNLOCALIZED_RESOURCES_FOLDER_PATH)/AppIcon.icns",
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t\tshellPath = /bin/sh;
\t\t\tshellScript = "cp \\"${SRCROOT}/Voxa/Resources/AppIcon.icns\\" \\"${BUILT_PRODUCTS_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/AppIcon.icns\\"\n";
\t\t\tshowEnvVarsInLog = 0;
\t\t};
/* End PBXShellScriptBuildPhase section */

'''

content = content.replace(resources_phase_marker, shell_script_section + resources_phase_marker)

# 2. 在 Voxa target 的 buildPhases 中添加新的构建阶段
# 找到 buildPhases 并在 Resources 后添加我们的脚本
old_buildphases = '''buildPhases = (
\t\t\t\tE100000000000000000001 /* Sources */,
\t\t\t\tE100000000000000000002 /* Frameworks */,
\t\t\t\tE100000000000000000003 /* Resources */,
\t\t\t);'''

new_buildphases = '''buildPhases = (
\t\t\t\tE100000000000000000001 /* Sources */,
\t\t\t\tE100000000000000000002 /* Frameworks */,
\t\t\t\tE100000000000000000003 /* Resources */,
\t\t\t\tE100000000000000000006 /* Copy AppIcon.icns */,
\t\t\t);'''

content = content.replace(old_buildphases, new_buildphases)

# 写回文件
with open(project_file, 'w') as f:
    f.write(content)

print("Build phase added successfully!")
