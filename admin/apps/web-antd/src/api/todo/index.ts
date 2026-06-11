import { todoRequestClient } from './request';

export interface AdminStats {
  users: number;
  tasks: number;
  completedTasks: number;
  lists: number;
}

export interface TodoUser {
  id: string;
  email: string;
  name?: string;
  role: string;
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

export function getAdminUsers() {
  return todoRequestClient.get<TodoUser[]>('/admin/users');
}

export function getTasks() {
  return todoRequestClient.get<TodoTask[]>('/tasks');
}

export function getLists() {
  return todoRequestClient.get<TodoList[]>('/lists');
}
