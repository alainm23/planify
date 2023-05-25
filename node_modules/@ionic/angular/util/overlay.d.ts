interface ControllerShape<Opts, HTMLElm> {
    create(options: Opts): Promise<HTMLElm>;
    dismiss(data?: any, role?: string, id?: string): Promise<boolean>;
    getTop(): Promise<HTMLElm | undefined>;
}
export declare class OverlayBaseController<Opts, Overlay> implements ControllerShape<Opts, Overlay> {
    private ctrl;
    constructor(ctrl: ControllerShape<Opts, Overlay>);
    /**
     * Creates a new overlay
     */
    create(opts?: Opts): Promise<Overlay>;
    /**
     * When `id` is not provided, it dismisses the top overlay.
     */
    dismiss(data?: any, role?: string, id?: string): Promise<boolean>;
    /**
     * Returns the top overlay.
     */
    getTop(): Promise<Overlay | undefined>;
}
export {};
