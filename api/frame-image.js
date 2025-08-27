// Vercel serverless function for Frame image generation
export default function handler(req, res) {
  // 启用CORS
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  
  if (req.method === 'OPTIONS') {
    res.status(200).end();
    return;
  }
  
  const { pair = 'Unknown', pnl = '0', strategy = 'Unknown', sentiment = 'Unknown' } = req.query;
  const pnlValue = parseFloat(pnl) || 0;
  
  const svg = `<svg width="600" height="315" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <linearGradient id="bg" x1="0%" y1="0%" x2="100%" y2="100%">
        <stop offset="0%" style="stop-color:#1a1a2e"/>
        <stop offset="50%" style="stop-color:#16213e"/>
        <stop offset="100%" style="stop-color:#0f0f23"/>
      </linearGradient>
      <linearGradient id="neon" x1="0%" y1="0%" x2="100%" y2="0%">
        <stop offset="0%" style="stop-color:#00ff88"/>
        <stop offset="100%" style="stop-color:#00d4aa"/>
      </linearGradient>
    </defs>
    
    <rect width="600" height="315" fill="url(#bg)" rx="15"/>
    <rect x="0" y="0" width="600" height="60" fill="rgba(0,255,136,0.1)" rx="15"/>
    
    <text x="300" y="35" font-family="Arial, sans-serif" font-size="24" font-weight="bold" fill="url(#neon)" text-anchor="middle">
      🔥 ThunderTrack 交易复盘
    </text>
    
    <rect x="30" y="80" width="540" height="180" fill="rgba(255,255,255,0.05)" rx="10" stroke="rgba(0,255,136,0.3)" stroke-width="1"/>
    
    <text x="50" y="110" font-family="Arial, sans-serif" font-size="18" fill="#ffffff">📊 交易对:</text>
    <text x="450" y="110" font-family="Arial, sans-serif" font-size="18" fill="url(#neon)" font-weight="bold" text-anchor="end">${pair}</text>
    
    <text x="50" y="145" font-family="Arial, sans-serif" font-size="18" fill="#ffffff">💰 盈亏:</text>
    <text x="450" y="145" font-family="Arial, sans-serif" font-size="20" fill="${pnlValue >= 0 ? '#00ff88' : '#ff4757'}" font-weight="bold" text-anchor="end">${pnlValue >= 0 ? '+' : ''}$${pnlValue.toFixed(2)}</text>
    
    <text x="50" y="180" font-family="Arial, sans-serif" font-size="18" fill="#ffffff">🎯 策略:</text>
    <text x="450" y="180" font-family="Arial, sans-serif" font-size="16" fill="#cccccc" text-anchor="end">${strategy}</text>
    
    <text x="50" y="215" font-family="Arial, sans-serif" font-size="18" fill="#ffffff">😊 心情:</text>
    <text x="450" y="215" font-family="Arial, sans-serif" font-size="16" fill="#cccccc" text-anchor="end">${sentiment}</text>
    
    <line x1="50" y1="240" x2="550" y2="240" stroke="rgba(0,255,136,0.3)" stroke-width="1"/>
    <text x="300" y="280" font-family="Arial, sans-serif" font-size="14" fill="rgba(0,255,136,0.8)" text-anchor="middle">#ThunderTrack #TTrade</text>
  </svg>`;
  
  res.setHeader('Content-Type', 'image/svg+xml');
  res.setHeader('Cache-Control', 'public, max-age=3600');
  res.status(200).send(svg);
}