#!/bin/bash
# build.sh - Generate data.json from research files
# Run this during heartbeats to update the dashboard

cd "$(dirname "$0")"

# Generate data.json using Node.js
node << 'EOF'
const fs = require('fs');
const path = require('path');

const researchPath = path.join(__dirname, '../RESEARCH.md');
const breakingPath = path.join(__dirname, '../BREAKING.md');

const items = [];

function parseResearchMarkdown(content, source) {
    const lines = content.split('\n');
    let i = 0;
    
    while (i < lines.length) {
        const line = lines[i];
        
        // Match ### headers (items)
        const headerMatch = line.match(/^###\s+(.+)/);
        if (headerMatch) {
            let title = headerMatch[1];
            
            // Clean up title (remove emoji, HN position, etc)
            title = title.replace(/🚨|📄|🔥|🤖|🌐|💰|🚫|🎨|🧠|⚖️|📊|🔬/g, '').trim();
            title = title.replace(/\*\*/g, '').trim();
            title = title.replace(/\(#\d+.*?\)/g, '').trim(); // Remove HN position
            
            // Extract content until next ### or ##
            let description = '';
            let link = null;
            let metrics = null;
            let category = 'breaking';
            
            i++;
            while (i < lines.length && !lines[i].match(/^##/)) {
                const contentLine = lines[i];
                
                // Extract links
                const linkMatch = contentLine.match(/https?:\/\/[^\s)]+/);
                if (linkMatch && !link) {
                    link = linkMatch[0];
                }
                
                // Extract arXiv ID
                const arxivMatch = contentLine.match(/arXiv:(\d+\.\d+)|arxiv\.org\/abs\/(\d+\.\d+)/);
                if (arxivMatch) {
                    category = 'arxiv';
                    const arxivId = arxivMatch[1] || arxivMatch[2];
                    if (!link) link = `https://arxiv.org/abs/${arxivId}`;
                }
                
                // Extract HN metrics
                const metricsMatch = contentLine.match(/(\d+)\s+(?:points|pts).*?(\d+)\s+comments/);
                if (metricsMatch) {
                    category = 'hn';
                    metrics = `${metricsMatch[1]} points • ${metricsMatch[2]} comments`;
                }
                
                // Check for Anthropic/Claude content
                if (contentLine.match(/anthropic|claude/i)) {
                    category = 'anthropic';
                }
                
                // Build description (skip empty lines and headers)
                if (contentLine.trim() && !contentLine.startsWith('#') && !contentLine.startsWith('---') && !contentLine.startsWith('📍')) {
                    description += contentLine.trim() + ' ';
                }
                
                i++;
            }
            
            // Create item
            if (title && description.length > 10) {
                items.push({
                    category,
                    title: title.substring(0, 150),
                    description: description.substring(0, 400).trim() + (description.length > 400 ? '...' : ''),
                    timestamp: new Date().toISOString(),
                    link: link,
                    subtitle: null,
                    metrics: metrics
                });
            }
            
        } else {
            i++;
        }
    }
}

// Parse RESEARCH.md
try {
    const research = fs.readFileSync(researchPath, 'utf8');
    parseResearchMarkdown(research, 'research');
    console.log(`Parsed RESEARCH.md: ${items.length} items so far`);
} catch (error) {
    console.error('Could not parse RESEARCH.md:', error.message);
}

// Parse BREAKING.md (higher priority - these go on top)
try {
    const breaking = fs.readFileSync(breakingPath, 'utf8');
    const breakingItems = [];
    parseResearchMarkdown(breaking, 'breaking');
    
    // Mark recent items from BREAKING.md with newer timestamp
    const recentCount = items.length > breakingItems.length ? items.length - breakingItems.length : 0;
    for (let i = recentCount; i < items.length; i++) {
        items[i].timestamp = new Date(Date.now() + (i * 1000)).toISOString(); // Ensure breaking items sort first
    }
    
    console.log(`Parsed BREAKING.md: ${items.length} total items`);
} catch (error) {
    console.error('Could not parse BREAKING.md:', error.message);
}

// Sort by timestamp (newest first)
items.sort((a, b) => {
    const dateA = new Date(a.timestamp);
    const dateB = new Date(b.timestamp);
    return dateB - dateA;
});

// Generate output (keep more items now)
const output = {
    lastUpdate: new Date().toISOString(),
    totalItems: items.length,
    items: items.slice(0, 100) // Keep top 100 items
};

fs.writeFileSync(path.join(__dirname, 'data.json'), JSON.stringify(output, null, 2));
console.log(`✅ Generated data.json with ${output.items.length} items (sorted newest first)`);
EOF

echo "Dashboard data updated successfully!"
