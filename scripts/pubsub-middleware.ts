#!/usr/bin/env node
/* eslint-disable no-console */

import PubSubApiClient from 'salesforce-pubsub-api-client';

type IpcMessage =
  | { type: 'ready' }
  | { type: 'event'; count: number }
  | { type: 'done'; count: number }
  | { type: 'error'; error: string }
  | { type: 'end' }
  | { type: 'timeout' }
  | { type: 'shutdown' };

  const logger = {
    debug: () => {},              // drop debug
    info: console.log,
    warn: console.warn,
    error: console.error
  };

const client: any = new (PubSubApiClient as any)({
  authType: 'user-supplied',
  accessToken: process.env.SCRATCH_ACCESS_TOKEN,
  instanceUrl: process.env.SCRATCH_INSTANCE_URL,
  organizationId: process.env.SCRATCH_ORG_ID
}, logger);

let eventsReceived = 0;
let timeout: NodeJS.Timeout | undefined;
let isShuttingDown = false;

function safeSend(message: IpcMessage): void {
  if (typeof (process as any).send === 'function') {
    try {
      (process as any).send(message);
    } catch {
      // ignore IPC send errors
    }
  }
}

function subscribeCallback(_subscription: any, callbackType: string, data: unknown): void {
  switch (callbackType) {
    case 'event': {
      eventsReceived++;
      console.log(
        `📨 Received event ${eventsReceived}:`,
        JSON.stringify(
          data,
          (key, value) => (typeof value === 'bigint' ? value.toString() : value),
          2
        )
      );
      safeSend({ type: 'event', count: eventsReceived });

      // Exit successfully after receiving expected events (3 from OrderEventIntegrationTest)
      if (eventsReceived >= 3 && !isShuttingDown) {
        console.log(`✅ Successfully received ${eventsReceived} OrderActivated events!`);
        safeSend({ type: 'done', count: eventsReceived });
        process.exit(0);
      }
      break;
    }
    case 'error': {
      console.error('❌ Subscription error:', data);
      safeSend({ type: 'error', error: String(data) });
      if (!isShuttingDown) {
        process.exit(1);
      }
      break;
    }
    case 'end': {
      console.log('🔚 Subscription ended');
      safeSend({ type: 'end' });
      break;
    }
    default:
      break;
  }
}

async function subscribeToOrderEvents(): Promise<void> {
  try {
    console.log('🔐 Connecting to Salesforce...');
    await client.connect();
    console.log('✅ Connected successfully');
    console.log('📡 Subscribing to OrderActivated__e events...');
    // Request 3 events (based on OrderEventIntegrationTest which creates 3 orders)
    await client.subscribe('/event/OrderActivated__e', subscribeCallback, 3);
    console.log('✅ Subscribed to OrderActivated__e events...');
    safeSend({ type: 'ready' });
    console.log('⏳ Waiting for events...');

    // Set timeout to fail if no events received
    timeout = setTimeout(() => {
      if (!isShuttingDown) {
        console.error('❌ Timeout: No events received within 90 seconds');
        safeSend({ type: 'timeout' });
        process.exit(1);
      }
    }, 90000);
  } catch (error) {
    console.error('❌ Authentication error:', error);
    safeSend({ type: 'error', error: String(error) });
    process.exit(1);
  }
}

// Handle graceful shutdown
process.on('SIGINT', () => {
  isShuttingDown = true;
  if (timeout) clearTimeout(timeout);
  console.log('🛑 Shutting down middleware...');
  safeSend({ type: 'shutdown' });
  process.exit(0);
});

process.on('SIGTERM', () => {
  isShuttingDown = true;
  if (timeout) clearTimeout(timeout);
  console.log('🛑 Shutting down middleware...');
  safeSend({ type: 'shutdown' });
  process.exit(0);
});

subscribeToOrderEvents();


