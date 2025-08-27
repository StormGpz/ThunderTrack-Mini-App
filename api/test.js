export default function handler(req, res) {
  return res.status(200).json({ 
    message: 'Hello from Vercel API!', 
    method: req.method,
    path: req.url,
    timestamp: new Date().toISOString()
  });
}