#!/usr/bin/env zsh

# 测试模块重构是否成功
# 这个脚本测试各个模块是否可以正确加载并使用

# 导入common模块（应该会自动导入所有其他模块）
source "$(dirname "$0")/_common.zsh"

echo "=== 测试 UI 模块 ==="
# 测试log_msg函数
log_msg STEP "测试消息" "参数1" "参数2"
log_msg INFO "测试消息" "参数1" "参数2"
log_msg SUCCESS "测试消息" "参数1" "参数2"
log_msg WARN "测试消息" "参数1" "参数2"
log_msg ERROR "测试消息" "参数1" "参数2"
# 显示debug信息时只有当RUNNER_DEBUG=true时才会显示
RUNNER_DEBUG=true log_msg DEBUG "测试消息" "参数1" "参数2"

echo "=== 测试 国际化 模块 ==="
# 测试get_msg函数
echo "默认消息: $(get_msg "program_completed")"
RUNNER_LANGUAGE="zh"
echo "中文消息: $(get_msg "program_completed")"
RUNNER_LANGUAGE="en"
echo "英文消息: $(get_msg "program_completed")"

echo "=== 测试 验证 模块 ==="
# 测试validate_numeric函数
if validate_numeric 10 "测试参数" 1 100; then
  echo "数值验证通过"
else
  echo "数值验证失败"
fi

if ! validate_numeric 200 "测试参数" 1 100; then
  echo "超出范围验证通过"
else
  echo "超出范围验证失败"
fi

# 测试run_with_timeout函数
echo "测试超时函数 (应该在2秒后终止):"
run_with_timeout 2 sleep 5
echo "超时函数执行完毕，退出码: $?"

echo "=== 测试 沙箱 模块 ==="
# 测试detect_sandbox_tech函数
echo "检测到的沙箱技术: $(detect_sandbox_tech)"

echo "=== 测试 缓存 模块 ==="
# 测试get_cache_dir函数
echo "缓存目录: $(get_cache_dir)"

echo "=== 测试 Common 模块 ==="
# 测试execute_and_show_output函数
echo "执行ls命令:"
execute_and_show_output ls -la

echo "=== 所有测试完成 ===" 