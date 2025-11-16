// Global variables
let map;
let markers = [];
let allEvents = [];
let currentFilters = {
  category: null,
  type: null,
  yearFrom: null,
  yearTo: null
};

// Icon mappings for different event types
const iconMap = {
  pyramid: '🔺',
  atlantis: '🌊',
  stone: '🗿',
  lines: '✈️',
  temple: '🛕',
  moai: '🗿',
  stones: '⚡',
  ufo: '🛸',
  crash: '💥',
  lights: '💡',
  explosion: '💥',
  cult: '🎭',
  airport: '✈️',
  building: '🏛️',
  church: '⛪',
  skull: '💀',
  station: '📡',
  radar: '📡',
  ship: '⛴️',
  cia: '🕵️',
  chemical: '☣️',
  mountain: '⛰️',
  pole: '🧭',
  underground: '🕳️',
  triangle: '🔺',
  vortex: '🌀',
  ruins: '🏛️',
  cern: '⚛️',
  antenna: '📡',
  question: '❓'
};

const typeColors = {
  ancient: '#FFD700',
  ufo: '#00FF00',
  conspiracy: '#FF4444',
  mystery: '#9370DB'
};

// Initialize map
function initMap() {
  // Create map centered on Europe
  map = L.map('map', {
    center: [48.8566, 2.3522], // Paris
    zoom: 4,
    minZoom: 2,
    maxZoom: 18,
    zoomControl: true
  });

  // Add dark tile layer
  L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png', {
    attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors &copy; <a href="https://carto.com/attributions">CARTO</a>',
    subdomains: 'abcd',
    maxZoom: 20
  }).addTo(map);

  // Load initial data
  loadCategories();
  loadTypes();
  loadEvents();
}

// Load categories
async function loadCategories() {
  try {
    const response = await axios.get('/api/events/categories');
    const categoriesDiv = document.getElementById('categories-filter');
    
    if (response.data.success && response.data.categories.length > 0) {
      categoriesDiv.innerHTML = response.data.categories.map(cat => `
        <div class="filter-chip" data-category="${cat.category}" onclick="toggleCategoryFilter('${cat.category}')">
          ${cat.category} (${cat.count})
        </div>
      `).join('');
    } else {
      categoriesDiv.innerHTML = '<p class="text-gray-400">Keine Kategorien gefunden</p>';
    }
  } catch (error) {
    console.error('Error loading categories:', error);
    document.getElementById('categories-filter').innerHTML = '<p class="text-red-400">Fehler beim Laden</p>';
  }
}

// Load event types
async function loadTypes() {
  try {
    const response = await axios.get('/api/events/types');
    const typesDiv = document.getElementById('types-filter');
    
    if (response.data.success && response.data.types.length > 0) {
      typesDiv.innerHTML = response.data.types.map(type => `
        <div class="filter-chip" data-type="${type.event_type}" onclick="toggleTypeFilter('${type.event_type}')">
          ${type.event_type} (${type.count})
        </div>
      `).join('');
    } else {
      typesDiv.innerHTML = '<p class="text-gray-400">Keine Typen gefunden</p>';
    }
  } catch (error) {
    console.error('Error loading types:', error);
    document.getElementById('types-filter').innerHTML = '<p class="text-red-400">Fehler beim Laden</p>';
  }
}

// Load events
async function loadEvents() {
  try {
    const params = new URLSearchParams();
    if (currentFilters.category) params.append('category', currentFilters.category);
    if (currentFilters.type) params.append('type', currentFilters.type);
    if (currentFilters.yearFrom) params.append('year_from', currentFilters.yearFrom);
    if (currentFilters.yearTo) params.append('year_to', currentFilters.yearTo);

    const response = await axios.get(`/api/events?${params}`);
    
    if (response.data.success) {
      allEvents = response.data.events;
      displayEventsOnMap(allEvents);
    }
  } catch (error) {
    console.error('Error loading events:', error);
  }
}

