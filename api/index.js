// Vercel Edge Function for Frame rendering
export const config = {
  runtime: 'edge',
};

export default function handler(request) {
  const { searchParams } = new URL(request.url);
  const isFrame = searchParams.get('frame') === 'true';
  
  if (isFrame) {
    // Frame模式 - 返回Frame格式的HTML
    const pair = searchParams.get('pair') || 'Unknown';
    const pnl = searchParams.get('pnl') || '0';
    const strategy = searchParams.get('strategy') || 'Unknown';
    const sentiment = searchParams.get('sentiment') || 'Unknown';
    
    const html = `<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>ThunderTrack 交易复盘 - ${pair}</title>
    
    <!-- Frame Meta Tags -->
    <meta property="fc:frame" content="vNext" />
    <meta property="fc:frame:image" content="https://thundertrack-miniapp.vercel.app/frame-image.svg" />
    <meta property="fc:frame:button:1" content="查看详情" />
    <meta property="fc:frame:button:1:action" content="link" />
    <meta property="fc:frame:button:1:target" content="https://thundertrack-miniapp.vercel.app/?diary=${encodeURIComponent(pair)}&pnl=${pnl}&strategy=${encodeURIComponent(strategy)}&sentiment=${encodeURIComponent(sentiment)}" />
    
    <!-- Open Graph -->
    <meta property="og:title" content="ThunderTrack 交易复盘 - ${pair}" />
    <meta property="og:description" content="交易对: ${pair} | 盈亏: ${pnl >= 0 ? '+' : ''}$${pnl} | 策略: ${strategy}" />
    <meta property="og:image" content="https://thundertrack-miniapp.vercel.app/frame-image.svg" />
</head>
<body>
    <h1>ThunderTrack 交易复盘</h1>
    <p>交易对: ${pair}</p>
    <p>盈亏: $${pnl}</p>
    <p>策略: ${strategy}</p>
    <p>情绪: ${sentiment}</p>
</body>
</html>`;
    
    return new Response(html, {
      headers: {
        'Content-Type': 'text/html',
        'Cache-Control': 'public, max-age=300',
      },
    });
  } else {
    // 非Frame模式 - 重定向到主应用
    return Response.redirect('https://thundertrack-miniapp.vercel.app/', 302);
  }
}