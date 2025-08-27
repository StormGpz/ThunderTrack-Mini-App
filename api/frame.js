// Vercel serverless function for Frame API
export default function handler(req, res) {
  // 启用CORS
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  
  if (req.method === 'OPTIONS') {
    res.status(200).end();
    return;
  }
  
  const { pair = 'Unknown', pnl = '0', strategy = 'Unknown', sentiment = 'Unknown' } = req.query;
  
  // 构建Mini App embed JSON
  const diaryId = req.query.id || `${pair}-${Date.now()}`;
  const miniAppEmbed = {
    version: "1",
    imageUrl: `${req.url.includes('localhost') ? 'http' : 'https'}://${req.headers.host}/api/frame-image?pair=${encodeURIComponent(pair)}&pnl=${pnl}&strategy=${encodeURIComponent(strategy)}&sentiment=${encodeURIComponent(sentiment)}`,
    button: {
      title: "查看详情",
      action: {
        type: "launch_miniapp",
        url: `${req.url.includes('localhost') ? 'http' : 'https'}://${req.headers.host}`,
        name: "ThunderTrack",
        splashImageUrl: `${req.url.includes('localhost') ? 'http' : 'https'}://${req.headers.host}/icons/Icon-192.png`,
        splashBackgroundColor: "#1a1a2e"
      }
    },
    metadata: {
      diaryId: diaryId,
      pair: pair,
      pnl: pnl,
      strategy: strategy,
      sentiment: sentiment
    }
  };
  
  const miniAppEmbedString = JSON.stringify(miniAppEmbed);
  
  const html = `<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>ThunderTrack 交易复盘 - ${pair}</title>
    
    <!-- Mini App embed meta tags -->
    <meta name="fc:miniapp" content='${miniAppEmbedString}' />
    <!-- For backward compatibility -->
    <meta name="fc:frame" content='${miniAppEmbedString}' />
    
    <!-- Open Graph Meta Tags -->
    <meta property="og:title" content="ThunderTrack 交易复盘 - ${pair}" />
    <meta property="og:description" content="交易对: ${pair} | 盈亏: ${pnl >= 0 ? '+' : ''}$${pnl} | 策略: ${strategy}" />
    <meta property="og:image" content="${req.url.includes('localhost') ? 'http' : 'https'}://${req.headers.host}/api/frame-image?pair=${encodeURIComponent(pair)}&pnl=${pnl}&strategy=${encodeURIComponent(strategy)}&sentiment=${encodeURIComponent(sentiment)}" />
    <meta property="og:url" content="${req.url.includes('localhost') ? 'http' : 'https'}://${req.headers.host}/api/frame" />
    <meta property="og:type" content="website" />
</head>
<body>
    <!-- Frame被Farcaster客户端处理，不显示页面内容 -->
    <script>
        // 如果是直接访问这个URL，重定向到Mini App
        if (window.location.href.includes('/api/frame')) {
            const urlParams = new URLSearchParams(window.location.search);
            const diaryId = urlParams.get('id') || '${diaryId}';
            const miniAppUrl = \`/diary/\${diaryId}?\${urlParams.toString()}\`;
            
            console.log('🔗 重定向到Mini App:', miniAppUrl);
            window.location.href = miniAppUrl;
        }
    </script>
    
    <div style="font-family: Arial, sans-serif; max-width: 400px; margin: 50px auto; padding: 20px; text-align: center;">
        <h2>🔄 正在重定向到ThunderTrack Mini App...</h2>
        <p>如果没有自动跳转，请 <a href="/" target="_blank">点击这里</a></p>
    </div>
</body>
</html>`;

  res.setHeader('Content-Type', 'text/html');
  res.status(200).send(html);
}