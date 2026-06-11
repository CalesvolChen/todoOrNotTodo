<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue';

import {
  Avatar,
  Button,
  Form,
  FormItem,
  Input,
  InputPassword,
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
  type AdminUserQuery,
  createAdminUser,
  deleteAdminUser,
  getAdminUsers,
  resetAdminUserPassword,
  type TodoUser,
  updateAdminUser,
} from '#/api/todo';
import { toFileUrl } from '#/api/todo/request';

const data = ref<TodoUser[]>([]);
const loading = ref(false);

const search = reactive<AdminUserQuery>({
  username: '',
  email: '',
  role: undefined,
});

const columns = [
  { title: '头像', dataIndex: 'avatar', key: 'avatar', width: 80 },
  { title: '昵称', dataIndex: 'username', key: 'username' },
  { title: '邮箱', dataIndex: 'email', key: 'email' },
  { title: '显示名', dataIndex: 'name', key: 'name' },
  { title: '角色', dataIndex: 'role', key: 'role', width: 100 },
  { title: '任务/分组', key: 'count', width: 110 },
  { title: '存储占用', dataIndex: 'storageUsed', key: 'storageUsed', width: 110 },
  { title: '创建时间', dataIndex: 'createdAt', key: 'createdAt', width: 180 },
  { title: '操作', key: 'action', width: 220 },
];

function formatBytes(bytes?: number): string {
  if (!bytes) return '0 B';
  const units = ['B', 'KB', 'MB', 'GB'];
  let n = bytes;
  let i = 0;
  while (n >= 1024 && i < units.length - 1) {
    n /= 1024;
    i += 1;
  }
  return `${n.toFixed(i === 0 ? 0 : 1)} ${units[i]}`;
}

async function fetchData() {
  loading.value = true;
  try {
    const params: AdminUserQuery = {};
    if (search.username) params.username = search.username;
    if (search.email) params.email = search.email;
    if (search.role) params.role = search.role;
    data.value = await getAdminUsers(params);
  } catch {
    // 后端未启动或未登录时忽略
  } finally {
    loading.value = false;
  }
}

function resetSearch() {
  search.username = '';
  search.email = '';
  search.role = undefined;
  fetchData();
}

// ===== 新建/编辑弹窗 =====
const modalOpen = ref(false);
const editingId = ref<null | string>(null);
const submitting = ref(false);
const formState = reactive({
  username: '',
  email: '',
  name: '',
  password: '',
  role: 'USER',
});

function openCreate() {
  editingId.value = null;
  formState.username = '';
  formState.email = '';
  formState.name = '';
  formState.password = '';
  formState.role = 'USER';
  modalOpen.value = true;
}

function openEdit(record: TodoUser) {
  editingId.value = record.id;
  formState.username = record.username ?? '';
  formState.email = record.email ?? '';
  formState.name = record.name ?? '';
  formState.password = '';
  formState.role = record.role;
  modalOpen.value = true;
}

async function submitForm() {
  submitting.value = true;
  try {
    if (editingId.value) {
      await updateAdminUser(editingId.value, {
        username: formState.username || undefined,
        email: formState.email || undefined,
        name: formState.name || undefined,
        role: formState.role,
      });
      message.success('已更新');
    } else {
      if (!formState.password || formState.password.length < 6) {
        message.error('密码至少 6 位');
        submitting.value = false;
        return;
      }
      await createAdminUser({
        username: formState.username || undefined,
        email: formState.email || undefined,
        name: formState.name || undefined,
        password: formState.password,
        role: formState.role,
      });
      message.success('已创建');
    }
    modalOpen.value = false;
    fetchData();
  } catch (error: any) {
    message.error(error?.message || '操作失败');
  } finally {
    submitting.value = false;
  }
}

async function handleDelete(record: TodoUser) {
  try {
    await deleteAdminUser(record.id);
    message.success('已删除');
    fetchData();
  } catch (error: any) {
    message.error(error?.message || '删除失败');
  }
}

// ===== 重置密码 =====
const pwdModalOpen = ref(false);
const pwdUserId = ref<null | string>(null);
const newPassword = ref('');

