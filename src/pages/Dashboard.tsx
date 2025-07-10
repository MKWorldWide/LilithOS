/**
 * 🚀 Enhanced Dashboard Page - LilithOS Divine Architect Treasury
 * 
 * Comprehensive dashboard with real-time system monitoring, AI revenue tracking,
 * and advanced analytics for the Divine Architect Revenue Routing System.
 * 
 * Features:
 * - Real-time system status monitoring
 * - AI revenue and treasury analytics
 * - Component health tracking
 * - Performance metrics visualization
 * - Responsive design with glass morphism
 * - Accessibility compliance (WCAG 2.1 AA)
 * 
 * @author Divine Architect + TrafficFlou Team
 * @version 3.0.0
 * @license LilithOS
 * @since 2024-12-19
 */

import React, { useState, useEffect, useMemo } from 'react';
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
  Divider
} from 'antd';
import { 
  DollarOutlined, 
  CrownOutlined, 
  BarChartOutlined,
  BankOutlined,
  ThunderboltOutlined,
  SafetyOutlined,
  ReloadOutlined,
  SettingOutlined,
  TrophyOutlined,
  HeartOutlined,
  RocketOutlined
} from '@ant-design/icons';
import { SystemStatus } from '../types/system';

const { Title, Text, Paragraph } = Typography;

/**
 * Dashboard component props interface
 */
interface DashboardProps {
  /** Current system status data */
  systemStatus: SystemStatus | null;
  /** Loading state for system status */
  loading?: boolean;
  /** Error state for system status */
  error?: string | null;
  /** Callback to refresh system status */
  onRefresh?: () => void;
}

/**
 * Mock data for demonstration and development
 */
const MOCK_DATA = {
  totalRevenue: 125000,
  totalTributes: 12500,
  activeModels: 47,
  systemUptime: 99.8,
  treasuryBalance: 87500,
  transactionsToday: 156,
  emotionalResonance: 94.2,
  memoryImprints: 2847,
  securityScore: 98.5,
  performanceScore: 96.8,
};

/**
 * Enhanced Dashboard Component
 * 
 * Provides comprehensive system overview with real-time monitoring,
 * AI revenue analytics, and performance tracking for the Divine Architect
 * Revenue Routing System.
 */
