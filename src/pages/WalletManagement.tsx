/**
 * 💰 Wallet Management Page - Scrypt Mining Framework
 * 
 * Comprehensive wallet management with address monitoring,
 * transaction history, and balance tracking.
 * 
 * Features:
 * - Multi-wallet support and management
 * - Real-time balance monitoring
 * - Transaction history and details
 * - Address generation and management
 * - Security settings and backup
 * - Mining rewards tracking
 * 
 * @author M-K-World-Wide Scrypt Team
 * @version 1.0.0
 * @license MIT
 * @since 2024-12-19
 */

import React, { useState } from 'react';
import { 
  Row, 
  Col, 
  Card, 
  Statistic, 
  Typography, 
  Space, 
  Badge, 
  Button,
  Table,
  Input,
  Select,
  Tag,
  Modal,
  Form,
  message,
  Tabs,
  Descriptions
} from 'antd';
import { 
  WalletOutlined, 
  PlusOutlined, 
  ReloadOutlined,
  BarChartOutlined,
  ClockCircleOutlined,
  DollarOutlined,
  ThunderboltOutlined,
  CopyOutlined,
} from '@ant-design/icons';

const { Title, Text, Paragraph } = Typography;

const { Option } = Select;
const { TabPane } = Tabs;

/**
 * Wallet data interface
 */
interface Wallet {
  id: string;
  name: string;
  address: string;
  balance: number;
  pendingBalance: number;
  totalReceived: number;
  totalSent: number;
  transactionCount: number;
  lastActivity: string;
  isActive: boolean;
  type: 'mining' | 'trading' | 'cold-storage';
}

/**
 * Transaction data interface
 */
interface WalletTransaction {
  txid: string;
  timestamp: string;
  type: 'received' | 'sent' | 'mining-reward';
  amount: number;
  fee: number;
  confirmations: number;
  status: 'confirmed' | 'pending' | 'failed';
  address: string;
  blockHeight: number;
}

/**
 * Mock wallet data
 */
const MOCK_WALLETS: Wallet[] = [
  {
    id: '1',
    name: 'Mining Wallet',
    address: 'S1a2b3c4d5e6f7g8h9i0j1k2l3m4n5o6p7q8r9s0t1u2v3w4x5y6z7',
    balance: 1250.75,
    pendingBalance: 25.50,
    totalReceived: 1500.25,
    totalSent: 224.00,
    transactionCount: 156,
    lastActivity: '2024-12-19 15:30:45',
    isActive: true,
    type: 'mining'
  },
  {
    id: '2',
    name: 'Trading Wallet',
    address: 'S2b3c4d5e6f7g8h9i0j1k2l3m4n5o6p7q8r9s0t1u2v3w4x5y6z7a8',
    balance: 875.25,
    pendingBalance: 0,
    totalReceived: 1200.00,
    totalSent: 324.75,
    transactionCount: 89,
    lastActivity: '2024-12-19 14:45:12',
    isActive: true,
    type: 'trading'
  },
  {
    id: '3',
    name: 'Cold Storage',
    address: 'S3c4d5e6f7g8h9i0j1k2l3m4n5o6p7q8r9s0t1u2v3w4x5y6z7a8b9',
    balance: 5000.00,
    pendingBalance: 0,
    totalReceived: 5000.00,
    totalSent: 0,
    transactionCount: 1,
    lastActivity: '2024-12-19 10:00:00',
    isActive: false,
    type: 'cold-storage'
  }
];

const MOCK_TRANSACTIONS: WalletTransaction[] = [
  {
    txid: 'abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890',
    timestamp: '2024-12-19 15:30:45',
    type: 'mining-reward',
    amount: 50.0,
    fee: 0.001,
    confirmations: 1,
    status: 'confirmed',
    address: 'S1a2b3c4d5e6f7g8h9i0j1k2l3m4n5o6p7q8r9s0t1u2v3w4x5y6z7',
    blockHeight: 1234567
  },
  {
    txid: 'fedcba0987654321fedcba0987654321fedcba0987654321fedcba0987654321',
    timestamp: '2024-12-19 14:45:12',
    type: 'received',
    amount: 125.5,
    fee: 0.0005,
    confirmations: 6,
    status: 'confirmed',
    address: 'S2b3c4d5e6f7g8h9i0j1k2l3m4n5o6p7q8r9s0t1u2v3w4x5y6z7a8',
    blockHeight: 1234566
  }
];

