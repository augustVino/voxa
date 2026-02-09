#!/bin/bash
#
# configure-api-key.sh
# 配置智谱 STT API Key
#
# Usage: ./scripts/configure-api-key.sh YOUR_API_KEY
#

set -e

if [ -z "$1" ]; then
    echo "❌ 错误: 请提供 API Key"
    echo ""
    echo "用法: $0 YOUR_API_KEY"
    echo ""
    echo "示例: $0 sk-xxxxxxxxxxxxxxxxxxxxx"
    exit 1
fi

API_KEY="$1"

echo "🔧 配置智谱 STT API Key..."

# 使用 defaults 命令写入 UserDefaults
defaults write com.voxa.Voxa sttApiKey "$API_KEY"
defaults write com.voxa.Voxa sttBaseURL "https://open.bigmodel.cn/api/paas/v4/audio/transcriptions"
defaults write com.voxa.Voxa sttModel "glm-asr-2512"
defaults write com.voxa.Voxa streamingEnabled -bool true

echo "✅ API Key 配置完成!"
echo ""
echo "配置信息:"
echo "  - API Key: ${API_KEY:0:10}..."
echo "  - Base URL: https://open.bigmodel.cn/api/paas/v4/audio/transcriptions"
echo "  - Model: glm-asr-2512"
echo "  - 流式模式: 已启用"
echo ""
echo "💡 提示: 重启 Voxa 应用以使配置生效"
