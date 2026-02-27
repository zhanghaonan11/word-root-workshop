/**
 * LocalStorage + 可选云同步数据管理
 * 默认离线可用；开启同步码后支持云端同步
 */

const StorageManager = {
  KEYS: {
    PROGRESS: 'wordRootProgress',
    SETTINGS: 'wordRootSettings',
    ACHIEVEMENTS: 'wordRootAchievements',
    SYNC_CONFIG: 'wordRootSyncConfig',
    META: 'wordRootMeta'
  },
  AUTO_SYNC_DELAY_MS: 1200,
  autoSyncTimer: null,

  /**
   * 解析 JSON，失败时回退默认值
   */
  safeParse(data, fallback) {
    if (!data) return fallback;
    try {
      return JSON.parse(data);
    } catch (error) {
      console.warn('Storage parse error:', error);
      return fallback;
    }
  },

  /**
   * 获取元数据（修改时间、同步时间）
   */
  getMeta() {
    const meta = this.safeParse(localStorage.getItem(this.KEYS.META), {});
    return {
      lastModified: typeof meta.lastModified === 'string' ? meta.lastModified : null,
      lastSyncedAt: typeof meta.lastSyncedAt === 'string' ? meta.lastSyncedAt : null
    };
  },

  saveMeta(meta) {
    localStorage.setItem(this.KEYS.META, JSON.stringify(meta));
  },

  touchLastModified(timestamp = new Date().toISOString()) {
    const meta = this.getMeta();
    meta.lastModified = timestamp;
    this.saveMeta(meta);
    return meta;
  },

  setLastSyncedAt(timestamp = new Date().toISOString()) {
    const meta = this.getMeta();
    meta.lastSyncedAt = timestamp;
    this.saveMeta(meta);
    return meta;
  },

  /**
   * 同步码规范化（仅保留 A-Z/0-9/-/_）
   */
  normalizeSyncCode(syncCode) {
    return String(syncCode || '')
      .trim()
      .toUpperCase()
      .replace(/[^A-Z0-9_-]/g, '')
      .slice(0, 64);
  },

  getSyncConfig() {
    const config = this.safeParse(localStorage.getItem(this.KEYS.SYNC_CONFIG), {});
    return {
      syncCode: this.normalizeSyncCode(config.syncCode || '')
    };
  },

  saveSyncConfig(config) {
    localStorage.setItem(this.KEYS.SYNC_CONFIG, JSON.stringify(config));
  },

  setSyncCode(syncCode) {
    const normalizedCode = this.normalizeSyncCode(syncCode);
    if (!normalizedCode) {
      throw new Error('同步码不能为空或格式无效');
    }
    this.saveSyncConfig({ syncCode: normalizedCode });
    return normalizedCode;
  },

  clearSyncCode() {
    localStorage.removeItem(this.KEYS.SYNC_CONFIG);
  },

  isCloudSyncEnabled() {
    return Boolean(this.getSyncConfig().syncCode);
  },

  /**
   * 获取学习进度数据
   */
  getProgress() {
    const data = this.safeParse(localStorage.getItem(this.KEYS.PROGRESS), null);
    if (!data) {
      return this.initProgress();
    }
    const meta = this.getMeta();

    return {
      level: Number.isFinite(data.level) ? data.level : 1,
      masteredRoots: Array.isArray(data.masteredRoots) ? data.masteredRoots : [],
      currentRootIndex: Number.isFinite(data.currentRootIndex) ? data.currentRootIndex : 0,
      totalScore: Number.isFinite(data.totalScore) ? data.totalScore : 0,
      lastStudyDate: data.lastStudyDate || new Date().toISOString(),
      studyStreak: Number.isFinite(data.studyStreak) ? data.studyStreak : 0,
      sessionCount: Number.isFinite(data.sessionCount) ? data.sessionCount : 0,
      updatedAt: data.updatedAt || meta.lastModified || data.lastStudyDate || new Date().toISOString()
    };
  },

  /**
   * 初始化进度数据
   */
  initProgress() {
    const initialData = {
      level: 1,
      masteredRoots: [],
      currentRootIndex: 0,
      totalScore: 0,
      lastStudyDate: new Date().toISOString(),
      studyStreak: 0,
      sessionCount: 0,
      updatedAt: new Date().toISOString()
    };
    this.saveProgress(initialData, { skipSync: true });
    return initialData;
  },

  /**
   * 保存进度数据
   */
  saveProgress(data = {}, options = {}) {
    const updatedAt = options.updatedAt || new Date().toISOString();
    const progressData = {
      level: Number.isFinite(data.level) ? data.level : 1,
      masteredRoots: Array.isArray(data.masteredRoots) ? data.masteredRoots : [],
      currentRootIndex: Number.isFinite(data.currentRootIndex) ? data.currentRootIndex : 0,
      totalScore: Number.isFinite(data.totalScore) ? data.totalScore : 0,
      lastStudyDate: data.lastStudyDate || new Date().toISOString(),
      studyStreak: Number.isFinite(data.studyStreak) ? data.studyStreak : 0,
      sessionCount: Number.isFinite(data.sessionCount) ? data.sessionCount : 0,
      updatedAt
    };

    localStorage.setItem(this.KEYS.PROGRESS, JSON.stringify(progressData));

    if (!options.skipModifiedTouch) {
      this.touchLastModified(updatedAt);
    }
    if (!options.skipSync) {
      this.scheduleAutoCloudSync();
    }

    return progressData;
  },

  saveAchievements(achievements, options = {}) {
    const list = Array.isArray(achievements) ? achievements : [];
    const updatedAt = options.updatedAt || new Date().toISOString();
    localStorage.setItem(this.KEYS.ACHIEVEMENTS, JSON.stringify(list));

    if (!options.skipModifiedTouch) {
      this.touchLastModified(updatedAt);
    }
    if (!options.skipSync) {
      this.scheduleAutoCloudSync();
    }
    return list;
  },

  /**
   * 标记词根为已掌握
   */
  markRootAsMastered(rootId) {
    const progress = this.getProgress();
    if (!progress.masteredRoots.includes(rootId)) {
      progress.masteredRoots.push(rootId);
      progress.totalScore += 10;

      const newLevel = Math.floor(progress.masteredRoots.length / 10) + 1;
      if (newLevel > progress.level) {
        progress.level = newLevel;
        this.unlockAchievement('levelUp', newLevel);
      }

      this.saveProgress(progress);
    }
    return progress;
  },

  /**
   * 更新连续学习天数
   */
  updateStudyStreak() {
    const progress = this.getProgress();
    const today = new Date().toDateString();
    const lastStudy = new Date(progress.lastStudyDate).toDateString();

    if (today !== lastStudy) {
      const yesterday = new Date();
      yesterday.setDate(yesterday.getDate() - 1);
      const yesterdayStr = yesterday.toDateString();

      if (lastStudy === yesterdayStr) {
        progress.studyStreak += 1;
      } else {
        progress.studyStreak = 1;
      }

      progress.lastStudyDate = new Date().toISOString();
      progress.sessionCount += 1;

      if (progress.studyStreak === 7) {
        this.unlockAchievement('streak7');
      } else if (progress.studyStreak === 30) {
        this.unlockAchievement('streak30');
      }

      this.saveProgress(progress);
    }

    return progress.studyStreak;
  },

  /**
   * 获取成就列表
   */
  getAchievements() {
    return this.safeParse(localStorage.getItem(this.KEYS.ACHIEVEMENTS), []);
  },

  /**
   * 解锁成就
   */
  unlockAchievement(type, value = null) {
    const achievements = this.getAchievements();
    const timestamp = new Date().toISOString();

    let newAchievement = null;

    switch (type) {
      case 'levelUp':
        newAchievement = {
          id: `level_${value}`,
          type: 'level',
          title: `等级 ${value}`,
          description: `恭喜升级到 Lv.${value}！`,
          icon: '⭐',
          unlockedAt: timestamp
        };
        break;
      case 'streak7':
        newAchievement = {
          id: 'streak_7',
          type: 'streak',
          title: '七日修行',
          description: '连续学习 7 天',
          icon: '🔥',
          unlockedAt: timestamp
        };
        break;
      case 'streak30':
        newAchievement = {
          id: 'streak_30',
          type: 'streak',
          title: '月度大师',
          description: '连续学习 30 天',
          icon: '👑',
          unlockedAt: timestamp
        };
        break;
      case 'firstRoot':
        newAchievement = {
          id: 'first_root',
          type: 'milestone',
          title: '初出茅庐',
          description: '掌握第一个词根',
          icon: '🌱',
          unlockedAt: timestamp
        };
        break;
      case 'roots50':
        newAchievement = {
          id: 'roots_50',
          type: 'milestone',
          title: '小有所成',
          description: '掌握 50 个词根',
          icon: '🎯',
          unlockedAt: timestamp
        };
        break;
      case 'roots100':
        newAchievement = {
          id: 'roots_100',
          type: 'milestone',
          title: '百词宗师',
          description: '掌握 100 个词根',
          icon: '💎',
          unlockedAt: timestamp
        };
        break;
      default:
        break;
    }

    if (newAchievement && !achievements.find(a => a.id === newAchievement.id)) {
      achievements.push(newAchievement);
      this.saveAchievements(achievements, { updatedAt: timestamp });
      this.showAchievementNotification(newAchievement);
    }
  },

  /**
   * 显示成就解锁通知
   */
  showAchievementNotification(achievement) {
    const notification = document.createElement('div');
    notification.className = 'fixed top-24 right-4 z-50 clay-card bg-white p-4 animate-bounce';
    notification.innerHTML = `
      <div class="flex items-center space-x-3">
        <span class="text-3xl">${achievement.icon}</span>
        <div>
          <div class="font-heading font-bold text-primary">🎉 成就解锁！</div>
          <div class="text-sm text-textMain/80">${achievement.title}</div>
        </div>
      </div>
    `;

    document.body.appendChild(notification);

    setTimeout(() => {
      notification.style.transition = 'opacity 300ms';
      notification.style.opacity = '0';
      setTimeout(() => notification.remove(), 300);
    }, 3000);
  },

  /**
   * 导出数据（用于备份或迁移）
   */
  exportData() {
    const meta = this.getMeta();
    return {
      version: 1,
      progress: this.getProgress(),
      achievements: this.getAchievements(),
      lastModified: meta.lastModified,
      exportDate: new Date().toISOString()
    };
  },

  /**
   * 导入数据
   */
  importData(data, options = {}) {
    if (!data || typeof data !== 'object' || !data.progress) {
      throw new Error('导入失败：缺少 progress 字段');
    }

    const modifiedAt = data.lastModified || data.progress.updatedAt || new Date().toISOString();

    this.saveProgress(data.progress, {
      updatedAt: modifiedAt,
      skipSync: true,
      skipModifiedTouch: true
    });

    if (Array.isArray(data.achievements)) {
      this.saveAchievements(data.achievements, {
        updatedAt: modifiedAt,
        skipSync: true,
        skipModifiedTouch: true
      });
    }

    this.touchLastModified(modifiedAt);

    if (!options.skipSync) {
      this.scheduleAutoCloudSync();
    }
  },

  /**
   * 生成云同步负载
   */
  buildSyncPayload() {
    const progress = this.getProgress();
    const achievements = this.getAchievements();
    const meta = this.getMeta();
    const lastModified = meta.lastModified || progress.updatedAt || new Date().toISOString();

    return {
      version: 1,
      progress,
      achievements,
      lastModified
    };
  },

  applySyncPayload(payload) {
    this.importData(payload, { skipSync: true });
  },

  scheduleAutoCloudSync() {
    if (!this.isCloudSyncEnabled()) return;
    if (!window.CloudSyncManager) return;

    if (this.autoSyncTimer) {
      clearTimeout(this.autoSyncTimer);
    }

    this.autoSyncTimer = setTimeout(() => {
      window.CloudSyncManager.syncNow('push', { silent: true }).catch((error) => {
        console.warn('Auto cloud sync failed:', error);
      });
    }, this.AUTO_SYNC_DELAY_MS);
  },

  /**
   * 清除所有数据（重置）
   */
  clearAll(options = { confirm: true }) {
    const shouldConfirm = options.confirm !== false;
    if (shouldConfirm && !confirm('确定要清除所有学习数据吗？此操作不可恢复！')) {
      return false;
    }

    localStorage.removeItem(this.KEYS.PROGRESS);
    localStorage.removeItem(this.KEYS.ACHIEVEMENTS);
    localStorage.removeItem(this.KEYS.SETTINGS);
    localStorage.removeItem(this.KEYS.META);
    window.location.reload();
    return true;
  }
};

