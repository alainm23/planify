export declare const proxyInputs: (Cmp: any, inputs: string[]) => void;
export declare const proxyMethods: (Cmp: any, methods: string[]) => void;
export declare const proxyOutputs: (instance: any, el: any, events: string[]) => void;
export declare const defineCustomElement: (tagName: string, customElement: any) => void;
export declare function ProxyCmp(opts: {
    defineCustomElementFn?: () => void;
    inputs?: any;
    methods?: any;
}): (cls: any) => any;
