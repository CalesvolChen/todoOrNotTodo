/**
 * Todo 业务后端（NestJS）请求客户端。
 * 与模板内置的 mock 鉴权解耦：核心登录仍走 Nitro mock，
 * 业务数据（任务/清单/统计）走真实后端，返回原始 JSON。
 */
import { RequestClient } from '@vben/request';
import { useAccessStore } from '@vben/stores';

const todoApiURL =
  import.meta.env.VITE_GLOB_TODO_API_URL || 'http://localhost:3000/api';

export const todoRequestClient = new RequestClient({
  baseURL: todoApiURL,
  responseReturn: 'data',
});

todoRequestClient.addRequestInterceptor({
  fulfilled: (config) => {
    const accessStore = useAccessStore();
    if (accessStore.accessToken) {
      config.headers.Authorization = `Bearer ${accessStore.accessToken}`;
    }
    return config;
  },
});
