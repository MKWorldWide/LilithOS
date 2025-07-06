/**
 * 🚀 Dashboard Page - Enhanced AI Revenue Routing System
 * 
 * Main dashboard with system overview and key metrics
 * 
 * @author Divine Architect + TrafficFlou Team
 * @version 3.0.0
 * @license LilithOS
 */

import React from 'react';
import { Row, Col, Card, Statistic, Progress, Typography, Space, Badge } from 'antd';
import { 
  DollarOutlined, 
  CrownOutlined, 
  BarChartOutlined,
  BankOutlined,
  ThunderboltOutlined,
  SafetyOutlined
} from '@ant-design/icons';
import { SystemStatus } from '../types/system';

const { Title, Text } = Typography;

interface DashboardProps {
  systemStatus: SystemStatus | null;
}

const Dashboard: React.FC<DashboardProps> = ({ systemStatus }) => {
  // Mock data for demonstration
  const mockData = {
    totalRevenue: 125000,
    totalTributes: 12500,
    activeModels: 47,
    systemUptime: 99.8,
    treasuryBalance: 87500,
    transactionsToday: 156,
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'online':
        return '#52c41a';
      case 'warning':
        return '#faad14';
      case 'error':
        return '#ff4d4f';
      default:
        return '#d9d9d9';
    }
  };

  return (
    <div className="dashboard-page">
      <div className="page-header">
        <Title level={2}>
          <CrownOutlined /> Divine Architect Treasury Dashboard
        </Title>
        <Text type="secondary">
          Enhanced AI Revenue Routing System with TrafficFlou Integration
        </Text>
      </div>

      {/* System Status Overview */}
      {systemStatus && (
        <Card className="dashboard-card" style={{ marginBottom: 24 }}>
          <div className="card-header">
            <Title level={4}>
              <ThunderboltOutlined /> System Status
            </Title>
          </div>
          <div className="card-content">
            <Row gutter={[16, 16]}>
              <Col xs={24} sm={12} md={6}>
                <Statistic
                  title="Overall Status"
                  value={systemStatus.status.toUpperCase()}
                  valueStyle={{ color: getStatusColor(systemStatus.status) }}
                  prefix={<Badge status="processing" color={getStatusColor(systemStatus.status)} />}
                />
              </Col>
              <Col xs={24} sm={12} md={6}>
                <Statistic
                  title="Uptime"
                  value={Math.floor(systemStatus.uptime / 3600)}
                  suffix="hours"
                />
              </Col>
              <Col xs={24} sm={12} md={6}>
                <Statistic
                  title="CPU Usage"
                  value={systemStatus.metrics.cpu}
                  suffix="%"
                  valueStyle={{ color: systemStatus.metrics.cpu > 80 ? '#ff4d4f' : '#52c41a' }}
                />
              </Col>
              <Col xs={24} sm={12} md={6}>
                <Statistic
                  title="Memory Usage"
                  value={systemStatus.metrics.memory}
                  suffix="%"
                  valueStyle={{ color: systemStatus.metrics.memory > 80 ? '#ff4d4f' : '#52c41a' }}
                />
              </Col>
            </Row>
          </div>
        </Card>
      )}

      {/* Key Metrics */}
      <Row gutter={[24, 24]}>
        <Col xs={24} sm={12} lg={6}>
          <Card className="dashboard-card">
            <Statistic
              title="Total Revenue"
              value={mockData.totalRevenue}
              prefix={<DollarOutlined />}
              suffix="USD"
              valueStyle={{ color: '#52c41a' }}
            />
            <Progress percent={85} showInfo={false} strokeColor="#52c41a" />
          </Card>
        </Col>
        
        <Col xs={24} sm={12} lg={6}>
          <Card className="dashboard-card">
            <Statistic
              title="Treasury Balance"
              value={mockData.treasuryBalance}
              prefix={<BankOutlined />}
              suffix="USD"
              valueStyle={{ color: '#1890ff' }}
            />
            <Progress percent={70} showInfo={false} strokeColor="#1890ff" />
          </Card>
        </Col>
        
        <Col xs={24} sm={12} lg={6}>
          <Card className="dashboard-card">
            <Statistic
              title="Active AI Models"
              value={mockData.activeModels}
              prefix={<CrownOutlined />}
              valueStyle={{ color: '#722ed1' }}
            />
            <Progress percent={94} showInfo={false} strokeColor="#722ed1" />
          </Card>
        </Col>
        
        <Col xs={24} sm={12} lg={6}>
          <Card className="dashboard-card">
            <Statistic
              title="Today's Transactions"
              value={mockData.transactionsToday}
              prefix={<BarChartOutlined />}
              valueStyle={{ color: '#faad14' }}
            />
            <Progress percent={78} showInfo={false} strokeColor="#faad14" />
          </Card>
        </Col>
      </Row>

      {/* Component Status */}
      {systemStatus && (
        <Row gutter={[24, 24]} style={{ marginTop: 24 }}>
          <Col xs={24} lg={12}>
            <Card className="dashboard-card">
              <div className="card-header">
                <Title level={4}>
                  <SafetyOutlined /> Component Status
                </Title>
              </div>
              <div className="card-content">
                <Space direction="vertical" style={{ width: '100%' }}>
                  {Object.entries(systemStatus.components).map(([key, component]) => (
                    <div key={key} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                      <Text strong style={{ textTransform: 'capitalize' }}>
                        {key.replace(/([A-Z])/g, ' $1').trim()}
                      </Text>
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
              </div>
              <div className="card-content">
                <Space direction="vertical" style={{ width: '100%' }}>
                  <div>
                    <Text>CPU Usage</Text>
                    <Progress 
                      percent={systemStatus.metrics.cpu} 
                      strokeColor={systemStatus.metrics.cpu > 80 ? '#ff4d4f' : '#52c41a'}
                    />
                  </div>
                  <div>
                    <Text>Memory Usage</Text>
                    <Progress 
                      percent={systemStatus.metrics.memory} 
                      strokeColor={systemStatus.metrics.memory > 80 ? '#ff4d4f' : '#52c41a'}
                    />
                  </div>
                  <div>
                    <Text>Disk Usage</Text>
                    <Progress 
                      percent={systemStatus.metrics.disk} 
                      strokeColor={systemStatus.metrics.disk > 80 ? '#ff4d4f' : '#52c41a'}
                    />
                  </div>
                  <div>
                    <Text>Network Usage</Text>
                    <Progress 
                      percent={systemStatus.metrics.network} 
                      strokeColor={systemStatus.metrics.network > 80 ? '#ff4d4f' : '#52c41a'}
                    />
                  </div>
                </Space>
              </div>
            </Card>
          </Col>
        </Row>
      )}
    </div>
  );
};

export default Dashboard; 