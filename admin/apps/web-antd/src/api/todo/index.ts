import { todoRequestClient } from './request';

export interface AdminStats {
  users: number;
  tasks: number;
  completedTasks: number;
  lists: number;
  trend?: { date: string; count: number }[];
  perUser?: { name: string; tasks: number; storageUsed: number }[];
}

export interface TodoUser {
  id: string;
  email?: string;
  username?: string;
  name?: string;
  avatar?: string;
  role: string;
  storageUsed?: number;
  createdAt: string;
  _count?: { tasks: number; lists: number };
}

export interface TodoTask {
  id: string;
  title: string;
  note?: string;
  completed: boolean;
  important: boolean;
  dueDate?: string;
}

export interface TodoList {
  id: string;
  name: string;
  isDefault: boolean;
}

export function getAdminStats() {
  return todoRequestClient.get<AdminStats>('/admin/stats');
}

// ===== 用户管理 =====
export interface AdminUserQuery {
  username?: string;
  email?: string;
  role?: string;
}

export interface CreateUserPayload {
  username?: string;
  email?: string;
  password: string;
  name?: string;
  role?: string;
}

export interface UpdateUserPayload {
  username?: string;
  email?: string;
  name?: string;
  role?: string;
}

export function getAdminUsers(params?: AdminUserQuery) {
  return todoRequestClient.get<TodoUser[]>('/admin/users', { params });
}

export function createAdminUser(data: CreateUserPayload) {
  return todoRequestClient.post<TodoUser>('/admin/users', data);
}

export function updateAdminUser(id: string, data: UpdateUserPayload) {
  return todoRequestClient.patch<TodoUser>(`/admin/users/${id}`, data);
}

export function resetAdminUserPassword(id: string, password: string) {
  return todoRequestClient.post(`/admin/users/${id}/reset-password`, {
    password,
  });
}

export function deleteAdminUser(id: string) {
  return todoRequestClient.delete(`/admin/users/${id}`);
}

export function getTasks() {
  return todoRequestClient.get<TodoTask[]>('/tasks');
}

export function getLists() {
  return todoRequestClient.get<TodoList[]>('/lists');
}

// ===== 管理端：任务管理 =====
export interface AdminAttachment {
  id: string;
  kind: 'AUDIO' | 'IMAGE';
  path: string;
  mime: string;
  size: number;
}

export interface AdminTask {
  id: string;
  title: string;
  note?: string;
  completed: boolean;
  important: boolean;
  dueDate?: string;
  createdAt: string;
  completedAt?: string | null;
  owner?: { id: string; username?: string; name?: string; email?: string };
  list?: { id: string; name: string };
  attachments?: AdminAttachment[];
  _count?: { steps: number };
}

export interface AdminTaskQuery {
  title?: string;
  completed?: boolean;
  important?: boolean;
  ownerId?: string;
}

export interface UpdateTaskPayload {
  title?: string;
  note?: string;
  completed?: boolean;
  important?: boolean;
}

export function getAdminTasks(params?: AdminTaskQuery) {
  return todoRequestClient.get<AdminTask[]>('/admin/tasks', { params });
}

export function updateAdminTask(id: string, data: UpdateTaskPayload) {
  return todoRequestClient.patch<AdminTask>(`/admin/tasks/${id}`, data);
}

export function deleteAdminTask(id: string) {
  return todoRequestClient.delete(`/admin/tasks/${id}`);
}

// ===== 管理端：分组管理 =====
export interface AdminList {
  id: string;
  name: string;
  isDefault: boolean;
  createdAt: string;
  owner?: { id: string; username?: string; name?: string; email?: string };
  _count?: { tasks: number; members: number };
}

export interface AdminListQuery {
  name?: string;
  ownerId?: string;
}

export function getAdminLists(params?: AdminListQuery) {
  return todoRequestClient.get<AdminList[]>('/admin/lists', { params });
}

export function updateAdminList(id: string, data: { name: string }) {
  return todoRequestClient.patch<AdminList>(`/admin/lists/${id}`, data);
}

export function deleteAdminList(id: string) {
  return todoRequestClient.delete(`/admin/lists/${id}`);
}
