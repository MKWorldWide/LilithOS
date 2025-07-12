/**
 * 🔗 Blockchain Explorer Page - Scrypt Mining Framework
 * 
 * Comprehensive blockchain explorer with real-time block monitoring,
 * transaction tracking, and network statistics.
 * 
 * Features:
 * - Real-time blockchain data monitoring
 * - Block and transaction exploration
 * - Network statistics and metrics
 * - Mining difficulty tracking
 * - Wallet address monitoring
 * - Transaction history
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
  Descriptions,
  message
} from 'antd';
import { 
  LinkOutlined, 
  SearchOutlined, 
  ReloadOutlined,
  BarChartOutlined,
    ClockCircleOutlined,
  ThunderboltOutlined,
  SafetyOutlined,
  EyeOutlined
} from '@ant-design/icons';

const { Title, Text, Paragraph } = Typography;
const { Search } = Input;
const { Option } = Select;

/**
 * Block data interface
 */
interface Block {
  height: number;
  hash: string;
  timestamp: string;
  transactions: number;
  size: number;
  difficulty: number;
  nonce: number;
  merkleRoot: string;
  previousHash: string;
  miner: string;
  reward: number;
}

/**
 * Transaction data interface
 */
interface Transaction {
  txid: string;
  blockHeight: number;
  timestamp: string;
  inputs: number;
  outputs: number;
  amount: number;
  fee: number;
  confirmations: number;
  status: 'confirmed' | 'pending' | 'failed';
}

/**
 * Mock blockchain data
 */
const MOCK_BLOCKS: Block[] = [
  {
    height: 1234567,
    hash: '0000000000000000001234567890abcdef1234567890abcdef1234567890abcdef',
    timestamp: '2024-12-19 15:30:45',
    transactions: 1250,
    size: 1024,
    difficulty: 2847.123,
    nonce: 12345678,
    merkleRoot: 'abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890',
    previousHash: '0000000000000000001234567890abcdef1234567890abcdef1234567890abcdee',
    miner: 'scrypt.pool.example.com',
    reward: 50.0
  },
  {
    height: 1234566,
    hash: '0000000000000000001234567890abcdef1234567890abcdef1234567890abcdee',
    timestamp: '2024-12-19 15:25:32',
    transactions: 1180,
    size: 956,
    difficulty: 2847.123,
    nonce: 87654321,
    merkleRoot: 'fedcba0987654321fedcba0987654321fedcba0987654321fedcba0987654321',
    previousHash: '0000000000000000001234567890abcdef1234567890abcdef1234567890abcdee',
    miner: 'scrypt.pool2.example.com',
    reward: 50.0
  }
];

const MOCK_TRANSACTIONS: Transaction[] = [
  {
    txid: 'abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890',
    blockHeight: 1234567,
    timestamp: '2024-12-19 15:30:45',
    inputs: 2,
    outputs: 3,
    amount: 125.5,
    fee: 0.001,
    confirmations: 1,
    status: 'confirmed'
  },
  {
    txid: 'fedcba0987654321fedcba0987654321fedcba0987654321fedcba0987654321',
    blockHeight: 1234567,
    timestamp: '2024-12-19 15:29:12',
    inputs: 1,
    outputs: 2,
    amount: 75.25,
    fee: 0.0005,
    confirmations: 1,
    status: 'confirmed'
  }
];

/**
 * Blockchain Explorer Component
 * 
 * Provides comprehensive blockchain exploration with real-time monitoring,
 * block and transaction tracking for the Scrypt Mining Framework.
 */
