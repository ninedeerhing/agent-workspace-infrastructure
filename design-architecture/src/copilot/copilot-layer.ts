/**
 * L6 · AI Copilot 协作层
 *
 * 对应 CopilotKit 核心能力：Agent Runtime、Generative UI、Shared State。
 * 兼容 AG-UI 协议，支持与多种 AI 后端（LangGraph/Deep Agents/Google ADK）集成。
 */

import type { AgentMessage, GenerativeUIComponent, FrontendTool } from '../core/types';

// ==================== Agent Runtime ====================

interface AgentRuntimeState {
  messages: AgentMessage[];
  isRunning: boolean;
  threadId: string | null;
  error: Error | null;
}

/** 创建代理运行时 — 管理 AI 代理的消息和线程生命周期 */
export function createAgentRuntime(config?: {
  systemPrompt?: string;
  threadId?: string;
}) {
  const state: AgentRuntimeState = {
    messages: [],
    isRunning: false,
    threadId: config?.threadId || null,
    error: null,
  };

  const listeners = new Set<(state: AgentRuntimeState) => void>();

  function notify() {
    const snapshot = { ...state, messages: [...state.messages] };
    listeners.forEach((fn) => fn(snapshot));
  }

  if (config?.systemPrompt) {
    state.messages.push({
      id: 'system-1', role: 'system',
      content: config.systemPrompt, timestamp: Date.now(),
    });
  }

  return {
    getState(): Readonly<AgentRuntimeState> {
      return { ...state, messages: [...state.messages] };
    },

    subscribe(listener: (state: AgentRuntimeState) => void): () => void {
      listeners.add(listener);
      return () => listeners.delete(listener);
    },

    async run(userMessage: string): Promise<void> {
      state.isRunning = true;
      state.error = null;
      state.messages.push({
        id: `user-${Date.now()}`, role: 'user',
        content: userMessage, timestamp: Date.now(),
      });
      notify();
      // 预留：通过 AG-UI 协议接入 AI 后端
    },

    addAssistantMessage(content: string): void {
      state.messages.push({
        id: `assistant-${Date.now()}`, role: 'assistant',
        content, timestamp: Date.now(),
      });
      state.isRunning = false;
      notify();
    },

    addToolMessage(toolName: string, content: string): void {
      state.messages.push({
        id: `tool-${Date.now()}`, role: 'tool',
        content: JSON.stringify({ tool: toolName, result: content }),
        timestamp: Date.now(),
      });
      notify();
    },

    setError(error: Error): void {
      state.error = error;
      state.isRunning = false;
      notify();
    },

    clear(): void {
      state.messages = [];
      state.error = null;
      state.isRunning = false;
      notify();
    },

    setThreadId(id: string): void { state.threadId = id; },
  };
}

// ==================== Generative UI 注册表 ====================

/** 生成式 UI 组件注册表 — AI 可通过组件名称动态渲染 */
export function createGenerativeUIRegistry() {
  const components = new Map<string, GenerativeUIComponent>();
  const renderers = new Map<string, (props: Record<string, unknown>) => unknown>();

  return {
    register(
      component: GenerativeUIComponent,
      renderer: (props: Record<string, unknown>) => unknown,
    ): void {
      components.set(component.name, component);
      renderers.set(component.name, renderer);
    },

    getComponent(name: string): GenerativeUIComponent | undefined {
      return components.get(name);
    },

    render(name: string, props: Record<string, unknown>): unknown {
      const renderer = renderers.get(name);
      if (!renderer) throw new Error(`生成式 UI 组件 "${name}" 未注册`);
      return renderer(props);
    },

    getComponentSchema(): string {
      const schemas: string[] = ['## 可用的生成式 UI 组件', ''];
      for (const [name, comp] of components) {
        const params = Object.entries(comp.parameters)
          .map(([key, param]) => {
            const required = param.required ? '(必填)' : '(可选)';
            return `  - ${key}: ${param.type} ${required} — ${param.description}`;
          })
          .join('\n');
        schemas.push(`### ${name}`);
        schemas.push(`**描述**: ${comp.description}`);
        schemas.push(`**参数**:\n${params}\n`);
      }
      return schemas.join('\n');
    },

    list(): string[] { return Array.from(components.keys()); },
  };
}

// ==================== Frontend Tools ====================

/** 前端工具注册表 — AI 可调用注册的前端操作 */
export function createFrontendTools() {
  const tools = new Map<string, FrontendTool>();

  return {
    register(tool: FrontendTool): void { tools.set(tool.name, tool); },

    async execute(name: string, params: Record<string, unknown>): Promise<unknown> {
      const tool = tools.get(name);
      if (!tool) throw new Error(`前端工具 "${name}" 未注册`);
      return tool.handler(params);
    },

    getToolsDescription(): string {
      const descs: string[] = ['## 可用的前端工具', ''];
      for (const [name, tool] of tools) {
        descs.push(`- **${name}**: ${tool.description}`);
      }
      return descs.join('\n');
    },

    list(): string[] { return Array.from(tools.keys()); },
  };
}

// ==================== Shared State ====================

/** 共享状态管理器 — AI 和用户可以同时读写 */
export function createSharedState<T extends Record<string, unknown>>(initialState: T) {
  let state = { ...initialState };
  const listeners = new Set<(state: T) => void>();

  return {
    get(): Readonly<T> { return state; },

    update(patch: Partial<T>): void {
      state = { ...state, ...patch };
      listeners.forEach((fn) => fn(state));
    },

    set(newState: T): void {
      state = { ...newState };
      listeners.forEach((fn) => fn(state));
    },

    subscribe(listener: (state: T) => void): () => void {
      listeners.add(listener);
      return () => listeners.delete(listener);
    },

    reset(): void {
      state = { ...initialState };
      listeners.forEach((fn) => fn(state));
    },

    snapshot(): string { return JSON.stringify(state); },
  };
}
