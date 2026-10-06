import { ApiError, createFirebaseVerifier, createDriveTokenProvider } from './auth.js';

const MAX_BYTES = 10 * 1024 * 1024;
const APP = 'yellow-ribbon-drive-poc-v1';
const ID = /^[A-Za-z0-9_-]{1,160}$/;
const OP = /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const TYPES = new Set(['image/png', 'image/jpeg', 'application/pdf']);
const headers = { 'cache-control': 'private, no-store', 'x-content-type-options': 'nosniff' };
const json = (body, status = 200) => Response.json(body, { status, headers });

function configuration(env) {
  let students;
  try { students = JSON.parse(env.POC_STUDENT_IDS); } catch { /* fail closed */ }
  if (env.POC_ENABLED !== 'true' || !/^[a-z][a-z0-9-]{4,61}[a-z0-9]$/.test(env.FIREBASE_PROJECT_ID ?? '') ||
    !ID.test(env.DRIVE_FOLDER_ID ?? '') || !Array.isArray(students) || !students.length ||
    students.some(id => typeof id !== 'string' || !ID.test(id)) ||
    !env.GOOGLE_SERVICE_ACCOUNT_EMAIL || !env.GOOGLE_SERVICE_ACCOUNT_PRIVATE_KEY)
    throw new ApiError(503, 'poc_not_configured');
  return students;
}

async function upstream(fetcher, url, options = {}) {
  try { return await fetcher(url, { ...options, redirect: 'error', signal: options.signal ?? AbortSignal.timeout(15000) }); }
  catch { throw new ApiError(503, 'upstream_unavailable'); }
}
async function authorizeStudent(fetcher, env, studentId, token) {
  const name = `projects/${env.FIREBASE_PROJECT_ID}/databases/(default)/documents/students/${studentId}`;
  const response = await upstream(fetcher, `https://firestore.googleapis.com/v1/${name}`, {
    headers: { authorization: `Bearer ${token}` },
  });
  if (response.status === 401) throw new ApiError(401, 'invalid_login');
  if (response.status === 403) throw new ApiError(403, 'student_access_denied');
  if (response.status === 404) throw new ApiError(404, 'student_not_found');
  if (!response.ok) throw new ApiError(503, 'authorization_unavailable');
  const data = await response.json();
  if (data.name !== name) throw new ApiError(503, 'authorization_unavailable');
}
function matches(file, folder, student) {
  return file.trashed !== true && file.parents?.includes(folder) && file.appProperties?.app === APP && file.appProperties?.studentId === student;
}

function uploadInput(request) {
  const type = request.headers.get('content-type');
  const rawLength = request.headers.get('content-length');
  const length = Number(rawLength);
  const operationId = request.headers.get('x-upload-id');
  let name;
  try { name = decodeURIComponent(request.headers.get('x-file-name') ?? ''); } catch { /* reject */ }
  if (!TYPES.has(type)) throw new ApiError(415, 'unsupported_file_type');
  if (!rawLength || !/^\d+$/.test(rawLength) || !Number.isSafeInteger(length) || length < 8)
    throw new ApiError(400, 'invalid_file_length');
  if (length > MAX_BYTES) throw new ApiError(413, 'file_too_large');
  if (!OP.test(operationId ?? '')) throw new ApiError(400, 'invalid_upload_id');
  if (!name || name.length > 160 || /[\x00-\x1f\x7f/\\]/.test(name)) throw new ApiError(400, 'invalid_file_name');
  return { type, length, operationId, name };
}
function validMagic(bytes, type) {
  if (type === 'image/png') return [137, 80, 78, 71, 13, 10, 26, 10].every((v, i) => bytes[i] === v);
  if (type === 'image/jpeg') return bytes[0] === 255 && bytes[1] === 216 && bytes[2] === 255;
  return [37, 80, 68, 70, 45].every((v, i) => bytes[i] === v);
}

// Keep at most the initial network chunk plus an 8-byte signature; do not buffer the file.
async function multipart(request, input, env, studentId) {
  if (!request.body) throw new ApiError(400, 'missing_file');
  const reader = request.body.getReader();
  const initial = []; const prefix = new Uint8Array(8); let prefixSize = 0, total = 0;
  try {
    while (prefixSize < 8) {
      const { value, done } = await reader.read();
      if (done) throw new ApiError(400, 'invalid_file_length');
      total += value.byteLength;
      if (total > input.length) throw new ApiError(400, 'invalid_file_length');
      initial.push(value);
      const count = Math.min(8 - prefixSize, value.byteLength);
      prefix.set(value.subarray(0, count), prefixSize); prefixSize += count;
    }
    if (!validMagic(prefix, input.type)) throw new ApiError(415, 'file_signature_mismatch');
  } catch (error) { await reader.cancel().catch(() => {}); throw error; }
  const boundary = `yr_${crypto.randomUUID().replaceAll('-', '')}`;
  const encoder = new TextEncoder();
  const metadata = { name: input.name, mimeType: input.type, parents: [env.DRIVE_FOLDER_ID],
    appProperties: { app: APP, studentId, operationId: input.operationId } };
  let started = false;
  const body = new ReadableStream({
    async pull(controller) {
      try {
        if (!started) {
          started = true;
          controller.enqueue(encoder.encode(`--${boundary}\r\nContent-Type: application/json; charset=UTF-8\r\n\r\n${JSON.stringify(metadata)}\r\n--${boundary}\r\nContent-Type: ${input.type}\r\n\r\n`));
          return;
        }
        if (initial.length) { controller.enqueue(initial.shift()); return; }
        const { value, done } = await reader.read();
        if (done) {
          if (total !== input.length) throw Error('length mismatch');
          controller.enqueue(encoder.encode(`\r\n--${boundary}--\r\n`)); controller.close(); return;
        }
        total += value.byteLength;
        if (total > input.length || total > MAX_BYTES) throw Error('length exceeded');
        controller.enqueue(value);
      } catch (error) { await reader.cancel().catch(() => {}); controller.error(error); }
    },
    cancel(reason) { return reader.cancel(reason); },
  });
  return { body, boundary };
}

