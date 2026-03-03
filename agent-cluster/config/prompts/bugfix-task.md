# Bug 修复任务 Prompt

## 任务信息
- **任务 ID**: {{task_id}}
- **Bug 描述**: {{bug_description}}
- **复现步骤**: {{reproduce_steps}}
- **预期行为**: {{expected_behavior}}
- **实际行为**: {{actual_behavior}}

## 业务上下文
{{context}}

## 技术栈
- **前端**: Vue3 + Vite + Pinia + TypeScript
- **后端**: Node.js

## 目标
1. 定位 Bug 根因
2. 修复问题
3. 添加测试防止回归
4. 确保通过 CI

## 约束
- 只修改与 Bug 相关的文件
- 不要引入新的问题
- 保持代码风格一致

## 调试建议
- 前端: 使用 Vue Devtools + 浏览器开发者工具
- 后端: 检查日志，使用调试模式

## 完成后
- 推送代码
- 创建 PR
- 附上修复截图（如果涉及 UI）
- 确保 CI 通过
