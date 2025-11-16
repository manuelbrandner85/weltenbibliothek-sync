// Weltenbibliothek Cost Monitoring & Quota System
// Ensures all paid features stay within FREE quota limits

// FREE QUOTAS (Monthly Limits)
const FREE_QUOTAS = {
  agora: {
    minutes: 10000,        // 10,000 minutes/month FREE
    resetDay: 1,           // Reset on 1st of each month
    costPerMinute: 0.0      // Free until limit
  },
  gemini: {
    requests: 86400,       // 60 req/min = ~86,400/day theoretical max
    resetDay: 1,           // Daily reset
    costPerRequest: 0.0    // Always FREE
  }
};

// Storage key prefix
const STORAGE_PREFIX = 'weltenbibliothek_quota_';

// Get current month key (YYYY-MM)
function getCurrentMonthKey() {
  const now = new Date();
  return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;
}

// Get quota data from localStorage
function getQuotaData(service) {
  const monthKey = getCurrentMonthKey();
  const storageKey = `${STORAGE_PREFIX}${service}_${monthKey}`;
  const data = localStorage.getItem(storageKey);
  
  if (!data) {
    return {
      used: 0,
      lastReset: new Date().toISOString(),
      monthKey: monthKey
    };
  }
  
  return JSON.parse(data);
}

// Save quota data to localStorage
function saveQuotaData(service, data) {
  const monthKey = getCurrentMonthKey();
  const storageKey = `${STORAGE_PREFIX}${service}_${monthKey}`;
  localStorage.setItem(storageKey, JSON.stringify(data));
}

// Check if quota is available
function checkQuota(service, amount = 1) {
  const quota = FREE_QUOTAS[service];
  if (!quota) return { allowed: true, remaining: Infinity };
  
  const data = getQuotaData(service);
  
  // Check if we need to reset (new month)
  const currentMonth = getCurrentMonthKey();
  if (data.monthKey !== currentMonth) {
    data.used = 0;
    data.monthKey = currentMonth;
    data.lastReset = new Date().toISOString();
    saveQuotaData(service, data);
  }
  
  const remaining = quota.minutes || quota.requests - data.used;
  const allowed = remaining >= amount;
  
  return {
    allowed,
    remaining,
    used: data.used,
    limit: quota.minutes || quota.requests,
    resetDate: getNextResetDate()
  };
}

// Record usage
function recordUsage(service, amount) {
  const data = getQuotaData(service);
  data.used += amount;
  saveQuotaData(service, data);
  
  console.log(`[Cost Monitor] ${service}: Used ${amount}, Total: ${data.used}`);
  
  return data;
}

// Get next reset date
function getNextResetDate() {
  const now = new Date();
  const nextMonth = new Date(now.getFullYear(), now.getMonth() + 1, 1);
  return nextMonth.toLocaleDateString('de-DE');
}

// Format remaining quota for display
function formatQuotaDisplay(service) {
  const status = checkQuota(service, 0);
  const quota = FREE_QUOTAS[service];
  
  let unit = service === 'agora' ? 'Minuten' : 'Anfragen';
  let percentUsed = (status.used / status.limit * 100).toFixed(1);
  
  return {
    service: service === 'agora' ? 'Livestreaming (Agora)' : 'AI Chat (Gemini)',
    used: status.used,
    remaining: status.remaining,
    limit: status.limit,
    percentUsed: percentUsed,
    unit: unit,
    resetDate: status.resetDate,
    status: status.remaining > status.limit * 0.2 ? 'good' : 
            status.remaining > 0 ? 'warning' : 'exceeded'
  };
}

// Check Agora Livestream Quota (per minute)
function checkAgoraQuota() {
  return checkQuota('agora', 1); // Check 1 minute
}

// Track Agora usage (called every minute during stream)
let agoraTrackingInterval = null;

function startAgoraTracking() {
  if (agoraTrackingInterval) return;
  
  agoraTrackingInterval = setInterval(() => {
    const data = recordUsage('agora', 1); // 1 minute used
    
    const status = checkQuota('agora', 1);
    
    if (!status.allowed) {
      // Quota exceeded - stop stream immediately
      console.warn('[Cost Monitor] Agora quota exceeded - stopping stream');
      
      if (window.livestreamModule && typeof window.livestreamModule.stopLivestream === 'function') {
        window.livestreamModule.stopLivestream();
        
        alert(`⚠️ KOSTENLIMIT ERREICHT!\n\nDein kostenloses Livestreaming-Kontingent für diesen Monat ist aufgebraucht.\n\n📊 Verbrauch: ${status.used} / ${status.limit} Minuten\n🔄 Zurückgesetzt: ${status.resetDate}\n\nDer Stream wurde automatisch beendet.`);
      }
      
      stopAgoraTracking();
    } else if (status.remaining < 60) {
      // Warning: Less than 60 minutes left
      console.warn(`[Cost Monitor] Low quota: ${status.remaining} minutes remaining`);
      
      // Show warning toast (non-blocking)
      showQuotaWarning('agora', status.remaining);
    }
  }, 60000); // Every minute
}

function stopAgoraTracking() {
  if (agoraTrackingInterval) {
    clearInterval(agoraTrackingInterval);
    agoraTrackingInterval = null;
  }
}

// Check Gemini AI Quota
function checkGeminiQuota() {
  return checkQuota('gemini', 1); // Check 1 request
}

// Track Gemini usage
function recordGeminiUsage() {
  const data = recordUsage('gemini', 1);
  
  const status = checkQuota('gemini', 1);
  
  if (!status.allowed) {
    console.warn('[Cost Monitor] Gemini quota exceeded for today');
    return false; // Block request
  }
  
  return true; // Allow request
}