function openResetPwd(record: TodoUser) {
  pwdUserId.value = record.id;
  newPassword.value = '';
  pwdModalOpen.value = true;
}

async function submitResetPwd() {
  if (!pwdUserId.value) return;
  if (newPassword.value.length < 6) {
    message.error('密码至少 6 位');
    return;
  }
  try {
    await resetAdminUserPassword(pwdUserId.value, newPassword.value);
    message.success('密码已重置');
    pwdModalOpen.value = false;
  } catch (error: any) {
    message.error(error?.message || '重置失败');
  }
}

onMounted(fetchData);
</script>

<template>
  <div class="p-4">
    <Form layout="inline" class="mb-4">
      <FormItem label="昵称">
        <Input
          v-model:value="search.username"
          placeholder="按昵称查询"
          allow-clear
          @press-enter="fetchData"
        />
      </FormItem>
      <FormItem label="邮箱">
        <Input
          v-model:value="search.email"
          placeholder="按邮箱查询"
          allow-clear
          @press-enter="fetchData"
        />
      </FormItem>
      <FormItem label="角色">
        <Select
          v-model:value="search.role"
          placeholder="全部"
          allow-clear
          style="width: 120px"
        >
          <SelectOption value="USER">普通用户</SelectOption>
          <SelectOption value="ADMIN">管理员</SelectOption>
        </Select>
      </FormItem>
      <FormItem>
        <Space>
          <Button type="primary" @click="fetchData">查询</Button>
          <Button @click="resetSearch">重置</Button>
          <Button type="primary" @click="openCreate">新建用户</Button>
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
        <template v-if="column.key === 'avatar'">
          <Avatar :src="toFileUrl(record.avatar)">
            {{ (record.username || record.email || '?').charAt(0).toUpperCase() }}
          </Avatar>
        </template>
        <template v-else-if="column.key === 'role'">
          <Tag :color="record.role === 'ADMIN' ? 'red' : 'blue'">
            {{ record.role === 'ADMIN' ? '管理员' : '普通用户' }}
          </Tag>
        </template>
        <template v-else-if="column.key === 'count'">
          {{ record._count?.tasks ?? 0 }} / {{ record._count?.lists ?? 0 }}
        </template>
        <template v-else-if="column.key === 'storageUsed'">
          {{ formatBytes(record.storageUsed) }}
        </template>
        <template v-else-if="column.key === 'action'">
          <Space>
            <Button size="small" @click="openEdit(record)">编辑</Button>
            <Button size="small" @click="openResetPwd(record)">重置密码</Button>
            <Popconfirm title="确定删除该用户？" @confirm="handleDelete(record)">
              <Button size="small" danger>删除</Button>
            </Popconfirm>
          </Space>
        </template>
      </template>
    </Table>

    <Modal
      v-model:open="modalOpen"
      :title="editingId ? '编辑用户' : '新建用户'"
      :confirm-loading="submitting"
      @ok="submitForm"
    >
      <Form layout="vertical">
        <FormItem label="昵称（App 登录）">
          <Input v-model:value="formState.username" placeholder="昵称" />
        </FormItem>
        <FormItem label="邮箱（管理员登录）">
          <Input v-model:value="formState.email" placeholder="邮箱" />
        </FormItem>
        <FormItem label="显示名">
          <Input v-model:value="formState.name" placeholder="显示名" />
        </FormItem>
        <FormItem v-if="!editingId" label="密码">
          <InputPassword
            v-model:value="formState.password"
            placeholder="至少 6 位"
          />
        </FormItem>
        <FormItem label="角色">
          <Select v-model:value="formState.role">
            <SelectOption value="USER">普通用户</SelectOption>
            <SelectOption value="ADMIN">管理员</SelectOption>
          </Select>
        </FormItem>
      </Form>
    </Modal>

    <Modal
      v-model:open="pwdModalOpen"
      title="重置密码"
      @ok="submitResetPwd"
    >
      <Form layout="vertical">
        <FormItem label="新密码">
          <InputPassword
            v-model:value="newPassword"
            placeholder="至少 6 位"
          />
        </FormItem>
      </Form>
    </Modal>
  </div>
</template>
