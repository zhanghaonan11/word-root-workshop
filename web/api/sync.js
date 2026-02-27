const SYNC_KEY_PREFIX = 'wrw:sync:';

function json(res, statusCode, payload) {
  res.statusCode = statusCode;
  res.setHeader('Content-Type', 'application/json; charset=utf-8');
  res.setHeader('Cache-Control', 'no-store');
  res.end(JSON.stringify(payload));
}

function normalizeSyncCode(rawCode) {
  return String(rawCode || '')
    .trim()
    .toUpperCase()
    .replace(/[^A-Z0-9_-]/g, '')
    .slice(0, 64);
}

function parseBody(req) {
  if (!req.body) return {};
  if (typeof req.body === 'object') return req.body;
  if (typeof req.body === 'string') {
    try {
      return JSON.parse(req.body);
    } catch (error) {
      return {};
    }
  }
  return {};
}

function isValidPayload(payload) {
  return Boolean(
    payload &&
    typeof payload === 'object' &&
    payload.progress &&
    typeof payload.progress === 'object' &&
    Array.isArray(payload.achievements)
  );
}

function getPayloadTimestamp(payload) {
  const value =
    (payload && (payload.lastModified || (payload.progress && payload.progress.updatedAt))) ||
    '';
  const time = Date.parse(value);
  return Number.isNaN(time) ? 0 : time;
}

async function runKvCommand(command) {
  const restUrl = process.env.KV_REST_API_URL;
  const restToken = process.env.KV_REST_API_TOKEN;

  if (!restUrl || !restToken) {
    const error = new Error('kv_not_configured');
    error.code = 'kv_not_configured';
    throw error;
  }

  const response = await fetch(restUrl, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${restToken}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify(command)
  });

  if (!response.ok) {
    const text = await response.text();
    const error = new Error(`kv_request_failed:${response.status}`);
    error.details = text;
    throw error;
  }

  const data = await response.json();
  return data.result;
}

async function getRecord(syncCode) {
  const key = `${SYNC_KEY_PREFIX}${syncCode}`;
  const rawRecord = await runKvCommand(['GET', key]);
  if (!rawRecord) return null;

  try {
    const parsed = JSON.parse(rawRecord);
    if (!parsed || typeof parsed !== 'object') return null;
    return parsed;
  } catch (error) {
    return null;
  }
}

async function saveRecord(syncCode, payload) {
  const key = `${SYNC_KEY_PREFIX}${syncCode}`;
  const record = {
    version: 1,
    serverUpdatedAt: new Date().toISOString(),
    payload
  };
  await runKvCommand(['SET', key, JSON.stringify(record)]);
  return record;
}

module.exports = async function handler(req, res) {
  if (req.method === 'OPTIONS') {
    res.statusCode = 204;
    res.setHeader('Allow', 'GET,POST,OPTIONS');
    return res.end();
  }

  if (req.method === 'GET') {
    const syncCode = normalizeSyncCode(req.query.code || req.query.syncCode);
    if (!syncCode) {
      return json(res, 400, { ok: false, error: 'invalid_sync_code' });
    }

    try {
      const record = await getRecord(syncCode);
      if (!record) {
        return json(res, 200, { ok: true, present: false });
      }

      return json(res, 200, {
        ok: true,
        present: true,
        data: record.payload,
        serverUpdatedAt: record.serverUpdatedAt
      });
    } catch (error) {
      const errorCode = error && error.code ? error.code : 'sync_read_failed';
      return json(res, 500, { ok: false, error: errorCode });
    }
  }

  if (req.method === 'POST') {
    const body = parseBody(req);
    const syncCode = normalizeSyncCode(body.code || body.syncCode);
    const payload = body.payload;
    const strategy = body.strategy || 'overwrite';

    if (!syncCode) {
      return json(res, 400, { ok: false, error: 'invalid_sync_code' });
    }
    if (!isValidPayload(payload)) {
      return json(res, 400, { ok: false, error: 'invalid_payload' });
    }

    try {
      const existing = await getRecord(syncCode);

      if (strategy === 'if-newer' && existing && existing.payload) {
        const incomingTimestamp = getPayloadTimestamp(payload);
        const existingTimestamp = getPayloadTimestamp(existing.payload);

        if (incomingTimestamp <= existingTimestamp) {
          return json(res, 200, {
            ok: true,
            updated: false,
            reason: 'stale_payload',
            serverUpdatedAt: existing.serverUpdatedAt
          });
        }
      }

      const savedRecord = await saveRecord(syncCode, payload);
      return json(res, 200, {
        ok: true,
        updated: true,
        serverUpdatedAt: savedRecord.serverUpdatedAt
      });
    } catch (error) {
      const errorCode = error && error.code ? error.code : 'sync_write_failed';
      return json(res, 500, { ok: false, error: errorCode });
    }
  }

  res.setHeader('Allow', 'GET,POST,OPTIONS');
  return json(res, 405, { ok: false, error: 'method_not_allowed' });
};
