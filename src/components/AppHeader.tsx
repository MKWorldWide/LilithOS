/**
 * 🚀 App Header Component - Enhanced AI Revenue Routing System
 * 
 * Main header component with user info, system status, and navigation
 * 
 * @author Divine Architect + TrafficFlou Team
 * @version 3.0.0
 * @license LilithOS
 */

import React from 'react';
import { Layout, Avatar, Dropdown, Badge, Space, Button, Typography } from 'antd';
import { 
  UserOutlined, 
  BellOutlined, 
  SettingOutlined, 
  LogoutOutlined,
  DashboardOutlined,
  CrownOutlined
} from '@ant-design/icons';
import { User, SystemStatus } from '../types/system';

const { Header } = Layout;
const { Text, Title } = Typography;

interface AppHeaderProps {
  user: User | null;
  systemStatus: SystemStatus | null;
  onLogout: () => Promise<void>;
}

const AppHeader: React.FC<AppHeaderProps> = ({ user, systemStatus, onLogout }) => {
  // User menu items
  const userMenuItems = [
    {
      key: 'profile',
      icon: <UserOutlined />,
      label: 'Profile',
    },
    {
      key: 'settings',
      icon: <SettingOutlined />,
      label: 'Settings',
    },
    {
      type: 'divider' as const,
    },
    {
      key: 'logout',
      icon: <LogoutOutlined />,
      label: 'Logout',
      onClick: onLogout,
    },
  ];

  // Notification menu items
  const notificationItems = [
    {
      key: '1',
      label: 'System operating normally',
      icon: <CrownOutlined style={{ color: '#52c41a' }} />,
    },
    {
      key: '2',
      label: 'Treasury Gateway active',
      icon: <DashboardOutlined style={{ color: '#1890ff' }} />,
    },
  ];

  // Get system status color
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
    <Header className="app-header">
      <div className="header-left">
        <div className="logo">
          <CrownOutlined className="logo-icon" />
          <Title level={4} className="logo-text">
            Divine Architect Treasury
          </Title>
        </div>
      </div>

      <div className="header-center">
        {systemStatus && (
          <Space>
            <Badge 
              status="processing" 
              color={getStatusColor(systemStatus.status)}
            />
            <Text type="secondary">
              System: {systemStatus.status.toUpperCase()}
            </Text>
            <Text type="secondary">
              Uptime: {Math.floor(systemStatus.uptime / 3600)}h {Math.floor((systemStatus.uptime % 3600) / 60)}m
            </Text>
          </Space>
        )}
      </div>

      <div className="header-right">
        <Space size="middle">
          {/* Notifications */}
          <Dropdown
            menu={{ items: notificationItems }}
            placement="bottomRight"
            trigger={['click']}
          >
            <Badge count={notificationItems.length} size="small">
              <Button 
                type="text" 
                icon={<BellOutlined />} 
                size="large"
                className="header-button"
              />
            </Badge>
          </Dropdown>

          {/* User Menu */}
          <Dropdown
            menu={{ items: userMenuItems }}
            placement="bottomRight"
            trigger={['click']}
          >
            <Space className="user-menu">
              <Avatar 
                icon={<UserOutlined />} 
                size="default"
                className="user-avatar"
              />
              <div className="user-info">
                <Text strong>{user?.username || 'User'}</Text>
                <Text type="secondary" className="user-role">
                  {user?.role || 'user'}
                </Text>
              </div>
            </Space>
          </Dropdown>
        </Space>
      </div>
    </Header>
  );
};

export default AppHeader; 