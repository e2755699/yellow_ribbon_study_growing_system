import { createRemoteJWKSet, customFetch, jwtVerify, importPKCS8, SignJWT } from 'jose';

export class ApiError extends Error {
  constructor(status, code) { super(code); this.status = status; this.code = code; }
}

export function createFirebaseVerifier(fetcher = fetch) {
  const jwks = createRemoteJWKSet(new URL('https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com'), {
    [customFetch]: fetcher, timeoutDuration: 10000, cooldownDuration: 30000, cacheMaxAge: 3600000,
  });
  return async (token, project) => {
    let payload;
    try {
      ({ payload } = await jwtVerify(token, jwks, {
        algorithms: ['RS256'], issuer: `https://securetoken.google.com/${project}`, audience: project,
        requiredClaims: ['exp', 'iat', 'sub', 'auth_time'],
      }));
    } catch (error) {
      // Key-service outages are not proof that the teacher lost permission.
      if (error.code === 'ERR_JWKS_TIMEOUT' || error.code === 'ERR_JOSE_GENERIC' || !error.code)
        throw new ApiError(503, 'identity_service_unavailable');
      throw new ApiError(401, 'invalid_login');
    }
    const now = Math.floor(Date.now() / 1000);
    if (typeof payload.sub !== 'string' || !payload.sub || payload.sub.length > 128 ||
      !Number.isFinite(payload.auth_time) || payload.auth_time < 0 || payload.auth_time > now || payload.iat > now)
      throw new ApiError(401, 'invalid_login');
    return payload.sub;
  };
}

// Only the service's short-lived Drive token is cached. Teacher authorization never is.
export function createDriveTokenProvider(fetcher = fetch, now = () => Date.now()) {
  let cached, pending;
  return async env => {
    const identity = `${env.GOOGLE_SERVICE_ACCOUNT_EMAIL}\n${env.GOOGLE_SERVICE_ACCOUNT_PRIVATE_KEY}`;
    if (cached?.identity === identity && cached.expires > now() + 60000) return cached.token;
    if (pending?.identity === identity) return pending.promise;
    const promise = (async () => {
      try {
        const key = await importPKCS8(env.GOOGLE_SERVICE_ACCOUNT_PRIVATE_KEY, 'RS256');
        const issued = Math.floor(now() / 1000);
        const assertion = await new SignJWT({ scope: 'https://www.googleapis.com/auth/drive' })
          .setProtectedHeader({ alg: 'RS256' }).setIssuer(env.GOOGLE_SERVICE_ACCOUNT_EMAIL)
          .setAudience('https://oauth2.googleapis.com/token').setIssuedAt(issued).setExpirationTime(issued + 3600).sign(key);
        const response = await fetcher('https://oauth2.googleapis.com/token', {
          method: 'POST', redirect: 'error', signal: AbortSignal.timeout(15000),
          body: new URLSearchParams({ grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer', assertion }),
        });
        if (!response.ok) throw Error('oauth failed');
        const data = await response.json();
        if (typeof data.access_token !== 'string' || !data.access_token || !Number.isFinite(data.expires_in) || data.expires_in <= 60)
          throw Error('invalid oauth response');
        cached = { identity, token: data.access_token, expires: now() + Math.min(data.expires_in, 3600) * 1000 };
        return cached.token;
      } catch { throw new ApiError(503, 'drive_identity_unavailable'); }
    })();
    pending = { identity, promise };
    try { return await promise; } finally { if (pending?.promise === promise) pending = undefined; }
  };
}
