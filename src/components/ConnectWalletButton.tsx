import React, { useState } from 'react';
import { Button, Modal, List, Avatar, Typography, Space, Tooltip } from 'antd';
import { WalletOutlined, CheckCircleTwoTone, DisconnectOutlined } from '@ant-design/icons';
// Solana wallet adapter imports
import { useWallet as useSolanaWallet } from '@solana/wallet-adapter-react';
import { WalletReadyState } from '@solana/wallet-adapter-base';
import { WalletModalProvider, WalletMultiButton } from '@solana/wallet-adapter-react-ui';
// EVM wallet imports
import { useWeb3React } from '@web3-react/core';
import { MetaMask } from '@web3-react/metamask';
import { ethers } from 'ethers';

const { Text } = Typography;

// List of supported wallets
const WALLET_OPTIONS = [
  {
    key: 'phantom',
    name: 'Phantom (Solana)',
    icon: 'https://cryptologos.cc/logos/phantom-phantom-logo.png',
    type: 'solana',
  },
  {
    key: 'solflare',
    name: 'Solflare (Solana)',
    icon: 'https://cryptologos.cc/logos/solflare-solflare-logo.png',
    type: 'solana',
  },
  {
    key: 'metamask',
    name: 'MetaMask (EVM)',
    icon: 'https://cryptologos.cc/logos/metamask-metamask-logo.png',
    type: 'evm',
  },
  {
    key: 'walletconnect',
    name: 'WalletConnect (EVM)',
    icon: 'https://cryptologos.cc/logos/walletconnect-walletconnect-logo.png',
    type: 'evm',
  },
];

const ConnectWalletButton: React.FC = () => {
  const [modalOpen, setModalOpen] = useState(false);
  // Solana
  const solanaWallet = useSolanaWallet();
  // EVM
  const { connector, account, isActive, activate, deactivate } = useWeb3React();

  // Unified state
  const isSolanaConnected = solanaWallet.connected;
  const isEvmConnected = isActive;
  const connectedAddress = isSolanaConnected
    ? solanaWallet.publicKey?.toBase58()
    : isEvmConnected
    ? account
    : null;
  const connectedType = isSolanaConnected ? 'solana' : isEvmConnected ? 'evm' : null;

  // Connect handlers
  const handleConnect = async (walletKey: string) => {
    if (walletKey === 'phantom' || walletKey === 'solflare') {
      setModalOpen(false);
      // Let WalletMultiButton handle connection
    } else if (walletKey === 'metamask') {
      try {
        await activate(new MetaMask());
        setModalOpen(false);
      } catch (err) {
        // handle error
      }
    } else if (walletKey === 'walletconnect') {
      // TODO: Add WalletConnect integration
      setModalOpen(false);
    }
  };

  // Disconnect handler
  const handleDisconnect = () => {
    if (isSolanaConnected) {
      solanaWallet.disconnect();
    } else if (isEvmConnected) {
      deactivate();
    }
  };

  return (
    <>
      <Space>
        {connectedAddress ? (
          <Tooltip title={connectedAddress}>
            <Button
              type="primary"
              icon={<WalletOutlined />}
              onClick={handleDisconnect}
              danger
            >
              {connectedType === 'solana' ? 'Solana' : 'EVM'}: {connectedAddress.slice(0, 6)}...{connectedAddress.slice(-4)}
              <DisconnectOutlined style={{ marginLeft: 8 }} />
            </Button>
          </Tooltip>
        ) : (
          <Button
            type="primary"
            icon={<WalletOutlined />}
            onClick={() => setModalOpen(true)}
          >
            Connect Wallet
          </Button>
        )}
      </Space>
      <Modal
        title="Connect Wallet"
        open={modalOpen}
        onCancel={() => setModalOpen(false)}
        footer={null}
      >
        <List
          itemLayout="horizontal"
          dataSource={WALLET_OPTIONS}
          renderItem={item => (
            <List.Item
              actions={[
                connectedType === item.type && connectedAddress ? (
                  <CheckCircleTwoTone twoToneColor="#52c41a" />
                ) : (
                  <Button type="link" onClick={() => handleConnect(item.key)}>
                    Connect
                  </Button>
                ),
              ]}
            >
              <List.Item.Meta
                avatar={<Avatar src={item.icon} />}
                title={item.name}
              />
            </List.Item>
          )}
        />
        {/* Solana wallet connect button (hidden, but triggers modal for Phantom/Solflare) */}
        <div style={{ display: 'none' }}>
          <WalletModalProvider>
            <WalletMultiButton />
          </WalletModalProvider>
        </div>
      </Modal>
    </>
  );
};

export default ConnectWalletButton; 