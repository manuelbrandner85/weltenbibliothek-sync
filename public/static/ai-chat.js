// Weltenbibliothek AI Chat Module (Google Gemini)
// KOSTENLOS: 60 Anfragen/Minute

const GEMINI_API_KEY = "AIzaSyB31CamtfNJv7eymRqah-dYkUxqvB5mex8";
const GEMINI_API_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent";
const GEMINI_VISION_API_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro-vision:generateContent";

// Web Speech API for Voice Recognition (completely FREE)
let recognition = null;
let isListening = false;

// Initialize Web Speech API
function initSpeechRecognition() {
  if (!('webkitSpeechRecognition' in window) && !('SpeechRecognition' in window)) {
    console.warn('Speech Recognition not supported');
    return null;
  }
  
  const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
  recognition = new SpeechRecognition();
  recognition.lang = 'de-DE';
  recognition.continuous = false;
  recognition.interimResults = false;
  
  recognition.onresult = (event) => {
    const transcript = event.results[0][0].transcript;
    console.log('Voice transcript:', transcript);
    
    // Display transcript in input
    const input = document.getElementById('ai-chat-input');
    if (input) {
      input.value = transcript;
    }
    
    // Automatically send to AI
    sendMessageToAI(transcript);
  };
  
  recognition.onerror = (event) => {
    console.error('Speech recognition error:', event.error);
    isListening = false;
    updateVoiceButton(false);
  };
  
  recognition.onend = () => {
    isListening = false;
    updateVoiceButton(false);
  };
  
  return recognition;
}

// Toggle Voice Recognition
function toggleVoiceRecognition() {
  if (!recognition) {
    recognition = initSpeechRecognition();
    if (!recognition) {
      alert('⚠️ Spracherkennung nicht verfügbar\n\nDein Browser unterstützt keine Spracherkennung.\n\nVerwende Chrome, Edge oder Safari.');
      return;
    }
  }
  
  if (isListening) {
    recognition.stop();
    isListening = false;
    updateVoiceButton(false);
  } else {
    recognition.start();
    isListening = true;
    updateVoiceButton(true);
  }
}

// Update Voice Button UI
function updateVoiceButton(listening) {
  const btn = document.getElementById('btn-voice-input');
  if (!btn) return;
  
  if (listening) {
    btn.classList.add('animate-pulse');
    btn.style.color = 'var(--danger)';
  } else {
    btn.classList.remove('animate-pulse');
    btn.style.color = '';
  }
}

// Send Message to Gemini AI
async function sendMessageToAI(message) {
  try {
    if (!message.trim()) {
      throw new Error('Nachricht darf nicht leer sein');
    }
    
    // Add user message to chat
    addMessageToAIChat('user', message);
    
    // Show loading indicator
    const loadingId = addLoadingToAIChat();
    
    // Call Gemini API
    const response = await fetch(`${GEMINI_API_URL}?key=${GEMINI_API_KEY}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        contents: [{
          parts: [{
            text: message
          }]
        }],
        generationConfig: {
          temperature: 0.7,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 1024,
        }
      })
    });
    
    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.error?.message || 'API Fehler');
    }
    
    const data = await response.json();
    const aiResponse = data.candidates[0]?.content?.parts[0]?.text || 'Keine Antwort erhalten';
    
    // Remove loading indicator
    removeLoadingFromAIChat(loadingId);
    
    // Add AI response to chat
    addMessageToAIChat('ai', aiResponse);
    
    // Speak response (optional)
    speakText(aiResponse);
    
  } catch (error) {
    console.error('Error calling Gemini API:', error);
    
    // Remove loading if exists
    const loading = document.querySelector('.ai-message.loading');
    if (loading) loading.remove();
    
    // Show error
    addMessageToAIChat('error', `❌ Fehler: ${error.message}`);
  }
}

// Analyze Image with Gemini Vision
async function analyzeImageWithAI(imageDataUrl, prompt = "Was siehst du in diesem Bild?") {
  try {
    // Remove data:image/jpeg;base64, prefix
    const base64Data = imageDataUrl.split(',')[1];
    
    // Show loading
    const loadingId = addLoadingToAIChat();
    
    const response = await fetch(`${GEMINI_VISION_API_URL}?key=${GEMINI_API_KEY}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        contents: [{
          parts: [
            { text: prompt },
            {
              inline_data: {
                mime_type: 'image/jpeg',
                data: base64Data
              }
            }
          ]
        }]
      })
    });
    
    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.error?.message || 'Vision API Fehler');
    }
    
    const data = await response.json();
    const aiResponse = data.candidates[0]?.content?.parts[0]?.text || 'Keine Analyse möglich';
    
    // Remove loading
    removeLoadingFromAIChat(loadingId);
    
    // Add response
    addMessageToAIChat('ai', `🖼️ Bildanalyse:\n${aiResponse}`);
    
  } catch (error) {
    console.error('Error analyzing image:', error);
    
    const loading = document.querySelector('.ai-message.loading');
    if (loading) loading.remove();
    
    addMessageToAIChat('error', `❌ Bildanalyse fehlgeschlagen: ${error.message}`);
  }
}

