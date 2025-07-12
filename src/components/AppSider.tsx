/**
 * 🔐 App Sider Component - Scrypt Mining Framework
 * 
 * Sidebar navigation component with mining menu items
 * 
 * @author M-K-World-Wide Scrypt Team
 * @version 1.0.0
 * @license MIT
 */

import React from 'react';
import { Layout, Menu } from 'antd';
import { useNavigate, useLocation } from 'react-router-dom';
import {
  DashboardOutlined,
  ThunderboltOutlined,
  LinkOutlined,
  WalletOutlined,
  BarChartOutlined,
  SettingOutlined,
  MenuFoldOutlined,
  MenuUnfoldOutlined,
} from '@ant-design/icons';

const { Sider } = Layout;

interface AppSiderProps {
  collapsed: boolean;
  onCollapse: (collapsed: boolean) => void;
}

const AppSider: React.FC<AppSiderProps> = ({ collapsed, onCollapse }) => {
  const navigate = useNavigate();
  const location = useLocation();

  const menuItems = [
    {
      key: '/',
      icon: <DashboardOutlined />,
      label: 'Dashboard',
    },
    {
      key: '/mining-operations',
      icon: <ThunderboltOutlined />,
      label: 'Mining Operations',
    },
    {
      key: '/blockchain-explorer',
      icon: <LinkOutlined />,
      label: 'Blockchain Explorer',
    },
    {
      key: '/wallet-management',
      icon: <WalletOutlined />,
      label: 'Wallet Management',
    },
    {
      key: '/mining-analytics',
      icon: <BarChartOutlined />,
      label: 'Mining Analytics',
    },
    {
      key: '/settings',
      icon: <SettingOutlined />,
      label: 'Settings',
    },
  ];

  const handleMenuClick = ({ key }: { key: string }) => {
    navigate(key);
  };

  return (
    <Sider 
      trigger={null} 
      collapsible 
      collapsed={collapsed}
      className="app-sider"
      width={256}
    >
      <div className="sider-header">
        {collapsed ? (
          <MenuUnfoldOutlined 
            className="trigger" 
            onClick={() => onCollapse(false)}
          />
        ) : (
          <MenuFoldOutlined 
            className="trigger" 
            onClick={() => onCollapse(true)}
          />
        )}
      </div>
      
      <Menu
        theme="light"
        mode="inline"
        selectedKeys={[location.pathname]}
        items={menuItems}
        onClick={handleMenuClick}
        className="sider-menu"
      />
    </Sider>
  );
};

export default AppSider; 