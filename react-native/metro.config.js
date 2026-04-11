const { getDefaultConfig, mergeConfig } = require('@react-native/metro-config');
const path = require('path');

const projectRoot = __dirname;
const sdkRoot = path.resolve(projectRoot, '..', 'sdk');

// Resolve symlink target for bb-player (file: dependency creates symlink outside project root)
const bbPlayerLink = path.resolve(projectRoot, 'node_modules', '@bluebillywig', 'react-native-bb-player');
const bbPlayerReal = require('fs').realpathSync(bbPlayerLink);

const defaultConfig = getDefaultConfig(projectRoot);

const config = {
  // Watch the SDK + bb-player real path (symlink target is outside project root)
  watchFolders: [sdkRoot, bbPlayerReal],

  resolver: {
    // Block nested node_modules to prevent duplicate dependencies
    blockList: [
      new RegExp(`${sdkRoot.replace(/[/\\]/g, '[/\\\\]')}/node_modules/.*`),
      new RegExp(`${bbPlayerReal.replace(/[/\\]/g, '[/\\\\]')}/node_modules/.*`),
      /node_modules\/@bluebillywig\/react-native-channel\/node_modules\/.*/,
    ],

    // Resolve all modules from example's node_modules only
    nodeModulesPaths: [
      path.resolve(projectRoot, 'node_modules'),
    ],

    // Ensure SDK dependencies resolve to example's node_modules
    extraNodeModules: {
      'react': path.resolve(projectRoot, 'node_modules/react'),
      'react-native': path.resolve(projectRoot, 'node_modules/react-native'),
      'react-native-webview': path.resolve(projectRoot, 'node_modules/react-native-webview'),
      '@bluebillywig/react-native-bb-player': path.resolve(projectRoot, 'node_modules/@bluebillywig/react-native-bb-player'),
    },
  },
};

module.exports = mergeConfig(defaultConfig, config);