const CloudSyncManager = {
  ENDPOINT: '/api/sync',

  generateSyncCode() {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    let randomPart = '';

    if (window.crypto && window.crypto.getRandomValues) {
      const randomBytes = new Uint8Array(10);
      window.crypto.getRandomValues(randomBytes);
      randomPart = Array.from(randomBytes, byte => alphabet[byte % alphabet.length]).join('');
    } else {
      for (let i = 0; i < 10; i += 1) {
        randomPart += alphabet[Math.floor(Math.random() * alphabet.length)];
      }
    }

    return `WR-${randomPart}`;
  },

  humanizeError(errorCode) {
    const normalized = String(errorCode || '').toLowerCase();
    if (normalized.includes('kv_not_configured')) return '服务端尚未配置云存储';
    if (normalized.includes('invalid_sync_code')) return '同步码格式不正确';
    if (normalized.includes('invalid_payload')) return '同步数据格式不正确';
    if (normalized.includes('fetch failed')) return '网络异常，请稍后重试';
    return String(errorCode || '未知错误');
  },

  async request(method, { code, payload, strategy } = {}) {
    if (!code) {
      throw new Error('请先设置同步码');
    }

    const isGet = method === 'GET';
    const url = isGet
      ? `${this.ENDPOINT}?code=${encodeURIComponent(code)}`
      : this.ENDPOINT;

    const response = await fetch(url, {
      method,
      headers: {
        'Content-Type': 'application/json'
      },
      body: isGet ? undefined : JSON.stringify({ code, payload, strategy })
    });

    let result = null;
    try {
      result = await response.json();
    } catch (error) {
      result = null;
    }

    if (!response.ok || !result || result.ok === false) {
      const reason = (result && (result.error || result.message)) || `HTTP ${response.status}`;
      throw new Error(this.humanizeError(reason));
    }

    return result;
  },

  async pull(syncCode = StorageManager.getSyncConfig().syncCode) {
    const code = StorageManager.normalizeSyncCode(syncCode);
    return this.request('GET', { code });
  },

  async push(syncCode = StorageManager.getSyncConfig().syncCode, payload = StorageManager.buildSyncPayload(), strategy = 'if-newer') {
    const code = StorageManager.normalizeSyncCode(syncCode);
    return this.request('POST', { code, payload, strategy });
  },

  getPayloadModifiedAt(payload) {
    return Date.parse(
      (payload && (payload.lastModified || (payload.progress && payload.progress.updatedAt))) ||
      0
    );
  },

  async syncNow(mode = 'smart', options = {}) {
    const silent = Boolean(options.silent);
    const syncCode = StorageManager.getSyncConfig().syncCode;
    if (!syncCode) {
      throw new Error('请先在进度页设置同步码');
    }

    try {
      if (mode === 'push') {
        await this.push(syncCode, StorageManager.buildSyncPayload(), 'if-newer');
        StorageManager.setLastSyncedAt();
        return { action: 'push' };
      }

      if (mode === 'pull') {
        const remote = await this.pull(syncCode);
        if (!remote.present || !remote.data) {
          if (!silent) alert('云端暂无可下载的数据');
          return { action: 'none', reason: 'remote_empty' };
        }

        StorageManager.applySyncPayload(remote.data);
        StorageManager.setLastSyncedAt(remote.serverUpdatedAt || new Date().toISOString());
        return { action: 'pull' };
      }

      const localPayload = StorageManager.buildSyncPayload();
      const remote = await this.pull(syncCode);

      if (!remote.present || !remote.data) {
        await this.push(syncCode, localPayload, 'if-newer');
        StorageManager.setLastSyncedAt();
        return { action: 'push', reason: 'remote_empty' };
      }

      const localTime = this.getPayloadModifiedAt(localPayload);
      const remoteTime = this.getPayloadModifiedAt(remote.data);

      if (Number.isNaN(remoteTime) || localTime >= remoteTime) {
        await this.push(syncCode, localPayload, 'if-newer');
        StorageManager.setLastSyncedAt();
        return { action: 'push', reason: 'local_newer' };
      }

      StorageManager.applySyncPayload(remote.data);
      StorageManager.setLastSyncedAt(remote.serverUpdatedAt || new Date().toISOString());
      return { action: 'pull', reason: 'remote_newer' };
    } catch (error) {
      if (!silent) {
        alert(`同步失败：${error.message}`);
      }
      throw error;
    }
  },

  async maybeSyncOnBoot() {
    if (!StorageManager.isCloudSyncEnabled()) return;

    const meta = StorageManager.getMeta();
    const lastSyncedAtMs = Date.parse(meta.lastSyncedAt || 0);
    const now = Date.now();
    const twelveHours = 12 * 60 * 60 * 1000;

    if (!Number.isNaN(lastSyncedAtMs) && now - lastSyncedAtMs < twelveHours) {
      return;
    }

    try {
      await this.syncNow('smart', { silent: true });
    } catch (error) {
      console.warn('Cloud boot sync skipped:', error);
    }
  }
};

window.StorageManager = StorageManager;
window.CloudSyncManager = CloudSyncManager;

// 页面加载时更新学习连续性，并尝试轻量自动同步
document.addEventListener('DOMContentLoaded', () => {
  StorageManager.updateStudyStreak();
  CloudSyncManager.maybeSyncOnBoot();
});
