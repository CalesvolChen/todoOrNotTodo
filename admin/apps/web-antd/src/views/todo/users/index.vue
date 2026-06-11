<script setup lang="ts">
import { onMounted, ref } from 'vue';

import { Table } from 'ant-design-vue';

import { getAdminUsers, type TodoUser } from '#/api/todo';

const data = ref<TodoUser[]>([]);
const loading = ref(false);

const columns = [
  { title: '邮箱', dataIndex: 'email', key: 'email' },
  { title: '昵称', dataIndex: 'name', key: 'name' },
  { title: '角色', dataIndex: 'role', key: 'role' },
  { title: '创建时间', dataIndex: 'createdAt', key: 'createdAt' },
];

onMounted(async () => {
  loading.value = true;
  try {
    data.value = await getAdminUsers();
  } catch {
    // 后端未启动或未登录时忽略
  } finally {
    loading.value = false;
  }
});
</script>

<template>
  <div class="p-4">
    <Table
      :columns="columns"
      :data-source="data"
      :loading="loading"
      row-key="id"
    />
  </div>
</template>
