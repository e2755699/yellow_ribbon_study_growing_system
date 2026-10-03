const {test} = require('node:test'), assert = require('node:assert/strict'), crypto = require('node:crypto');
const {appleSignature, equal, event, validRelease} = require('../core.cjs');
test('raw body HMAC rejects tampering and missing signatures', () => {
  const raw = Buffer.from('{"data":1}'), secret = 'synthetic-secret';
  const header = 'hmacsha256=' + crypto.createHmac('sha256', secret).update(raw).digest('hex');
  assert(appleSignature(raw, header, secret)); assert(!appleSignature(Buffer.from('{"data":2}'), header, secret)); assert(!appleSignature(raw, '', secret)); assert(!equal('x','xx'));
});
test('only terminal upload events trigger verification; external beta events do not establish success', () => {
  const d = {id:'event-1', type:'buildUploadStateUpdated', attributes:{newState:'COMPLETE'}, relationships:{instance:{data:{type:'buildUploads',id:'upload-1'}}}};
  assert(event({data:d}).terminal); d.attributes.newState='PROCESSING'; assert(!event({data:d}).terminal);
  d.type='buildBetaDetailExternalBuildStateUpdated'; assert(event({data:d}).ignored);
});
test('untrusted event IDs cannot escape storage namespace', () => {assert.throws(()=>event({data:{id:'../students'}}));});
test('only valid release metadata accepted', () => {
  const r={id:'ci-12', appId:'6746115397',version:'1.0.1',buildNumber:'12',commit:'a'.repeat(40),branch:'codex/student-roster-integrity'};
  assert(validRelease(r)); assert(!validRelease({...r,appId:'other'})); assert(!validRelease({...r,commit:'$(evil)'}));
});
