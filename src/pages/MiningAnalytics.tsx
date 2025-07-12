/**
 * 📊 Mining Analytics Page - Scrypt Mining Framework
 * 
 * Comprehensive mining analytics with performance charts,
 * profitability analysis, and trend monitoring.
 * 
 * Features:
 * - Real-time mining performance charts
 * - Hash rate and difficulty tracking
 * - Profitability analysis and projections
 * - Mining pool performance comparison
 * - Historical data visualization
 * - ROI and earnings calculations
 * 
 * @author M-K-World-Wide Scrypt Team
 * @version 1.0.0
 * @license MIT
 * @since 2024-12-19
 */

import React, { useState, useEffect } from 'react';
import { 
  Row, 
  Col, 
  Card, 
  Statistic, 
  Progress, 
  Typography, 
  Space, 
  Badge, 
  Alert,
  Spin,
  Tooltip,
  Button,
  Divider,
  Table,
  Select,
  DatePicker,
  Tag,
  Tabs
} from 'antd';
import { 
  BarChartOutlined, 
  LineChartOutlined, 
  PieChartOutlined,
  ReloadOutlined,
  DollarOutlined,
  ThunderboltOutlined,
  SafetyOutlined,
  CheckCircleOutlined,
  ExclamationCircleOutlined,
  TrendingUpOutlined,
  TrendingDownOutlined
} from '@ant-design/icons';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip as RechartsTooltip, ResponsiveContainer, BarChart, Bar, PieChart, Pie, Cell } from 'recharts';

const { Title, Text, Paragraph } = Typography;
const { Option } = Select;
const { RangePicker } = DatePicker;
const { TabPane } = Tabs;

/**
 * Mining performance data interface
 */
interface MiningPerformance {
  timestamp: string;
  hashRate: number;
  difficulty: number;
  shares: number;
  rejectedShares: number;
  rewards: number;
  electricityCost: number;
  profit: number;
}

/**
 * Mining pool performance interface
 */
interface PoolPerformance {
  name: string;
  hashRate: number;
  shares: number;
  rejectedShares: number;
  uptime: number;
  rewards: number;
  efficiency: number;
}

/**
 * Mock mining performance data
 */
const MOCK_PERFORMANCE_DATA: MiningPerformance[] = [
  { timestamp: '00:00', hashRate: 125.5, difficulty: 2847, shares: 1250, rejectedShares: 12, rewards: 50.0, electricityCost: 15.0, profit: 35.0 },
  { timestamp: '04:00', hashRate: 128.2, difficulty: 2850, shares: 1280, rejectedShares: 10, rewards: 51.2, electricityCost: 15.2, profit: 36.0 },
  { timestamp: '08:00', hashRate: 122.8, difficulty: 2845, shares: 1225, rejectedShares: 15, rewards: 49.0, electricityCost: 14.8, profit: 34.2 },
  { timestamp: '12:00', hashRate: 130.1, difficulty: 2855, shares: 1300, rejectedShares: 8, rewards: 52.0, electricityCost: 15.5, profit: 36.5 },
  { timestamp: '16:00', hashRate: 127.3, difficulty: 2848, shares: 1270, rejectedShares: 11, rewards: 50.8, electricityCost: 15.1, profit: 35.7 },
  { timestamp: '20:00', hashRate: 124.7, difficulty: 2846, shares: 1245, rejectedShares: 13, rewards: 49.8, electricityCost: 14.9, profit: 34.9 }
];

const MOCK_POOL_PERFORMANCE: PoolPerformance[] = [
  { name: 'scrypt.pool.example.com', hashRate: 125.5, shares: 1250, rejectedShares: 12, uptime: 99.8, rewards: 50.0, efficiency: 98.5 },
  { name: 'scrypt.pool2.example.com', hashRate: 98.2, shares: 980, rejectedShares: 8, uptime: 99.5, rewards: 39.2, efficiency: 97.8 },
  { name: 'scrypt.pool3.example.com', hashRate: 75.3, shares: 750, rejectedShares: 5, uptime: 98.9, rewards: 30.1, efficiency: 96.2 }
];

/**
 * Mining Analytics Component
 * 
 * Provides comprehensive mining analytics with real-time charts,
 * performance tracking, and profitability analysis for the Scrypt Mining Framework.
 */
