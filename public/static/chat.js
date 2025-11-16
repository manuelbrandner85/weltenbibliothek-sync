// Weltenbibliothek Chat JavaScript
const API_URL = window.location.origin;
let currentUser = null;
let currentChatId = null;
let chats = [];
let messages = [];
let messagePollingInterval = null;

// Initialize
document.addEventListener('DOMContentLoaded', () => {
    checkAuth();
});

// Check authentication
function checkAuth() {
    const token = localStorage.getItem('auth_token');
    const user = localStorage.getItem('user');
    
    if (!token || !user) {
        window.location.href = '/static/auth.html';
        return;
    }
    
    currentUser = JSON.parse(user);
    displayUserInfo();
    loadChats();
}

// Display user info
function displayUserInfo() {
    document.getElementById('user-display-name').textContent = currentUser.display_name || currentUser.username;
    document.getElementById('user-username').textContent = `@${currentUser.username}`;
    document.getElementById('user-initials').textContent = getInitials(currentUser.display_name || currentUser.username);
}

// Get initials from name
function getInitials(name) {
    return name.split(' ').map(n => n[0]).join('').toUpperCase().substring(0, 2);
}

// Logout
function logout() {
    const token = localStorage.getItem('auth_token');
    
    axios.post(`${API_URL}/api/auth/logout`, {}, {
        headers: { 'Authorization': `Bearer ${token}` }
    }).finally(() => {
        localStorage.removeItem('auth_token');
        localStorage.removeItem('user');
        window.location.href = '/static/auth.html';
    });
}

// Switch tabs
function switchTab(tab) {
    const chatsTab = document.getElementById('tab-chats');
    const mapTab = document.getElementById('tab-map');
    
    if (tab === 'chats') {
        chatsTab.classList.add('text-yellow-400', 'border-b-2', 'border-yellow-400');
        chatsTab.classList.remove('text-gray-400');
        mapTab.classList.remove('text-yellow-400', 'border-b-2', 'border-yellow-400');
        mapTab.classList.add('text-gray-400');
    } else {
        window.location.href = '/';
    }
}

// Load chats
async function loadChats() {
    const token = localStorage.getItem('auth_token');
    
    try {
        const response = await axios.get(`${API_URL}/api/chats`, {
            headers: { 'Authorization': `Bearer ${token}` }
        });
        
        if (response.data.success) {
            chats = response.data.chats;
            displayChats();
        }
    } catch (error) {
        console.error('Error loading chats:', error);
        document.getElementById('chat-list').innerHTML = `
            <div class="p-4 text-center text-gray-500">
                <i class="fas fa-exclamation-circle text-2xl mb-2"></i>
                <p>Fehler beim Laden der Chats</p>
            </div>
        `;
    }
}

// Display chats
function displayChats() {
    const chatList = document.getElementById('chat-list');
    
    if (chats.length === 0) {
        chatList.innerHTML = `
            <div class="p-4 text-center text-gray-500">
                <i class="fas fa-comment-slash text-4xl mb-2"></i>
                <p>Noch keine Chats</p>
                <p class="text-sm mt-2">Starte einen neuen Chat!</p>
            </div>
        `;
        return;
    }
    
    chatList.innerHTML = chats.map(chat => {
        const isActive = currentChatId === chat.id;
        const title = chat.title || 'Privater Chat';
        const initials = getInitials(title);
        
        return `
            <div class="chat-item ${isActive ? 'active' : ''} p-4" onclick="selectChat(${chat.id})">
                <div class="flex items-center">
                    <div class="user-avatar relative mr-3">
                        <span>${initials}</span>
                    </div>
                    <div class="flex-1 min-w-0">
                        <div class="flex justify-between items-center mb-1">
                            <div class="text-white font-semibold truncate">${title}</div>
                            <div class="text-gray-500 text-xs">${formatTime(chat.last_message_at)}</div>
                        </div>
                        <div class="text-gray-400 text-sm truncate">
                            ${chat.description || (chat.chat_type === 'private' ? 'Privater Chat' : `${chat.member_count} Mitglieder`)}
                        </div>
                    </div>
                </div>
            </div>
        `;
    }).join('');
}

// Select chat
async function selectChat(chatId) {
    currentChatId = chatId;
    displayChats(); // Update active state
    
    // Show chat header and input
    document.getElementById('chat-header').classList.remove('hidden');
    document.getElementById('message-input-area').classList.remove('hidden');
    
    // Update chat header
    const chat = chats.find(c => c.id === chatId);
    if (chat) {
        const title = chat.title || 'Privater Chat';
        document.getElementById('chat-title').textContent = title;
        document.getElementById('chat-title-initials').textContent = getInitials(title);
        document.getElementById('chat-subtitle').textContent = 
            chat.chat_type === 'private' ? 'Online' : `${chat.member_count} Mitglieder`;
    }
    
    // Load messages
    await loadMessages(chatId);
    
    // Start polling for new messages
    if (messagePollingInterval) {
        clearInterval(messagePollingInterval);
    }
    messagePollingInterval = setInterval(() => loadMessages(chatId), 3000);
}

// Load messages
async function loadMessages(chatId) {
    const token = localStorage.getItem('auth_token');
    
    try {
        const response = await axios.get(`${API_URL}/api/chats/${chatId}/messages`, {
            headers: { 'Authorization': `Bearer ${token}` }
        });
        
        if (response.data.success) {
            messages = response.data.messages;
            displayMessages();
        }
    } catch (error) {
        console.error('Error loading messages:', error);
    }
}

