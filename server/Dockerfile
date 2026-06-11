FROM node:22

WORKDIR /app

# 安装依赖（含 dev 依赖，供 prisma CLI / ts-node 使用）
COPY package*.json ./
RUN npm install

# 复制源码，生成 Prisma Client 并编译
COPY . .
RUN npx prisma generate && npm run build

EXPOSE 3000

# 启动流程：同步数据库结构 -> 写入种子数据 -> 启动服务
CMD ["sh", "-c", "npx prisma db push --skip-generate --accept-data-loss && npx prisma db seed && node dist/main"]