const MiningAnalytics: React.FC = () => {
  // State management
  const [performanceData, setPerformanceData] = useState<MiningPerformance[]>(MOCK_PERFORMANCE_DATA);
  const [poolPerformance, setPoolPerformance] = useState<PoolPerformance[]>(MOCK_POOL_PERFORMANCE);
  const [loading, setLoading] = useState(false);
  const [timeRange, setTimeRange] = useState<'24h' | '7d' | '30d' | '90d'>('24h');
  const [selectedMetric, setSelectedMetric] = useState<'hashRate' | 'rewards' | 'profit'>('hashRate');

  // Calculate totals
  const totalHashRate = poolPerformance.reduce((sum, pool) => sum + pool.hashRate, 0);
  const totalShares = poolPerformance.reduce((sum, pool) => sum + pool.shares, 0);
  const totalRejectedShares = poolPerformance.reduce((sum, pool) => sum + pool.rejectedShares, 0);
  const totalRewards = poolPerformance.reduce((sum, pool) => sum + pool.rewards, 0);
  const averageEfficiency = poolPerformance.reduce((sum, pool) => sum + pool.efficiency, 0) / poolPerformance.length;

  // Calculate profitability metrics
  const totalElectricityCost = performanceData.reduce((sum, data) => sum + data.electricityCost, 0);
  const totalProfit = performanceData.reduce((sum, data) => sum + data.profit, 0);
  const roi = totalProfit > 0 ? ((totalProfit / totalElectricityCost) * 100) : 0;

  /**
   * Handle time range change
   */
  const handleTimeRangeChange = (range: '24h' | '7d' | '30d' | '90d') => {
    setTimeRange(range);
    setLoading(true);
    
    // Simulate data loading
    setTimeout(() => {
      setLoading(false);
    }, 1000);
  };

  /**
   * Handle metric change
   */
  const handleMetricChange = (metric: 'hashRate' | 'rewards' | 'profit') => {
    setSelectedMetric(metric);
  };

  /**
   * Get chart color based on metric
   */
  const getChartColor = (metric: string): string => {
    switch (metric) {
      case 'hashRate':
        return '#52c41a';
      case 'rewards':
        return '#1890ff';
      case 'profit':
        return '#722ed1';
      default:
        return '#52c41a';
    }
  };

  /**
   * Get chart data based on selected metric
   */
  const getChartData = () => {
    return performanceData.map(data => ({
      time: data.timestamp,
      value: data[selectedMetric]
    }));
  };

  /**
   * Pool performance table columns
   */
  const poolColumns = [
    {
      title: 'Pool Name',
      dataIndex: 'name',
      key: 'name',
      render: (name: string) => <Text code>{name}</Text>
    },
    {
      title: 'Hash Rate',
      dataIndex: 'hashRate',
      key: 'hashRate',
      render: (hashRate: number) => `${hashRate.toFixed(1)} MH/s`
    },
    {
      title: 'Shares',
      dataIndex: 'shares',
      key: 'shares',
      render: (shares: number, record: PoolPerformance) => (
        <Space direction="vertical" size="small">
          <Text>{shares.toLocaleString()}</Text>
          <Text type="secondary" style={{ fontSize: '12px' }}>
            Rejected: {record.rejectedShares}
          </Text>
        </Space>
      )
    },
    {
      title: 'Uptime',
      dataIndex: 'uptime',
      key: 'uptime',
      render: (uptime: number) => (
        <Progress 
          percent={uptime} 
          size="small" 
          showInfo={false}
          strokeColor={uptime > 99 ? '#52c41a' : uptime > 95 ? '#faad14' : '#ff4d4f'}
        />
      )
    },
    {
      title: 'Rewards',
      dataIndex: 'rewards',
      key: 'rewards',
      render: (rewards: number) => `${rewards.toFixed(2)} SCrypt`
    },
    {
      title: 'Efficiency',
      dataIndex: 'efficiency',
      key: 'efficiency',
      render: (efficiency: number) => (
        <Tag color={efficiency > 98 ? 'green' : efficiency > 95 ? 'orange' : 'red'}>
          {efficiency.toFixed(1)}%
        </Tag>
      )
    }
  ];

  return (
    <div className="mining-analytics-page">
      {/* Page Header */}
      <div className="page-header">
        <Title level={2}>
          <BarChartOutlined className="title-icon" />
          Mining Analytics
        </Title>
        <Paragraph type="secondary">
          Comprehensive mining performance analysis and profitability tracking
        </Paragraph>
      </div>

      {/* Time Range and Metric Controls */}
      <Card className="controls-card">
        <Row gutter={[16, 16]} align="middle">
          <Col xs={24} sm={12} lg={8}>
            <Space>
              <Text strong>Time Range:</Text>
              <Select value={timeRange} onChange={handleTimeRangeChange} style={{ width: 120 }}>
                <Option value="24h">Last 24 Hours</Option>
                <Option value="7d">Last 7 Days</Option>
                <Option value="30d">Last 30 Days</Option>
                <Option value="90d">Last 90 Days</Option>
              </Select>
            </Space>
          </Col>
          <Col xs={24} sm={12} lg={8}>
            <Space>
              <Text strong>Metric:</Text>
              <Select value={selectedMetric} onChange={handleMetricChange} style={{ width: 120 }}>
                <Option value="hashRate">Hash Rate</Option>
                <Option value="rewards">Rewards</Option>
                <Option value="profit">Profit</Option>
              </Select>
            </Space>
          </Col>
          <Col xs={24} sm={24} lg={8}>
            <Button icon={<ReloadOutlined />} onClick={() => message.info('Refreshing analytics...')}>
              Refresh Data
            </Button>
          </Col>
        </Row>
      </Card>

      {/* Key Metrics */}
      <Row gutter={[16, 16]} className="stats-row">
        <Col xs={24} sm={12} lg={6}>
          <Card className="stat-card">
            <Statistic
              title="Total Hash Rate"
              value={totalHashRate}
              suffix="MH/s"
              prefix={<ThunderboltOutlined />}
              valueStyle={{ color: '#52c41a' }}
            />
          </Card>
        </Col>
        <Col xs={24} sm={12} lg={6}>
          <Card className="stat-card">
            <Statistic
              title="Total Rewards"
              value={totalRewards}
              suffix="SCrypt"
              prefix={<DollarOutlined />}
              valueStyle={{ color: '#1890ff' }}
            />
          </Card>
        </Col>
        <Col xs={24} sm={12} lg={6}>
          <Card className="stat-card">
            <Statistic
              title="Total Profit"
              value={totalProfit}
              suffix="USD"
              prefix={<TrendingUpOutlined />}
              valueStyle={{ color: '#722ed1' }}
            />
          </Card>
        </Col>
        <Col xs={24} sm={12} lg={6}>
          <Card className="stat-card">
            <Statistic
              title="ROI"
              value={roi}
              suffix="%"
              prefix={<BarChartOutlined />}
              valueStyle={{ color: roi > 0 ? '#52c41a' : '#ff4d4f' }}
            />
          </Card>
        </Col>
      </Row>

      {/* Charts and Analytics */}
      <Row gutter={[16, 16]}>
        <Col xs={24} lg={16}>
          <Card title={`${selectedMetric.charAt(0).toUpperCase() + selectedMetric.slice(1)} Over Time`} className="chart-card">
            <ResponsiveContainer width="100%" height={300}>
              <LineChart data={getChartData()}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="time" />
                <YAxis />
                <RechartsTooltip />
                <Line 
                  type="monotone" 
                  dataKey="value" 
                  stroke={getChartColor(selectedMetric)} 
                  strokeWidth={2}
                  dot={{ fill: getChartColor(selectedMetric) }}
                />
              </LineChart>
            </ResponsiveContainer>
          </Card>
        </Col>
        <Col xs={24} lg={8}>
          <Card title="Pool Performance" className="pool-card">
            <ResponsiveContainer width="100%" height={300}>
              <PieChart>
                <Pie
                  data={poolPerformance}
                  cx="50%"
                  cy="50%"
                  labelLine={false}
                  label={({ name, percent }) => `${name} ${(percent * 100).toFixed(0)}%`}
                  outerRadius={80}
                  fill="#8884d8"
                  dataKey="hashRate"
                >
                  {poolPerformance.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={['#52c41a', '#1890ff', '#722ed1'][index % 3]} />
                  ))}
                </Pie>
                <RechartsTooltip />
              </PieChart>
            </ResponsiveContainer>
          </Card>
        </Col>
      </Row>

      {/* Pool Performance Table */}
      <Card title="Mining Pool Performance" className="pool-table-card">
        <Table
          dataSource={poolPerformance}
          columns={poolColumns}
          rowKey="name"
          pagination={false}
          loading={loading}
        />
      </Card>

      {/* Profitability Analysis */}
      <Row gutter={[16, 16]}>
        <Col xs={24} lg={12}>
          <Card title="Profitability Analysis" className="profitability-card">
            <Row gutter={[16, 16]}>
              <Col span={12}>
                <Statistic
                  title="Total Electricity Cost"
                  value={totalElectricityCost}
                  suffix="USD"
                  valueStyle={{ color: '#ff4d4f' }}
                />
              </Col>
              <Col span={12}>
                <Statistic
                  title="Net Profit"
                  value={totalProfit}
                  suffix="USD"
                  valueStyle={{ color: totalProfit > 0 ? '#52c41a' : '#ff4d4f' }}
                />
              </Col>
            </Row>
            <Divider />
            <Row gutter={[16, 16]}>
              <Col span={12}>
                <Statistic
                  title="Average Efficiency"
                  value={averageEfficiency}
                  suffix="%"
                  valueStyle={{ color: averageEfficiency > 95 ? '#52c41a' : '#faad14' }}
                />
              </Col>
              <Col span={12}>
                <Statistic
                  title="Share Rejection Rate"
                  value={totalRejectedShares > 0 ? ((totalRejectedShares / totalShares) * 100) : 0}
                  suffix="%"
                  valueStyle={{ color: '#faad14' }}
                />
              </Col>
            </Row>
          </Card>
        </Col>
        <Col xs={24} lg={12}>
          <Card title="Performance Trends" className="trends-card">
            <ResponsiveContainer width="100%" height={200}>
              <BarChart data={performanceData}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="timestamp" />
                <YAxis />
                <RechartsTooltip />
                <Bar dataKey="rewards" fill="#1890ff" />
                <Bar dataKey="electricityCost" fill="#ff4d4f" />
              </BarChart>
            </ResponsiveContainer>
          </Card>
        </Col>
      </Row>
    </div>
  );
};

export default MiningAnalytics; 