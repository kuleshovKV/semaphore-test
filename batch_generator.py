#!/usr/bin/env python3
# Casino Sites Batch Generator
# Multi-threaded HTML generation with Jinja2 templating

import os
import sys
import csv
import argparse
import threading
import time
from pathlib import Path
from queue import Queue
from jinja2 import Environment, FileSystemLoader, select_autoescape
from datetime import datetime

class BatchGenerator:
    def __init__(self, input_file, output_dir, template_dir, batch_size=50, parallel=8, log_file=None):
        self.input_file = input_file
        self.output_dir = output_dir
        self.template_dir = template_dir
        self.batch_size = batch_size
        self.parallel = parallel
        self.log_file = log_file
        self.queue = Queue()
        self.generated = 0
        self.errors = 0
        self.lock = threading.Lock()
        
        # Setup Jinja2
        self.env = Environment(
            loader=FileSystemLoader(template_dir),
            autoescape=select_autoescape(['html', 'xml'])
        )
        
        # Create output directory
        Path(output_dir).mkdir(parents=True, exist_ok=True)

    def log(self, message):
        """Log message to file and stdout"""
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        msg = f"[{timestamp}] {message}"
        print(msg)
        if self.log_file:
            with open(self.log_file, 'a') as f:
                f.write(msg + '\n')

    def read_csv(self):
        """Read CSV file and return domain list"""
        domains = []
        try:
            with open(self.input_file, 'r', encoding='utf-8') as f:
                reader = csv.DictReader(f, delimiter=';')
                for row in reader:
                    if row['subdomain']:  # Skip empty rows
                        domains.append(row)
            self.log(f"✅ Loaded {len(domains)} domains from CSV")
            return domains
        except Exception as e:
            self.log(f"❌ Error reading CSV: {e}")
            return []

    def generate_site(self, domain_info):
        """Generate HTML pages for a single domain"""
        try:
            subdomain = domain_info['subdomain']
            domain = domain_info['domain']
            brand = domain_info['brand']
            keyword = domain_info['keyword']
            main_fqdn = domain_info['main_fqdn']
            mirror_fqdn = domain_info['mirror_fqdn']
            year = str(datetime.now().year)
            
            # Create domain directory
            site_dir = Path(self.output_dir) / main_fqdn
            site_dir.mkdir(parents=True, exist_ok=True)
            
            # Template context
            context = {
                'SUBDOMAIN': subdomain,
                'DOMAIN': domain,
                'BRAND': brand,
                'KEYWORD': keyword,
                'MAIN_FQDN': main_fqdn,
                'MIRROR_FQDN': mirror_fqdn,
                'YEAR': year,
            }
            
            # Load template
            template = self.env.get_template('index.html.tpl')
            
            # Generate pages
            pages = {
                'index.html': {},
                'register/index.html': {'title_suffix': '— Регистрация'},
                'bonus/index.html': {'title_suffix': '— Бонусы'},
                'reviews/index.html': {'title_suffix': '— Отзывы'},
                'withdrawal/index.html': {'title_suffix': '— Вывод денег'},
            }
            
            for page_path, page_context in pages.items():
                page_context.update(context)
                html_content = template.render(page_context)
                
                # Create subdirectory if needed
                full_path = site_dir / page_path
                full_path.parent.mkdir(parents=True, exist_ok=True)
                
                # Write HTML file
                with open(full_path, 'w', encoding='utf-8') as f:
                    f.write(html_content)
            
            # Generate robots.txt
            robots_content = f"""# Robots.txt for {brand}
User-agent: *
Allow: /
Disallow: /admin/
Disallow: /api/private/
Sitemap: https://{main_fqdn}/sitemap.xml
"""
            with open(site_dir / 'robots.txt', 'w', encoding='utf-8') as f:
                f.write(robots_content)
            
            # Generate sitemap.xml
            sitemap_content = f"""<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
    <url>
        <loc>https://{main_fqdn}/</loc>
        <lastmod>{datetime.now().strftime('%Y-%m-%d')}</lastmod>
        <priority>1.0</priority>
    </url>
    <url>
        <loc>https://{main_fqdn}/register/</loc>
        <lastmod>{datetime.now().strftime('%Y-%m-%d')}</lastmod>
        <priority>0.9</priority>
    </url>
    <url>
        <loc>https://{main_fqdn}/bonus/</loc>
        <lastmod>{datetime.now().strftime('%Y-%m-%d')}</lastmod>
        <priority>0.8</priority>
    </url>
    <url>
        <loc>https://{main_fqdn}/reviews/</loc>
        <lastmod>{datetime.now().strftime('%Y-%m-%d')}</lastmod>
        <priority>0.7</priority>
    </url>
    <url>
        <loc>https://{main_fqdn}/withdrawal/</loc>
        <lastmod>{datetime.now().strftime('%Y-%m-%d')}</lastmod>
        <priority>0.7</priority>
    </url>
</urlset>
"""
            with open(site_dir / 'sitemap.xml', 'w', encoding='utf-8') as f:
                f.write(sitemap_content)
            
            with self.lock:
                self.generated += 1
            
            return True, main_fqdn
            
        except Exception as e:
            with self.lock:
                self.errors += 1
            return False, str(e)

    def worker(self):
        """Worker thread that processes domains from queue"""
        while True:
            item = self.queue.get()
            if item is None:
                break
            
            success, result = self.generate_site(item)
            if success:
                self.log(f"✅ Generated: {result}")
            else:
                self.log(f"❌ Error: {result}")
            
            self.queue.task_done()

    def run(self):
        """Main generation process"""
        self.log("🎰 CASINO SITES BATCH GENERATOR")
        self.log(f"Input: {self.input_file}")
        self.log(f"Output: {self.output_dir}")
        self.log(f"Template: {self.template_dir}")
        self.log(f"Parallel threads: {self.parallel}")
        
        # Read CSV
        domains = self.read_csv()
        if not domains:
            self.log("❌ No domains found. Exiting.")
            return False
        
        # Start worker threads
        threads = []
        for i in range(self.parallel):
            t = threading.Thread(target=self.worker)
            t.start()
            threads.append(t)
        
        # Queue domains
        start_time = time.time()
        for domain in domains:
            self.queue.put(domain)
        
        # Wait for completion
        self.queue.join()
        
        # Stop workers
        for _ in range(self.parallel):
            self.queue.put(None)
        for t in threads:
            t.join()
        
        # Summary
        elapsed = time.time() - start_time
        self.log(f"\n{'='*50}")
        self.log(f"✅ GENERATION COMPLETE")
        self.log(f"Generated: {self.generated} sites")
        self.log(f"Errors: {self.errors}")
        self.log(f"Time: {elapsed:.2f}s")
        self.log(f"Rate: {self.generated/elapsed:.2f} sites/sec")
        self.log(f"{'='*50}\n")
        
        return self.errors == 0

def main():
    parser = argparse.ArgumentParser(description='Casino Sites Batch Generator')
    parser.add_argument('--input', required=True, help='Input CSV file')
    parser.add_argument('--output', required=True, help='Output directory')
    parser.add_argument('--template', required=True, help='Template directory')
    parser.add_argument('--batch-size', type=int, default=50, help='Batch size')
    parser.add_argument('--parallel', type=int, default=8, help='Parallel threads')
    parser.add_argument('--log', help='Log file path')
    
    args = parser.parse_args()
    
    generator = BatchGenerator(
        input_file=args.input,
        output_dir=args.output,
        template_dir=args.template,
        batch_size=args.batch_size,
        parallel=args.parallel,
        log_file=args.log
    )
    
    success = generator.run()
    sys.exit(0 if success else 1)

if __name__ == '__main__':
    main()

