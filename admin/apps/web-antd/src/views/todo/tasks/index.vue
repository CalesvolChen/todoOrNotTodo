<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue';

import {
  Button,
  Form,
  FormItem,
  Image as AImage,
  Input,
  message,
  Modal,
  Popconfirm,
  Select,
  SelectOption,
  Space,
  Table,
  Tag,
} from 'ant-design-vue';

import {
  type AdminTask,
  type AdminTaskQuery,
  deleteAdminTask,
  getAdminTasks,
  updateAdminTask,
} from '#/api/todo';
import { toFileUrl } from '#/api/todo/request';

const data = ref<AdminTask[]>([]);
const loading = ref(false);

const search = reactive<{
  title: string;
  completed?: boolean;
  important?: boolean;
}>({ title: '', completed: undefined, important: undefined });

const columns = [
  { title: '标题', dataIndex: 'title', key: 'title' },
  { title: '拥有者', key: 'owner', width: 120 },
  { title: '分组', key: 'list', width: 120 },
  { title: '状态', dataIndex: 'completed', key: 'completed', width: 90 },
  { title: '重要', dataIndex: 'important', key: 'important', width: 80 },
  { title: '图片', key: 'images', width: 160 },
  { title: '语音', key: 'audios', width: 200 },
  { title: '创建时间', dataIndex: 'createdAt', key: 'createdAt', width: 180 },
  { title: '操作', key: 'action', width: 160 },
];

async function fetchData() {
  loading.value = true;
  try {
    const params: AdminTaskQuery = {};
    if (search.title) params.title = search.title;
    if (search.completed !== undefined) params.completed = search.completed;
    if (search.important !== undefined) params.important = search.important;
    data.value = await getAdminTasks(params);
  } catch {
    // 忽略
  } finally {
    loading.value = false;
  }
}

function resetSearch() {
  search.title = '';
  search.completed = undefined;
  search.important = undefined;
  fetchData();
}

const modalOpen = ref(false);
const editingId = ref<null | string>(null);
const formState = reactive({
  title: '',
  note: '',
  completed: false,
  important: false,
});

function openEdit(record: AdminTask) {
  editingId.value = record.id;
  formState.title = record.title;
  formState.note = record.note ?? '';
  formState.completed = record.completed;
  formState.important = record.important;
  modalOpen.value = true;
}

async function submitForm() {
  if (!editingId.value) return;
  try {
    await updateAdminTask(editingId.value, {
      title: formState.title,
      note: formState.note,
      completed: formState.completed,
      important: formState.important,
    });
    message.success('已更新');
    modalOpen.value = false;
    fetchData();
  } catch (error: any) {
    message.error(error?.message || '更新失败');
  }
}

async function handleDelete(record: AdminTask) {
  try {
    await deleteAdminTask(record.id);
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
      <FormItem label="标题">
        <Input
          v-model:value="search.title"
          placeholder="按标题查询"
          allow-clear
          @press-enter="fetchData"
        />
      </FormItem>
      <FormItem label="状态">
        <Select
          v-model:value="search.completed"
          placeholder="全部"
          allow-clear
          style="width: 120px"
        >
          <SelectOption :value="false">进行中</SelectOption>
          <SelectOption :value="true">已完成</SelectOption>
        </Select>
      </FormItem>
      <FormItem label="重要">
        <Select
          v-model:value="search.important"
          placeholder="全部"
          allow-clear
          style="width: 120px"
        >
          <SelectOption :value="true">重要</SelectOption>
          <SelectOption :value="false">普通</SelectOption>
        </Select>
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
      :scroll="{ x: 1200 }"
    >
      <template #bodyCell="{ column, record }">
        <template v-if="column.key === 'owner'">
          {{ record.owner?.name || record.owner?.username || record.owner?.email || '-' }}
        </template>
        <template v-else-if="column.key === 'list'">
          {{ record.list?.name || '-' }}
        </template>
        <template v-else-if="column.key === 'completed'">
          <Tag :color="record.completed ? 'green' : 'default'">
            {{ record.completed ? '已完成' : '进行中' }}
          </Tag>
        </template>
        <template v-else-if="column.key === 'important'">
          <Tag v-if="record.important" color="gold">重要</Tag>
        </template>
        <template v-else-if="column.key === 'images'">
          <Space>
            <template
              v-for="att in (record.attachments || []).filter(
                (a) => a.kind === 'IMAGE',
              )"
              :key="att.id"
            >
              <AImage :width="40" :height="40" :src="toFileUrl(att.path)" />
            </template>
            <span
              v-if="!(record.attachments || []).some((a) => a.kind === 'IMAGE')"
            >
              -
            </span>
          </Space>
        </template>
        <template v-else-if="column.key === 'audios'">
          <div
            v-for="att in (record.attachments || []).filter(
              (a) => a.kind === 'AUDIO',
            )"
            :key="att.id"
          >
            <audio controls :src="toFileUrl(att.path)" style="height: 32px"></audio>
          </div>
          <span
            v-if="!(record.attachments || []).some((a) => a.kind === 'AUDIO')"
          >
            -
          </span>
        </template>
        <template v-else-if="column.key === 'action'">
          <Space>
            <Button size="small" @click="openEdit(record)">编辑</Button>
            <Popconfirm title="确定删除该任务？" @confirm="handleDelete(record)">
              <Button size="small" danger>删除</Button>
            </Popconfirm>
          </Space>
        </template>
      </template>
    </Table>

    <Modal
      v-model:open="modalOpen"
      title="编辑任务"
      @ok="submitForm"
    >
      <Form layout="vertical">
        <FormItem label="标题">
          <Input v-model:value="formState.title" />
        </FormItem>
        <FormItem label="备注">
          <Input.TextArea v-model:value="formState.note" :rows="3" />
        </FormItem>
        <FormItem label="状态">
          <Select v-model:value="formState.completed">
            <SelectOption :value="false">进行中</SelectOption>
            <SelectOption :value="true">已完成</SelectOption>
          </Select>
        </FormItem>
        <FormItem label="重要">
          <Select v-model:value="formState.important">
            <SelectOption :value="false">普通</SelectOption>
            <SelectOption :value="true">重要</SelectOption>
          </Select>
        </FormItem>
      </Form>
    </Modal>
  </div>
</template>
