/**
 * Todo 业务后端（NestJS）请求客户端。
 * 与模板内置的 mock 鉴权解耦：核心登录仍走 Nitro mock，
 * 业务数据（任务/清单/统计）走真实后端，返回原始 JSON。
 */
import { defaultResponseInterceptor, RequestClient } from '@vben/request';
import { useAccessStore } from '@vben/stores';

const todoApiURL =
  import.meta.env.VITE_GLOB_TODO_API_URL || 'http://localhost:3000/api';

/** 文件服务基址（去掉 /api 前缀），用于拼接 /uploads 静态资源绝对地址 */
export const todoFileBaseURL = todoApiURL.replace(/\/api\/?$/, '');

/** 把后端返回的相对文件路径（/uploads/...）拼成绝对 URL */
export function toFileUrl(path?: string): string {
  if (!path) return '';
  if (/^https?:\/\//.test(path)) return path;
  return `${todoFileBaseURL}${path}`;
}

export const todoRequestClient = new RequestClient({
  baseURL: todoApiURL,
  responseReturn: 'body',
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

// 将 AxiosResponse 解包成响应体（NestJS 原始 JSON，无 code/data 包裹）。
todoRequestClient.addResponseInterceptor(
  defaultResponseInterceptor({
    codeField: 'code',
    dataField: 'data',
    successCode: 0,
  }),
);