// Display events on map
function displayEventsOnMap(events) {
  // Clear existing markers
  markers.forEach(marker => map.removeLayer(marker));
  markers = [];

  // Add new markers
  events.forEach(event => {
    const icon = iconMap[event.icon_type] || '📍';
    const color = typeColors[event.event_type] || '#FFFFFF';
    
    // Create custom icon
    const markerIcon = L.divIcon({
      className: 'custom-marker',
      html: `<div style="font-size: 30px; filter: drop-shadow(0 0 3px ${color});">${icon}</div>`,
      iconSize: [30, 30],
      iconAnchor: [15, 30],
      popupAnchor: [0, -30]
    });

    // Create marker
    const marker = L.marker([event.latitude, event.longitude], {
      icon: markerIcon,
      title: event.title
    });

    // Create popup content
    const popupContent = `
      <div class="popup-content">
        <div class="popup-title">${event.title}</div>
        <div class="popup-meta">
          <span><i class="fas fa-tag"></i> ${event.category || 'Unbekannt'}</span>
          ${event.year ? `<span><i class="fas fa-calendar"></i> ${event.date_text || event.year}</span>` : ''}
        </div>
        <div class="popup-description">${event.description || 'Keine Beschreibung verfügbar'}</div>
        <a href="/event/${event.id}" class="popup-button">
          <i class="fas fa-info-circle mr-2"></i>
          Details anzeigen
        </a>
      </div>
    `;

    marker.bindPopup(popupContent, {
      maxWidth: 300,
      className: 'custom-popup'
    });

    marker.addTo(map);
    markers.push(marker);
  });

  // Fit bounds if there are markers
  if (markers.length > 0) {
    const group = L.featureGroup(markers);
    map.fitBounds(group.getBounds().pad(0.1));
  }
}

// Toggle filters
function toggleFilters() {
  const panel = document.getElementById('side-panel');
  panel.classList.toggle('open');
}

// Toggle category filter
function toggleCategoryFilter(category) {
  const chip = document.querySelector(`[data-category="${category}"]`);
  
  if (currentFilters.category === category) {
    currentFilters.category = null;
    chip.classList.remove('active');
  } else {
    // Remove active from all category chips
    document.querySelectorAll('#categories-filter .filter-chip').forEach(c => c.classList.remove('active'));
    currentFilters.category = category;
    chip.classList.add('active');
  }
  
  loadEvents();
}

// Toggle type filter
function toggleTypeFilter(type) {
  const chip = document.querySelector(`[data-type="${type}"]`);
  
  if (currentFilters.type === type) {
    currentFilters.type = null;
    chip.classList.remove('active');
  } else {
    // Remove active from all type chips
    document.querySelectorAll('#types-filter .filter-chip').forEach(c => c.classList.remove('active'));
    currentFilters.type = type;
    chip.classList.add('active');
  }
  
  loadEvents();
}

// Apply year filters
function applyFilters() {
  const yearFrom = document.getElementById('year-from').value;
  const yearTo = document.getElementById('year-to').value;
  
  currentFilters.yearFrom = yearFrom || null;
  currentFilters.yearTo = yearTo || null;
  
  loadEvents();
}

// Clear all filters
function clearFilters() {
  currentFilters = {
    category: null,
    type: null,
    yearFrom: null,
    yearTo: null
  };
  
  // Clear UI
  document.querySelectorAll('.filter-chip').forEach(chip => chip.classList.remove('active'));
  document.getElementById('year-from').value = '';
  document.getElementById('year-to').value = '';
  
  loadEvents();
}

// Search functionality
let searchTimeout;
document.getElementById('search-input').addEventListener('input', (e) => {
  clearTimeout(searchTimeout);
  searchTimeout = setTimeout(() => {
    const query = e.target.value.toLowerCase();
    
    if (!query) {
      displayEventsOnMap(allEvents);
      return;
    }
    
    const filtered = allEvents.filter(event => 
      event.title.toLowerCase().includes(query) ||
      (event.description && event.description.toLowerCase().includes(query)) ||
      (event.category && event.category.toLowerCase().includes(query))
    );
    
    displayEventsOnMap(filtered);
  }, 300);
});

// Switch tabs
function switchTab(tab) {
  // Remove active from all nav items
  document.querySelectorAll('.nav-item').forEach(item => item.classList.remove('active'));
  
  // Add active to clicked tab
  event.target.closest('.nav-item').classList.add('active');
  
  // Navigate to different pages
  switch(tab) {
    case 'map':
      window.location.href = '/';
      break;
    case 'list':
      window.location.href = '/list';
      break;
    case 'documents':
      window.location.href = '/documents';
      break;
    case 'timeline':
      window.location.href = '/timeline';
      break;
  }
}

// Initialize on page load
document.addEventListener('DOMContentLoaded', () => {
  initMap();
});
