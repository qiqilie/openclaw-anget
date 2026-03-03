# 任务 Prompt 模板

这个目录包含用于不同任务类型的 Prompt 模板。

## 模板变量

- `{{task_id}}` - 任务 ID
- `{{description}}` - 任务描述
- `{{context}}` - 业务上下文
- `{{codebase}}` - 代码库信息

## 使用方法

```bash
# 渲染模板
cat prompts/backend-task.md | sed 's/{{description}}/实现用户认证/'
```

## 模板列表

- `backend-task.md` - 后端任务
- `frontend-task.md` - 前端任务
- `bugfix-task.md` - Bug 修复任务
