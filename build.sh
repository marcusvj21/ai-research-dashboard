#!/bin/bash
# build.sh - Generate data.json from research files
# Run this during heartbeats to update the dashboard

cd "$(dirname "$0")"

# Generate data.json using Node.js
node << 'EOF'
const fs = require('fs');
const path = require('path');

// Read source files
const researchPath = path.join(__dirname, '../RESEARCH.md');
const breakingPath = path.join(__dirname, '../BREAKING.md');
const memoryDir = path.join(__dirname, '../memory');

const items = [];

// Helper to parse markdown sections
function extractItems(content, category) {
    const lines = content.split('\n');
    let currentItem = null;
    
    for (let i = 0; i < lines.length; i++) {
        const line = lines[i];
        
        // Match headers like "### Title" or "## Title"
        if (line.match(/^###?\s+(.+)/)) {
            if (currentItem) items.push(currentItem);
            const title = line.replace(/^###?\s+/, '').trim();
            currentItem = {
                category,
                title,
                description: '',
                timestamp: new Date().toISOString().split('T')[0],
                link: null,
                subtitle: null,
                metrics: null
            };
        } else if (currentItem && line.trim()) {
            // Extract links
            const linkMatch = line.match(/\[([^\]]+)\]\(([^)]+)\)/);
            if (linkMatch) {
                currentItem.link = linkMatch[2];
                currentItem.description += linkMatch[1] + ' ';
            }
            
            // Extract HN metrics
            const metricsMatch = line.match(/(\d+)\s+points.*?(\d+)\s+comments/);
            if (metricsMatch) {
                currentItem.metrics = `${metricsMatch[1]} points • ${metricsMatch[2]} comments`;
            }
            
            // Accumulate description
            if (!line.startsWith('#') && !line.startsWith('**Last') && !line.startsWith('---')) {
                currentItem.description += line.trim() + ' ';
            }
        }
    }
    
    if (currentItem) items.push(currentItem);
}

// Parse BREAKING.md
try {
    const breaking = fs.readFileSync(breakingPath, 'utf8');
    const sections = breaking.split(/^## /m).slice(1);
    
    sections.forEach(section => {
        const lines = section.split('\n');
        const title = lines[0].trim();
        const content = lines.slice(1).join('\n').trim();
        
        let category = 'breaking';
        if (title.includes('arXiv')) category = 'arxiv';
        else if (title.includes('Hacker News')) category = 'hn';
        else if (title.includes('Anthropic') || title.includes('Claude')) category = 'anthropic';
        
        const item = {
            category,
            title: title.replace(/🚨|📄|🔥|🤖/g, '').trim(),
            description: content.substring(0, 300).trim() + '...',
            timestamp: new Date().toISOString().split('T')[0],
            link: null,
            subtitle: null,
            metrics: null
        };
        
        // Extract link
        const linkMatch = content.match(/https?:\/\/[^\s)]+/);
        if (linkMatch) item.link = linkMatch[0];
        
        // Extract metrics
        const metricsMatch = content.match(/(\d+)\s+points.*?(\d+)\s+comments/);
        if (metricsMatch) {
            item.metrics = `${metricsMatch[1]} points • ${metricsMatch[2]} comments`;
        }
        
        items.push(item);
    });
} catch (error) {
    console.error('Could not parse BREAKING.md:', error.message);
}

// Parse RESEARCH.md for recent items (last 10 entries per category)
try {
    const research = fs.readFileSync(researchPath, 'utf8');
    
    // Extract arXiv papers
    const arxivMatch = research.match(/## arXiv AI Papers[\s\S]*?(?=^## |\Z)/m);
    if (arxivMatch) {
        const papers = arxivMatch[0].match(/### .+[\s\S]*?(?=^### |\Z)/gm);
        if (papers) {
            papers.slice(-5).forEach(paper => {
                const titleMatch = paper.match(/### (.+)/);
                const arxivMatch = paper.match(/arxiv\.org\/abs\/(\d+\.\d+)/);
                
                if (titleMatch) {
                    items.push({
                        category: 'arxiv',
                        title: titleMatch[1].trim(),
                        description: paper.substring(0, 250).replace(/^### .+\n/, '').trim() + '...',
                        timestamp: new Date().toISOString().split('T')[0],
                        link: arxivMatch ? `https://arxiv.org/abs/${arxivMatch[1]}` : null,
                        subtitle: arxivMatch ? `arXiv:${arxivMatch[1]}` : null,
                        metrics: null
                    });
                }
            });
        }
    }
    
    // Extract HN trending
    const hnMatch = research.match(/## Hacker News[\s\S]*?(?=^## |\Z)/m);
    if (hnMatch) {
        const stories = hnMatch[0].match(/### .+[\s\S]*?(?=^### |\Z)/gm);
        if (stories) {
            stories.slice(-5).forEach(story => {
                const titleMatch = story.match(/### (.+)/);
                const linkMatch = story.match(/https?:\/\/[^\s)]+/);
                const metricsMatch = story.match(/(\d+)\s+points.*?(\d+)\s+comments/);
                
                if (titleMatch) {
                    items.push({
                        category: 'hn',
                        title: titleMatch[1].trim(),
                        description: story.substring(0, 250).replace(/^### .+\n/, '').trim() + '...',
                        timestamp: new Date().toISOString().split('T')[0],
                        link: linkMatch ? linkMatch[0] : null,
                        subtitle: null,
                        metrics: metricsMatch ? `${metricsMatch[1]} points • ${metricsMatch[2]} comments` : null
                    });
                }
            });
        }
    }
} catch (error) {
    console.error('Could not parse RESEARCH.md:', error.message);
}

// Sort by timestamp (newest first) and limit to 30
items.sort((a, b) => {
    const dateA = new Date(a.timestamp || '2000-01-01');
    const dateB = new Date(b.timestamp || '2000-01-01');
    return dateB - dateA; // Descending order (newest first)
});

// Generate output
const output = {
    lastUpdate: new Date().toISOString(),
    items: items.slice(0, 30) // Keep top 30 items (newest)
};

fs.writeFileSync(path.join(__dirname, 'data.json'), JSON.stringify(output, null, 2));
console.log(`✅ Generated data.json with ${output.items.length} items (sorted newest first)`);
EOF

echo "Dashboard data updated successfully!"