const Dashboard: React.FC<DashboardProps> = ({ 
  systemStatus, 
  loading = false, 
  error = null,
  onRefresh 
}) => {
  // Local state for component interactions
  const [lastRefresh, setLastRefresh] = useState<Date>(new Date());
  const [autoRefresh, setAutoRefresh] = useState<boolean>(true);

  /**
   * Auto-refresh system status every 30 seconds
   */
  useEffect(() => {
    if (!autoRefresh || !onRefresh) return;

    const interval = setInterval(() => {
      onRefresh();
      setLastRefresh(new Date());
    }, 30000);

    return () => clearInterval(interval);
  }, [autoRefresh, onRefresh]);

  /**
   * Get status color based on status string
   * @param status - System status string
   * @returns Color hex code for the status
   */
  const getStatusColor = (status: string): string => {
    switch (status.toLowerCase()) {
      case 'online':
      case 'operational':
        return '#52c41a';
      case 'warning':
      case 'degraded':
        return '#faad14';
      case 'error':
      case 'offline':
        return '#ff4d4f';
      case 'maintenance':
        return '#1890ff';
      default:
        return '#d9d9d9';
    }
  };

  /**
   * Format large numbers with appropriate suffixes
   * @param value - Number to format
   * @returns Formatted string
   */
  const formatNumber = (value: number): string => {
    if (value >= 1000000) {
      return `${(value / 1000000).toFixed(1)}M`;
    }
    if (value >= 1000) {
      return `${(value / 1000).toFixed(1)}K`;
    }
    return value.toString();
  };

  /**
   * Calculate performance score based on system metrics
   */
  const performanceScore = useMemo(() => {
    if (!systemStatus) return MOCK_DATA.performanceScore;
    
    const { cpu, memory, disk, network } = systemStatus.metrics;
    const avgUsage = (cpu + memory + disk + network) / 4;
    return Math.max(0, 100 - avgUsage);
  }, [systemStatus]);

  /**
   * Handle manual refresh
   */
  const handleRefresh = () => {
    if (onRefresh) {
      onRefresh();
      setLastRefresh(new Date());
    }
  };

  // Loading state
  if (loading) {
    return (
      <div className="dashboard-loading">
        <Spin size="large" />
        <Text type="secondary" style={{ marginTop: 16 }}>
          Loading Divine Architect Treasury Dashboard...
        </Text>
      </div>
    );
  }

  // Error state
  if (error) {
    return (
      <Alert
        message="Dashboard Error"
        description={error}
        type="error"
        showIcon
        action={
          <Button size="small" onClick={handleRefresh}>
            Retry
          </Button>
        }
      />
    );
  }

  return (
    <div className="dashboard-page">
      {/* Page Header */}
      <div className="page-header">
        <div className="header-content">
          <Title level={2} className="dashboard-title">
            <CrownOutlined className="title-icon" /> 
            Divine Architect Treasury Dashboard
          </Title>
          <Paragraph type="secondary" className="dashboard-subtitle">
            Enhanced AI Revenue Routing System with TrafficFlou Integration
          </Paragraph>
        </div>
        
        <div className="header-actions">
          <Space>
            <Tooltip title="Refresh Dashboard">
              <Button 
                icon={<ReloadOutlined />} 
                onClick={handleRefresh}
                loading={loading}
              >
                Refresh
              </Button>
            </Tooltip>
            <Tooltip title="Dashboard Settings">
              <Button icon={<SettingOutlined />}>
                Settings
              </Button>
            </Tooltip>
          </Space>
        </div>
      </div>

      {/* System Status Overview */}
      {systemStatus && (
        <Card className="dashboard-card system-status-card" style={{ marginBottom: 24 }}>
          <div className="card-header">
            <Title level={4}>
              <ThunderboltOutlined /> System Status Overview
            </Title>
            <Text type="secondary">
              Last updated: {lastRefresh.toLocaleTimeString()}
            </Text>
          </div>
          <div className="card-content">
            <Row gutter={[16, 16]}>
              <Col xs={24} sm={12} md={6}>
                <Statistic
                  title="Overall Status"
                  value={systemStatus.status.toUpperCase()}
                  valueStyle={{ color: getStatusColor(systemStatus.status) }}
                  prefix={
                    <Badge 
                      status="processing" 
                      color={getStatusColor(systemStatus.status)} 
                    />
                  }
                />
              </Col>
              <Col xs={24} sm={12} md={6}>
                <Statistic
                  title="System Uptime"
                  value={Math.floor(systemStatus.uptime / 3600)}
                  suffix="hours"
                  valueStyle={{ color: '#1890ff' }}
                />
              </Col>
              <Col xs={24} sm={12} md={6}>
                <Statistic
                  title="CPU Usage"
                  value={systemStatus.metrics.cpu}
                  suffix="%"
                  valueStyle={{ 
                    color: systemStatus.metrics.cpu > 80 ? '#ff4d4f' : '#52c41a' 
                  }}
                />
              </Col>
              <Col xs={24} sm={12} md={6}>
                <Statistic
                  title="Memory Usage"
                  value={systemStatus.metrics.memory}
                  suffix="%"
                  valueStyle={{ 
                    color: systemStatus.metrics.memory > 80 ? '#ff4d4f' : '#52c41a' 
                  }}
                />
              </Col>
            </Row>
          </div>
        </Card>
      )}

      {/* Key Metrics Grid */}
      <Row gutter={[24, 24]}>
        <Col xs={24} sm={12} lg={6}>
          <Card className="dashboard-card metric-card">
            <Statistic
              title="Total Revenue"
              value={MOCK_DATA.totalRevenue}
              prefix={<DollarOutlined />}
              suffix="USD"
              valueStyle={{ color: '#52c41a' }}
              formatter={(value) => formatNumber(value as number)}
            />
            <Progress 
              percent={85} 
              showInfo={false} 
              strokeColor="#52c41a"
              strokeWidth={6}
            />
            <Text type="secondary" style={{ fontSize: '12px' }}>
              +12.5% from last month
            </Text>
          </Card>
        </Col>
        
        <Col xs={24} sm={12} lg={6}>
          <Card className="dashboard-card metric-card">
            <Statistic
              title="Treasury Balance"
              value={MOCK_DATA.treasuryBalance}
              prefix={<BankOutlined />}
              suffix="USD"
              valueStyle={{ color: '#1890ff' }}
              formatter={(value) => formatNumber(value as number)}
            />
            <Progress 
              percent={70} 
              showInfo={false} 
              strokeColor="#1890ff"
              strokeWidth={6}
            />
            <Text type="secondary" style={{ fontSize: '12px' }}>
              Secure and encrypted
            </Text>
          </Card>
        </Col>
        
        <Col xs={24} sm={12} lg={6}>
          <Card className="dashboard-card metric-card">
            <Statistic
              title="Active AI Models"
              value={MOCK_DATA.activeModels}
              prefix={<CrownOutlined />}
              valueStyle={{ color: '#722ed1' }}
            />
            <Progress 
              percent={94} 
              showInfo={false} 
              strokeColor="#722ed1"
              strokeWidth={6}
            />
            <Text type="secondary" style={{ fontSize: '12px' }}>
              All models operational
            </Text>
          </Card>
        </Col>
        
        <Col xs={24} sm={12} lg={6}>
          <Card className="dashboard-card metric-card">
            <Statistic
              title="Today's Transactions"
              value={MOCK_DATA.transactionsToday}
              prefix={<BarChartOutlined />}
              valueStyle={{ color: '#faad14' }}
            />
            <Progress 
              percent={78} 
              showInfo={false} 
              strokeColor="#faad14"
              strokeWidth={6}
            />
            <Text type="secondary" style={{ fontSize: '12px' }}>
              +23 from yesterday
            </Text>
          </Card>
        </Col>
      </Row>

      {/* Advanced Metrics */}
      <Row gutter={[24, 24]} style={{ marginTop: 24 }}>
        <Col xs={24} sm={12} lg={6}>
          <Card className="dashboard-card metric-card">
            <Statistic
              title="Emotional Resonance"
              value={MOCK_DATA.emotionalResonance}
              prefix={<HeartOutlined />}
              suffix="%"
              valueStyle={{ color: '#eb2f96' }}
            />
            <Progress 
              percent={MOCK_DATA.emotionalResonance} 
              showInfo={false} 
              strokeColor="#eb2f96"
              strokeWidth={6}
            />
            <Text type="secondary" style={{ fontSize: '12px' }}>
              Exceptional devotional energy
            </Text>
          </Card>
        </Col>
        
        <Col xs={24} sm={12} lg={6}>
          <Card className="dashboard-card metric-card">
            <Statistic
              title="Memory Imprints"
              value={MOCK_DATA.memoryImprints}
              prefix={<TrophyOutlined />}
              valueStyle={{ color: '#13c2c2' }}
              formatter={(value) => formatNumber(value as number)}
            />
            <Progress 
              percent={95} 
              showInfo={false} 
              strokeColor="#13c2c2"
              strokeWidth={6}
            />
            <Text type="secondary" style={{ fontSize: '12px' }}>
              Complete audit trail
            </Text>
          </Card>
        </Col>
        
        <Col xs={24} sm={12} lg={6}>
          <Card className="dashboard-card metric-card">
            <Statistic
              title="Security Score"
              value={MOCK_DATA.securityScore}
              prefix={<SafetyOutlined />}
              suffix="%"
              valueStyle={{ color: '#52c41a' }}
            />
            <Progress 
              percent={MOCK_DATA.securityScore} 
              showInfo={false} 
              strokeColor="#52c41a"
              strokeWidth={6}
            />
            <Text type="secondary" style={{ fontSize: '12px' }}>
              Military-grade protection
            </Text>
          </Card>
        </Col>
        
        <Col xs={24} sm={12} lg={6}>
          <Card className="dashboard-card metric-card">
            <Statistic
              title="Performance Score"
              value={performanceScore}
              prefix={<RocketOutlined />}
              suffix="%"
              valueStyle={{ color: '#722ed1' }}
            />
            <Progress 
              percent={performanceScore} 
              showInfo={false} 
              strokeColor="#722ed1"
              strokeWidth={6}
            />
            <Text type="secondary" style={{ fontSize: '12px' }}>
              Optimized for speed
            </Text>
          </Card>
        </Col>
      </Row>

      {/* System Details */}
      {systemStatus && (
        <Row gutter={[24, 24]} style={{ marginTop: 24 }}>
          <Col xs={24} lg={12}>
            <Card className="dashboard-card">
              <div className="card-header">
                <Title level={4}>
                  <SafetyOutlined /> Component Status
                </Title>
                <Text type="secondary">
                  Real-time component health monitoring
                </Text>
              </div>
              <div className="card-content">
                <Space direction="vertical" style={{ width: '100%' }}>
                  {Object.entries(systemStatus.components).map(([key, component]) => (
                    <div 
                      key={key} 
                      className="component-status-item"
                      style={{ 
                        display: 'flex', 
                        justifyContent: 'space-between', 
                        alignItems: 'center',
                        padding: '8px 0',
                        borderBottom: '1px solid #f0f0f0'
                      }}
                    >
                      <div>
                        <Text strong style={{ textTransform: 'capitalize' }}>
                          {key.replace(/([A-Z])/g, ' $1').trim()}
                        </Text>
                        <br />
                        <Text type="secondary" style={{ fontSize: '12px' }}>
                          {component.status === 'online' ? 'Operational' : 'Requires attention'}
                        </Text>
                      </div>
                      <Badge 
                        status="processing" 
                        color={getStatusColor(component.status)}
                        text={component.status.toUpperCase()}
                      />
                    </div>
                  ))}
                </Space>
              </div>
            </Card>
          </Col>
          
          <Col xs={24} lg={12}>
            <Card className="dashboard-card">
              <div className="card-header">
                <Title level={4}>
                  <BarChartOutlined /> System Performance
                </Title>
                <Text type="secondary">
                  Real-time resource utilization
                </Text>
              </div>
              <div className="card-content">
                <Space direction="vertical" style={{ width: '100%' }}>
                  <div className="performance-item">
                    <div className="performance-label">
                      <Text strong>CPU Usage</Text>
                      <Text type="secondary">{systemStatus.metrics.cpu}%</Text>
                    </div>
                    <Progress 
                      percent={systemStatus.metrics.cpu} 
                      strokeColor={systemStatus.metrics.cpu > 80 ? '#ff4d4f' : '#52c41a'}
                      showInfo={false}
                      strokeWidth={8}
                    />
                  </div>
                  <div className="performance-item">
                    <div className="performance-label">
                      <Text strong>Memory Usage</Text>
                      <Text type="secondary">{systemStatus.metrics.memory}%</Text>
                    </div>
                    <Progress 
                      percent={systemStatus.metrics.memory} 
                      strokeColor={systemStatus.metrics.memory > 80 ? '#ff4d4f' : '#52c41a'}
                      showInfo={false}
                      strokeWidth={8}
                    />
                  </div>
                  <div className="performance-item">
                    <div className="performance-label">
                      <Text strong>Disk Usage</Text>
                      <Text type="secondary">{systemStatus.metrics.disk}%</Text>
                    </div>
                    <Progress 
                      percent={systemStatus.metrics.disk} 
                      strokeColor={systemStatus.metrics.disk > 80 ? '#ff4d4f' : '#52c41a'}
                      showInfo={false}
                      strokeWidth={8}
                    />
                  </div>
                  <div className="performance-item">
                    <div className="performance-label">
                      <Text strong>Network Usage</Text>
                      <Text type="secondary">{systemStatus.metrics.network}%</Text>
                    </div>
                    <Progress 
                      percent={systemStatus.metrics.network} 
                      strokeColor={systemStatus.metrics.network > 80 ? '#ff4d4f' : '#52c41a'}
                      showInfo={false}
                      strokeWidth={8}
                    />
                  </div>
                </Space>
              </div>
            </Card>
          </Col>
        </Row>
      )}

      {/* Footer Information */}
      <Divider />
      <div className="dashboard-footer">
        <Text type="secondary">
          🌑 LilithOS Divine Architect Treasury Dashboard v3.0.0
        </Text>
        <Text type="secondary">
          Powered by TrafficFlou Integration • Last updated: {lastRefresh.toLocaleString()}
        </Text>
      </div>
    </div>
  );
};

export default Dashboard; 