# Node.js 后端任务 Prompt

## 任务信息
- **任务 ID**: {{task_id}}
- **描述**: {{description}}

## 业务上下文
{{context}}

## 技术栈
- **运行时**: Node.js
- **框架**: Express / Koa / NestJS
- **数据库**: MySQL / MongoDB
- **语言**: TypeScript

## 项目结构
```
server/
├── src/
│   ├── controllers/   # 控制器
│   ├── services/     # 业务逻辑
│   ├── models/       # 数据模型
│   ├── routes/       # 路由
│   ├── middleware/   # 中间件
│   └── utils/       # 工具函数
├── config/           # 配置文件
└── tests/           # 测试
```

## 目标
完成以下任务：
1. 阅读相关模块代码，理解现有架构
2. 实现 API 接口
3. 编写单元测试
4. 确保通过 lint 和类型检查

## 约束
- 遵循 RESTful API 设计规范
- 使用 TypeScript
- 添加适当的错误处理
- 注意安全性（SQL注入、XSS等）

## 完成后
- 推送代码
- 创建 PR
- 确保 CI 通过
