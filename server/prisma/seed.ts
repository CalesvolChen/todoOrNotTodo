import { PrismaClient, Role } from '@prisma/client';
import * as bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function main() {
  const email = 'admin@todo.dev';
  const passwordHash = await bcrypt.hash('admin123', 10);

  const admin = await prisma.user.upsert({
    where: { email },
    update: {},
    create: { email, passwordHash, name: 'Administrator', role: Role.ADMIN },
  });

  const existing = await prisma.taskList.findFirst({
    where: { ownerId: admin.id, isDefault: true },
  });

  if (!existing) {
    const list = await prisma.taskList.create({
      data: { name: 'Tasks', isDefault: true, ownerId: admin.id },
    });

    await prisma.task.create({
      data: {
        title: '欢迎使用 Todo or Not Todo',
        note: '这是一个示例任务，可在 App 或后台中查看。',
        important: true,
        listId: list.id,
        ownerId: admin.id,
        steps: { create: [{ title: '第一步' }, { title: '第二步' }] },
      },
    });
  }

  // 普通用户（仅可登录 App，使用昵称登录）
  const userPasswordHash = await bcrypt.hash('user123', 10);
  const seedUsers = [
    { username: 'alice', name: 'Alice' },
    { username: 'bob', name: 'Bob' },
  ];

  for (const u of seedUsers) {
    const user = await prisma.user.upsert({
      where: { username: u.username },
      update: {},
      create: {
        username: u.username,
        name: u.name,
        passwordHash: userPasswordHash,
        role: Role.USER,
      },
    });

    const hasDefault = await prisma.taskList.findFirst({
      where: { ownerId: user.id, isDefault: true },
    });
    if (!hasDefault) {
      await prisma.taskList.create({
        data: { name: '我的待办', isDefault: true, ownerId: user.id },
      });
    }
  }

  console.log('Seed 完成：');
  console.log('  管理员（后台）: admin@todo.dev / admin123');
  console.log('  普通用户（App）: alice / user123, bob / user123');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
