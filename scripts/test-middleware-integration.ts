#!/usr/bin/env node
/* eslint-disable no-console */

import { spawn, fork, type ChildProcess } from 'child_process';
import { EventEmitter } from 'events';

type IpcMessage =
  | { type: 'ready' }
  | { type: 'event'; count: number }
  | { type: 'done'; count: number }
  | { type: 'error'; error: string }
  | { type: 'end' }
  | { type: 'timeout' }
  | { type: 'shutdown' };

class MiddlewareIntegrationTest extends EventEmitter {
  private middlewareProcess: ChildProcess | null;
  private eventsReceived: unknown[];
  private testTimeout: number;
  private expectedEvents: number;

  constructor() {
    super();
    this.middlewareProcess = null;
    this.eventsReceived = [];
    this.testTimeout = 60000; // 60 seconds
    this.expectedEvents = 3; // Based on OrderEventIntegrationTest
  }

  async startMiddleware(): Promise<void> {
    console.log('🚀 Starting Pub/Sub middleware...');

    return new Promise((resolve, reject) => {
      this.middlewareProcess = fork('scripts/pubsub-middleware.ts', [], {
        stdio: ['pipe', 'pipe', 'pipe', 'ipc'],
        execArgv: ['--loader', 'ts-node/esm'],
        env: {
          ...process.env,
          SK_CLIENTID: process.env.SK_CLIENTID,
          SK_CLIENT_SECRET: process.env.SK_CLIENT_SECRET,
          SK_USER: process.env.SK_USER
        }
      });

      let middlewareReady = false;
      const timeout = setTimeout(() => {
        if (!middlewareReady) {
          reject(new Error('Timeout: Middleware did not become ready in 30 seconds'));
        }
      }, 30000);

      // Structured IPC from middleware
      this.middlewareProcess.on('message', (msg: IpcMessage) => {
        if (msg && msg.type === 'ready' && !middlewareReady) {
          middlewareReady = true;
          clearTimeout(timeout);
          console.log('✅ Middleware is ready (IPC)');
          resolve();
        }
        if (msg && msg.type === 'event') {
          this.eventsReceived.push(msg);
          console.log(`✅ Event received via IPC! Total: ${this.eventsReceived.length}`);
        }
        if (msg && msg.type === 'done') {
          // Validate IPC communication integrity
          const reported = Number(msg.count || 0);
          if (reported > this.eventsReceived.length) {
            const delta = reported - this.eventsReceived.length;
            reject(new Error(
              `IPC communication issue: Child reported ${reported} events ` +
              `but parent only received ${this.eventsReceived.length} individual event messages`
            ));
            return;
          }
        }
        if (msg && (msg.type === 'error' || msg.type === 'timeout')) {
          // Allow close handler to surface the failure
          console.error(`[Middleware IPC] ${msg.type}: ${(msg as any).error || ''}`.trim());
        }
      });

      this.middlewareProcess.stderr?.on('data', (data: Buffer) => {
        console.error(`[Middleware Error] ${data.toString().trim()}`);
      });

      this.middlewareProcess.on('close', (code: number | null) => {
        console.log(`[Middleware] Process exited with code ${code}`);
        if (code === 0) {
          console.log('✅ Middleware exited successfully');
        } else if (!middlewareReady) {
          clearTimeout(timeout);
          reject(new Error(`Middleware exited with error code ${code} before becoming ready`));
        }
      });
    });
  }

  async runIntegrationTests(): Promise<string> {
    console.log('🧪 Publishing platform events to real event bus...');

    return new Promise(async (resolve, reject) => {
      // Execute Apex script that publishes events to the real event bus
      const testProcess = spawn('sf', ['apex', 'run', '--file', 'scripts/publish-test-event.apex', '--target-org', 'ci-scratch'], {
        stdio: ['pipe', 'pipe', 'pipe']
      });

      let output = '';
      testProcess.stdout?.on('data', (data: Buffer) => {
        output += data.toString();
      });

      testProcess.stderr?.on('data', (data: Buffer) => {
        console.error(`[Publish Error] ${data.toString().trim()}`);
      });

      testProcess.on('close', async (code: number | null) => {
        if (code === 0) {
          console.log('✅ Events published successfully');
          console.log(output);
          // Give events time to propagate to external subscribers
          console.log('⏳ Waiting 10 seconds for events to propagate...');
          await new Promise((resolveDelay) => setTimeout(resolveDelay, 10000));
          resolve(output);
        } else {
          console.error(`❌ Event publishing failed with code ${code}`);
          reject(new Error(`Event publishing failed with code ${code}`));
        }
      });
    });
  }

  async waitForEvents(): Promise<void> {
    console.log(`⏳ Waiting for ${this.expectedEvents} events...`);

    return new Promise((resolve, reject) => {
      const timeout = setTimeout(() => {
        reject(new Error(`Timeout: Expected ${this.expectedEvents} events, received ${this.eventsReceived.length}`));
      }, this.testTimeout);

      const checkEvents = () => {
        if (this.eventsReceived.length >= this.expectedEvents) {
          clearTimeout(timeout);
          resolve();
        } else {
          setTimeout(checkEvents, 1000);
        }
      };

      checkEvents();
    });
  }

  stopMiddleware(): void {
    if (this.middlewareProcess) {
      console.log('🛑 Stopping middleware...');
      this.middlewareProcess.kill('SIGTERM');
    }
  }

  async runTest(): Promise<boolean> {
    try {
      console.log('🧪 Starting Middleware Integration Test');
      console.log('=====================================');

      // Start middleware
      await this.startMiddleware();

      // Run integration tests
      await this.runIntegrationTests();

      // Wait for events
      await this.waitForEvents();

      console.log('=====================================');
      console.log('✅ Middleware Integration Test PASSED');
      console.log(`📊 Received ${this.eventsReceived.length} events as expected`);

      return true;
    } catch (error: any) {
      console.log('=====================================');
      console.log('❌ Middleware Integration Test FAILED');
      console.log(`🚨 Error: ${error?.message ?? String(error)}`);
      return false;
    } finally {
      this.stopMiddleware();
    }
  }
}

// Run the test
const test = new MiddlewareIntegrationTest();
test
  .runTest()
  .then((success) => {
    process.exit(success ? 0 : 1);
  })
  .catch((error) => {
    console.error('❌ Test execution failed:', error);
    process.exit(1);
  });


