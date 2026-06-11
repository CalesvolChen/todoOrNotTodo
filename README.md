# Todo or Not Todo

一个类 Microsoft To Do 的待办应用，包含移动端、管理后台与后端 API 三部分。

## 目录结构

```text
todoOrNotTodo/
├── app/        # Flutter 移动端（Feature-First + Riverpod）
├── admin/      # 管理后台（Vben Admin 5.x，Vue3 + Vite + Ant Design Vue）
└── server/     # 后端 API（NestJS + PostgreSQL + Prisma）
```

## 整体架构

```text
Flutter App ─┐
             ├─ REST + JWT ─> NestJS API ─ Prisma ─> PostgreSQL
Vben Admin ──┘
```

## 环境要求

- 后端 server：Node.js 18+（推荐 20）、PostgreSQL 14+（本地或 Docker）
- 管理后台 admin：Node.js 22+ 且 pnpm 11+（Vben Admin 5.7 的硬性要求）
- 移动端 app：Flutter SDK 3.x

## 快速开始

### 一键启动后端 + 数据库（Docker Compose，推荐）

在仓库根目录执行：

```bash
docker compose up -d --build
```

会启动两个容器：
- `todo-db`：PostgreSQL 16（数据持久化在卷 `todo-db-data`，宿主机端口 5432）
- `todo-server`：NestJS 后端（启动时自动 `prisma db push` 同步表结构并写入种子数据），地址 http://localhost:3000 ，文档 http://localhost:3000/api/docs

默认管理员：`admin@todo.dev` / `admin123`。

常用命令：

```bash
docker compose logs -f server   # 查看后端日志
docker compose down             # 停止并移除容器（保留数据卷）
docker compose down -v          # 连同数据库数据一起清除
```

> 国内网络若拉取镜像失败，可在 Docker Desktop 的 `daemon.json` 配置 `registry-mirrors` 加速器后重启 Docker。

### 后端 server/（本地运行，可选）

```bash
cd server
cp .env.example .env          # 配置数据库连接
npm install
npm run prisma:generate
npm run prisma:migrate        # 初始化数据库表
npm run prisma:seed           # 写入默认管理员
npm run start:dev             # 默认 http://localhost:3000，文档 /api/docs
```

### 管理后台 admin/

```bash
cd admin
pnpm install
pnpm dev:antd                 # 默认 http://localhost:5666
```

> 基于 Vben Admin 5.x 精简而来，仅保留 `web-antd` 应用。需 Node 22+ / pnpm 11+。
> 登录鉴权使用模板内置 Nitro mock（登录页有演示账号提示）；
> 任务/清单/统计页面通过 `VITE_GLOB_TODO_API_URL`（默认 `http://localhost:3000/api`）连接真实后端，需先登录并由后端签发 JWT 才能取到数据。
> 业务页面位于 `apps/web-antd/src/views/todo/`，菜单为「To Do 管理」。

### 移动端 app/

```bash
cd app
flutter pub get
flutter run
```

## 说明

当前为脚手架阶段：目录骨架、基础配置与数据模型已就绪，可编译/启动；具体业务功能为占位，后续迭代实现。
