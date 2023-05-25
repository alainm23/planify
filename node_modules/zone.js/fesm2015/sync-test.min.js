"use strict";
/**
 * @license Angular v<unknown>
 * (c) 2010-2022 Google LLC. https://angular.io/
 * License: MIT
 */class SyncTestZoneSpec{constructor(e){this.runZone=Zone.current,this.name="syncTestZone for "+e}onScheduleTask(e,s,n,c){switch(c.type){case"microTask":case"macroTask":throw new Error(`Cannot call ${c.source} from within a sync test (${this.name}).`);case"eventTask":c=e.scheduleTask(n,c)}return c}}Zone.SyncTestZoneSpec=SyncTestZoneSpec;