// Show quota warning toast
function showQuotaWarning(service, remaining) {
  const serviceName = service === 'agora' ? 'Livestreaming' : 'AI Chat';
  const unit = service === 'agora' ? 'Minuten' : 'Anfragen';
  
  // Create toast element
  const toast = document.createElement('div');
  toast.style.cssText = `
    position: fixed;
    top: 80px;
    right: 20px;
    background: rgba(245, 158, 11, 0.95);
    color: white;
    padding: 16px 20px;
    border-radius: 12px;
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
    z-index: 10000;
    max-width: 350px;
    animation: slideInRight 0.3s ease-out;
    backdrop-filter: blur(10px);
  `;
  
  toast.innerHTML = `
    <div style="display: flex; align-items: start; gap: 12px;">
      <i class="fas fa-exclamation-triangle" style="font-size: 24px; margin-top: 2px;"></i>
      <div>
        <div style="font-weight: 600; margin-bottom: 4px;">⚠️ Kontingent niedrig!</div>
        <div style="font-size: 14px; opacity: 0.95;">
          ${serviceName}: Nur noch ${remaining} ${unit} verfügbar in diesem Monat.
        </div>
      </div>
    </div>
  `;
  
  document.body.appendChild(toast);
  
  // Auto-remove after 5 seconds
  setTimeout(() => {
    toast.style.animation = 'fadeOut 0.3s ease-out';
    setTimeout(() => toast.remove(), 300);
  }, 5000);
}

// Get all quota status
function getAllQuotaStatus() {
  return {
    agora: formatQuotaDisplay('agora'),
    gemini: formatQuotaDisplay('gemini')
  };
}

// Show quota dashboard (called from UI)
function showQuotaDashboard() {
  const status = getAllQuotaStatus();
  
  const modalHTML = `
    <div class="modal" style="display: flex;">
      <div class="modal-content" style="max-width: 600px;">
        <div class="flex items-center justify-between mb-lg">
          <h2 class="text-2xl font-bold text-primary">
            <i class="fas fa-chart-bar mr-2"></i>
            Kostenlose Kontingente
          </h2>
          <button onclick="closeQuotaDashboard()" class="btn-icon btn-ghost">
            <i class="fas fa-times"></i>
          </button>
        </div>
        
        ${Object.values(status).map(s => `
          <div class="card mb-md">
            <div class="flex items-center justify-between mb-sm">
              <h3 class="font-semibold text-lg">${s.service}</h3>
              <span class="badge badge-${s.status === 'good' ? 'success' : s.status === 'warning' ? 'warning' : 'danger'}">
                ${s.percentUsed}% genutzt
              </span>
            </div>
            
            <div class="mb-sm">
              <div style="background: var(--surface-light); height: 8px; border-radius: 4px; overflow: hidden;">
                <div style="
                  width: ${s.percentUsed}%;
                  height: 100%;
                  background: linear-gradient(90deg, 
                    ${s.status === 'good' ? 'var(--success)' : s.status === 'warning' ? 'var(--warning)' : 'var(--danger)'}, 
                    ${s.status === 'good' ? 'var(--success)' : s.status === 'warning' ? 'var(--warning)' : 'var(--danger)'});
                  transition: width 0.3s ease;
                "></div>
              </div>
            </div>
            
            <div class="flex justify-between text-sm text-secondary">
              <span>Genutzt: ${s.used.toLocaleString()} ${s.unit}</span>
              <span>Verfügbar: ${s.remaining.toLocaleString()} ${s.unit}</span>
            </div>
            <div class="text-xs text-tertiary mt-xs">
              <i class="fas fa-sync-alt mr-1"></i>
              Zurückgesetzt am: ${s.resetDate}
            </div>
          </div>
        `).join('')}
        
        <div class="card" style="background: rgba(99, 102, 241, 0.1); border-color: var(--primary);">
          <div class="flex items-start gap-sm">
            <i class="fas fa-info-circle text-primary" style="font-size: 20px; margin-top: 2px;"></i>
            <div class="text-sm">
              <div class="font-semibold text-primary mb-xs">Automatischer Schutz aktiv</div>
              <div class="text-secondary">
                Alle kostenpflichtigen Features werden automatisch beendet, sobald das kostenlose Kontingent aufgebraucht ist.
                Am 1. des nächsten Monats werden die Kontingente zurückgesetzt.
              </div>
            </div>
          </div>
        </div>
        
        <div class="flex gap-sm mt-lg">
          <button onclick="closeQuotaDashboard()" class="flex-1 btn-secondary">
            Schließen
          </button>
        </div>
      </div>
    </div>
  `;
  
  // Remove existing dashboard if any
  const existing = document.getElementById('quota-dashboard');
  if (existing) existing.remove();
  
  const container = document.createElement('div');
  container.id = 'quota-dashboard';
  container.innerHTML = modalHTML;
  document.body.appendChild(container);
}

function closeQuotaDashboard() {
  const dashboard = document.getElementById('quota-dashboard');
  if (dashboard) dashboard.remove();
}

// Export functions for global access
window.costMonitor = {
  checkAgoraQuota,
  checkGeminiQuota,
  recordGeminiUsage,
  startAgoraTracking,
  stopAgoraTracking,
  showQuotaDashboard,
  getAllQuotaStatus,
  formatQuotaDisplay
};

console.log('[Cost Monitor] Loaded - Protecting against overage costs');