// Capture Video Frame and Analyze
async function captureAndAnalyzeVideoFrame() {
  try {
    const video = document.querySelector('#local-video-player video');
    if (!video) {
      throw new Error('Kein Video aktiv');
    }
    
    const canvas = document.createElement('canvas');
    canvas.width = video.videoWidth;
    canvas.height = video.videoHeight;
    const ctx = canvas.getContext('2d');
    ctx.drawImage(video, 0, 0);
    
    const imageDataUrl = canvas.toDataURL('image/jpeg', 0.8);
    
    await analyzeImageWithAI(imageDataUrl, 'Beschreibe was du in diesem Video-Frame siehst.');
    
  } catch (error) {
    console.error('Error capturing video frame:', error);
    alert(`Fehler: ${error.message}`);
  }
}

// Add Message to AI Chat UI
function addMessageToAIChat(type, content) {
  const container = document.getElementById('ai-chat-messages');
  if (!container) return;
  
  const messageDiv = document.createElement('div');
  messageDiv.className = `ai-message ${type}`;
  
  if (type === 'user') {
    messageDiv.innerHTML = `
      <div class="message own">
        <div class="message-content">
          <div class="message-text">${escapeHtml(content)}</div>
        </div>
      </div>
    `;
  } else if (type === 'ai') {
    messageDiv.innerHTML = `
      <div class="message">
        <div class="message-avatar">
          <div class="avatar-sm" style="background: linear-gradient(135deg, var(--accent), var(--secondary));">
            <i class="fas fa-robot"></i>
          </div>
        </div>
        <div class="message-content">
          <div class="message-sender">AI Assistant</div>
          <div class="message-text">${formatAIResponse(content)}</div>
        </div>
      </div>
    `;
  } else if (type === 'error') {
    messageDiv.innerHTML = `
      <div class="text-center" style="color: var(--danger); padding: var(--spacing-md);">
        ${escapeHtml(content)}
      </div>
    `;
  }
  
  container.appendChild(messageDiv);
  container.scrollTop = container.scrollHeight;
}

// Add Loading Indicator
function addLoadingToAIChat() {
  const container = document.getElementById('ai-chat-messages');
  if (!container) return null;
  
  const loadingId = 'loading-' + Date.now();
  const loadingDiv = document.createElement('div');
  loadingDiv.id = loadingId;
  loadingDiv.className = 'ai-message loading';
  loadingDiv.innerHTML = `
    <div class="message">
      <div class="message-avatar">
        <div class="avatar-sm animate-pulse" style="background: linear-gradient(135deg, var(--accent), var(--secondary));">
          <i class="fas fa-robot"></i>
        </div>
      </div>
      <div class="message-content">
        <div class="message-sender">AI Assistant</div>
        <div class="message-text">
          <i class="fas fa-spinner fa-spin mr-2"></i>
          Denkt nach...
        </div>
      </div>
    </div>
  `;
  
  container.appendChild(loadingDiv);
  container.scrollTop = container.scrollHeight;
  
  return loadingId;
}

// Remove Loading Indicator
function removeLoadingFromAIChat(loadingId) {
  const loading = document.getElementById(loadingId);
  if (loading) {
    loading.remove();
  }
}

// Format AI Response (basic markdown-like formatting)
function formatAIResponse(text) {
  // Escape HTML first
  text = escapeHtml(text);
  
  // Convert **bold** to <strong>
  text = text.replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>');
  
  // Convert *italic* to <em>
  text = text.replace(/\*(.*?)\*/g, '<em>$1</em>');
  
  // Convert line breaks
  text = text.replace(/\n/g, '<br>');
  
  return text;
}

// Text-to-Speech (Browser native, completely FREE)
function speakText(text) {
  if (!('speechSynthesis' in window)) {
    console.warn('Text-to-Speech not supported');
    return;
  }
  
  // Cancel any ongoing speech
  window.speechSynthesis.cancel();
  
  const utterance = new SpeechSynthesisUtterance(text);
  utterance.lang = 'de-DE';
  utterance.rate = 1.0;
  utterance.pitch = 1.0;
  utterance.volume = 0.8;
  
  window.speechSynthesis.speak(utterance);
}

// Stop Text-to-Speech
function stopSpeaking() {
  if ('speechSynthesis' in window) {
    window.speechSynthesis.cancel();
  }
}

// Utility: Escape HTML
function escapeHtml(text) {
  const div = document.createElement('div');
  div.textContent = text;
  return div.innerHTML;
}

// Export functions for global access
window.aiChatModule = {
  sendMessageToAI,
  toggleVoiceRecognition,
  analyzeImageWithAI,
  captureAndAnalyzeVideoFrame,
  speakText,
  stopSpeaking
};

console.log('AI Chat module loaded (Gemini API)');
