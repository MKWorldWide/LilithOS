/**
 * 🔐 Mining Operations - Scrypt Mining Framework
 * 
 * Real-time mining operations control panel with live status updates,
 * mining configuration, and process management.
 * 
 * @author M-K-World-Wide Scrypt Team
 * @version 1.0.0
 * @license MIT
 */

import React, { useState, useEffect } from 'react';
import {
  Card,
  Row,
  Col,
  Button,
  Form,
  Input,
  Select,
  InputNumber,
  Table,
  Tag,
  Progress,
  Alert,
  Space,
  Typography,
  Divider,
  Badge,
  Tooltip,
  Modal,
  message,
  Statistic,
  Descriptions,
  Switch,
  Slider,
} from 'antd';
import {
  PlayCircleOutlined,
  StopOutlined,
  ReloadOutlined,
  SettingOutlined,
  DashboardOutlined,
  ThunderboltOutlined,
  ClockCircleOutlined,
  CheckCircleOutlined,
  CloseCircleOutlined,
  WarningOutlined,
  InfoCircleOutlined,
  RocketOutlined,
  WalletOutlined,
  DatabaseOutlined,
} from '@ant-design/icons';
import { useMiningController, MiningConfig, MiningStatus } from '../hooks/useMiningController';

const { Title, Text, Paragraph } = Typography;
const { Option } = Select;

