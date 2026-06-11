<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue';

import {
  Button,
  Form,
  FormItem,
  Input,
  message,
  Modal,
  Popconfirm,
  Space,
  Table,
  Tag,
} from 'ant-design-vue';

import {
  type AdminList,
  type AdminListQuery,
  deleteAdminList,
  getAdminLists,
  updateAdminList,
} from '#/api/todo';

const data = ref<AdminList[]>([]);
const loading = ref(false);

const search = reactive<AdminListQuery>({ name: '' });

const columns = [
  { title: '名称', dataIndex: 'name', key: 'name' },
  { title: '拥有者', key: 'owner', width: 140 },
  { title: '任务数', key: 'tasks', width: 90 },
  { title: '协作成员', key: 'members', width: 100 },
  { title: '默认', dataIndex: 'isDefault', key: 'isDefault', width: 80 },
  { title: '创建时间', dataIndex: 'createdAt', key: 'createdAt', width: 180 },
  { title: '操作', key: 'action', width: 160 },
];

async function fetchData() {
  loading.value = true;
  try {
    const params: AdminListQuery = {};
    if (search.name) params.name = search.name;
    data.value = await getAdminLists(params);
  } catch {
    // 忽略
  } finally {
    loading.value = false;
  }
}

function resetSearch() {
  search.name = '';
  fetchData();
}

const modalOpen = ref(false);
const editingId = ref<null | string>(null);
const editName = ref('');

function openEdit(record: AdminList) {
  editingId.value = record.id;
  editName.value = record.name;
  modalOpen.value = true;
}

async function submitForm() {
  if (!editingId.value) return;
  try {
    await updateAdminList(editingId.value, { name: editName.value });
    message.success('已更新');
    modalOpen.value = false;
    fetchData();
  } catch (error: any) {
    message.error(error?.message || '更新失败');
  }
}

async function handleDelete(record: AdminList) {
  try {
    await deleteAdminList(record.id);
    message.success('已删除');
    fetchData();
  } catch (error: any) {
    message.error(error?.message || '删除失败');
  }
}

onMounted(fetchData);
</script>

<template>
  <div class="p-4">
    <Form layout="inline" class="mb-4">
      <FormItem label="名称">
        <Input
          v-model:value="search.name"
          placeholder="按名称查询"
          allow-clear
          @press-enter="fetchData"
        />
      </FormItem>
      <FormItem>
        <Space>
          <Button type="primary" @click="fetchData">查询</Button>
          <Button @click="resetSearch">重置</Button>
        </Space>
      </FormItem>
    </Form>

    <Table
      :columns="columns"
      :data-source="data"
      :loading="loading"
      row-key="id"
      size="middle"
    >
      <template #bodyCell="{ column, record }">
        <template v-if="column.key === 'owner'">
          {{ record.owner?.name || record.owner?.username || record.owner?.email || '-' }}
        </template>
        <template v-else-if="column.key === 'tasks'">
          {{ record._count?.tasks ?? 0 }}
        </template>
        <template v-else-if="column.key === 'members'">
          {{ record._count?.members ?? 0 }}
        </template>
        <template v-else-if="column.key === 'isDefault'">
          <Tag v-if="record.isDefault" color="blue">默认</Tag>
        </template>
        <template v-else-if="column.key === 'action'">
          <Space>
            <Button size="small" @click="openEdit(record)">重命名</Button>
            <Popconfirm title="确定删除该分组？组内任务将一并删除" @confirm="handleDelete(record)">
              <Button size="small" danger>删除</Button>
            </Popconfirm>
          </Space>
        </template>
      </template>
    </Table>

    <Modal v-model:open="modalOpen" title="重命名分组" @ok="submitForm">
      <Form layout="vertical">
        <FormItem label="名称">
          <Input v-model:value="editName" />
        </FormItem>
      </Form>
    </Modal>
  </div>
</template>
