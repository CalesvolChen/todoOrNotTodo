<script setup lang="ts">
import { onMounted, ref } from 'vue';

import { Table, Tag } from 'ant-design-vue';

import { getTasks, type TodoTask } from '#/api/todo';

const data = ref<TodoTask[]>([]);
const loading = ref(false);

const columns = [
  { title: '标题', dataIndex: 'title', key: 'title' },
  { title: '状态', dataIndex: 'completed', key: 'completed' },
  { title: '重要', dataIndex: 'important', key: 'important' },
  { title: '截止时间', dataIndex: 'dueDate', key: 'dueDate' },
];

onMounted(async () => {
  loading.value = true;
  try {
    data.value = await getTasks();
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
    >
      <template #bodyCell="{ column, record }">
        <template v-if="column.key === 'completed'">
          <Tag :color="record.completed ? 'green' : 'default'">
            {{ record.completed ? '已完成' : '进行中' }}
          </Tag>
        </template>
        <template v-else-if="column.key === 'important'">
          <Tag v-if="record.important" color="gold">重要</Tag>
        </template>
      </template>
    </Table>
  </div>
</template>
