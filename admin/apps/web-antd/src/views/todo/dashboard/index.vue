<script setup lang="ts">
import type { EchartsUIType } from '@vben/plugins/echarts';

import { onMounted, ref } from 'vue';

import { EchartsUI, useEcharts } from '@vben/plugins/echarts';
import { Card, Col, Row, Statistic } from 'ant-design-vue';

import { type AdminStats, getAdminStats } from '#/api/todo';

const stats = ref<AdminStats>({
  users: 0,
  tasks: 0,
  completedTasks: 0,
  lists: 0,
});
const loading = ref(false);

const pieRef = ref<EchartsUIType>();
const trendRef = ref<EchartsUIType>();
const userTaskRef = ref<EchartsUIType>();
const storageRef = ref<EchartsUIType>();

const { renderEcharts: renderPie } = useEcharts(pieRef);
const { renderEcharts: renderTrend } = useEcharts(trendRef);
const { renderEcharts: renderUserTask } = useEcharts(userTaskRef);
const { renderEcharts: renderStorage } = useEcharts(storageRef);

function renderCharts(data: AdminStats) {
  const pending = Math.max(data.tasks - data.completedTasks, 0);
  renderPie({
    legend: { bottom: '2%', left: 'center' },
    tooltip: { trigger: 'item' },
    series: [
      {
        name: '任务完成情况',
        type: 'pie',
        radius: ['40%', '65%'],
        color: ['#52c41a', '#faad14'],
        data: [
          { name: '已完成', value: data.completedTasks },
          { name: '进行中', value: pending },
        ],
        label: { show: true, formatter: '{b}: {c}' },
      },
    ],
  });

  const trend = data.trend ?? [];
  renderTrend({
    tooltip: { trigger: 'axis' },
    grid: { left: '3%', right: '4%', bottom: '3%', containLabel: true },
    xAxis: { type: 'category', data: trend.map((t) => t.date) },
    yAxis: { type: 'value', minInterval: 1 },
    series: [
      {
        name: '新建任务',
        type: 'line',
        smooth: true,
        areaStyle: {},
        data: trend.map((t) => t.count),
      },
    ],
  });

  const perUser = data.perUser ?? [];
  renderUserTask({
    tooltip: { trigger: 'axis' },
    grid: { left: '3%', right: '4%', bottom: '3%', containLabel: true },
    xAxis: { type: 'category', data: perUser.map((u) => u.name) },
    yAxis: { type: 'value', minInterval: 1 },
    series: [
      {
        name: '任务数',
        type: 'bar',
        color: '#5ab1ef',
        data: perUser.map((u) => u.tasks),
      },
    ],
  });

  renderStorage({
    tooltip: {
      trigger: 'axis',
      formatter: (params: any) => {
        const p = Array.isArray(params) ? params[0] : params;
        return `${p.name}: ${(p.value / 1024).toFixed(1)} KB`;
      },
    },
    grid: { left: '3%', right: '4%', bottom: '3%', containLabel: true },
    xAxis: { type: 'category', data: perUser.map((u) => u.name) },
    yAxis: {
      type: 'value',
      axisLabel: { formatter: (v: number) => `${(v / 1024).toFixed(0)}KB` },
    },
    series: [
      {
        name: '存储占用',
        type: 'bar',
        color: '#b6a2de',
        data: perUser.map((u) => u.storageUsed),
      },
    ],
  });
}

onMounted(async () => {
  loading.value = true;
  try {
    stats.value = await getAdminStats();
    renderCharts(stats.value);
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
          <Statistic title="分组数" :value="stats.lists" />
        </Card>
      </Col>
    </Row>

    <Row :gutter="16" class="mt-4">
      <Col :span="12">
        <Card title="任务完成率">
          <EchartsUI ref="pieRef" />
        </Card>
      </Col>
      <Col :span="12">
        <Card title="近 14 天新建任务趋势">
          <EchartsUI ref="trendRef" />
        </Card>
      </Col>
    </Row>

    <Row :gutter="16" class="mt-4">
      <Col :span="12">
        <Card title="各用户任务数">
          <EchartsUI ref="userTaskRef" />
        </Card>
      </Col>
      <Col :span="12">
        <Card title="各用户存储占用">
          <EchartsUI ref="storageRef" />
        </Card>
      </Col>
    </Row>
  </div>
</template>
