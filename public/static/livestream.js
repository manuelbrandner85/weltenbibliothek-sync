// Weltenbibliothek Livestreaming Module (Agora RTC)
// Requires: agora-rtc-sdk-ng
// Note: This is for browser-based import, use CDN version

// ✅ Agora App ID konfiguriert
// Account: https://console.agora.io
const AGORA_APP_ID = "7f9011a9b696435aac64bb04b87c0919";

let agoraClient = null;
let localAudioTrack = null;
let localVideoTrack = null;
let isLivestreaming = false;
let currentStreamChatId = null;
let remoteUsers = {};

// Initialize Agora Client (dynamically imported)
async function initAgoraClient() {
  if (agoraClient) return agoraClient;
  
  // Dynamically import Agora SDK from CDN
  if (!window.AgoraRTC) {
    const script = document.createElement('script');
    script.src = 'https://cdn.jsdelivr.net/npm/agora-rtc-sdk-ng@4.20.0/dist/AgoraRTC_N-4.20.0.js';
    document.head.appendChild(script);
    
    await new Promise((resolve) => {
      script.onload = resolve;
    });
  }
  
  const AgoraRTC = window.AgoraRTC;
  agoraClient = AgoraRTC.createClient({ mode: "rtc", codec: "vp8" });
  
  // Event listeners
  agoraClient.on("user-published", handleUserPublished);
  agoraClient.on("user-unpublished", handleUserUnpublished);
  agoraClient.on("user-left", handleUserLeft);
  
  return agoraClient;
}

// Start Livestream
async function startLivestream(chatId) {
  try {
    if (AGORA_APP_ID === "YOUR_AGORA_APP_ID") {
      alert('⚠️ Agora App ID fehlt!\n\nBitte erstelle einen kostenlosen Account bei:\nhttps://console.agora.io\n\nund trage deine App ID in livestream.js ein.');
      return;
    }
    
    // Check quota BEFORE starting stream
    if (window.costMonitor) {
      const quotaCheck = window.costMonitor.checkAgoraQuota();
      
      if (!quotaCheck.allowed) {
        alert(`⚠️ KOSTENLIMIT ERREICHT!\n\nDein kostenloses Livestreaming-Kontingent ist aufgebraucht.\n\n📊 Verbrauch: ${quotaCheck.used} / ${quotaCheck.limit} Minuten\n🔄 Zurückgesetzt am: ${quotaCheck.resetDate}\n\nBitte warte bis zum nächsten Monat oder upgrade deinen Account.`);
        return;
      }
      
      // Show warning if less than 100 minutes remaining
      if (quotaCheck.remaining < 100) {
        const proceed = confirm(`⚠️ Niedriges Kontingent!\n\nNur noch ${quotaCheck.remaining} kostenlose Minuten verfügbar.\n\nStream trotzdem starten?`);
        if (!proceed) return;
      }
    }
    
    currentStreamChatId = chatId;
    
    // Initialize client
    await initAgoraClient();
    
    // Generate token (in production, get from your server)
    // For testing: Use null token (only works with App ID in testing mode)
    const token = null;
    const uid = null; // Let Agora assign UID
    
    // Join channel
    const channelName = `chat_${chatId}`;
    await agoraClient.join(AGORA_APP_ID, channelName, token, uid);
    
    // Create local tracks
    localAudioTrack = await window.AgoraRTC.createMicrophoneAudioTrack();
    localVideoTrack = await window.AgoraRTC.createCameraVideoTrack({
      encoderConfig: "720p_2" // 1280x720, 30fps
    });
    
    // Publish tracks
    await agoraClient.publish([localAudioTrack, localVideoTrack]);
    
    // Display local video
    const localPlayer = document.getElementById('local-video-player');
    if (localPlayer) {
      localVideoTrack.play(localPlayer);
    }
    
    isLivestreaming = true;
    
    // Show livestream UI
    showLivestreamUI();
    
    // Start cost tracking (monitors usage per minute)
    if (window.costMonitor) {
      window.costMonitor.startAgoraTracking();
      console.log('[Agora] Cost tracking started');
    }
    
    console.log('Livestream started successfully');
  } catch (error) {
    console.error('Error starting livestream:', error);
    alert(`Fehler beim Starten des Livestreams:\n${error.message}`);
  }
}

// Stop Livestream
async function stopLivestream() {
  try {
    // Close local tracks
    if (localAudioTrack) {
      localAudioTrack.close();
      localAudioTrack = null;
    }
    
    if (localVideoTrack) {
      localVideoTrack.close();
      localVideoTrack = null;
    }
    
    // Leave channel
    if (agoraClient) {
      await agoraClient.leave();
    }
    
    // Clear remote users
    remoteUsers = {};
    
    isLivestreaming = false;
    currentStreamChatId = null;
    
    // Stop cost tracking
    if (window.costMonitor) {
      window.costMonitor.stopAgoraTracking();
      console.log('[Agora] Cost tracking stopped');
    }
    
    // Hide livestream UI
    hideLivestreamUI();
    
    console.log('Livestream stopped');
  } catch (error) {
    console.error('Error stopping livestream:', error);
  }
}

