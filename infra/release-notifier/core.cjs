'use strict';
const crypto = require('node:crypto');
function equal(a, b) { const x = Buffer.from(a || ''), y = Buffer.from(b || ''); return x.length === y.length && crypto.timingSafeEqual(x, y); }
function appleSignature(raw, header, secret) {
  if (!secret || !Buffer.isBuffer(raw)) return false;
  return equal(header, 'hmacsha256=' + crypto.createHmac('sha256', secret).update(raw).digest('hex'));
}
function safeId(id) { return typeof id === 'string' && /^[a-zA-Z0-9_-]{1,100}$/.test(id); }
function validRelease(r) {
  return safeId(r.id) && r.appId === '6746115397' && /^\d+\.\d+(?:\.\d+)?$/.test(r.version) && /^[1-9]\d*$/.test(r.buildNumber) && /^[a-f0-9]{40}$/.test(r.commit) && typeof r.branch === 'string' && /^[\w./-]{1,150}$/.test(r.branch);
}
function event(body) {
  const d = body?.data;
  if (!d || !safeId(d.id)) throw new Error('Invalid event identity');
  if (d.type === 'ping') return {id: d.id, ping: true};
  if (d.type !== 'buildUploadStateUpdated') return {id: d.id, ignored: true};
  if (!safeId(d.relationships?.instance?.data?.id) || d.relationships.instance.data.type !== 'buildUploads') throw new Error('Invalid build upload event');
  return {id: d.id, uploadId: d.relationships.instance.data.id, terminal: ['COMPLETE', 'FAILED'].includes(d.attributes?.newState)};
}
module.exports = {equal, appleSignature, safeId, validRelease, event};