export function createWorker({ fetcher = fetch, verify = createFirebaseVerifier(fetcher), driveToken = createDriveTokenProvider(fetcher) } = {}) {
  return { async fetch(request, env) {
    let uploadOperation;
    try {
      const path = new URL(request.url).pathname;
      if (request.method === 'GET' && path === '/health') return json({ service: APP, status: 'ok' });
      const route = /^\/v1\/students\/([A-Za-z0-9_-]+)\/(files|uploads)(?:\/([A-Za-z0-9_-]+))?$/.exec(path);
      if (!route) throw new ApiError(404, 'not_found');
      const [, studentId, kind, fileId] = route;
      if (!ID.test(studentId) || (fileId && !ID.test(fileId))) throw new ApiError(400, 'invalid_id');
      if (!((request.method === 'GET' && fileId) || (request.method === 'POST' && kind === 'files' && !fileId)))
        throw new ApiError(405, 'method_not_allowed');
      const auth = /^Bearer ([^\s]+)$/.exec(request.headers.get('authorization') ?? '');
      if (!auth || auth[1].length > 8192) throw new ApiError(401, 'login_required');
      const students = configuration(env);
      if (!students.includes(studentId)) throw new ApiError(403, 'outside_test_scope');
      await verify(auth[1], env.FIREBASE_PROJECT_ID);
      await authorizeStudent(fetcher, env, studentId, auth[1]);
      const input = request.method === 'POST' ? uploadInput(request) : null;
      if (kind === 'uploads' && !OP.test(fileId)) throw new ApiError(400, 'invalid_upload_id');
      const bearer = await driveToken(env);
      const driveHeaders = { authorization: `Bearer ${bearer}` };
      if (input) {
        const { body, boundary } = await multipart(request, input, env, studentId);
        // From this point a dropped response can mean the Drive write succeeded.
        uploadOperation = input.operationId;
        const response = await upstream(fetcher, 'https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart&supportsAllDrives=true&fields=id', {
          method: 'POST', headers: { ...driveHeaders, 'content-type': `multipart/related; boundary=${boundary}` },
          body, duplex: 'half', signal: AbortSignal.timeout(120000),
        });
        if (!response.ok) {
          if ([400, 401, 403, 404, 413, 415, 429].includes(response.status)) {
            uploadOperation = undefined;
            throw new ApiError(response.status === 429 ? 503 : 502, 'drive_upload_rejected');
          }
          throw new ApiError(503, 'upload_outcome_unknown');
        }
        const data = await response.json();
        if (!ID.test(data.id ?? '')) throw new ApiError(503, 'upload_outcome_unknown');
        return json({ provider: 'googleDrive', fileId: data.id, operationId: input.operationId }, 201);
      }
      if (kind === 'uploads') {
        const query = `'${env.DRIVE_FOLDER_ID}' in parents and trashed = false and appProperties has { key='app' and value='${APP}' } and appProperties has { key='studentId' and value='${studentId}' } and appProperties has { key='operationId' and value='${fileId}' }`;
        const params = new URLSearchParams({ q: query, spaces: 'drive', supportsAllDrives: 'true', includeItemsFromAllDrives: 'true', pageSize: '100', fields: 'files(id),nextPageToken' });
        const response = await upstream(fetcher, `https://www.googleapis.com/drive/v3/files?${params}`, { headers: driveHeaders });
        if (!response.ok) throw new ApiError(503, 'drive_unavailable');
        const data = await response.json();
        const files = data.files;
        if (!Array.isArray(files) || files.some(f => !ID.test(f.id ?? ''))) throw new ApiError(503, 'drive_unavailable');
        return json({ operationId: fileId, status: files.length ? 'found' : 'unknown', fileIds: files.map(f => f.id) });
      }
      const base = `https://www.googleapis.com/drive/v3/files/${fileId}`;
      const metadata = await upstream(fetcher, `${base}?supportsAllDrives=true&fields=id,parents,appProperties,mimeType,size,trashed`, { headers: driveHeaders });
      if (metadata.status === 404) throw new ApiError(404, 'file_not_found');
      if (!metadata.ok) throw new ApiError(503, 'drive_unavailable');
      const file = await metadata.json();
      if (!matches(file, env.DRIVE_FOLDER_ID, studentId)) throw new ApiError(404, 'file_not_found');
      if (!TYPES.has(file.mimeType) || !Number.isSafeInteger(Number(file.size)) || Number(file.size) < 1 || Number(file.size) > MAX_BYTES)
        throw new ApiError(415, 'unsupported_file');
      const media = await upstream(fetcher, `${base}?alt=media&supportsAllDrives=true`, { headers: driveHeaders, signal: AbortSignal.timeout(120000) });
      if (!media.ok) throw new ApiError(503, 'drive_unavailable');
      return new Response(media.body, { headers: { ...headers, 'content-type': file.mimeType,
        'content-disposition': 'attachment', 'content-security-policy': "default-src 'none'; sandbox" } });
    } catch (error) {
      if (uploadOperation) return json({ error: 'upload_outcome_unknown', operationId: uploadOperation }, 503);
      return json({ error: error instanceof ApiError ? error.code : 'upstream_unavailable' }, error instanceof ApiError ? error.status : 503);
    }
  } };
}

export default createWorker();
