"""Attach to the user's debug Chrome (CDP) and verify we can reach Sephora protected pages."""
import re
import sys
from playwright.sync_api import sync_playwright

CDP = "http://localhost:9222"
TARGET = sys.argv[1] if len(sys.argv) > 1 else "https://www.sephora.com/brand/rare-beauty"


def main():
    with sync_playwright() as p:
        browser = p.chromium.connect_over_cdp(CDP)
        # Reuse the EXISTING context so we inherit the user's validated Akamai cookies.
        ctx = browser.contexts[0] if browser.contexts else browser.new_context()
        page = ctx.pages[0] if ctx.pages else ctx.new_page()
        resp = page.goto(TARGET, wait_until="domcontentloaded", timeout=45000)
        page.wait_for_timeout(3500)
        html = page.content()
        ok = 'id="linkStore"' in html and "Access Denied" not in html
        print(f"target={TARGET}")
        print(f"  status={resp.status if resp else '?'} denied={'Access Denied' in html} "
              f"linkStore={'id=\"linkStore\"' in html} html_len={len(html)} "
              f"product_links={len(re.findall(r'/product/', html))}")
        print("==> SUCCESS — session works" if ok else "==> still blocked")
        # leave browser open (it's the user's); just disconnect
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
