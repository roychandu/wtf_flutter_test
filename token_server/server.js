import crypto from 'node:crypto';
import fs from 'node:fs';
import http from 'node:http';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

// Load .env file if present
function loadEnv() {
  const possiblePaths = [
    path.join(__dirname, '..', '.env'),
    path.join(__dirname, '.env')
  ];
  for (const envPath of possiblePaths) {
    if (fs.existsSync(envPath)) {
      try {
        const content = fs.readFileSync(envPath, 'utf8');
        const lines = content.split(/\r?\n/);
        for (const line of lines) {
          const trimmed = line.trim();
          if (!trimmed || trimmed.startsWith('#')) continue;
          const equalsIdx = trimmed.indexOf('=');
          if (equalsIdx === -1) continue;
          const key = trimmed.substring(0, equalsIdx).trim();
          let val = trimmed.substring(equalsIdx + 1).trim();
          if ((val.startsWith('"') && val.endsWith('"')) || (val.startsWith("'") && val.endsWith("'"))) {
            val = val.substring(1, val.length - 1);
          }
          if (key && !process.env[key]) {
            process.env[key] = val;
          }
        }
        console.log(`[ENV] Loaded environment variables from ${envPath}`);
      } catch (err) {
        console.error(`[ENV] Error reading env file at ${envPath}:`, err);
      }
    }
  }
}
loadEnv();

const port = Number(process.env.PORT || 8787);
let stateFile = process.env.WTF_STATE_FILE || path.join(__dirname, 'state.json');
if (!path.isAbsolute(stateFile)) {
  stateFile = path.resolve(path.join(__dirname, '..'), stateFile);
}

const seedUser = {
  member: {
    id: 'member_dk',
    role: 'member',
    name: 'DK',
    email: 'dk@wtf.local',
    avatarUrl: 'DK',
    assignedTrainerId: 'trainer_aarav'
  },
  trainer: {
    id: 'trainer_aarav',
    role: 'trainer',
    name: 'Aarav',
    email: 'aarav@wtf.local',
    avatarUrl: 'AR',
    assignedTrainerId: null
  }
};

function seedState() {
  return {
    users: [seedUser.member, seedUser.trainer],
    messages: [],
    requests: [],
    sessions: [],
    logs: ['[AUTH] Bridge seeded DK and Aarav profiles'],
    trainerTyping: false,
    memberTyping: false
  };
}

let state = loadState();

function loadState() {
  try {
    return JSON.parse(fs.readFileSync(stateFile, 'utf8'));
  } catch {
    const seeded = seedState();
    saveState(seeded);
    return seeded;
  }
}

function saveState(next = state) {
  fs.writeFileSync(stateFile, JSON.stringify(next, null, 2));
}

function id(prefix) {
  return `${prefix}_${Date.now()}_${crypto.randomBytes(4).toString('hex')}`;
}

function iso(date = new Date()) {
  return date.toISOString();
}

function addLog(message) {
  state.logs.push(message);
  state.logs = state.logs.slice(-20);
}

function send(res, status, data) {
  res.writeHead(status, {
    'content-type': 'application/json; charset=utf-8',
    'access-control-allow-origin': '*',
    'access-control-allow-methods': 'GET,POST,OPTIONS',
    'access-control-allow-headers': 'content-type'
  });
  res.end(JSON.stringify(data));
}

async function parseBody(req) {
  const chunks = [];
  for await (const chunk of req) {
    chunks.push(chunk);
  }
  if (chunks.length === 0) {
    return {};
  }
  return JSON.parse(Buffer.concat(chunks).toString('utf8'));
}

function statusMessageFor(request, approved, reason) {
  const when = new Date(request.scheduledFor);
  const date = when.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
  const time = when.toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' });
  return approved
    ? `Call approved for ${date} ${time}.`
    : `Call request declined. Reason: ${reason || 'No reason provided'}.`;
}

function addSystemMessage(text) {
  state.messages.push({
    id: id('msg_system'),
    chatId: 'chat_dk_aarav',
    senderId: 'system',
    receiverId: 'member_dk',
    text,
    createdAt: iso(),
    status: 'sent',
    system: true
  });
}

