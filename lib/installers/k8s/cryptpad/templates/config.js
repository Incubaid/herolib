module.exports = {
    httpUnsafeOrigin: 'https://@{config_values.hostname}.gent01.grid.tf',
    httpSafeOrigin: 'https://@{config_values.hostname}sb.gent01.grid.tf',
    httpAddress: '0.0.0.0',
    httpPort: 80,

    websocketPort: 3003,
    websocketPath: '/cryptpad_websocket',

    blockPath: './block',
    blobPath: './blob',
    dataPath: './data',
    filePath: './datastore',
    logToStdout: true,
    logLevel: 'info',
};