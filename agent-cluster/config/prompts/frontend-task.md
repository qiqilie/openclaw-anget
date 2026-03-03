# Vue3 前端任务 Prompt

## 任务信息
- **任务 ID**: {{task_id}}
- **描述**: {{description}}

## 业务上下文
{{context}}

## 技术栈
- **框架**: Vue 3 (Composition API)
- **构建工具**: Vite
- **状态管理**: Pinia
- **语言**: TypeScript

## 项目结构
```
src/
├── components/      # 组件
├── views/          # 页面
├── stores/         # Pinia stores
├── api/            # API 接口
├── types/          # 类型定义
├── utils/          # 工具函数
└── router/         # 路由配置
```

## 目标
完成以下任务：
1. 阅读相关组件/页面代码，理解现有实现
2. 使用 Composition API + TypeScript 实现功能
3. 如需新增 API，同步更新后端
4. 编写 Vitest 单元测试
5. 确保通过 lint 和类型检查

## 约束
- 使用 `<script setup lang="ts">` 语法
- 遵循 Vue3 最佳实践
- 使用 Pinia 进行状态管理
- 组件文件放在 `src/components/` 下
- 页面文件放在 `src/views/` 下

## UI 要求
- 使用 Element Plus 或其他 UI 库
- 保持一致的代码风格
- 添加必要的 TypeScript 类型

## 完成后
- 推送代码
- 创建 PR
- 附上 UI 截图（如果改了界面）
- 确保 CI 通过
