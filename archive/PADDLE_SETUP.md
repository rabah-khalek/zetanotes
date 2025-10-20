# Paddle Checkout Setup Instructions

## Current Status
✅ Website links updated to show "Paddle checkout is being set up" message
✅ Privacy policy already mentions Paddle.com as payment processor
⏳ Waiting for Paddle verification to complete

## When Paddle Verification is Complete

Once you receive your Paddle checkout URL, update these files:

### 1. Update `docs/index.html`

**Location:** Line ~1048-1050

**Replace:**
```html
<a href="#" class="btn btn-primary"
   data-umami-event="get-pro-click"
   onclick="alert('Paddle checkout is being set up. Check back soon!'); return false;">Get Pro Access</a>
```

**With:**
```html
<a href="YOUR_PADDLE_CHECKOUT_URL" class="btn btn-primary"
   data-umami-event="get-pro-click"
   target="_blank">Get Pro Access</a>
```

### 2. Update `docs/download.html`

**Location:** Line ~518-520

**Replace:**
```html
<a href="#" class="btn"
   onclick="alert('Paddle checkout is being set up. Check back soon!'); return false;">
    Get Pro Access
</a>
```

**With:**
```html
<a href="YOUR_PADDLE_CHECKOUT_URL" class="btn" target="_blank">
    Get Pro Access
</a>
```

## Finding Your Paddle Checkout URL

Your Paddle checkout URL will look something like:
- `https://buy.paddle.com/product/xxxxxxx` (Classic Paddle)
- `https://checkout.paddle.com/checkout/buy/xxxxxxx` (Paddle Billing)

You can create different URLs for different pricing plans (Monthly, Annual, Lifetime) or use a single URL with a pricing table.

## Quick Update Command

Once you have your Paddle URL, run:

```bash
# Update both files at once
PADDLE_URL="https://your-paddle-checkout-url.com"

sed -i '' "s|href=\"#\" class=\"btn btn-primary\".*onclick=\"alert.*|href=\"$PADDLE_URL\" class=\"btn btn-primary\" data-umami-event=\"get-pro-click\" target=\"_blank\">Get Pro Access</a>|" docs/index.html

sed -i '' "s|href=\"#\" class=\"btn\".*onclick=\"alert.*Get Pro Access.*</a>|href=\"$PADDLE_URL\" class=\"btn\" target=\"_blank\">Get Pro Access</a>|" docs/download.html

# Verify changes
git diff docs/index.html docs/download.html

# Commit and push
git add docs/index.html docs/download.html
git commit -m "Update checkout links to use Paddle"
git push
```

## Testing

After updating:
1. Visit https://zetanotes.com/#pricing
2. Click "Get Pro Access"
3. Verify Paddle checkout page opens
4. Test purchase flow (can use Paddle's test mode)
5. Check Umami analytics to see "get-pro-click" events

## Notes

- The `target="_blank"` opens Paddle in a new tab
- Umami event tracking (`data-umami-event="get-pro-click"`) is preserved
- Privacy policy already mentions Paddle.com (no changes needed there)
