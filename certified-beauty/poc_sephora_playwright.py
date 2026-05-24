"""POC v2: beat Akamai on Sephora via warm-up nav + real Chrome + stealth.

Tries escalating configs until one returns real content (linkStore present).
"""
import re
import sys
from playwright.sync_api import sync_playwright

UA = ("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")

TARGET = "https://www.sephora.com/brand/rare-beauty"
HOME = "https://www.sephora.com/"

STEALTH = """
Object.defineProperty(navigator, 'webdriver', {get: () => undefined});
window.chrome = window.chrome || {runtime: {}};
Object.defineProperty(navigator, 'languages', {get: () => ['en-US','en']});
Object.defineProperty(navigator, 'plugins', {get: () => [1,2,3,4,5]});
"""


def attempt(label, *, headless, channel):
    with sync_playwright() as p:
        try:
            kw = {"headless": headless}
            if channel:
                kw["channel"] = channel
            browser = p.chromium.launch(**kw)
        except Exception as e:
            print(f"[{label}] launch failed: {e}")
            return False
        ctx = browser.new_context(user_agent=UA, viewport={"width": 1366, "height": 900},
                                  locale="en-US")
        ctx.add_init_script(STEALTH)
        page = ctx.new_page()
        # warm-up: browse the allowed homepage so Akamai's sensor validates the session
        page.goto(HOME, wait_until="domcontentloaded", timeout=45000)
        page.wait_for_timeout(5000)
        resp = page.goto(TARGET, wait_until="domcontentloaded", timeout=45000)
        page.wait_for_timeout(4000)
        html = page.content()
        ok = 'id="linkStore"' in html and "Access Denied" not in html
        print(f"[{label}] status={resp.status if resp else '?'} "
              f"denied={'Access Denied' in html} linkStore={'id=\"linkStore\"' in html} "
              f"len={len(html)}")
        browser.close()
        return ok


configs = [
    ("headless+chromium", dict(headless=True, channel=None)),
    ("headless+chrome",   dict(headless=True, channel="chrome")),
    ("headed+chrome",     dict(headless=False, channel="chrome")),
]
for label, kw in configs:
    try:
        if attempt(label, **kw):
            print(f"==> SUCCESS with: {label}")
            sys.exit(0)
    except Exception as e:
        print(f"[{label}] error: {type(e).__name__}: {e}")
print("==> all configs blocked")
