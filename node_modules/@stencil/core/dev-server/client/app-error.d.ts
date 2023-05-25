interface AppErrorData {
    window: Window;
    buildResults: any;
    openInEditor?: OpenInEditorCallback;
}
type OpenInEditorCallback = (data: {
    file: string;
    line: number;
    column: number;
}) => void;
export declare const appError: (data: AppErrorData) => {
    diagnostics: any[];
    status: string;
};
export declare const clearAppErrorModal: (data: {
    window: Window;
}) => void;
export {};