function hasConflict(slotIso, skipRequestId = null) {
  const slot = new Date(slotIso).getTime();
  return state.requests.some((request) => {
    if (request.id === skipRequestId || request.status !== 'approved') {
      return false;
    }
    return Math.abs(new Date(request.scheduledFor).getTime() - slot) < 30 * 60 * 1000;
  });
}

function base64url(input) {
  return Buffer.from(input).toString('base64url');
}

function signJwt(payload, secret) {
  const header = { alg: 'HS256', typ: 'JWT' };
  const body = {
    ...payload,
    iat: Math.floor(Date.now() / 1000),
    exp: Math.floor(Date.now() / 1000) + 24 * 60 * 60,
    jti: crypto.randomUUID()
  };
  const unsigned = `${base64url(JSON.stringify(header))}.${base64url(JSON.stringify(body))}`;
  const signature = crypto.createHmac('sha256', secret).update(unsigned).digest('base64url');
  return `${unsigned}.${signature}`;
}

function hmsToken({ userId, role, roomId }) {
  const accessKey = process.env.HMS_APP_ACCESS_KEY;
  const secret = process.env.HMS_APP_SECRET;
  if (!accessKey || !secret || !roomId) {
    return {
      authToken: `mock.${Buffer.from(`${userId}:${role}:${roomId || 'dev'}`).toString('base64url')}`,
      roomId: roomId || process.env.HMS_DEV_ROOM_ID || 'mock-room',
      role,
      mock: true
    };
  }

  return {
    authToken: signJwt({
      access_key: accessKey,
      room_id: roomId,
      user_id: userId,
      role,
      type: 'app',
      version: 2
    }, secret),
    roomId,
    role,
    mock: false
  };
}

