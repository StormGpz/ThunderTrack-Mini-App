// 服务器端Frame处理
function handleFrameRequest() {
  const urlParams = new URLSearchParams(window.location.search);
  
  if (urlParams.get('frame') === 'true') {
    const pair = urlParams.get('pair') || 'Unknown';
    const pnl = urlParams.get('pnl') || '0';
    const strategy = urlParams.get('strategy') || 'Unknown';
    const sentiment = urlParams.get('sentiment') || 'Unknown';
    
    // 立即更新meta标签（在页面加载前）
    const frameEmbed = {
      version: "1",
      imageUrl: "https://thundertrack-miniapp.vercel.app/frame-image.svg",
      button: {
        title: "查看详情",
        action: {
          type: "launch_miniapp",
          url: `https://thundertrack-miniapp.vercel.app/?diary=${encodeURIComponent(pair)}&pnl=${pnl}&strategy=${encodeURIComponent(strategy)}&sentiment=${encodeURIComponent(sentiment)}`,
          name: "ThunderTrack",
          splashImageUrl: "https://thundertrack-miniapp.vercel.app/icons/Icon-192.png",
          splashBackgroundColor: "#1a1a2e"
        }
      }
    };
    
    // 更新页面标题和描述
    document.title = `ThunderTrack 交易复盘 - ${pair}`;
    
    // 更新meta标签
    const metaTag = document.querySelector('meta[name="fc:miniapp"]');
    if (metaTag) {
      metaTag.setAttribute('content', JSON.stringify(frameEmbed));
    }
    
    // 更新OG标签
    const ogTitle = document.querySelector('meta[property="og:title"]');
    const ogDesc = document.querySelector('meta[property="og:description"]');
    const ogImage = document.querySelector('meta[property="og:image"]');
    
    if (ogTitle) ogTitle.setAttribute('content', `ThunderTrack 交易复盘 - ${pair}`);
    if (ogDesc) ogDesc.setAttribute('content', `交易对: ${pair} | 盈亏: ${pnl >= 0 ? '+' : ''}$${pnl} | 策略: ${strategy}`);
    if (ogImage) ogImage.setAttribute('content', 'https://thundertrack-miniapp.vercel.app/frame-image.svg');
  }
}

// 在DOM加载前就执行
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', handleFrameRequest);
} else {
  handleFrameRequest();
}