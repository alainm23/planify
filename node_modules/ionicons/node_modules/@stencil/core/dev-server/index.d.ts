import type { CompilerWatcher, DevServer, Logger, StencilDevServerConfig } from '../internal/index';
export declare function start(stencilDevServerConfig: StencilDevServerConfig, logger: Logger, watcher?: CompilerWatcher): Promise<DevServer>;
export { DevServer, StencilDevServerConfig as DevServerConfig, Logger };