const server = http.createServer(async (req, res) => {
  try {
    if (req.method === 'OPTIONS') {
      return send(res, 200, {});
    }

    const url = new URL(req.url, `http://${req.headers.host}`);

    if (req.method === 'GET' && url.pathname === '/health') {
      return send(res, 200, { ok: true });
    }

    if (req.method === 'GET' && url.pathname === '/state') {
      return send(res, 200, state);
    }

    if (req.method === 'GET' && url.pathname === '/token') {
      return send(res, 200, hmsToken({
        userId: url.searchParams.get('userId') || 'anonymous',
        role: url.searchParams.get('role') || 'member',
        roomId: url.searchParams.get('roomId') || process.env.HMS_DEV_ROOM_ID || ''
      }));
    }

    if (req.method === 'POST' && url.pathname === '/reset') {
      state = seedState();
      saveState();
      return send(res, 200, state);
    }

    if (req.method === 'POST' && url.pathname === '/messages') {
      const body = await parseBody(req);
      const message = {
        id: id('msg'),
        chatId: 'chat_dk_aarav',
        senderId: body.senderId,
        receiverId: body.receiverId,
        text: String(body.text || '').slice(0, 1000),
        createdAt: iso(),
        status: 'sent',
        system: false
      };
      state.messages.push(message);
      if (body.senderId === 'member_dk') {
        state.trainerTyping = true;
        setTimeout(() => {
          state.trainerTyping = false;
          saveState();
        }, 700);
      } else {
        state.memberTyping = true;
        setTimeout(() => {
          state.memberTyping = false;
          saveState();
        }, 700);
      }
      addLog(`[CHAT] ${body.senderId} -> ${body.receiverId}`);
      saveState();
      return send(res, 201, message);
    }

    if (req.method === 'POST' && url.pathname === '/messages/read') {
      const body = await parseBody(req);
      state.messages = state.messages.map((message) => {
        if (message.chatId === body.chatId && message.receiverId === body.userId) {
          return { ...message, status: 'read' };
        }
        return message;
      });
      addLog(`[CHAT] ${body.userId} marked chat read`);
      saveState();
      return send(res, 200, { ok: true });
    }

    if (req.method === 'POST' && url.pathname === '/requests') {
      const body = await parseBody(req);
      const scheduledFor = String(body.scheduledFor);
      if (new Date(scheduledFor).getTime() <= Date.now()) {
        return send(res, 400, { error: 'Choose a future time slot.' });
      }
      if (hasConflict(scheduledFor)) {
        return send(res, 409, { error: 'That slot is already approved. Pick another time.' });
      }
      const request = {
        id: id('req'),
        memberId: body.memberId || 'member_dk',
        trainerId: body.trainerId || 'trainer_aarav',
        requestedAt: iso(),
        scheduledFor,
        note: String(body.note || '').slice(0, 140),
        status: 'pending',
        declineReason: null,
        roomMeta: null
      };
      state.requests.push(request);
      addLog('[SCHEDULE] DK requested a call');
      saveState();
      return send(res, 201, request);
    }

    if (req.method === 'POST' && url.pathname === '/requests/review') {
      const body = await parseBody(req);
      const index = state.requests.findIndex((request) => request.id === body.requestId);
      if (index === -1) {
        return send(res, 404, { error: 'Request not found.' });
      }
      const request = state.requests[index];
      if (body.approved && hasConflict(request.scheduledFor, request.id)) {
        return send(res, 409, { error: 'That slot is already approved. Pick another time.' });
      }
      const approved = Boolean(body.approved);
      const updated = {
        ...request,
        status: approved ? 'approved' : 'declined',
        declineReason: approved ? null : String(body.reason || 'No reason provided'),
        roomMeta: approved
          ? {
              id: id('room'),
              callRequestId: request.id,
              hmsRoomId: process.env.HMS_DEV_ROOM_ID || `dev_${request.id}`,
              hmsRoleMember: process.env.HMS_ROLE_MEMBER || 'member',
              hmsRoleTrainer: process.env.HMS_ROLE_TRAINER || 'trainer'
            }
          : null
      };
      state.requests[index] = updated;
      addSystemMessage(statusMessageFor(updated, approved, body.reason));
      addLog(approved ? '[SCHEDULE] Trainer approved call' : '[SCHEDULE] Trainer declined call');
      saveState();
      return send(res, 200, updated);
    }

    if (req.method === 'POST' && url.pathname === '/requests/simulate-now') {
      const body = await parseBody(req);
      const index = state.requests.findIndex((request) => request.id === body.requestId);
      if (index === -1) {
        return send(res, 404, { error: 'Request not found.' });
      }
      state.requests[index] = {
        ...state.requests[index],
        scheduledFor: iso(new Date(Date.now() + 60 * 1000))
      };
      addLog('[RTC] Call moved into join window');
      saveState();
      return send(res, 200, state.requests[index]);
    }

    if (req.method === 'POST' && url.pathname === '/sessions') {
      const body = await parseBody(req);
      const start = new Date(body.startedAt);
      const end = new Date(body.endedAt);
      const session = {
        id: id('session'),
        memberId: 'member_dk',
        trainerId: 'trainer_aarav',
        startedAt: start.toISOString(),
        endedAt: end.toISOString(),
        durationSec: Math.max(0, Math.floor((end.getTime() - start.getTime()) / 1000)),
        rating: null,
        trainerNotes: body.trainerNotes || null,
        memberNotes: body.memberNotes || null
      };
      state.sessions.push(session);
      addSystemMessage('Session saved to your logs.');
      addLog('[RTC] Session saved to logs');
      saveState();
      return send(res, 201, session);
    }

    if (req.method === 'POST' && url.pathname === '/sessions/update') {
      const body = await parseBody(req);
      const index = state.sessions.findIndex((session) => session.id === body.sessionId);
      if (index === -1) {
        return send(res, 404, { error: 'Session not found.' });
      }
      state.sessions[index] = {
        ...state.sessions[index],
        rating: body.rating ?? state.sessions[index].rating,
        trainerNotes: body.trainerNotes ?? state.sessions[index].trainerNotes,
        memberNotes: body.memberNotes ?? state.sessions[index].memberNotes
      };
      addLog('[RTC] Session feedback updated');
      saveState();
      return send(res, 200, state.sessions[index]);
    }

    return send(res, 404, { error: 'Route not found.' });
  } catch (error) {
    return send(res, 500, { error: error.message || String(error) });
  }
});

server.listen(port, '0.0.0.0', () => {
  console.log(`WTF token and sync server listening on http://0.0.0.0:${port}`);
});
