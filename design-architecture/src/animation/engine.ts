/**
 * L4 · Animation 层 — 动画引擎
 *
 * 基于 Anime.js v4 的抽象动画系统。
 * 提供统一 API、预设库、滚动动画和时间线编排。
 * Anime.js 不可用时自动降级到 CSS Animation / WAAPI。
 */

import type { AnimationConfig, TimelineConfig } from '../core/types';

/** 缓动函数预设 */
const EASINGS = {
  default: 'cubic-bezier(0.16, 1, 0.3, 1)',
  spring: 'cubic-bezier(0.34, 1.56, 0.64, 1)',
  out: 'cubic-bezier(0, 0, 0.2, 1)',
  in: 'cubic-bezier(0.4, 0, 1, 1)',
  inOut: 'cubic-bezier(0.4, 0, 0.2, 1)',
  easeOutExpo: 'easeOutExpo',
  easeOutBack: 'easeOutBack',
} as const;

interface AnimeInstance {
  play: () => void;
  pause: () => void;
  restart: () => void;
  reverse: () => void;
  seek: (time: number) => void;
  finished: Promise<void>;
}

type AnimeModule = {
  animate: (targets: unknown, config: Record<string, unknown>) => AnimeInstance;
  stagger: (value: number | string, options?: Record<string, unknown>) => unknown;
  timeline: (config?: Record<string, unknown>) => {
    add: (config: Record<string, unknown>, position?: number | string) => AnimeInstance;
  };
};

/** 将 targets 解析为 HTMLElement 数组 */
function resolveTargets(targets: AnimationConfig['targets']): HTMLElement[] {
  if (typeof targets === 'string') {
    return Array.from(document.querySelectorAll<HTMLElement>(targets));
  }
  if (targets instanceof HTMLElement) return [targets];
  if (Array.isArray(targets)) {
    return targets.filter((t): t is HTMLElement => t instanceof HTMLElement);
  }
  return [];
}