const MiningOperations: React.FC = () => {
  // Mining controller hook
  const {
    miningStatus,
    pools,
    isConnected,
    isLoading,
    error,
    startMining,
    stopMining,
    fetchMiningStatus,
    getMiningStats,
    getPoolOptions,
    clearError,
  } = useMiningController();

  // Local state
  const [form] = Form.useForm();
  const [isModalVisible, setIsModalVisible] = useState(false);
  const [selectedMiner, setSelectedMiner] = useState<MiningStatus | null>(null);
  const [autoRefresh, setAutoRefresh] = useState(true);

  // Mining statistics
  const miningStats = getMiningStats();

  // Auto-refresh effect
  useEffect(() => {
    if (!autoRefresh) return;

    const interval = setInterval(() => {
      fetchMiningStatus();
    }, 5000);

    return () => clearInterval(interval);
  }, [autoRefresh, fetchMiningStatus]);

  // Handle start mining
  const handleStartMining = async (values: any) => {
    const config: MiningConfig = {
      algorithm: values.algorithm || 'scrypt',
      pool: values.pool || 'prohashing',
      wallet: values.wallet,
      workerName: values.workerName || 'worker1',
      threads: values.threads || 4,
      intensity: values.intensity || 8,
    };

    const result = await startMining(config);
    if (result.success) {
      setIsModalVisible(false);
      form.resetFields();
    }
  };

  // Handle stop mining
  const handleStopMining = async (processId: string) => {
    Modal.confirm({
      title: 'Stop Mining Operation',
      content: 'Are you sure you want to stop this mining operation?',
      okText: 'Stop',
      okType: 'danger',
      cancelText: 'Cancel',
      onOk: async () => {
        await stopMining(processId);
      },
    });
  };

  // Table columns for mining operations
  const columns = [
    {
      title: 'Process ID',
      dataIndex: 'processId',
      key: 'processId',
      render: (text: string) => (
        <Text code style={{ fontSize: '12px' }}>
          {text.slice(-8)}
        </Text>
      ),
    },
    {
      title: 'Status',
      dataIndex: 'status',
      key: 'status',
      render: (status: string) => {
        const statusConfig = {
          running: { color: 'green', icon: <CheckCircleOutlined />, text: 'Running' },
          stopped: { color: 'red', icon: <CloseCircleOutlined />, text: 'Stopped' },
          error: { color: 'orange', icon: <WarningOutlined />, text: 'Error' },
          starting: { color: 'blue', icon: <ClockCircleOutlined />, text: 'Starting' },
        };
        const config = statusConfig[status as keyof typeof statusConfig] || statusConfig.stopped;
        
        return (
          <Tag color={config.color} icon={config.icon}>
            {config.text}
          </Tag>
        );
      },
    },
    {
      title: 'Algorithm',
      dataIndex: ['config', 'algorithm'],
      key: 'algorithm',
      render: (algorithm: string) => (
        <Tag color="blue">
          <ThunderboltOutlined /> {algorithm.toUpperCase()}
        </Tag>
      ),
    },
    {
      title: 'Pool',
      dataIndex: ['config', 'pool'],
      key: 'pool',
      render: (pool: string) => (
        <Tag color="purple">
          <DatabaseOutlined /> {pools[pool]?.name || pool}
        </Tag>
      ),
    },
    {
      title: 'Hash Rate',
      dataIndex: 'hashRate',
      key: 'hashRate',
      render: (hashRate: number) => (
        <Text strong>
          {hashRate > 0 ? `${hashRate.toFixed(2)} MH/s` : '0 MH/s'}
        </Text>
      ),
    },
    {
      title: 'Shares',
      key: 'shares',
      render: (record: MiningStatus) => (
        <Space direction="vertical" size="small">
          <Text type="success">✓ {record.shares}</Text>
          <Text type="danger">✗ {record.rejectedShares}</Text>
        </Space>
      ),
    },
    {
      title: 'Uptime',
      dataIndex: 'uptime',
      key: 'uptime',
      render: (uptime: number) => {
        const hours = Math.floor(uptime / 3600000);
        const minutes = Math.floor((uptime % 3600000) / 60000);
        return (
          <Text>
            <ClockCircleOutlined /> {hours}h {minutes}m
          </Text>
        );
      },
    },
    {
      title: 'Actions',
      key: 'actions',
      render: (record: MiningStatus) => (
        <Space>
          {record.status === 'running' && (
            <Button
              type="primary"
              danger
              size="small"
              icon={<StopOutlined />}
              onClick={() => handleStopMining(record.processId)}
            >
              Stop
            </Button>
          )}
          <Button
            size="small"
            icon={<ReloadOutlined />}
            onClick={() => fetchMiningStatus()}
          >
            Refresh
          </Button>
        </Space>
      ),
    },
  ];

  // Form validation rules
  const formRules = {
    wallet: [
      { required: true, message: 'Please enter your ProHashing username' },
      { min: 3, message: 'Username must be at least 3 characters' },
    ],
    algorithm: [{ required: true, message: 'Please select an algorithm' }],
    pool: [{ required: true, message: 'Please select a mining pool' }],
    threads: [
      { required: true, message: 'Please specify number of threads' },
      { type: 'number', min: 1, max: 16, message: 'Threads must be between 1 and 16' },
    ],
  };

  return (
    <div style={{ padding: '24px' }}>
      {/* Header */}
      <Row gutter={[16, 16]} style={{ marginBottom: '24px' }}>
        <Col span={16}>
          <Title level={2}>
            <RocketOutlined /> Mining Operations
          </Title>
          <Paragraph type="secondary">
            Control and monitor your Scrypt mining operations in real-time
          </Paragraph>
        </Col>
        <Col span={8} style={{ textAlign: 'right' }}>
          <Space>
            <Badge
              status={isConnected ? 'success' : 'error'}
              text={isConnected ? 'Connected' : 'Disconnected'}
            />
            <Switch
              checked={autoRefresh}
              onChange={setAutoRefresh}
              checkedChildren="Auto"
              unCheckedChildren="Manual"
            />
            <Button
              type="primary"
              icon={<PlayCircleOutlined />}
              onClick={() => setIsModalVisible(true)}
              loading={isLoading}
            >
              Start Mining
            </Button>
          </Space>
        </Col>
      </Row>

      {/* Connection Status */}
      {error && (
        <Alert
          message="Connection Error"
          description={error}
          type="error"
          showIcon
          closable
          onClose={clearError}
          style={{ marginBottom: '16px' }}
        />
      )}

      {/* Mining Statistics */}
      <Row gutter={[16, 16]} style={{ marginBottom: '24px' }}>
        <Col span={6}>
          <Card>
            <Statistic
              title="Total Hash Rate"
              value={miningStats.totalHashRate}
              suffix="MH/s"
              prefix={<ThunderboltOutlined />}
              valueStyle={{ color: '#3f8600' }}
            />
          </Card>
        </Col>
        <Col span={6}>
          <Card>
            <Statistic
              title="Active Miners"
              value={miningStats.activeMiners}
              prefix={<DashboardOutlined />}
              valueStyle={{ color: '#1890ff' }}
            />
          </Card>
        </Col>
        <Col span={6}>
          <Card>
            <Statistic
              title="Accepted Shares"
              value={miningStats.totalShares}
              prefix={<CheckCircleOutlined />}
              valueStyle={{ color: '#52c41a' }}
            />
          </Card>
        </Col>
        <Col span={6}>
          <Card>
            <Statistic
              title="Rejected Shares"
              value={miningStats.totalRejectedShares}
              prefix={<CloseCircleOutlined />}
              valueStyle={{ color: '#ff4d4f' }}
            />
          </Card>
        </Col>
      </Row>

      {/* Mining Operations Table */}
      <Card
        title={
          <Space>
            <SettingOutlined />
            Active Mining Operations
            <Badge count={miningStatus.length} showZero />
          </Space>
        }
        extra={
          <Button
            icon={<ReloadOutlined />}
            onClick={fetchMiningStatus}
            loading={isLoading}
          >
            Refresh
          </Button>
        }
      >
        <Table
          dataSource={miningStatus}
          columns={columns}
          rowKey="processId"
          pagination={false}
          loading={isLoading}
          locale={{
            emptyText: (
              <div style={{ padding: '40px', textAlign: 'center' }}>
                <InfoCircleOutlined style={{ fontSize: '48px', color: '#d9d9d9' }} />
                <div style={{ marginTop: '16px' }}>
                  <Text type="secondary">No mining operations running</Text>
                  <br />
                  <Button
                    type="primary"
                    icon={<PlayCircleOutlined />}
                    onClick={() => setIsModalVisible(true)}
                    style={{ marginTop: '8px' }}
                  >
                    Start Your First Mining Operation
                  </Button>
                </div>
              </div>
            ),
          }}
        />
      </Card>

      {/* Start Mining Modal */}
      <Modal
        title={
          <Space>
            <PlayCircleOutlined />
            Start New Mining Operation
          </Space>
        }
        open={isModalVisible}
        onCancel={() => setIsModalVisible(false)}
        footer={null}
        width={600}
      >
        <Form
          form={form}
          layout="vertical"
          onFinish={handleStartMining}
          initialValues={{
            algorithm: 'scrypt',
            pool: 'prohashing',
            threads: 4,
            intensity: 8,
            workerName: 'worker1',
          }}
        >
          <Row gutter={16}>
            <Col span={12}>
              <Form.Item
                name="algorithm"
                label="Mining Algorithm"
                rules={formRules.algorithm}
              >
                <Select>
                  <Option value="scrypt">Scrypt (LTC/DOGE)</Option>
                  <Option value="randomx">RandomX (XMR)</Option>
                </Select>
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item
                name="pool"
                label="Mining Pool"
                rules={formRules.pool}
              >
                <Select>
                  {getPoolOptions().map(option => (
                    <Option key={option.value} value={option.value}>
                      {option.label}
                    </Option>
                  ))}
                </Select>
              </Form.Item>
            </Col>
          </Row>

          <Form.Item
            name="wallet"
            label={
              <Space>
                <WalletOutlined />
                ProHashing Username
              </Space>
            }
            rules={formRules.wallet}
          >
            <Input placeholder="Enter your ProHashing username (e.g., EsKaye)" />
          </Form.Item>

          <Row gutter={16}>
            <Col span={12}>
              <Form.Item
                name="workerName"
                label="Worker Name"
              >
                <Input placeholder="worker1" />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item
                name="threads"
                label="CPU Threads"
                rules={formRules.threads}
              >
                <InputNumber
                  min={1}
                  max={16}
                  style={{ width: '100%' }}
                  placeholder="4"
                />
              </Form.Item>
            </Col>
          </Row>

          <Form.Item
            name="intensity"
            label="Mining Intensity"
          >
            <Slider
              min={1}
              max={20}
              marks={{
                1: 'Low',
                10: 'Medium',
                20: 'High',
              }}
            />
          </Form.Item>

          <Divider />

          <Form.Item>
            <Space>
              <Button
                type="primary"
                htmlType="submit"
                icon={<PlayCircleOutlined />}
                loading={isLoading}
              >
                Start Mining
              </Button>
              <Button onClick={() => setIsModalVisible(false)}>
                Cancel
              </Button>
            </Space>
          </Form.Item>
        </Form>
      </Modal>
    </div>
  );
};

export default MiningOperations; 