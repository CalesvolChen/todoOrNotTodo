<script setup lang="ts">
import { onMounted, ref } from 'vue';

import { Table, Tag } from 'ant-design-vue';

import { getLists, type TodoList } from '#/api/todo';

const data = ref<TodoList[]>([]);
const loading = ref(false);

const columns = [
  { title: '名称', dataIndex: 'name', key: 'name' },
  { title: '默认清单', dataIndex: 'isDefault', key: 'isDefault' },
];

onMounted(async () => {
  loading.value = true;
  try {
    data.value = await getLists();
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
        <template v-if="column.key === 'isDefault'">
          <Tag v-if="record.isDefault" color="blue">默认</Tag>
        </template>
      </template>
    </Table>
  </div>
</template>