/** 创建动画引擎 */
export function createAnimationEngine() {
  let animeModule: AnimeModule | null = null;
  let loadAttempted = false;

  function tryLoadAnime(): AnimeModule | null {
    if (loadAttempted) return animeModule;
    loadAttempted = true;
    try {
      const g = globalThis as Record<string, unknown>;
      const a = g.anime as AnimeModule | undefined;
      if (a && typeof a.animate === 'function') animeModule = a;
    } catch { /* 降级 */ }
    return animeModule;
  }

  /** CSS 降级 */
  function cssFallback(
    targets: AnimationConfig['targets'],
    properties: AnimationConfig['properties'],
    duration: number,
    easing: string,
  ): AnimeInstance | null {
    const elements = resolveTargets(targets);
    if (!elements || elements.length === 0) return null;

    const styleElement = document.createElement('style');
    const animName = 'da-' + Date.now();
    const keyframes: string[] = [];

    for (const [prop, value] of Object.entries(properties)) {
      const cssProp = prop.replace(/([A-Z])/g, '-$1').toLowerCase();
      if (Array.isArray(value)) {
        keyframes.push('from { ' + cssProp + ': ' + value[0] + '; }');
        keyframes.push('to { ' + cssProp + ': ' + value[1] + '; }');
      } else {
        keyframes.push('to { ' + cssProp + ': ' + value + '; }');
      }
    }

    styleElement.textContent = '@keyframes ' + animName + ' { ' + keyframes.join(' ') + ' }';
    document.head.appendChild(styleElement);

    let completed = false;
    const finishPromise = new Promise<void>((resolve) => {
      const handler = () => {
        if (!completed) { completed = true; document.head.removeChild(styleElement); resolve(); }
      };
      elements.forEach((el) => {
        el.style.animation = animName + ' ' + duration + 'ms ' + easing + ' forwards';
        el.addEventListener('animationend', handler, { once: true });
      });
      setTimeout(handler, duration + 100);
    });

    return {
      play: () => {}, pause: () => {},
      restart: () => elements.forEach((el) => {
        el.style.animation = 'none'; void el.offsetHeight;
        el.style.animation = animName + ' ' + duration + 'ms ' + easing + ' forwards';
      }),
      reverse: () => {}, seek: () => {},
      finished: finishPromise,
    };
  }

  return {
    animate(config: AnimationConfig): AnimeInstance | null {
      const anime = tryLoadAnime();
      const duration = config.duration || 300;
      const easing = config.easing || EASINGS.default;

      if (anime) {
        return anime.animate(config.targets, {
          ...config.properties, duration, easing,
          delay: config.delay, loop: config.loop,
          alternate: config.alternate, autoplay: config.autoplay !== false,
        });
      }
      return cssFallback(config.targets, config.properties, duration, easing);
    },

    stagger(config: AnimationConfig, staggerValue = 50): AnimeInstance | null {
      const anime = tryLoadAnime();
      if (anime) {
        return anime.animate(config.targets, {
          ...config.properties,
          duration: config.duration || 300,
          easing: config.easing || EASINGS.default,
          delay: anime.stagger(staggerValue, { from: 'start' }),
        });
      }
      const elements = resolveTargets(config.targets);
      elements.forEach((el, i) => {
        setTimeout(() => this.animate({ ...config, targets: el }), i * staggerValue);
      });
      return null;
    },

    timeline(config?: TimelineConfig) {
      const anime = tryLoadAnime();
      if (!anime) return null;
      const tl = anime.timeline({ autoplay: config?.autoplay !== false, loop: config?.loop });
      return {
        add(animConfig: AnimationConfig, position?: number | string) {
          return tl.add({ ...animConfig.properties, ...animConfig }, position) as unknown as AnimeInstance;
        },
      };
    },

    scrollAnimation(config: {
      targets: AnimationConfig['targets'];
      properties: AnimationConfig['properties'];
      container?: HTMLElement | string;
      syncMode?: string;
    }) {
      const elements = resolveTargets(config.targets);
      if (elements.length === 0) return;
      const container = typeof config.container === 'string'
        ? document.querySelector(config.container)
        : config.container || null;

      const observer = new IntersectionObserver((entries) => {
        for (const entry of entries) {
          if (entry.isIntersecting) {
            this.animate({ targets: entry.target, properties: config.properties });
            if (config.syncMode === 'onenter') observer.unobserve(entry.target);
          }
        }
      }, { root: container instanceof HTMLElement ? container : null, threshold: 0.1 });

      elements.forEach((el) => observer.observe(el));
    },

    getEasing(name: keyof typeof EASINGS): string { return EASINGS[name]; },

    destroy() { animeModule = null; loadAttempted = false; },
  };
}

/** 入场动画预设 */
export const ENTRANCE_PRESETS = {
  fadeInUp: {
    properties: { opacity: [0, 1], translateY: [24, 0] },
    duration: 400, easing: EASINGS.default,
  },
  fadeInLeft: {
    properties: { opacity: [0, 1], translateX: [-24, 0] },
    duration: 400, easing: EASINGS.default,
  },
  fadeInRight: {
    properties: { opacity: [0, 1], translateX: [24, 0] },
    duration: 400, easing: EASINGS.default,
  },
  scaleIn: {
    properties: { opacity: [0, 1], scale: [0.95, 1] },
    duration: 350, easing: EASINGS.spring,
  },
  slideDown: {
    properties: { opacity: [0, 1], translateY: [-12, 0] },
    duration: 300, easing: EASINGS.out,
  },
} as const;

/** 悬停效果预设 */
export const HOVER_PRESETS = {
  gentleScale: {
    properties: { scale: [1, 1.03] },
    duration: 200, easing: EASINGS.out,
  },
  lift: {
    properties: {
      translateY: [0, -2],
      boxShadow: ['0 1px 3px rgba(0,0,0,0.06)', '0 8px 16px rgba(0,0,0,0.08)'],
    },
    duration: 250, easing: EASINGS.out,
  },
} as const;

/** 页面转场预设 */
export const PAGE_TRANSITIONS = {
  pageEnter: {
    properties: { opacity: [0, 1], translateY: [8, 0] },
    duration: 350, easing: EASINGS.out,
  },
  modalEnter: {
    properties: { opacity: [0, 1], scale: [0.96, 1] },
    duration: 250, easing: EASINGS.spring,
  },
  modalExit: {
    properties: { opacity: [1, 0], scale: [1, 0.96] },
    duration: 200, easing: EASINGS.in,
  },
} as const;
