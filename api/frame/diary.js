export default function handler(req, res) {
  if (req.method !== 'GET') {
    return res.status(405).json({ message: 'Method not allowed' });
  }

  const { pair = 'Unknown', pnl = '0', strategy = 'Unknown', sentiment = 'Unknown' } = req.query;
  
  const html = `<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>ThunderTrack 交易复盘 - ${pair}</title>
    
    <!-- Frame Protocol Meta Tags -->
    <meta property="fc:frame" content="vNext" />
    <meta property="fc:frame:image" content="https://thundertrack-miniapp.vercel.app/api/frame/image?pair=${encodeURIComponent(pair)}&pnl=${pnl}&strategy=${encodeURIComponent(strategy)}&sentiment=${encodeURIComponent(sentiment)}" />
    <meta property="fc:frame:image:aspect_ratio" content="1.91:1" />
    <meta property="fc:frame:button:1" content="查看详情" />
    <meta property="fc:frame:button:1:action" content="link" />
    <meta property="fc:frame:button:1:target" content="https://thundertrack-miniapp.vercel.app" />
    
    <!-- Open Graph Meta Tags -->
    <meta property="og:title" content="ThunderTrack 交易复盘 - ${pair}" />
    <meta property="og:description" content="交易对: ${pair} | 盈亏: ${pnl >= 0 ? '+' : ''}$${pnl} | 策略: ${strategy}" />
    <meta property="og:image" content="https://thundertrack-miniapp.vercel.app/api/frame/image?pair=${encodeURIComponent(pair)}&pnl=${pnl}&strategy=${encodeURIComponent(strategy)}&sentiment=${encodeURIComponent(sentiment)}" />
    <meta property="og:url" content="https://thundertrack-miniapp.vercel.app/api/frame/diary" />
    <meta property="og:type" content="website" />
    
    <!-- Twitter Meta Tags -->
    <meta name="twitter:card" content="summary_large_image" />
    <meta name="twitter:title" content="ThunderTrack 交易复盘 - ${pair}" />
    <meta name="twitter:description" content="交易对: ${pair} | 盈亏: ${pnl >= 0 ? '+' : ''}$${pnl} | 策略: ${strategy}" />
    <meta name="twitter:image" content="https://thundertrack-miniapp.vercel.app/api/frame/image?pair=${encodeURIComponent(pair)}&pnl=${pnl}&strategy=${encodeURIComponent(strategy)}&sentiment=${encodeURIComponent(sentiment)}" />
</head>
<body>
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 50px auto; padding: 20px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; border-radius: 15px;">
        <h1 style="text-align: center; margin-bottom: 30px;">🔥 ThunderTrack 交易复盘</h1>
        
        <div style="background: rgba(255,255,255,0.1); padding: 25px; border-radius: 10px; backdrop-filter: blur(10px);">
            <h2 style="color: #00ff88; margin-top: 0;">📊 交易详情</h2>
            <div style="display: grid; gap: 15px;">
                <div style="display: flex; justify-content: space-between; align-items: center; padding: 10px; background: rgba(255,255,255,0.1); border-radius: 8px;">
                    <span><strong>交易对:</strong></span>
                    <span style="color: #00ff88; font-weight: bold;">${pair}</span>
                </div>
                <div style="display: flex; justify-content: space-between; align-items: center; padding: 10px; background: rgba(255,255,255,0.1); border-radius: 8px;">
                    <span><strong>盈亏:</strong></span>
                    <span style="color: ${pnl >= 0 ? '#00ff88' : '#ff4757'}; font-weight: bold; font-size: 18px;">
                        ${pnl >= 0 ? '+' : ''}$${pnl}
                    </span>
                </div>
                <div style="display: flex; justify-content: space-between; align-items: center; padding: 10px; background: rgba(255,255,255,0.1); border-radius: 8px;">
                    <span><strong>策略:</strong></span>
                    <span>${strategy}</span>
                </div>
                <div style="display: flex; justify-content: space-between; align-items: center; padding: 10px; background: rgba(255,255,255,0.1); border-radius: 8px;">
                    <span><strong>心情:</strong></span>
                    <span>${sentiment}</span>
                </div>
            </div>
        </div>
        
        <div style="text-align: center; margin-top: 30px; padding: 20px; background: rgba(255,255,255,0.05); border-radius: 10px;">
            <p style="margin: 0; opacity: 0.8;">在Farcaster客户端中查看以获得完整交互体验</p>
            <p style="margin: 10px 0 0 0; font-size: 14px; opacity: 0.6;">#ThunderTrack #TTrade</p>
        </div>
    </div>
</body>
</html>`;

  res.setHeader('Content-Type', 'text/html');
  res.send(html);
}