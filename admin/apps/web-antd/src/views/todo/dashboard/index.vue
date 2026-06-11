<script setup lang="ts">
import { onMounted, ref } from 'vue';

import { Card, Col, Row, Statistic } from 'ant-design-vue';

import { type AdminStats, getAdminStats } from '#/api/todo';

const stats = ref<AdminStats>({
  users: 0,
  tasks: 0,
  completedTasks: 0,
  lists: 0,
});
const loading = ref(false);

onMounted(async () => {
  loading.value = true;
  try {
    stats.value = await getAdminStats();
  } catch {
    // 后端未启动或未登录时忽略，保留默认值
  } finally {
    loading.value = false;
  }
});
</script>

<template>
  <div class="p-4">
    <Row :gutter="16">
      <Col :span="6">
        <Card :loading="loading">
          <Statistic title="用户数" :value="stats.users" />
        </Card>
      </Col>
      <Col :span="6">
        <Card :loading="loading">
          <Statistic title="任务总数" :value="stats.tasks" />
        </Card>
      </Col>
      <Col :span="6">
        <Card :loading="loading">
          <Statistic title="已完成" :value="stats.completedTasks" />
        </Card>
      </Col>
      <Col :span="6">
        <Card :loading="loading">
          <Statistic title="清单数" :value="stats.lists" />
        </Card>
      </Col>
    </Row>
  </div>
</template>
