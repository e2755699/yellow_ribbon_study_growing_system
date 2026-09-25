const {before, after, beforeEach, test} = require('node:test');
const {readFileSync} = require('node:fs');
const {initializeTestEnvironment, assertSucceeds, assertFails} = require('@firebase/rules-unit-testing');
const {doc, setDoc, getDoc, deleteDoc, serverTimestamp} = require('firebase/firestore');
let env;
before(async () => { env = await initializeTestEnvironment({projectId: 'demo-yellow-ribbon-theme', firestore: {host: '127.0.0.1', port: 8189, rules: readFileSync('../firestore.rules', 'utf8')}}); });
after(async () => { await env?.cleanup(); });
beforeEach(async () => { await env.clearFirestore(); });
const path = 'design_systems/yellow_ribbon/themes/caramel';
function payload() {
  const colors = Object.fromEntries(['primary','onPrimary','detail','secondary','tertiary','alternate','primaryText','secondaryText','primaryBackground','secondaryBackground','border','accent1','accent2','accent3','accent4','success','error','warning','info'].map(k => [k, '#C86B3C']));
  return {schemaVersion: 1, name: '焦糖橘棕', revision: 1, light: colors, dark: colors,
    metrics: {headingSize:32,titleSize:24,bodySize:16,labelSize:14,buttonSize:24,spaceSmall:8,spaceMedium:16,spaceLarge:32,radiusSmall:16,radiusMedium:24,hoverDarken:0.08,pressedDarken:0.12},
    updatedBy: 'admin', updatedAt: serverTimestamp()};
}
const admin = () => env.authenticatedContext('admin', {designSystemAdmin:true}).firestore();
test('trusted claim can create and advance revision; stale revision/delete denied', async () => {
  const ref = doc(admin(), path);
  await assertSucceeds(setDoc(ref, payload()));
  await assertFails(setDoc(ref, payload()));
  await assertSucceeds(setDoc(ref, {...payload(), revision:2}));
  await assertFails(deleteDoc(ref));
});
test('authenticated read; anonymous read/write and normal user publish denied', async () => {
  await assertSucceeds(setDoc(doc(admin(), path), payload()));
  await assertSucceeds(getDoc(doc(env.authenticatedContext('student').firestore(), path)));
  await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(), path)));
  await assertFails(setDoc(doc(env.authenticatedContext('student').firestore(), path), {...payload(), revision:2, updatedBy:'student'}));
  await assertFails(setDoc(doc(env.unauthenticatedContext().firestore(), path), payload()));
});
test('self-writable user role does not grant theme permission', async () => {
  const db = env.authenticatedContext('student').firestore();
  await assertSucceeds(setDoc(doc(db, 'users/student'), {role:3, designSystemAdmin:true}));
  await assertFails(setDoc(doc(db, path), {...payload(), updatedBy:'student'}));
});
test('invalid schema, identity, tokens, ranges and namespace denied', async () => {
  const db = admin();
  for (const change of [{schemaVersion:2}, {updatedBy:'someone'}, {revision:4}, {extra:true}, {light:{primary:'red'}}, {metrics:{...payload().metrics, bodySize:900}}, {updatedAt: new Date(0)}]) {
    await assertFails(setDoc(doc(db, path), {...payload(), ...change}));
  }
  await assertFails(setDoc(doc(db, 'design_systems/other/themes/caramel'), payload()));
  await assertFails(setDoc(doc(db, 'design_systems/yellow_ribbon/themes/invalid id!'), payload()));
});
test('custom theme IDs can be added beyond the built-in palettes', async () => {
  const db = admin();
  for (let i = 0; i < 12; i++) {
    const ref = doc(db, `design_systems/yellow_ribbon/themes/theme_custom_${i}`);
    await assertSucceeds(setDoc(ref, {...payload(), name:`Custom ${i}`}));
    await assertSucceeds(getDoc(ref));
  }
  await assertFails(setDoc(doc(db, `design_systems/yellow_ribbon/themes/${'x'.repeat(81)}`), payload()));
  await assertFails(setDoc(doc(env.authenticatedContext('student').firestore(), 'design_systems/yellow_ribbon/themes/new_from_student'), {...payload(), updatedBy:'student'}));
});
