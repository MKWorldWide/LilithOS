#!/usr/bin/env node

/**
 * Postinstall script to check for deprecated packages
 * Warns about deprecated dependencies that should be updated
 */

const { dependencies, devDependencies } = require('../package.json');
const allDeps = { ...dependencies, ...devDependencies };

console.log('🔍 Checking for deprecated packages...');

const deprecatedPackages = {
  '@toruslabs/solana-embed': {
    message: '⚠️  Warning: Deprecated dependency @toruslabs/solana-embed detected. Consider replacing it with @web3auth/ws-embed instead.',
    recommendation: 'npm uninstall @toruslabs/solana-embed && npm install @web3auth/ws-embed'
  },
  '@web3modal/react': {
    message: '⚠️  Warning: Deprecated dependency @web3modal/react detected. Please use new @web3modal/wagmi package.',
    recommendation: 'npm uninstall @web3modal/react && npm install @web3modal/wagmi'
  },
  '@web3modal/core': {
    message: '⚠️  Warning: Deprecated dependency @web3modal/core detected. Web3Modal is now Reown AppKit.',
    recommendation: 'Follow upgrade guide at https://docs.reown.com/appkit/upgrade/from-w3m-to-reown'
  },
  '@web3modal/ui': {
    message: '⚠️  Warning: Deprecated dependency @web3modal/ui detected. Web3Modal is now Reown AppKit.',
    recommendation: 'Follow upgrade guide at https://docs.reown.com/appkit/upgrade/from-w3m-to-reown'
  },
  'crypto': {
    message: '⚠️  Warning: Deprecated dependency crypto detected. It\'s now a built-in Node module.',
    recommendation: 'Remove crypto dependency and use Node.js built-in crypto module'
  }
};

let foundDeprecated = false;

Object.keys(deprecatedPackages).forEach(pkg => {
  if (allDeps[pkg]) {
    console.log(deprecatedPackages[pkg].message);
    console.log(`💡 Recommendation: ${deprecatedPackages[pkg].recommendation}\n`);
    foundDeprecated = true;
  }
});

if (!foundDeprecated) {
  console.log('✅ No deprecated packages found!');
}

console.log('📦 Package check completed.'); 