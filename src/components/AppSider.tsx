/**
 * 🚀 App Sider Component - Enhanced AI Revenue Routing System
 * 
 * Sidebar navigation component with menu items
 * 
 * @author Divine Architect + TrafficFlou Team
 * @version 3.0.0
 * @license LilithOS
 */

import React from 'react';
import { Layout, Menu } from 'antd';
import { useNavigate, useLocation } from 'react-router-dom';
import {
  DashboardOutlined,
  DollarOutlined,
  BarChartOutlined,
  BankOutlined,
  CrownOutlined,
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
      key: '/revenue-routing',
      icon: <DollarOutlined />,
      label: 'Revenue Routing',
    },
    {
      key: '/traffic-analytics',
      icon: <BarChartOutlined />,
      label: 'Traffic Analytics',
    },
    {
      key: '/treasury',
      icon: <BankOutlined />,
      label: 'Treasury Management',
    },
    {
      key: '/primal-genesis',
      icon: <CrownOutlined />,
      label: 'Primal Genesis',
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