// Toggle Audio (Mute/Unmute)
async function toggleAudio() {
  if (!localAudioTrack) return;
  
  const isMuted = !localAudioTrack.enabled;
  await localAudioTrack.setEnabled(isMuted);
  
  const btn = document.getElementById('btn-toggle-audio');
  if (btn) {
    btn.innerHTML = isMuted 
      ? '<i class="fas fa-microphone"></i>' 
      : '<i class="fas fa-microphone-slash"></i>';
    btn.classList.toggle('btn-danger', !isMuted);
  }
}

// Toggle Video (Camera On/Off)
async function toggleVideo() {
  if (!localVideoTrack) return;
  
  const isEnabled = !localVideoTrack.enabled;
  await localVideoTrack.setEnabled(isEnabled);
  
  const btn = document.getElementById('btn-toggle-video');
  if (btn) {
    btn.innerHTML = isEnabled 
      ? '<i class="fas fa-video"></i>' 
      : '<i class="fas fa-video-slash"></i>';
    btn.classList.toggle('btn-danger', !isEnabled);
  }
}

// Handle Remote User Published
async function handleUserPublished(user, mediaType) {
  try {
    await agoraClient.subscribe(user, mediaType);
    
    if (mediaType === 'video') {
      remoteUsers[user.uid] = user;
      
      // Create player div for remote user
      const remoteContainer = document.getElementById('remote-videos');
      if (!remoteContainer) return;
      
      let playerDiv = document.getElementById(`remote-player-${user.uid}`);
      if (!playerDiv) {
        playerDiv = document.createElement('div');
        playerDiv.id = `remote-player-${user.uid}`;
        playerDiv.className = 'video-tile glass';
        playerDiv.innerHTML = `
          <div class="video-overlay">
            <span class="badge badge-danger">LIVE</span>
            <span class="username">User ${user.uid}</span>
          </div>
        `;
        remoteContainer.appendChild(playerDiv);
      }
      
      user.videoTrack.play(playerDiv);
    }
    
    if (mediaType === 'audio') {
      user.audioTrack.play();
    }
  } catch (error) {
    console.error('Error handling user published:', error);
  }
}

// Handle Remote User Unpublished
function handleUserUnpublished(user, mediaType) {
  if (mediaType === 'video') {
    const playerDiv = document.getElementById(`remote-player-${user.uid}`);
    if (playerDiv) {
      playerDiv.remove();
    }
  }
}

// Handle Remote User Left
function handleUserLeft(user) {
  delete remoteUsers[user.uid];
  const playerDiv = document.getElementById(`remote-player-${user.uid}`);
  if (playerDiv) {
    playerDiv.remove();
  }
}

// Show Livestream UI
function showLivestreamUI() {
  const container = document.getElementById('livestream-container');
  if (container) {
    container.classList.remove('hidden');
  }
  
  // Hide messages container
  const messages = document.getElementById('messages-container');
  if (messages) {
    messages.classList.add('hidden');
  }
}

// Hide Livestream UI
function hideLivestreamUI() {
  const container = document.getElementById('livestream-container');
  if (container) {
    container.classList.add('hidden');
  }
  
  // Show messages container
  const messages = document.getElementById('messages-container');
  if (messages) {
    messages.classList.remove('hidden');
  }
  
  // Clear remote videos
  const remoteContainer = document.getElementById('remote-videos');
  if (remoteContainer) {
    remoteContainer.innerHTML = '';
  }
}

// Toggle Minimize Stream (Picture-in-Picture)
function toggleMinimizeStream() {
  const container = document.getElementById('livestream-container');
  if (!container) return;
  
  container.classList.toggle('minimized');
  
  // Show/hide chat messages
  const messages = document.getElementById('messages-container');
  if (messages) {
    messages.classList.toggle('hidden');
  }
}

// Expand Stream (from minimized)
function expandStream() {
  const container = document.getElementById('livestream-container');
  if (!container) return;
  
  container.classList.remove('minimized');
  
  // Hide chat messages
  const messages = document.getElementById('messages-container');
  if (messages) {
    messages.classList.add('hidden');
  }
}

// Export functions for global access
window.livestreamModule = {
  startLivestream,
  stopLivestream,
  toggleAudio,
  toggleVideo,
  toggleMinimizeStream,
  expandStream,
  isLivestreaming: () => isLivestreaming
};

console.log('Livestream module loaded');
