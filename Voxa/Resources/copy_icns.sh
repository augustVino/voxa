#!/bin/bash
# 将预生成的 AppIcon.icns 复制到应用包中

ICON_SOURCE="${SRCROOT}/Voxa/Resources/AppIcon.icns"
ICON_DEST="${BUILT_PRODUCTS_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/AppIcon.icns"

if [ -f "$ICON_SOURCE" ]; then
    echo "Copying AppIcon.icns to ${ICON_DEST}"
    cp "$ICON_SOURCE" "$ICON_DEST"
    echo "AppIcon.icns copied successfully"
else
    echo "Warning: AppIcon.icns not found at ${ICON_SOURCE}"
fi