// Display messages
function displayMessages() {
    const container = document.getElementById('messages-container');
    
    if (messages.length === 0) {
        container.innerHTML = `
            <div class="flex items-center justify-center h-full text-gray-500">
                <div class="text-center">
                    <i class="fas fa-comment text-4xl mb-2"></i>
                    <p>Noch keine Nachrichten</p>
                    <p class="text-sm mt-2">Sende die erste Nachricht!</p>
                </div>
            </div>
        `;
        return;
    }
    
    container.innerHTML = messages.map(msg => {
        const isOwn = msg.sender_id === currentUser.id;
        const senderName = msg.sender_display_name || msg.sender_username;
        
        return `
            <div class="mb-4 flex ${isOwn ? 'justify-end' : 'justify-start'}">
                <div class="message ${isOwn ? 'own' : 'other'} p-3 rounded-lg">
                    ${!isOwn ? `<div class="text-xs font-semibold mb-1 ${isOwn ? 'text-gray-800' : 'text-yellow-400'}">${senderName}</div>` : ''}
                    <div>${escapeHtml(msg.content)}</div>
                    <div class="text-xs mt-1 ${isOwn ? 'text-gray-700' : 'text-gray-500'}">${formatTime(msg.created_at)}</div>
                </div>
            </div>
        `;
    }).join('');
    
    // Scroll to bottom
    container.scrollTop = container.scrollHeight;
}

// Send message
document.getElementById('message-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    
    if (!currentChatId) return;
    
    const input = document.getElementById('message-input');
    const content = input.value.trim();
    
    if (!content) return;
    
    const token = localStorage.getItem('auth_token');
    
    try {
        const response = await axios.post(
            `${API_URL}/api/chats/${currentChatId}/messages`,
            { content, message_type: 'text' },
            { headers: { 'Authorization': `Bearer ${token}` } }
        );
        
        if (response.data.success) {
            input.value = '';
            await loadMessages(currentChatId);
        }
    } catch (error) {
        console.error('Error sending message:', error);
        alert('Fehler beim Senden der Nachricht');
    }
});

// New chat modal
function showNewChatModal() {
    document.getElementById('new-chat-modal').classList.remove('hidden');
    document.getElementById('user-search').focus();
}

function closeNewChatModal() {
    document.getElementById('new-chat-modal').classList.add('hidden');
    document.getElementById('user-search').value = '';
    document.getElementById('user-search-results').innerHTML = '';
}

// User search
let searchTimeout;
document.getElementById('user-search').addEventListener('input', (e) => {
    clearTimeout(searchTimeout);
    const query = e.target.value.trim();
    
    if (query.length < 2) {
        document.getElementById('user-search-results').innerHTML = '';
        return;
    }
    
    searchTimeout = setTimeout(async () => {
        const token = localStorage.getItem('auth_token');
        
        try {
            const response = await axios.get(`${API_URL}/api/users/search?q=${encodeURIComponent(query)}`, {
                headers: { 'Authorization': `Bearer ${token}` }
            });
            
            if (response.data.success) {
                displayUserSearchResults(response.data.users);
            }
        } catch (error) {
            console.error('Error searching users:', error);
        }
    }, 300);
});

// Display user search results
function displayUserSearchResults(users) {
    const container = document.getElementById('user-search-results');
    
    if (users.length === 0) {
        container.innerHTML = '<div class="text-gray-500 text-sm p-2">Keine Benutzer gefunden</div>';
        return;
    }
    
    container.innerHTML = users.map(user => {
        if (user.id === currentUser.id) return ''; // Skip current user
        
        return `
            <div class="flex items-center p-2 hover:bg-gray-800 rounded cursor-pointer" onclick="startPrivateChat(${user.id}, '${escapeHtml(user.username)}')">
                <div class="user-avatar mr-3">
                    <span>${getInitials(user.display_name || user.username)}</span>
                </div>
                <div>
                    <div class="text-white font-semibold">${escapeHtml(user.display_name || user.username)}</div>
                    <div class="text-gray-400 text-sm">@${escapeHtml(user.username)}</div>
                </div>
            </div>
        `;
    }).join('');
}

// Start private chat
async function startPrivateChat(userId, username) {
    const token = localStorage.getItem('auth_token');
    
    try {
        const response = await axios.post(
            `${API_URL}/api/chats`,
            {
                chat_type: 'private',
                title: username,
                member_ids: [userId]
            },
            { headers: { 'Authorization': `Bearer ${token}` } }
        );
        
        if (response.data.success) {
            closeNewChatModal();
            await loadChats();
            selectChat(response.data.chat_id);
        }
    } catch (error) {
        console.error('Error creating chat:', error);
        alert('Fehler beim Erstellen des Chats');
    }
}

// Utility functions
function formatTime(timestamp) {
    if (!timestamp) return '';
    const date = new Date(timestamp);
    const now = new Date();
    const diff = now - date;
    
    if (diff < 60000) return 'Gerade eben';
    if (diff < 3600000) return `${Math.floor(diff / 60000)} Min`;
    if (diff < 86400000) return `${Math.floor(diff / 3600000)} Std`;
    
    return date.toLocaleDateString('de-DE');
}

function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

// Cleanup on page unload
window.addEventListener('beforeunload', () => {
    if (messagePollingInterval) {
        clearInterval(messagePollingInterval);
    }
});
