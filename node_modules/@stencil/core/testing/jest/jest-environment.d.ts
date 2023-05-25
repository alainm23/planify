import type { JestEnvironmentGlobal } from '@stencil/core/internal';
export declare function createJestPuppeteerEnvironment(): {
    new (config: any): {
        [x: string]: any;
        global: JestEnvironmentGlobal;
        browser: any;
        pages: any[];
        setup(): Promise<void>;
        newPuppeteerPage(): Promise<import("puppeteer").Page>;
        closeOpenPages(): Promise<void>;
        teardown(): Promise<void>;
        getVmContext(): any;
    };
    [x: string]: any;
};