const BlockchainExplorer: React.FC = () => {
  // State management
  const [blocks] = useState<Block[]>(MOCK_BLOCKS);
  const [transactions] = useState<Transaction[]>(MOCK_TRANSACTIONS);
  const [loading, setLoading] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [searchType, setSearchType] = useState<'block' | 'transaction' | 'address'>('block');
  const [selectedBlock, setSelectedBlock] = useState<Block | null>(null);
  const [selectedTransaction, setSelectedTransaction] = useState<Transaction | null>(null);

  // Network statistics
  const networkStats = {
    totalBlocks: 1234567,
    totalTransactions: 456789012,
    averageBlockTime: 2.5,
    currentDifficulty: 2847.123,
    networkHashRate: 1250.5,
    totalSupply: 21000000
  };

  /**
   * Handle search
   */
  const handleSearch = (value: string) => {
    setSearchQuery(value);
    setLoading(true);
    
    // Simulate search
    setTimeout(() => {
      setLoading(false);
      // In real implementation, this would search the blockchain
    }, 1000);
  };

  /**
   * Handle block selection
   */
  const handleBlockSelect = (block: Block) => {
    setSelectedBlock(block);
  };

  /**
   * Handle transaction selection
   */
  const handleTransactionSelect = (transaction: Transaction) => {
    setSelectedTransaction(transaction);
  };

  /**
   * Block table columns
   */
  const blockColumns = [
    {
      title: 'Height',
      dataIndex: 'height',
      key: 'height',
      render: (height: number) => (
        <Button 
          type="link" 
          onClick={() => handleBlockSelect({ height, hash: '', timestamp: '', transactions: 0, size: 0, difficulty: 0, nonce: 0, merkleRoot: '', previousHash: '', miner: '', reward: 0 })}
        >
          {height.toLocaleString()}
        </Button>
      )
    },
    {
      title: 'Hash',
      dataIndex: 'hash',
      key: 'hash',
      render: (hash: string) => (
        <Text code style={{ fontSize: '12px' }}>
          {hash.substring(0, 16)}...
        </Text>
      )
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
      title: 'Transactions',
      dataIndex: 'transactions',
      key: 'transactions',
      render: (transactions: number) => transactions.toLocaleString()
    },
    {
      title: 'Size',
      dataIndex: 'size',
      key: 'size',
      render: (size: number) => `${size} KB`
    },
    {
      title: 'Difficulty',
      dataIndex: 'difficulty',
      key: 'difficulty',
      render: (difficulty: number) => difficulty.toFixed(3)
    },
    {
      title: 'Miner',
      dataIndex: 'miner',
      key: 'miner',
      render: (miner: string) => <Text code>{miner}</Text>
    },
    {
      title: 'Reward',
      dataIndex: 'reward',
      key: 'reward',
      render: (reward: number) => `${reward} SCrypt`
    }
  ];

  /**
   * Transaction table columns
   */
  const transactionColumns = [
    {
      title: 'Transaction ID',
      dataIndex: 'txid',
      key: 'txid',
      render: (txid: string) => (
        <Button 
          type="link" 
          onClick={() => handleTransactionSelect({ txid, blockHeight: 0, timestamp: '', inputs: 0, outputs: 0, amount: 0, fee: 0, confirmations: 0, status: 'confirmed' })}
        >
          <Text code style={{ fontSize: '12px' }}>
            {txid.substring(0, 16)}...
          </Text>
        </Button>
      )
    },
    {
      title: 'Block',
      dataIndex: 'blockHeight',
      key: 'blockHeight',
      render: (blockHeight: number) => blockHeight.toLocaleString()
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
      title: 'Amount',
      dataIndex: 'amount',
      key: 'amount',
      render: (amount: number) => `${amount} SCrypt`
    },
    {
      title: 'Fee',
      dataIndex: 'fee',
      key: 'fee',
      render: (fee: number) => `${fee} SCrypt`
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
    <div className="blockchain-explorer-page">
      {/* Page Header */}
      <div className="page-header">
        <Title level={2}>
          <LinkOutlined className="title-icon" />
          Blockchain Explorer
        </Title>
        <Paragraph type="secondary">
          Explore the Scrypt blockchain in real-time
        </Paragraph>
      </div>

      {/* Search Bar */}
      <Card className="search-card">
        <Row gutter={[16, 16]} align="middle">
          <Col xs={24} sm={8}>
            <Select
              value={searchType}
              onChange={setSearchType}
              style={{ width: '100%' }}
            >
              <Option value="block">Block Height</Option>
              <Option value="transaction">Transaction ID</Option>
              <Option value="address">Address</Option>
            </Select>
          </Col>
          <Col xs={24} sm={16}>
            <Search
              placeholder={`Search by ${searchType}...`}
              enterButton={<SearchOutlined />}
              size="large"
              onSearch={handleSearch}
              loading={loading}
            />
          </Col>
        </Row>
      </Card>

      {/* Network Statistics */}
      <Row gutter={[16, 16]} className="stats-row">
        <Col xs={24} sm={12} lg={6}>
          <Card className="stat-card">
            <Statistic
              title="Total Blocks"
              value={networkStats.totalBlocks}
              prefix={<BarChartOutlined />}
              valueStyle={{ color: '#52c41a' }}
            />
          </Card>
        </Col>
        <Col xs={24} sm={12} lg={6}>
          <Card className="stat-card">
            <Statistic
              title="Total Transactions"
              value={networkStats.totalTransactions}
              prefix={<LinkOutlined />}
              valueStyle={{ color: '#1890ff' }}
            />
          </Card>
        </Col>
        <Col xs={24} sm={12} lg={6}>
          <Card className="stat-card">
            <Statistic
              title="Network Hash Rate"
              value={networkStats.networkHashRate}
              suffix="MH/s"
              prefix={<ThunderboltOutlined />}
              valueStyle={{ color: '#722ed1' }}
            />
          </Card>
        </Col>
        <Col xs={24} sm={12} lg={6}>
          <Card className="stat-card">
            <Statistic
              title="Current Difficulty"
              value={networkStats.currentDifficulty}
              prefix={<SafetyOutlined />}
              valueStyle={{ color: '#faad14' }}
            />
          </Card>
        </Col>
      </Row>

      {/* Recent Blocks */}
      <Card 
        title="Recent Blocks" 
        className="blocks-card"
        extra={
          <Button icon={<ReloadOutlined />} onClick={() => message.info('Refreshing blocks...')}>
            Refresh
          </Button>
        }
      >
        <Table
          dataSource={blocks}
          columns={blockColumns}
          rowKey="height"
          pagination={{ pageSize: 10 }}
          loading={loading}
        />
      </Card>

      {/* Recent Transactions */}
      <Card 
        title="Recent Transactions" 
        className="transactions-card"
        extra={
          <Button icon={<ReloadOutlined />} onClick={() => message.info('Refreshing transactions...')}>
            Refresh
          </Button>
        }
      >
        <Table
          dataSource={transactions}
          columns={transactionColumns}
          rowKey="txid"
          pagination={{ pageSize: 10 }}
          loading={loading}
        />
      </Card>

      {/* Block Details Modal */}
      {selectedBlock && (
        <Card
          title={`Block ${selectedBlock.height}`}
          className="block-details-card"
          extra={
            <Button icon={<EyeOutlined />} onClick={() => setSelectedBlock(null)}>
              Close
            </Button>
          }
        >
          <Descriptions bordered column={2}>
            <Descriptions.Item label="Height">{selectedBlock.height}</Descriptions.Item>
            <Descriptions.Item label="Hash">
              <Text code>{selectedBlock.hash}</Text>
            </Descriptions.Item>
            <Descriptions.Item label="Timestamp">{selectedBlock.timestamp}</Descriptions.Item>
            <Descriptions.Item label="Transactions">{selectedBlock.transactions}</Descriptions.Item>
            <Descriptions.Item label="Size">{selectedBlock.size} KB</Descriptions.Item>
            <Descriptions.Item label="Difficulty">{selectedBlock.difficulty}</Descriptions.Item>
            <Descriptions.Item label="Nonce">{selectedBlock.nonce}</Descriptions.Item>
            <Descriptions.Item label="Miner">
              <Text code>{selectedBlock.miner}</Text>
            </Descriptions.Item>
            <Descriptions.Item label="Reward">{selectedBlock.reward} SCrypt</Descriptions.Item>
            <Descriptions.Item label="Merkle Root">
              <Text code>{selectedBlock.merkleRoot}</Text>
            </Descriptions.Item>
          </Descriptions>
        </Card>
      )}

      {/* Transaction Details Modal */}
      {selectedTransaction && (
        <Card
          title={`Transaction ${selectedTransaction.txid.substring(0, 16)}...`}
          className="transaction-details-card"
          extra={
            <Button icon={<EyeOutlined />} onClick={() => setSelectedTransaction(null)}>
              Close
            </Button>
          }
        >
          <Descriptions bordered column={2}>
            <Descriptions.Item label="Transaction ID">
              <Text code>{selectedTransaction.txid}</Text>
            </Descriptions.Item>
            <Descriptions.Item label="Block Height">{selectedTransaction.blockHeight}</Descriptions.Item>
            <Descriptions.Item label="Timestamp">{selectedTransaction.timestamp}</Descriptions.Item>
            <Descriptions.Item label="Amount">{selectedTransaction.amount} SCrypt</Descriptions.Item>
            <Descriptions.Item label="Fee">{selectedTransaction.fee} SCrypt</Descriptions.Item>
            <Descriptions.Item label="Confirmations">{selectedTransaction.confirmations}</Descriptions.Item>
            <Descriptions.Item label="Inputs">{selectedTransaction.inputs}</Descriptions.Item>
            <Descriptions.Item label="Outputs">{selectedTransaction.outputs}</Descriptions.Item>
            <Descriptions.Item label="Status">
              <Tag color={selectedTransaction.status === 'confirmed' ? 'green' : 'orange'}>
                {selectedTransaction.status}
              </Tag>
            </Descriptions.Item>
          </Descriptions>
        </Card>
      )}
    </div>
  );
};

export default BlockchainExplorer; 