/**
 * @license
 * Copyright Google LLC All Rights Reserved.
 *
 * Use of this source code is governed by an MIT-style license that can be
 * found in the LICENSE file at https://angular.io/license
 */
import { assertGreaterThan } from '../../util/assert';
import { assertIndexInDeclRange } from '../assert';
import { executeCheckHooks, executeInitAndCheckHooks } from '../hooks';
import { FLAGS } from '../interfaces/view';
import { getLView, getSelectedIndex, getTView, isInCheckNoChangesMode, setSelectedIndex } from '../state';
/**
 * Advances to an element for later binding instructions.
 *
 * Used in conjunction with instructions like {@link property} to act on elements with specified
 * indices, for example those created with {@link element} or {@link elementStart}.
 *
 * ```ts
 * (rf: RenderFlags, ctx: any) => {
 *   if (rf & 1) {
 *     text(0, 'Hello');
 *     text(1, 'Goodbye')
 *     element(2, 'div');
 *   }
 *   if (rf & 2) {
 *     advance(2); // Advance twice to the <div>.
 *     property('title', 'test');
 *   }
 *  }
 * ```
 * @param delta Number of elements to advance forwards by.
 *
 * @codeGenApi
 */
export function ɵɵadvance(delta) {
    ngDevMode && assertGreaterThan(delta, 0, 'Can only advance forward');
    selectIndexInternal(getTView(), getLView(), getSelectedIndex() + delta, !!ngDevMode && isInCheckNoChangesMode());
}
export function selectIndexInternal(tView, lView, index, checkNoChangesMode) {
    ngDevMode && assertIndexInDeclRange(lView, index);
    // Flush the initial hooks for elements in the view that have been added up to this point.
    // PERF WARNING: do NOT extract this to a separate function without running benchmarks
    if (!checkNoChangesMode) {
        const hooksInitPhaseCompleted = (lView[FLAGS] & 3 /* LViewFlags.InitPhaseStateMask */) === 3 /* InitPhaseState.InitPhaseCompleted */;
        if (hooksInitPhaseCompleted) {
            const preOrderCheckHooks = tView.preOrderCheckHooks;
            if (preOrderCheckHooks !== null) {
                executeCheckHooks(lView, preOrderCheckHooks, index);
            }
        }
        else {
            const preOrderHooks = tView.preOrderHooks;
            if (preOrderHooks !== null) {
                executeInitAndCheckHooks(lView, preOrderHooks, 0 /* InitPhaseState.OnInitHooksToBeRun */, index);
            }
        }
    }
    // We must set the selected index *after* running the hooks, because hooks may have side-effects
    // that cause other template functions to run, thus updating the selected index, which is global
    // state. If we run `setSelectedIndex` *before* we run the hooks, in some cases the selected index
    // will be altered by the time we leave the `ɵɵadvance` instruction.
    setSelectedIndex(index);
}
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoiYWR2YW5jZS5qcyIsInNvdXJjZVJvb3QiOiIiLCJzb3VyY2VzIjpbIi4uLy4uLy4uLy4uLy4uLy4uLy4uLy4uL3BhY2thZ2VzL2NvcmUvc3JjL3JlbmRlcjMvaW5zdHJ1Y3Rpb25zL2FkdmFuY2UudHMiXSwibmFtZXMiOltdLCJtYXBwaW5ncyI6IkFBQUE7Ozs7OztHQU1HO0FBQ0gsT0FBTyxFQUFDLGlCQUFpQixFQUFDLE1BQU0sbUJBQW1CLENBQUM7QUFDcEQsT0FBTyxFQUFDLHNCQUFzQixFQUFDLE1BQU0sV0FBVyxDQUFDO0FBQ2pELE9BQU8sRUFBQyxpQkFBaUIsRUFBRSx3QkFBd0IsRUFBQyxNQUFNLFVBQVUsQ0FBQztBQUNyRSxPQUFPLEVBQUMsS0FBSyxFQUEyQyxNQUFNLG9CQUFvQixDQUFDO0FBQ25GLE9BQU8sRUFBQyxRQUFRLEVBQUUsZ0JBQWdCLEVBQUUsUUFBUSxFQUFFLHNCQUFzQixFQUFFLGdCQUFnQixFQUFDLE1BQU0sVUFBVSxDQUFDO0FBR3hHOzs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7O0dBc0JHO0FBQ0gsTUFBTSxVQUFVLFNBQVMsQ0FBQyxLQUFhO0lBQ3JDLFNBQVMsSUFBSSxpQkFBaUIsQ0FBQyxLQUFLLEVBQUUsQ0FBQyxFQUFFLDBCQUEwQixDQUFDLENBQUM7SUFDckUsbUJBQW1CLENBQ2YsUUFBUSxFQUFFLEVBQUUsUUFBUSxFQUFFLEVBQUUsZ0JBQWdCLEVBQUUsR0FBRyxLQUFLLEVBQUUsQ0FBQyxDQUFDLFNBQVMsSUFBSSxzQkFBc0IsRUFBRSxDQUFDLENBQUM7QUFDbkcsQ0FBQztBQUVELE1BQU0sVUFBVSxtQkFBbUIsQ0FDL0IsS0FBWSxFQUFFLEtBQVksRUFBRSxLQUFhLEVBQUUsa0JBQTJCO0lBQ3hFLFNBQVMsSUFBSSxzQkFBc0IsQ0FBQyxLQUFLLEVBQUUsS0FBSyxDQUFDLENBQUM7SUFFbEQsMEZBQTBGO0lBQzFGLHNGQUFzRjtJQUN0RixJQUFJLENBQUMsa0JBQWtCLEVBQUU7UUFDdkIsTUFBTSx1QkFBdUIsR0FDekIsQ0FBQyxLQUFLLENBQUMsS0FBSyxDQUFDLHdDQUFnQyxDQUFDLDhDQUFzQyxDQUFDO1FBQ3pGLElBQUksdUJBQXVCLEVBQUU7WUFDM0IsTUFBTSxrQkFBa0IsR0FBRyxLQUFLLENBQUMsa0JBQWtCLENBQUM7WUFDcEQsSUFBSSxrQkFBa0IsS0FBSyxJQUFJLEVBQUU7Z0JBQy9CLGlCQUFpQixDQUFDLEtBQUssRUFBRSxrQkFBa0IsRUFBRSxLQUFLLENBQUMsQ0FBQzthQUNyRDtTQUNGO2FBQU07WUFDTCxNQUFNLGFBQWEsR0FBRyxLQUFLLENBQUMsYUFBYSxDQUFDO1lBQzFDLElBQUksYUFBYSxLQUFLLElBQUksRUFBRTtnQkFDMUIsd0JBQXdCLENBQUMsS0FBSyxFQUFFLGFBQWEsNkNBQXFDLEtBQUssQ0FBQyxDQUFDO2FBQzFGO1NBQ0Y7S0FDRjtJQUVELGdHQUFnRztJQUNoRyxnR0FBZ0c7SUFDaEcsa0dBQWtHO0lBQ2xHLG9FQUFvRTtJQUNwRSxnQkFBZ0IsQ0FBQyxLQUFLLENBQUMsQ0FBQztBQUMxQixDQUFDIiwic291cmNlc0NvbnRlbnQiOlsiLyoqXG4gKiBAbGljZW5zZVxuICogQ29weXJpZ2h0IEdvb2dsZSBMTEMgQWxsIFJpZ2h0cyBSZXNlcnZlZC5cbiAqXG4gKiBVc2Ugb2YgdGhpcyBzb3VyY2UgY29kZSBpcyBnb3Zlcm5lZCBieSBhbiBNSVQtc3R5bGUgbGljZW5zZSB0aGF0IGNhbiBiZVxuICogZm91bmQgaW4gdGhlIExJQ0VOU0UgZmlsZSBhdCBodHRwczovL2FuZ3VsYXIuaW8vbGljZW5zZVxuICovXG5pbXBvcnQge2Fzc2VydEdyZWF0ZXJUaGFufSBmcm9tICcuLi8uLi91dGlsL2Fzc2VydCc7XG5pbXBvcnQge2Fzc2VydEluZGV4SW5EZWNsUmFuZ2V9IGZyb20gJy4uL2Fzc2VydCc7XG5pbXBvcnQge2V4ZWN1dGVDaGVja0hvb2tzLCBleGVjdXRlSW5pdEFuZENoZWNrSG9va3N9IGZyb20gJy4uL2hvb2tzJztcbmltcG9ydCB7RkxBR1MsIEluaXRQaGFzZVN0YXRlLCBMVmlldywgTFZpZXdGbGFncywgVFZpZXd9IGZyb20gJy4uL2ludGVyZmFjZXMvdmlldyc7XG5pbXBvcnQge2dldExWaWV3LCBnZXRTZWxlY3RlZEluZGV4LCBnZXRUVmlldywgaXNJbkNoZWNrTm9DaGFuZ2VzTW9kZSwgc2V0U2VsZWN0ZWRJbmRleH0gZnJvbSAnLi4vc3RhdGUnO1xuXG5cbi8qKlxuICogQWR2YW5jZXMgdG8gYW4gZWxlbWVudCBmb3IgbGF0ZXIgYmluZGluZyBpbnN0cnVjdGlvbnMuXG4gKlxuICogVXNlZCBpbiBjb25qdW5jdGlvbiB3aXRoIGluc3RydWN0aW9ucyBsaWtlIHtAbGluayBwcm9wZXJ0eX0gdG8gYWN0IG9uIGVsZW1lbnRzIHdpdGggc3BlY2lmaWVkXG4gKiBpbmRpY2VzLCBmb3IgZXhhbXBsZSB0aG9zZSBjcmVhdGVkIHdpdGgge0BsaW5rIGVsZW1lbnR9IG9yIHtAbGluayBlbGVtZW50U3RhcnR9LlxuICpcbiAqIGBgYHRzXG4gKiAocmY6IFJlbmRlckZsYWdzLCBjdHg6IGFueSkgPT4ge1xuICogICBpZiAocmYgJiAxKSB7XG4gKiAgICAgdGV4dCgwLCAnSGVsbG8nKTtcbiAqICAgICB0ZXh0KDEsICdHb29kYnllJylcbiAqICAgICBlbGVtZW50KDIsICdkaXYnKTtcbiAqICAgfVxuICogICBpZiAocmYgJiAyKSB7XG4gKiAgICAgYWR2YW5jZSgyKTsgLy8gQWR2YW5jZSB0d2ljZSB0byB0aGUgPGRpdj4uXG4gKiAgICAgcHJvcGVydHkoJ3RpdGxlJywgJ3Rlc3QnKTtcbiAqICAgfVxuICogIH1cbiAqIGBgYFxuICogQHBhcmFtIGRlbHRhIE51bWJlciBvZiBlbGVtZW50cyB0byBhZHZhbmNlIGZvcndhcmRzIGJ5LlxuICpcbiAqIEBjb2RlR2VuQXBpXG4gKi9cbmV4cG9ydCBmdW5jdGlvbiDJtcm1YWR2YW5jZShkZWx0YTogbnVtYmVyKTogdm9pZCB7XG4gIG5nRGV2TW9kZSAmJiBhc3NlcnRHcmVhdGVyVGhhbihkZWx0YSwgMCwgJ0NhbiBvbmx5IGFkdmFuY2UgZm9yd2FyZCcpO1xuICBzZWxlY3RJbmRleEludGVybmFsKFxuICAgICAgZ2V0VFZpZXcoKSwgZ2V0TFZpZXcoKSwgZ2V0U2VsZWN0ZWRJbmRleCgpICsgZGVsdGEsICEhbmdEZXZNb2RlICYmIGlzSW5DaGVja05vQ2hhbmdlc01vZGUoKSk7XG59XG5cbmV4cG9ydCBmdW5jdGlvbiBzZWxlY3RJbmRleEludGVybmFsKFxuICAgIHRWaWV3OiBUVmlldywgbFZpZXc6IExWaWV3LCBpbmRleDogbnVtYmVyLCBjaGVja05vQ2hhbmdlc01vZGU6IGJvb2xlYW4pIHtcbiAgbmdEZXZNb2RlICYmIGFzc2VydEluZGV4SW5EZWNsUmFuZ2UobFZpZXcsIGluZGV4KTtcblxuICAvLyBGbHVzaCB0aGUgaW5pdGlhbCBob29rcyBmb3IgZWxlbWVudHMgaW4gdGhlIHZpZXcgdGhhdCBoYXZlIGJlZW4gYWRkZWQgdXAgdG8gdGhpcyBwb2ludC5cbiAgLy8gUEVSRiBXQVJOSU5HOiBkbyBOT1QgZXh0cmFjdCB0aGlzIHRvIGEgc2VwYXJhdGUgZnVuY3Rpb24gd2l0aG91dCBydW5uaW5nIGJlbmNobWFya3NcbiAgaWYgKCFjaGVja05vQ2hhbmdlc01vZGUpIHtcbiAgICBjb25zdCBob29rc0luaXRQaGFzZUNvbXBsZXRlZCA9XG4gICAgICAgIChsVmlld1tGTEFHU10gJiBMVmlld0ZsYWdzLkluaXRQaGFzZVN0YXRlTWFzaykgPT09IEluaXRQaGFzZVN0YXRlLkluaXRQaGFzZUNvbXBsZXRlZDtcbiAgICBpZiAoaG9va3NJbml0UGhhc2VDb21wbGV0ZWQpIHtcbiAgICAgIGNvbnN0IHByZU9yZGVyQ2hlY2tIb29rcyA9IHRWaWV3LnByZU9yZGVyQ2hlY2tIb29rcztcbiAgICAgIGlmIChwcmVPcmRlckNoZWNrSG9va3MgIT09IG51bGwpIHtcbiAgICAgICAgZXhlY3V0ZUNoZWNrSG9va3MobFZpZXcsIHByZU9yZGVyQ2hlY2tIb29rcywgaW5kZXgpO1xuICAgICAgfVxuICAgIH0gZWxzZSB7XG4gICAgICBjb25zdCBwcmVPcmRlckhvb2tzID0gdFZpZXcucHJlT3JkZXJIb29rcztcbiAgICAgIGlmIChwcmVPcmRlckhvb2tzICE9PSBudWxsKSB7XG4gICAgICAgIGV4ZWN1dGVJbml0QW5kQ2hlY2tIb29rcyhsVmlldywgcHJlT3JkZXJIb29rcywgSW5pdFBoYXNlU3RhdGUuT25Jbml0SG9va3NUb0JlUnVuLCBpbmRleCk7XG4gICAgICB9XG4gICAgfVxuICB9XG5cbiAgLy8gV2UgbXVzdCBzZXQgdGhlIHNlbGVjdGVkIGluZGV4ICphZnRlciogcnVubmluZyB0aGUgaG9va3MsIGJlY2F1c2UgaG9va3MgbWF5IGhhdmUgc2lkZS1lZmZlY3RzXG4gIC8vIHRoYXQgY2F1c2Ugb3RoZXIgdGVtcGxhdGUgZnVuY3Rpb25zIHRvIHJ1biwgdGh1cyB1cGRhdGluZyB0aGUgc2VsZWN0ZWQgaW5kZXgsIHdoaWNoIGlzIGdsb2JhbFxuICAvLyBzdGF0ZS4gSWYgd2UgcnVuIGBzZXRTZWxlY3RlZEluZGV4YCAqYmVmb3JlKiB3ZSBydW4gdGhlIGhvb2tzLCBpbiBzb21lIGNhc2VzIHRoZSBzZWxlY3RlZCBpbmRleFxuICAvLyB3aWxsIGJlIGFsdGVyZWQgYnkgdGhlIHRpbWUgd2UgbGVhdmUgdGhlIGDJtcm1YWR2YW5jZWAgaW5zdHJ1Y3Rpb24uXG4gIHNldFNlbGVjdGVkSW5kZXgoaW5kZXgpO1xufVxuIl19