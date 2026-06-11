import type { RouteRecordRaw } from 'vue-router';

const routes: RouteRecordRaw[] = [
  {
    meta: {
      icon: 'lucide:check-square',
      order: 0,
      title: 'To Do 管理',
    },
    name: 'Todo',
    path: '/todo',
    children: [
      {
        name: 'TodoDashboard',
        path: '/todo/dashboard',
        component: () => import('#/views/todo/dashboard/index.vue'),
        meta: { icon: 'lucide:layout-dashboard', title: '仪表盘' },
      },
      {
        name: 'TodoUsers',
        path: '/todo/users',
        component: () => import('#/views/todo/users/index.vue'),
        meta: { icon: 'lucide:users', title: '用户管理' },
      },
      {
        name: 'TodoTasks',
        path: '/todo/tasks',
        component: () => import('#/views/todo/tasks/index.vue'),
        meta: { icon: 'lucide:list-todo', title: '任务管理' },
      },
      {
        name: 'TodoLists',
        path: '/todo/lists',
        component: () => import('#/views/todo/lists/index.vue'),
        meta: { icon: 'lucide:folder', title: '清单管理' },
      },
    ],
  },
];

export default routes;
