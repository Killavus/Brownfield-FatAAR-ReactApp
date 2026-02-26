const { getDefaultConfig, mergeConfig } = require('@react-native/metro-config');
const path = require('path');

const nitroEventPipeDir = path.resolve(__dirname, "../../Utils/react-native-nitro-event-pipe");

/**
 * Metro configuration
 * https://reactnative.dev/docs/metro
 *
 * @type {import('@react-native/metro-config').MetroConfig}
 */
const config = {
  watchFolders: [nitroEventPipeDir],
  resolver: {
    extraNodeModules: {
      "react-native-nitro-event-pipe": nitroEventPipeDir
    } 
  }
};

module.exports = mergeConfig(getDefaultConfig(__dirname), config);
