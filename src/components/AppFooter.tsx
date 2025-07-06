/**
 * 🚀 App Footer Component - Enhanced AI Revenue Routing System
 * 
 * Footer component with system information and links
 * 
 * @author Divine Architect + TrafficFlou Team
 * @version 3.0.0
 * @license LilithOS
 */

import React from 'react';
import { Layout, Typography, Space } from 'antd';
import { CrownOutlined, HeartOutlined } from '@ant-design/icons';

const { Footer } = Layout;
const { Text, Link } = Typography;

const AppFooter: React.FC = () => {
  const currentYear = new Date().getFullYear();

  return (
    <Footer className="app-footer">
      <Space split={<Text type="secondary">|</Text>}>
        <Text type="secondary">
          <CrownOutlined /> Divine Architect Treasury v3.0.0
        </Text>
        <Text type="secondary">
          Powered by <HeartOutlined style={{ color: '#ff4d4f' }} /> LilithOS
        </Text>
        <Text type="secondary">
          © {currentYear} Divine Architect + TrafficFlou Team
        </Text>
        <Link href="#" type="secondary">
          Privacy Policy
        </Link>
        <Link href="#" type="secondary">
          Terms of Service
        </Link>
      </Space>
    </Footer>
  );
};

export default AppFooter; 