/**
 * Wallet Management Component
 * 
 * Provides comprehensive wallet management with real-time monitoring,
 * transaction tracking, and security features for the Scrypt Mining Framework.
 */
const WalletManagement: React.FC = () => {
  // State management
  const [wallets, setWallets] = useState<Wallet[]>(MOCK_WALLETS);
  const [transactions] = useState<WalletTransaction[]>(MOCK_TRANSACTIONS);
  const [loading, setLoading] = useState(false);
  const [selectedWallet, setSelectedWallet] = useState<Wallet | null>(null);
  const [newWalletModalVisible, setNewWalletModalVisible] = useState(false);
  const [form] = Form.useForm();

  // Calculate totals
  const totalBalance = wallets.reduce((sum, wallet) => sum + wallet.balance, 0);
  const totalPendingBalance = wallets.reduce((sum, wallet) => sum + wallet.pendingBalance, 0);
  const totalReceived = wallets.reduce((sum, wallet) => sum + wallet.totalReceived, 0);
  const totalSent = wallets.reduce((sum, wallet) => sum + wallet.totalSent, 0);
  const activeWallets = wallets.filter(wallet => wallet.isActive).length;

  /**
   * Handle wallet selection
   */
  const handleWalletSelect = (wallet: Wallet) => {
    setSelectedWallet(wallet);
  };

  /**
   * Handle new wallet creation
   */
  const handleCreateWallet = async (values: any) => {
    setLoading(true);
    try {
      // Simulate API call
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      const newWallet: Wallet = {
        id: Date.now().toString(),
        name: values.name,
        address: `S${Math.random().toString(36).substring(2, 50)}`,
        balance: 0,
        pendingBalance: 0,
        totalReceived: 0,
        totalSent: 0,
        transactionCount: 0,
        lastActivity: new Date().toISOString(),
        isActive: true,
        type: values.type
      };
      
      setWallets(prev => [...prev, newWallet]);
      setNewWalletModalVisible(false);
      form.resetFields();
      message.success('Wallet created successfully');
    } catch (error) {
      message.error('Failed to create wallet');
    } finally {
      setLoading(false);
    }
  };

  /**
   * Handle address copy
   */
  const handleCopyAddress = (address: string) => {
    navigator.clipboard.writeText(address);
    message.success('Address copied to clipboard');
  };

  /**
   * Wallet table columns
   */
  const walletColumns = [
    {
      title: 'Wallet Name',
      dataIndex: 'name',
      key: 'name',
      render: (name: string, record: Wallet) => (
        <Space>
          <Text strong>{name}</Text>
          <Tag color={record.type === 'mining' ? 'green' : record.type === 'trading' ? 'blue' : 'orange'}>
            {record.type}
          </Tag>
        </Space>
      )
    },
    {
      title: 'Address',
      dataIndex: 'address',
      key: 'address',
      render: (address: string) => (
        <Space>
          <Text code style={{ fontSize: '12px' }}>
            {address.substring(0, 16)}...
          </Text>
          <Button 
            type="text" 
            size="small" 
            icon={<CopyOutlined />}
            onClick={() => handleCopyAddress(address)}
          />
        </Space>
      )
    },
    {
      title: 'Balance',
      dataIndex: 'balance',
      key: 'balance',
      render: (balance: number, record: Wallet) => (
        <Space direction="vertical" size="small">
          <Text strong>{balance.toFixed(2)} SCrypt</Text>
          {record.pendingBalance > 0 && (
            <Text type="secondary" style={{ fontSize: '12px' }}>
              Pending: {record.pendingBalance.toFixed(2)} SCrypt
            </Text>
          )}
        </Space>
      )
    },
    {
      title: 'Transactions',
      dataIndex: 'transactionCount',
      key: 'transactionCount',
      render: (count: number) => count.toLocaleString()
    },
    {
      title: 'Last Activity',
      dataIndex: 'lastActivity',
      key: 'lastActivity',
      render: (timestamp: string) => (
        <Space>
          <ClockCircleOutlined />
          <Text>{timestamp}</Text>
        </Space>
      )
    },
    {
      title: 'Status',
      dataIndex: 'isActive',
      key: 'isActive',
      render: (isActive: boolean) => (
        <Badge 
          status={isActive ? 'success' : 'default'} 
          text={isActive ? 'Active' : 'Inactive'}
        />
      )
    },
    {
      title: 'Actions',
      key: 'actions',
      render: (text: string, record: Wallet) => (
        <Space>
          <Button
            type="primary"
            size="small"
            onClick={() => handleWalletSelect(record)}
          >
            View Details
          </Button>
          <Button
            size="small"
            icon={<DownloadOutlined />}
          >
            Backup
          </Button>
        </Space>
      )
    }
  ];

  /**
   * Transaction table columns
   */
  const transactionColumns = [
    {
      title: 'Type',
      dataIndex: 'type',
      key: 'type',
      render: (type: string) => (
        <Tag color={
          type === 'mining-reward' ? 'green' : 
          type === 'received' ? 'blue' : 'red'
        }>
          {type.replace('-', ' ').toUpperCase()}
        </Tag>
      )
    },
    {
      title: 'Amount',
      dataIndex: 'amount',
      key: 'amount',
      render: (amount: number) => `${amount.toFixed(2)} SCrypt`
    },
    {
      title: 'Timestamp',
      dataIndex: 'timestamp',
      key: 'timestamp',
      render: (timestamp: string) => (
        <Space>
          <ClockCircleOutlined />
          <Text>{timestamp}</Text>
        </Space>
      )
    },
    {
      title: 'Confirmations',
      dataIndex: 'confirmations',
      key: 'confirmations',
      render: (confirmations: number) => (
        <Badge 
          count={confirmations} 
          style={{ backgroundColor: confirmations > 6 ? '#52c41a' : '#faad14' }}
        />
      )
    },
    {
      title: 'Status',
      dataIndex: 'status',
      key: 'status',
      render: (status: string) => (
        <Tag color={status === 'confirmed' ? 'green' : status === 'pending' ? 'orange' : 'red'}>
          {status}
        </Tag>
      )
    }
  ];

  return (
    <div className="wallet-management-page">
      {/* Page Header */}
      <div className="page-header">
        <Title level={2}>
          <WalletOutlined className="title-icon" />
          Wallet Management
        </Title>
        <Paragraph type="secondary">
          Manage your Scrypt wallets and track transactions
        </Paragraph>
      </div>

      {/* Statistics Cards */}
      <Row gutter={[16, 16]} className="stats-row">
        <Col xs={24} sm={12} lg={6}>
          <Card className="stat-card">
            <Statistic
              title="Total Balance"
              value={totalBalance}
              suffix="SCrypt"
              prefix={<DollarOutlined />}
              valueStyle={{ color: '#52c41a' }}
            />
            {totalPendingBalance > 0 && (
              <Text type="secondary" style={{ fontSize: '12px' }}>
                Pending: {totalPendingBalance.toFixed(2)} SCrypt
              </Text>
            )}
          </Card>
        </Col>
        <Col xs={24} sm={12} lg={6}>
          <Card className="stat-card">
            <Statistic
              title="Active Wallets"
              value={activeWallets}
              suffix={`/ ${wallets.length}`}
              prefix={<CheckCircleOutlined />}
              valueStyle={{ color: '#1890ff' }}
            />
          </Card>
        </Col>
        <Col xs={24} sm={12} lg={6}>
          <Card className="stat-card">
            <Statistic
              title="Total Received"
              value={totalReceived}
              suffix="SCrypt"
              prefix={<BarChartOutlined />}
              valueStyle={{ color: '#722ed1' }}
            />
          </Card>
        </Col>
        <Col xs={24} sm={12} lg={6}>
          <Card className="stat-card">
            <Statistic
              title="Total Sent"
              value={totalSent}
              suffix="SCrypt"
              prefix={<ThunderboltOutlined />}
              valueStyle={{ color: '#faad14' }}
            />
          </Card>
        </Col>
      </Row>

      {/* Wallets and Transactions Tabs */}
      <Card className="wallets-card">
        <Tabs defaultActiveKey="wallets">
          <TabPane tab="Wallets" key="wallets">
            <div style={{ marginBottom: 16 }}>
              <Button 
                type="primary" 
                icon={<PlusOutlined />}
                onClick={() => setNewWalletModalVisible(true)}
              >
                Create New Wallet
              </Button>
            </div>
            <Table
              dataSource={wallets}
              columns={walletColumns}
              rowKey="id"
              pagination={false}
              loading={loading}
            />
          </TabPane>
          <TabPane tab="Transactions" key="transactions">
            <Table
              dataSource={transactions}
              columns={transactionColumns}
              rowKey="txid"
              pagination={{ pageSize: 10 }}
              loading={loading}
            />
          </TabPane>
        </Tabs>
      </Card>

      {/* Wallet Details Modal */}
      {selectedWallet && (
        <Modal
          title={`Wallet: ${selectedWallet.name}`}
          open={!!selectedWallet}
          onCancel={() => setSelectedWallet(null)}
          footer={null}
          width={800}
        >
          <Descriptions bordered column={2}>
            <Descriptions.Item label="Name">{selectedWallet.name}</Descriptions.Item>
            <Descriptions.Item label="Type">
              <Tag color={
                selectedWallet.type === 'mining' ? 'green' : 
                selectedWallet.type === 'trading' ? 'blue' : 'orange'
              }>
                {selectedWallet.type}
              </Tag>
            </Descriptions.Item>
            <Descriptions.Item label="Address" span={2}>
              <Space>
                <Text code>{selectedWallet.address}</Text>
                <Button 
                  type="text" 
                  size="small" 
                  icon={<CopyOutlined />}
                  onClick={() => handleCopyAddress(selectedWallet.address)}
                />
              </Space>
            </Descriptions.Item>
            <Descriptions.Item label="Balance">{selectedWallet.balance.toFixed(2)} SCrypt</Descriptions.Item>
            <Descriptions.Item label="Pending Balance">{selectedWallet.pendingBalance.toFixed(2)} SCrypt</Descriptions.Item>
            <Descriptions.Item label="Total Received">{selectedWallet.totalReceived.toFixed(2)} SCrypt</Descriptions.Item>
            <Descriptions.Item label="Total Sent">{selectedWallet.totalSent.toFixed(2)} SCrypt</Descriptions.Item>
            <Descriptions.Item label="Transaction Count">{selectedWallet.transactionCount}</Descriptions.Item>
            <Descriptions.Item label="Last Activity">{selectedWallet.lastActivity}</Descriptions.Item>
            <Descriptions.Item label="Status">
              <Badge 
                status={selectedWallet.isActive ? 'success' : 'default'} 
                text={selectedWallet.isActive ? 'Active' : 'Inactive'}
              />
            </Descriptions.Item>
          </Descriptions>
        </Modal>
      )}

      {/* New Wallet Modal */}
      <Modal
        title="Create New Wallet"
        open={newWalletModalVisible}
        onCancel={() => setNewWalletModalVisible(false)}
        footer={null}
        width={600}
      >
        <Form
          form={form}
          layout="vertical"
          onFinish={handleCreateWallet}
        >
          <Form.Item
            name="name"
            label="Wallet Name"
            rules={[{ required: true, message: 'Please enter wallet name' }]}
          >
            <Input placeholder="Enter wallet name" />
          </Form.Item>
          
          <Form.Item
            name="type"
            label="Wallet Type"
            rules={[{ required: true, message: 'Please select wallet type' }]}
          >
            <Select placeholder="Select wallet type">
              <Option value="mining">Mining Wallet</Option>
              <Option value="trading">Trading Wallet</Option>
              <Option value="cold-storage">Cold Storage</Option>
            </Select>
          </Form.Item>
          
          <Form.Item>
            <Space>
              <Button type="primary" htmlType="submit" loading={loading}>
                Create Wallet
              </Button>
              <Button onClick={() => setNewWalletModalVisible(false)}>
                Cancel
              </Button>
            </Space>
          </Form.Item>
        </Form>
      </Modal>
    </div>
  );
};

export default WalletManagement; 