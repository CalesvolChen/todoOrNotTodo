# Todo App (Flutter)

类 Microsoft To Do 的移动端，采用 Feature-First + Riverpod 架构。

## 目录结构

```text
lib/
├── main.dart                 # 入口
├── app.dart                  # MaterialApp.router + 主题
├── core/                     # 不依赖具体 feature 的基础设施
│   ├── constants/            # 常量（API 地址等）
│   ├── network/              # Dio 客户端 + JWT 拦截器
│   ├── router/               # go_router 配置
│   ├── storage/              # 本地安全存储（token）
│   └── theme/                # 主题/配色
├── shared/widgets/           # 跨 feature 复用组件
└── features/                 # 按功能分模块
    ├── auth/                 # 登录鉴权
    ├── tasks/                # 任务（增删改查、子步骤、星标）
    ├── lists/                # 清单
    └── settings/             # 设置
```
每个 feature 内分 `data/`（models + repository）与 `presentation/`（screens + widgets + view_models）；`domain/` 仅在逻辑复杂时按需引入。

## 运行

```bash
flutter create .          # 首次生成 android/ios 等平台目录（保留 lib）
flutter pub get
flutter run
```

> 后端默认地址见 `lib/core/constants/app_constants.dart`。Android 模拟器访问宿主机需将 `localhost` 改为 `10.0.2.2`。
> 默认测试账号：admin@todo.dev / admin123（需后端先执行 seed）。
