/// <reference types="jest" />
export declare const configureBrowser: (config: any, win?: any) => any;
export declare const mockMatchMedia: (media?: string[]) => jest.Mock<any, any>;
export declare const PlatformConfiguration: {
  AndroidTablet: {
    navigator: {
      userAgent: string;
    };
    innerWidth: number;
    innerHeight: number;
    matchMedia: jest.Mock<any, any>;
  };
  Capacitor: {
    Capacitor: {
      isNative: boolean;
    };
  };
  PWA: {
    navigator: {
      standalone: boolean;
    };
    matchMedia: jest.Mock<any, any>;
  };
  Cordova: {
    cordova: boolean;
  };
  DesktopSafari: {
    navigator: {
      userAgent: string;
    };
    innerWidth: number;
    innerHeight: number;
  };
  iPhone: {
    navigator: {
      userAgent: string;
    };
    innerWidth: number;
    innerHeight: number;
    matchMedia: jest.Mock<any, any>;
  };
  iPadPro: {
    navigator: {
      userAgent: string;
    };
    innerWidth: number;
    innerHeight: number;
    matchMedia: jest.Mock<any, any>;
  };
  Pixel2XL: {
    navigator: {
      userAgent: string;
    };
    innerWidth: number;
    innerHeight: number;
    matchMedia: jest.Mock<any, any>;
  };
  GalaxyView: {
    navigator: {
      userAgent: string;
    };
    innerWidth: number;
    innerHeight: number;
    matchMedia: jest.Mock<any, any>;
  };
  GalaxyS9Plus: {
    navigator: {
      userAgent: string;
    };
    innerWidth: number;
    innerHeight: number;
    matchMedia: jest.Mock<any, any>;
  };
  iPadOS: {
    navigator: {
      userAgent: string;
    };
    innerWidth: number;
    innerHeight: number;
    matchMedia: jest.Mock<any, any>;
  };
};
