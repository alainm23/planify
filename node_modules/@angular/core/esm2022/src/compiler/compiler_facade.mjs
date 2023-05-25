/**
 * @license
 * Copyright Google LLC All Rights Reserved.
 *
 * Use of this source code is governed by an MIT-style license that can be
 * found in the LICENSE file at https://angular.io/license
 */
import { global } from '../util/global';
export * from './compiler_facade_interface';
export function getCompilerFacade(request) {
    const globalNg = global['ng'];
    if (globalNg && globalNg.ɵcompilerFacade) {
        return globalNg.ɵcompilerFacade;
    }
    if (typeof ngDevMode === 'undefined' || ngDevMode) {
        // Log the type as an error so that a developer can easily navigate to the type from the
        // console.
        console.error(`JIT compilation failed for ${request.kind}`, request.type);
        let message = `The ${request.kind} '${request
            .type.name}' needs to be compiled using the JIT compiler, but '@angular/compiler' is not available.\n\n`;
        if (request.usage === 1 /* JitCompilerUsage.PartialDeclaration */) {
            message += `The ${request.kind} is part of a library that has been partially compiled.\n`;
            message +=
                `However, the Angular Linker has not processed the library such that JIT compilation is used as fallback.\n`;
            message += '\n';
            message +=
                `Ideally, the library is processed using the Angular Linker to become fully AOT compiled.\n`;
        }
        else {
            message +=
                `JIT compilation is discouraged for production use-cases! Consider using AOT mode instead.\n`;
        }
        message +=
            `Alternatively, the JIT compiler should be loaded by bootstrapping using '@angular/platform-browser-dynamic' or '@angular/platform-server',\n`;
        message +=
            `or manually provide the compiler with 'import "@angular/compiler";' before bootstrapping.`;
        throw new Error(message);
    }
    else {
        throw new Error('JIT compiler unavailable');
    }
}
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoiY29tcGlsZXJfZmFjYWRlLmpzIiwic291cmNlUm9vdCI6IiIsInNvdXJjZXMiOlsiLi4vLi4vLi4vLi4vLi4vLi4vLi4vcGFja2FnZXMvY29yZS9zcmMvY29tcGlsZXIvY29tcGlsZXJfZmFjYWRlLnRzIl0sIm5hbWVzIjpbXSwibWFwcGluZ3MiOiJBQUFBOzs7Ozs7R0FNRztBQUNILE9BQU8sRUFBQyxNQUFNLEVBQUMsTUFBTSxnQkFBZ0IsQ0FBQztBQUV0QyxjQUFjLDZCQUE2QixDQUFDO0FBYTVDLE1BQU0sVUFBVSxpQkFBaUIsQ0FBQyxPQUFnQztJQUNoRSxNQUFNLFFBQVEsR0FBMkIsTUFBTSxDQUFDLElBQUksQ0FBQyxDQUFDO0lBQ3RELElBQUksUUFBUSxJQUFJLFFBQVEsQ0FBQyxlQUFlLEVBQUU7UUFDeEMsT0FBTyxRQUFRLENBQUMsZUFBZSxDQUFDO0tBQ2pDO0lBRUQsSUFBSSxPQUFPLFNBQVMsS0FBSyxXQUFXLElBQUksU0FBUyxFQUFFO1FBQ2pELHdGQUF3RjtRQUN4RixXQUFXO1FBQ1gsT0FBTyxDQUFDLEtBQUssQ0FBQyw4QkFBOEIsT0FBTyxDQUFDLElBQUksRUFBRSxFQUFFLE9BQU8sQ0FBQyxJQUFJLENBQUMsQ0FBQztRQUUxRSxJQUFJLE9BQU8sR0FBRyxPQUFPLE9BQU8sQ0FBQyxJQUFJLEtBQzdCLE9BQU87YUFDRixJQUFJLENBQUMsSUFBSSw4RkFBOEYsQ0FBQztRQUNqSCxJQUFJLE9BQU8sQ0FBQyxLQUFLLGdEQUF3QyxFQUFFO1lBQ3pELE9BQU8sSUFBSSxPQUFPLE9BQU8sQ0FBQyxJQUFJLDJEQUEyRCxDQUFDO1lBQzFGLE9BQU87Z0JBQ0gsNEdBQTRHLENBQUM7WUFDakgsT0FBTyxJQUFJLElBQUksQ0FBQztZQUNoQixPQUFPO2dCQUNILDRGQUE0RixDQUFDO1NBQ2xHO2FBQU07WUFDTCxPQUFPO2dCQUNILDZGQUE2RixDQUFDO1NBQ25HO1FBQ0QsT0FBTztZQUNILDhJQUE4SSxDQUFDO1FBQ25KLE9BQU87WUFDSCwyRkFBMkYsQ0FBQztRQUNoRyxNQUFNLElBQUksS0FBSyxDQUFDLE9BQU8sQ0FBQyxDQUFDO0tBQzFCO1NBQU07UUFDTCxNQUFNLElBQUksS0FBSyxDQUFDLDBCQUEwQixDQUFDLENBQUM7S0FDN0M7QUFDSCxDQUFDIiwic291cmNlc0NvbnRlbnQiOlsiLyoqXG4gKiBAbGljZW5zZVxuICogQ29weXJpZ2h0IEdvb2dsZSBMTEMgQWxsIFJpZ2h0cyBSZXNlcnZlZC5cbiAqXG4gKiBVc2Ugb2YgdGhpcyBzb3VyY2UgY29kZSBpcyBnb3Zlcm5lZCBieSBhbiBNSVQtc3R5bGUgbGljZW5zZSB0aGF0IGNhbiBiZVxuICogZm91bmQgaW4gdGhlIExJQ0VOU0UgZmlsZSBhdCBodHRwczovL2FuZ3VsYXIuaW8vbGljZW5zZVxuICovXG5pbXBvcnQge2dsb2JhbH0gZnJvbSAnLi4vdXRpbC9nbG9iYWwnO1xuaW1wb3J0IHtDb21waWxlckZhY2FkZSwgRXhwb3J0ZWRDb21waWxlckZhY2FkZSwgVHlwZX0gZnJvbSAnLi9jb21waWxlcl9mYWNhZGVfaW50ZXJmYWNlJztcbmV4cG9ydCAqIGZyb20gJy4vY29tcGlsZXJfZmFjYWRlX2ludGVyZmFjZSc7XG5cbmV4cG9ydCBjb25zdCBlbnVtIEppdENvbXBpbGVyVXNhZ2Uge1xuICBEZWNvcmF0b3IsXG4gIFBhcnRpYWxEZWNsYXJhdGlvbixcbn1cblxuaW50ZXJmYWNlIEppdENvbXBpbGVyVXNhZ2VSZXF1ZXN0IHtcbiAgdXNhZ2U6IEppdENvbXBpbGVyVXNhZ2U7XG4gIGtpbmQ6ICdkaXJlY3RpdmUnfCdjb21wb25lbnQnfCdwaXBlJ3wnaW5qZWN0YWJsZSd8J05nTW9kdWxlJztcbiAgdHlwZTogVHlwZTtcbn1cblxuZXhwb3J0IGZ1bmN0aW9uIGdldENvbXBpbGVyRmFjYWRlKHJlcXVlc3Q6IEppdENvbXBpbGVyVXNhZ2VSZXF1ZXN0KTogQ29tcGlsZXJGYWNhZGUge1xuICBjb25zdCBnbG9iYWxOZzogRXhwb3J0ZWRDb21waWxlckZhY2FkZSA9IGdsb2JhbFsnbmcnXTtcbiAgaWYgKGdsb2JhbE5nICYmIGdsb2JhbE5nLsm1Y29tcGlsZXJGYWNhZGUpIHtcbiAgICByZXR1cm4gZ2xvYmFsTmcuybVjb21waWxlckZhY2FkZTtcbiAgfVxuXG4gIGlmICh0eXBlb2YgbmdEZXZNb2RlID09PSAndW5kZWZpbmVkJyB8fCBuZ0Rldk1vZGUpIHtcbiAgICAvLyBMb2cgdGhlIHR5cGUgYXMgYW4gZXJyb3Igc28gdGhhdCBhIGRldmVsb3BlciBjYW4gZWFzaWx5IG5hdmlnYXRlIHRvIHRoZSB0eXBlIGZyb20gdGhlXG4gICAgLy8gY29uc29sZS5cbiAgICBjb25zb2xlLmVycm9yKGBKSVQgY29tcGlsYXRpb24gZmFpbGVkIGZvciAke3JlcXVlc3Qua2luZH1gLCByZXF1ZXN0LnR5cGUpO1xuXG4gICAgbGV0IG1lc3NhZ2UgPSBgVGhlICR7cmVxdWVzdC5raW5kfSAnJHtcbiAgICAgICAgcmVxdWVzdFxuICAgICAgICAgICAgLnR5cGUubmFtZX0nIG5lZWRzIHRvIGJlIGNvbXBpbGVkIHVzaW5nIHRoZSBKSVQgY29tcGlsZXIsIGJ1dCAnQGFuZ3VsYXIvY29tcGlsZXInIGlzIG5vdCBhdmFpbGFibGUuXFxuXFxuYDtcbiAgICBpZiAocmVxdWVzdC51c2FnZSA9PT0gSml0Q29tcGlsZXJVc2FnZS5QYXJ0aWFsRGVjbGFyYXRpb24pIHtcbiAgICAgIG1lc3NhZ2UgKz0gYFRoZSAke3JlcXVlc3Qua2luZH0gaXMgcGFydCBvZiBhIGxpYnJhcnkgdGhhdCBoYXMgYmVlbiBwYXJ0aWFsbHkgY29tcGlsZWQuXFxuYDtcbiAgICAgIG1lc3NhZ2UgKz1cbiAgICAgICAgICBgSG93ZXZlciwgdGhlIEFuZ3VsYXIgTGlua2VyIGhhcyBub3QgcHJvY2Vzc2VkIHRoZSBsaWJyYXJ5IHN1Y2ggdGhhdCBKSVQgY29tcGlsYXRpb24gaXMgdXNlZCBhcyBmYWxsYmFjay5cXG5gO1xuICAgICAgbWVzc2FnZSArPSAnXFxuJztcbiAgICAgIG1lc3NhZ2UgKz1cbiAgICAgICAgICBgSWRlYWxseSwgdGhlIGxpYnJhcnkgaXMgcHJvY2Vzc2VkIHVzaW5nIHRoZSBBbmd1bGFyIExpbmtlciB0byBiZWNvbWUgZnVsbHkgQU9UIGNvbXBpbGVkLlxcbmA7XG4gICAgfSBlbHNlIHtcbiAgICAgIG1lc3NhZ2UgKz1cbiAgICAgICAgICBgSklUIGNvbXBpbGF0aW9uIGlzIGRpc2NvdXJhZ2VkIGZvciBwcm9kdWN0aW9uIHVzZS1jYXNlcyEgQ29uc2lkZXIgdXNpbmcgQU9UIG1vZGUgaW5zdGVhZC5cXG5gO1xuICAgIH1cbiAgICBtZXNzYWdlICs9XG4gICAgICAgIGBBbHRlcm5hdGl2ZWx5LCB0aGUgSklUIGNvbXBpbGVyIHNob3VsZCBiZSBsb2FkZWQgYnkgYm9vdHN0cmFwcGluZyB1c2luZyAnQGFuZ3VsYXIvcGxhdGZvcm0tYnJvd3Nlci1keW5hbWljJyBvciAnQGFuZ3VsYXIvcGxhdGZvcm0tc2VydmVyJyxcXG5gO1xuICAgIG1lc3NhZ2UgKz1cbiAgICAgICAgYG9yIG1hbnVhbGx5IHByb3ZpZGUgdGhlIGNvbXBpbGVyIHdpdGggJ2ltcG9ydCBcIkBhbmd1bGFyL2NvbXBpbGVyXCI7JyBiZWZvcmUgYm9vdHN0cmFwcGluZy5gO1xuICAgIHRocm93IG5ldyBFcnJvcihtZXNzYWdlKTtcbiAgfSBlbHNlIHtcbiAgICB0aHJvdyBuZXcgRXJyb3IoJ0pJVCBjb21waWxlciB1bmF2YWlsYWJsZScpO1xuICB9XG59XG4iXX0=