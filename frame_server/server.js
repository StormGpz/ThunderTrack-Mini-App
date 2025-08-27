const express = require('express');
const app = express();
const port = 3001;

// 中间件
app.use(express.json());
app.use(express.static('.'));

// Frame 端点
app.get('/frame/diary', (req, res) => {
  const { pair, pnl, strategy, sentiment } = req.query;
  
  const html = `
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>ThunderTrack 交易复盘 - ${pair || 'Unknown'}</title>
    
    <!-- Frame Protocol Meta Tags -->
    <meta property="fc:frame" content="vNext" />
    <meta property="fc:frame:image" content="http://localhost:3001/api/frame/image?pair=${encodeURIComponent(pair || '')}&pnl=${pnl || '0'}&strategy=${encodeURIComponent(strategy || '')}&sentiment=${encodeURIComponent(sentiment || '')}" />
    <meta property="fc:frame:image:aspect_ratio" content="1.91:1" />
    <meta property="fc:frame:button:1" content="查看详情" />
    <meta property="fc:frame:button:1:action" content="link" />
    <meta property="fc:frame:button:1:target" content="https://thundertrack.app" />
    
    <!-- Open Graph Meta Tags -->
    <meta property="og:title" content="ThunderTrack 交易复盘 - ${pair || 'Unknown'}" />
    <meta property="og:description" content="交易对: ${pair || 'Unknown'} | 盈亏: ${pnl ? (pnl >= 0 ? '+' : '') + '$' + pnl : '$0'} | 策略: ${strategy || 'Unknown'}" />
    <meta property="og:image" content="http://localhost:3001/api/frame/image?pair=${encodeURIComponent(pair || '')}&pnl=${pnl || '0'}&strategy=${encodeURIComponent(strategy || '')}&sentiment=${encodeURIComponent(sentiment || '')}" />
    <meta property="og:url" content="http://localhost:3001/frame/diary" />
    <meta property="og:type" content="website" />
    
    <!-- Twitter Meta Tags -->
    <meta name="twitter:card" content="summary_large_image" />
</head>
<body>
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 50px auto; padding: 20px;">
        <h1>🔥 ThunderTrack 交易复盘</h1>
        <div style="background: #f5f5f5; padding: 20px; border-radius: 10px; margin: 20px 0;">
            <h2>📊 交易详情</h2>
            <p><strong>交易对:</strong> ${pair || 'Unknown'}</p>
            <p><strong>盈亏:</strong> ${pnl ? (pnl >= 0 ? '+' : '') + '$' + pnl : '$0'}</p>
            <p><strong>策略:</strong> ${strategy || 'Unknown'}</p>
            <p><strong>心情:</strong> ${sentiment || 'Unknown'}</p>
        </div>
        <p>在Farcaster客户端中查看以获得完整交互体验。</p>
    </div>
</body>
</html>`;
  
  res.setHeader('Content-Type', 'text/html');
  res.send(html);
});

// 动态生成Frame图片的API
app.get('/api/frame/image', async (req, res) => {
  const { pair, pnl, strategy, sentiment } = req.query;
  
  // 这里应该使用图片生成库来创建动态图片
  // 现在返回一个简单的SVG作为示例
  const svg = `
    <svg width="600" height="315" xmlns="http://www.w3.org/2000/svg">
      <defs>
        <linearGradient id="bg" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" style="stop-color:#1a1a2e"/>
          <stop offset="100%" style="stop-color:#16213e"/>
        </linearGradient>
      </defs>
      
      <rect width="600" height="315" fill="url(#bg)"/>
      
      <!-- Title -->
      <text x="300" y="50" font-family="Arial, sans-serif" font-size="24" font-weight="bold" fill="#00ff88" text-anchor="middle">
        🔥 ThunderTrack 交易复盘
      </text>
      
      <!-- Trading Pair -->
      <text x="50" y="100" font-family="Arial, sans-serif" font-size="18" fill="#ffffff">
        📊 交易对: ${pair || 'Unknown'}
      </text>
      
      <!-- PnL -->
      <text x="50" y="140" font-family="Arial, sans-serif" font-size="18" fill="${pnl >= 0 ? '#00ff88' : '#ff4757'}">
        💰 盈亏: ${pnl ? (pnl >= 0 ? '+' : '') + '$' + pnl : '$0'}
      </text>
      
      <!-- Strategy -->
      <text x="50" y="180" font-family="Arial, sans-serif" font-size="18" fill="#ffffff">
        🎯 策略: ${strategy || 'Unknown'}
      </text>
      
      <!-- Sentiment -->
      <text x="50" y="220" font-family="Arial, sans-serif" font-size="18" fill="#ffffff">
        😊 心情: ${sentiment || 'Unknown'}
      </text>
      
      <!-- Bottom text -->
      <text x="300" y="280" font-family="Arial, sans-serif" font-size="14" fill="#888888" text-anchor="middle">
        #ThunderTrack #TTrade
      </text>
    </svg>
  `;
  
  res.setHeader('Content-Type', 'image/svg+xml');
  res.send(svg);
});

app.listen(port, () => {
  console.log(`ThunderTrack Frame服务器运行在 http://localhost:${port}`);
});