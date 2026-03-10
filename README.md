# AI Research Intelligence Dashboard

Automated research dashboard for tracking AI developments, arXiv papers, Hacker News trends, and Anthropic/Claude ecosystem updates.

## Features

- 🚨 **Breaking News** - Major developments requiring immediate attention
- 📄 **arXiv Papers** - Latest AI/ML/Agent research
- 🔥 **Hacker News** - Trending AI discussions
- 🤖 **Anthropic/Claude** - Model updates, agent integration guides
- 🌐 **Ecosystem** - OpenClaw, tooling, infrastructure

## Setup

### Option 1: GitHub Pages (Recommended)

1. **Create a new GitHub repo** (or use existing)
   ```bash
   cd research-dashboard
   git init
   git add .
   git commit -m "Initial dashboard"
   git branch -M main
   git remote add origin https://github.com/YOUR_USERNAME/ai-research-dashboard.git
   git push -u origin main
   ```

2. **Enable GitHub Pages**
   - Go to repo Settings → Pages
   - Source: Deploy from branch `main` → `/` (root)
   - Save

3. **Your dashboard will be live at:**
   `https://YOUR_USERNAME.github.io/ai-research-dashboard/`

### Option 2: Local Testing

```bash
cd research-dashboard
python3 -m http.server 8000
# Open http://localhost:8000
```

### Option 3: Deploy to Vercel/Netlify

Just point these services at the `research-dashboard/` directory - they'll automatically serve `index.html`.

## Updates

The dashboard auto-refreshes data every 5 minutes. To manually update:

```bash
./build.sh
git add data.json
git commit -m "Update research data"
git push
```

## Automated Updates via Heartbeat

Add this to your heartbeat routine (already in `HEARTBEAT.md`):

```bash
cd /home/node/.openclaw/research/research-dashboard
./build.sh
git add data.json
git commit -m "Auto-update: $(date)"
git push
```

This will update the dashboard automatically every ~45-60 minutes.

## Customization

- **Edit `index.html`** to change styling, layout, or add sections
- **Modify `build.sh`** to parse different sources or change data structure
- **Update filters** in the HTML to add new categories

## Data Sources

- `../RESEARCH.md` - Comprehensive tracking
- `../BREAKING.md` - Breaking news
- `../memory/YYYY-MM-DD.md` - Daily logs
- Auto-generated via heartbeat monitoring of:
  - arXiv (cs.AI, cs.CL, cs.LG)
  - Hacker News top stories
  - Anthropic blog & research
  - OpenClaw ecosystem

---

Built with ❤️ by Researcher Agent 🔬
