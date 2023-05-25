/**
 * @license
 * Copyright Google LLC All Rights Reserved.
 *
 * Use of this source code is governed by an MIT-style license that can be
 * found in the LICENSE file at https://angular.io/license
 */
import { Injectable } from './di';
import { inject } from './di/injector_compatibility';
import { NgZone } from './zone/ng_zone';
import * as i0 from "./r3_symbols";
/**
 * *Internal* service that keeps track of pending tasks happening in the system
 * during the initial rendering. No tasks are tracked after an initial
 * rendering.
 *
 * This information is needed to make sure that the serialization on the server
 * is delayed until all tasks in the queue (such as an initial navigation or a
 * pending HTTP request) are completed.
 */
class InitialRenderPendingTasks {
    get whenAllTasksComplete() {
        if (this.collection.size === 0) {
            this.complete();
        }
        return this.promise;
    }
    constructor() {
        this.taskId = 0;
        this.collection = new Set();
        this.ngZone = inject(NgZone);
        this.completed = false;
        // Run outside of the Angular zone to avoid triggering
        // extra change detection cycles.
        this.ngZone.runOutsideAngular(() => {
            this.promise = new Promise((resolve) => {
                this.resolve = resolve;
            });
        });
    }
    add() {
        if (this.completed) {
            // Indicates that the task was added after
            // the task queue completion, so it's a noop.
            return -1;
        }
        const taskId = this.taskId++;
        this.collection.add(taskId);
        return taskId;
    }
    remove(taskId) {
        if (this.completed)
            return;
        this.collection.delete(taskId);
        if (this.collection.size === 0) {
            this.complete();
        }
    }
    ngOnDestroy() {
        this.complete();
        this.collection.clear();
    }
    complete() {
        this.completed = true;
        this.resolve();
    }
    static { this.ɵfac = function InitialRenderPendingTasks_Factory(t) { return new (t || InitialRenderPendingTasks)(); }; }
    static { this.ɵprov = /*@__PURE__*/ i0.ɵɵdefineInjectable({ token: InitialRenderPendingTasks, factory: InitialRenderPendingTasks.ɵfac, providedIn: 'root' }); }
}
export { InitialRenderPendingTasks };
(function () { (typeof ngDevMode === "undefined" || ngDevMode) && i0.setClassMetadata(InitialRenderPendingTasks, [{
        type: Injectable,
        args: [{ providedIn: 'root' }]
    }], function () { return []; }, null); })();
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoiaW5pdGlhbF9yZW5kZXJfcGVuZGluZ190YXNrcy5qcyIsInNvdXJjZVJvb3QiOiIiLCJzb3VyY2VzIjpbIi4uLy4uLy4uLy4uLy4uLy4uL3BhY2thZ2VzL2NvcmUvc3JjL2luaXRpYWxfcmVuZGVyX3BlbmRpbmdfdGFza3MudHMiXSwibmFtZXMiOltdLCJtYXBwaW5ncyI6IkFBQUE7Ozs7OztHQU1HO0FBRUgsT0FBTyxFQUFDLFVBQVUsRUFBQyxNQUFNLE1BQU0sQ0FBQztBQUNoQyxPQUFPLEVBQUMsTUFBTSxFQUFDLE1BQU0sNkJBQTZCLENBQUM7QUFFbkQsT0FBTyxFQUFDLE1BQU0sRUFBQyxNQUFNLGdCQUFnQixDQUFDOztBQUV0Qzs7Ozs7Ozs7R0FRRztBQUNILE1BQ2EseUJBQXlCO0lBUXBDLElBQUksb0JBQW9CO1FBQ3RCLElBQUksSUFBSSxDQUFDLFVBQVUsQ0FBQyxJQUFJLEtBQUssQ0FBQyxFQUFFO1lBQzlCLElBQUksQ0FBQyxRQUFRLEVBQUUsQ0FBQztTQUNqQjtRQUVELE9BQU8sSUFBSSxDQUFDLE9BQU8sQ0FBQztJQUN0QixDQUFDO0lBSUQ7UUFqQlEsV0FBTSxHQUFHLENBQUMsQ0FBQztRQUNYLGVBQVUsR0FBRyxJQUFJLEdBQUcsRUFBVSxDQUFDO1FBQy9CLFdBQU0sR0FBRyxNQUFNLENBQUMsTUFBTSxDQUFDLENBQUM7UUFhaEMsY0FBUyxHQUFHLEtBQUssQ0FBQztRQUdoQixzREFBc0Q7UUFDdEQsaUNBQWlDO1FBQ2pDLElBQUksQ0FBQyxNQUFNLENBQUMsaUJBQWlCLENBQUMsR0FBRyxFQUFFO1lBQ2pDLElBQUksQ0FBQyxPQUFPLEdBQUcsSUFBSSxPQUFPLENBQU8sQ0FBQyxPQUFPLEVBQUUsRUFBRTtnQkFDM0MsSUFBSSxDQUFDLE9BQU8sR0FBRyxPQUFPLENBQUM7WUFDekIsQ0FBQyxDQUFDLENBQUM7UUFDTCxDQUFDLENBQUMsQ0FBQztJQUNMLENBQUM7SUFFRCxHQUFHO1FBQ0QsSUFBSSxJQUFJLENBQUMsU0FBUyxFQUFFO1lBQ2xCLDBDQUEwQztZQUMxQyw2Q0FBNkM7WUFDN0MsT0FBTyxDQUFDLENBQUMsQ0FBQztTQUNYO1FBQ0QsTUFBTSxNQUFNLEdBQUcsSUFBSSxDQUFDLE1BQU0sRUFBRSxDQUFDO1FBQzdCLElBQUksQ0FBQyxVQUFVLENBQUMsR0FBRyxDQUFDLE1BQU0sQ0FBQyxDQUFDO1FBQzVCLE9BQU8sTUFBTSxDQUFDO0lBQ2hCLENBQUM7SUFFRCxNQUFNLENBQUMsTUFBYztRQUNuQixJQUFJLElBQUksQ0FBQyxTQUFTO1lBQUUsT0FBTztRQUUzQixJQUFJLENBQUMsVUFBVSxDQUFDLE1BQU0sQ0FBQyxNQUFNLENBQUMsQ0FBQztRQUMvQixJQUFJLElBQUksQ0FBQyxVQUFVLENBQUMsSUFBSSxLQUFLLENBQUMsRUFBRTtZQUM5QixJQUFJLENBQUMsUUFBUSxFQUFFLENBQUM7U0FDakI7SUFDSCxDQUFDO0lBRUQsV0FBVztRQUNULElBQUksQ0FBQyxRQUFRLEVBQUUsQ0FBQztRQUNoQixJQUFJLENBQUMsVUFBVSxDQUFDLEtBQUssRUFBRSxDQUFDO0lBQzFCLENBQUM7SUFFTyxRQUFRO1FBQ2QsSUFBSSxDQUFDLFNBQVMsR0FBRyxJQUFJLENBQUM7UUFDdEIsSUFBSSxDQUFDLE9BQU8sRUFBRSxDQUFDO0lBQ2pCLENBQUM7MEZBeERVLHlCQUF5Qjt1RUFBekIseUJBQXlCLFdBQXpCLHlCQUF5QixtQkFEYixNQUFNOztTQUNsQix5QkFBeUI7c0ZBQXpCLHlCQUF5QjtjQURyQyxVQUFVO2VBQUMsRUFBQyxVQUFVLEVBQUUsTUFBTSxFQUFDIiwic291cmNlc0NvbnRlbnQiOlsiLyoqXG4gKiBAbGljZW5zZVxuICogQ29weXJpZ2h0IEdvb2dsZSBMTEMgQWxsIFJpZ2h0cyBSZXNlcnZlZC5cbiAqXG4gKiBVc2Ugb2YgdGhpcyBzb3VyY2UgY29kZSBpcyBnb3Zlcm5lZCBieSBhbiBNSVQtc3R5bGUgbGljZW5zZSB0aGF0IGNhbiBiZVxuICogZm91bmQgaW4gdGhlIExJQ0VOU0UgZmlsZSBhdCBodHRwczovL2FuZ3VsYXIuaW8vbGljZW5zZVxuICovXG5cbmltcG9ydCB7SW5qZWN0YWJsZX0gZnJvbSAnLi9kaSc7XG5pbXBvcnQge2luamVjdH0gZnJvbSAnLi9kaS9pbmplY3Rvcl9jb21wYXRpYmlsaXR5JztcbmltcG9ydCB7T25EZXN0cm95fSBmcm9tICcuL2ludGVyZmFjZS9saWZlY3ljbGVfaG9va3MnO1xuaW1wb3J0IHtOZ1pvbmV9IGZyb20gJy4vem9uZS9uZ196b25lJztcblxuLyoqXG4gKiAqSW50ZXJuYWwqIHNlcnZpY2UgdGhhdCBrZWVwcyB0cmFjayBvZiBwZW5kaW5nIHRhc2tzIGhhcHBlbmluZyBpbiB0aGUgc3lzdGVtXG4gKiBkdXJpbmcgdGhlIGluaXRpYWwgcmVuZGVyaW5nLiBObyB0YXNrcyBhcmUgdHJhY2tlZCBhZnRlciBhbiBpbml0aWFsXG4gKiByZW5kZXJpbmcuXG4gKlxuICogVGhpcyBpbmZvcm1hdGlvbiBpcyBuZWVkZWQgdG8gbWFrZSBzdXJlIHRoYXQgdGhlIHNlcmlhbGl6YXRpb24gb24gdGhlIHNlcnZlclxuICogaXMgZGVsYXllZCB1bnRpbCBhbGwgdGFza3MgaW4gdGhlIHF1ZXVlIChzdWNoIGFzIGFuIGluaXRpYWwgbmF2aWdhdGlvbiBvciBhXG4gKiBwZW5kaW5nIEhUVFAgcmVxdWVzdCkgYXJlIGNvbXBsZXRlZC5cbiAqL1xuQEluamVjdGFibGUoe3Byb3ZpZGVkSW46ICdyb290J30pXG5leHBvcnQgY2xhc3MgSW5pdGlhbFJlbmRlclBlbmRpbmdUYXNrcyBpbXBsZW1lbnRzIE9uRGVzdHJveSB7XG4gIHByaXZhdGUgdGFza0lkID0gMDtcbiAgcHJpdmF0ZSBjb2xsZWN0aW9uID0gbmV3IFNldDxudW1iZXI+KCk7XG4gIHByaXZhdGUgbmdab25lID0gaW5qZWN0KE5nWm9uZSk7XG5cbiAgcHJpdmF0ZSByZXNvbHZlITogVm9pZEZ1bmN0aW9uO1xuICBwcml2YXRlIHByb21pc2UhOiBQcm9taXNlPHZvaWQ+O1xuXG4gIGdldCB3aGVuQWxsVGFza3NDb21wbGV0ZSgpOiBQcm9taXNlPHZvaWQ+IHtcbiAgICBpZiAodGhpcy5jb2xsZWN0aW9uLnNpemUgPT09IDApIHtcbiAgICAgIHRoaXMuY29tcGxldGUoKTtcbiAgICB9XG5cbiAgICByZXR1cm4gdGhpcy5wcm9taXNlO1xuICB9XG5cbiAgY29tcGxldGVkID0gZmFsc2U7XG5cbiAgY29uc3RydWN0b3IoKSB7XG4gICAgLy8gUnVuIG91dHNpZGUgb2YgdGhlIEFuZ3VsYXIgem9uZSB0byBhdm9pZCB0cmlnZ2VyaW5nXG4gICAgLy8gZXh0cmEgY2hhbmdlIGRldGVjdGlvbiBjeWNsZXMuXG4gICAgdGhpcy5uZ1pvbmUucnVuT3V0c2lkZUFuZ3VsYXIoKCkgPT4ge1xuICAgICAgdGhpcy5wcm9taXNlID0gbmV3IFByb21pc2U8dm9pZD4oKHJlc29sdmUpID0+IHtcbiAgICAgICAgdGhpcy5yZXNvbHZlID0gcmVzb2x2ZTtcbiAgICAgIH0pO1xuICAgIH0pO1xuICB9XG5cbiAgYWRkKCk6IG51bWJlciB7XG4gICAgaWYgKHRoaXMuY29tcGxldGVkKSB7XG4gICAgICAvLyBJbmRpY2F0ZXMgdGhhdCB0aGUgdGFzayB3YXMgYWRkZWQgYWZ0ZXJcbiAgICAgIC8vIHRoZSB0YXNrIHF1ZXVlIGNvbXBsZXRpb24sIHNvIGl0J3MgYSBub29wLlxuICAgICAgcmV0dXJuIC0xO1xuICAgIH1cbiAgICBjb25zdCB0YXNrSWQgPSB0aGlzLnRhc2tJZCsrO1xuICAgIHRoaXMuY29sbGVjdGlvbi5hZGQodGFza0lkKTtcbiAgICByZXR1cm4gdGFza0lkO1xuICB9XG5cbiAgcmVtb3ZlKHRhc2tJZDogbnVtYmVyKSB7XG4gICAgaWYgKHRoaXMuY29tcGxldGVkKSByZXR1cm47XG5cbiAgICB0aGlzLmNvbGxlY3Rpb24uZGVsZXRlKHRhc2tJZCk7XG4gICAgaWYgKHRoaXMuY29sbGVjdGlvbi5zaXplID09PSAwKSB7XG4gICAgICB0aGlzLmNvbXBsZXRlKCk7XG4gICAgfVxuICB9XG5cbiAgbmdPbkRlc3Ryb3koKSB7XG4gICAgdGhpcy5jb21wbGV0ZSgpO1xuICAgIHRoaXMuY29sbGVjdGlvbi5jbGVhcigpO1xuICB9XG5cbiAgcHJpdmF0ZSBjb21wbGV0ZSgpOiB2b2lkIHtcbiAgICB0aGlzLmNvbXBsZXRlZCA9IHRydWU7XG4gICAgdGhpcy5yZXNvbHZlKCk7XG4gIH1cbn1cbiJdfQ==