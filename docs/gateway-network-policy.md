# Gateway Network Firewall Policy

When using WARP + Termius (Method 2), you may need a Gateway Network policy to explicitly allow traffic to your Mac's private IP.

## Create the Policy

1. Go to **Traffic policies > Firewall policies > Network** tab
2. Click **Add a policy**
3. Configure:
   - **Name:** `Allow Mac SSH`
   - **Selector:** `Destination IP`
   - **Operator:** `in`
   - **Value:** `YOUR_MAC_IP/32` (your Mac's IP)
   - **Action:** `Allow`
4. Save

## Why This May Be Needed

By default, Cloudflare Gateway may not have an explicit policy for private network traffic. Without an Allow policy, traffic to your Mac's IP could be silently dropped by Gateway even though the tunnel and split tunnel are correctly configured.

## Verify in Gateway Logs

After creating the policy, check if traffic appears in:
- **Traffic policies > Gateway activity logs > Network** tab
- Filter by destination IP `YOUR_MAC_IP`

If you see entries with Action: `Allow`, the policy is working.
If you see no entries at all, the WARP client is not sending traffic through Gateway (check `is_gateway` status).
