'use strict';
const {equal, appleSignature, safeId, validRelease, event} = require('./core.cjs');
function createHandler({store, enqueue, dispatch, ciToken, appleSecret, logger}) {
  return async (req, res) => {
  try {
    if (req.method !== 'POST') return res.status(405).json({error: 'POST required'});
    if (req.path === '/apple') {
      if (!appleSignature(req.rawBody, req.get('x-apple-signature'), appleSecret.value())) return res.status(401).json({error: 'Invalid signature'});
      const e = event(req.body);
      await store.update(`events/${e.id}.json`, old => old ? undefined : {...e, receivedAt: new Date().toISOString()});
      if (e.terminal) {
        const active = (await store.read('active.json')).value;
        if (active?.id) await enqueue('event-' + e.id, {id: active.id, uploadId: e.uploadId});
      }
      // ACK only after durable receipt and scheduling; duplicate delivery repairs partial work.
      return res.status(200).json({received: true});
    }
    if (!equal(req.get('authorization'), `Bearer ${ciToken.value()}`)) return res.status(401).json({error: 'Unauthorized'});
    const b = req.body;
    if (!safeId(b?.id)) return res.status(400).json({error: 'Invalid release ID'});
    const path = `releases/${b.id}.json`;
    if (req.path === '/register') {
      if (!validRelease(b)) return res.status(400).json({error: 'Invalid release metadata'});
      const now = Date.now(); let conflict = false;
      await store.update('active.json', old => {conflict = false; if (old?.id !== b.id && old?.until > now) {conflict = true; return;} return {id: b.id, until: now + 2 * 3600000};});
      if (conflict) return res.status(409).json({error: 'Another release is active'});
      const saved = await store.update(path, old => old || {...b, registeredAt: new Date(now).toISOString(), deadline: now + 90 * 60000});
      if (saved.version !== b.version || saved.buildNumber !== b.buildNumber || saved.commit !== b.commit) return res.status(409).json({error: 'Release identity cannot change'});
      await enqueue(`${b.id}-watchdog`, {id: b.id}, now + 30 * 60000);
      return res.json({registered: true});
    }
    if (req.path === '/release') return res.json((await store.read(path)).value);
    if (req.path === '/build-complete') {await enqueue(`${b.id}-build-complete`,{id:b.id,kind:'build_status'},Date.now()+60000); return res.json({accepted:true});}
    if (req.path === '/dispatch') {await dispatch(b.id, b.uploadId, b.kind); return res.json({accepted: true});}
    if (req.path === '/claim') {
      if (!safeId(b.runId)) return res.status(400).json({error: 'Invalid verifier run'});
      let claimed = false; const now = Date.now();
      const release = await store.update(path, old => {claimed = false; if (!old || old.result || (old.runId && old.runId !== b.runId && old.leaseUntil > now)) return; claimed = true; return {...old, runId: b.runId, leaseUntil: now + 22 * 60000};});
      return res.json({claimed, release});
    }
    if (req.path === '/finish') {
      if (!['ready', 'failed', 'unknown'].includes(b.result?.status)) return res.status(400).json({error: 'Invalid result'});
      let notify = false;
      await store.update(path, old => {notify = false; if (!old || old.result || old.runId !== b.runId) return; if (b.result.appId !== old.appId || b.result.version !== old.version || b.result.buildNumber !== old.buildNumber) throw new Error('Result identity mismatch'); notify = true; return {...old, result: b.result, completedAt: new Date().toISOString()};});
      if (notify) await store.update('active.json', old => old?.id === b.id ? {id: b.id, until: 0} : undefined);
      return res.json({notify});
    }
    return res.status(404).json({error: 'Unknown route'});
  } catch (e) {
    // Cloud Monitoring watches this independent channel, including revoked Codemagic tokens.
    logger.error('Release notification service error', {reason: e.message, path: req.path});
    return res.status(503).json({error: 'Notification service unavailable'});
  }
};
}
module.exports = {createHandler};
