interface StyleOptions {
  style: Style;
}
export declare enum Style {
  Dark = "DARK",
  Light = "LIGHT",
  Default = "DEFAULT"
}
export declare const StatusBar: {
  getEngine(): any;
  supportsDefaultStatusBarStyle(): boolean;
  setStyle(options: StyleOptions): void;
  getStyle: () => Promise<Style>;
};
export {};
