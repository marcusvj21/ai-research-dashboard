#!/bin/bash
# build.sh - Generate data.json from research files
# FILTER FOR SIGNAL: Only practical, actionable intelligence for AI-native engineering

cd "$(dirname "$0")"

node << 'EOF'
const fs = require('fs');
const path = require('path');

const researchPath = path.join(__dirname, '../RESEARCH.md');
const breakingPath = path.join(__dirname, '../BREAKING.md');

const items = [];

// Keywords that indicate USEFUL content for AI-native engineering
const SIGNAL_KEYWORDS = [
    // Tools & frameworks
    'claude code', 'anthropic', 'openclaw', 'cursor', 'github copilot', 'agent framework',
    'coding agent', 'ai assistant', 'developer tool', 'ide', 'vscode', 'terminal',
    
    // Practical patterns
    'tutorial', 'guide', 'how to', 'demo', 'show hn', 'open source', 'github',
    'api', 'integration', 'workflow', 'setup', 'install',
    
    // Agent capabilities
    'tool use', 'function calling', 'multi-agent', 'autonomous', 'self-improving',
    'code generation', 'debugging', 'testing'
];

// Keywords that indicate NOISE (skip these)
const NOISE_KEYWORDS = [
    // Funding & business
    'raises $', '$1b', 'billion', 'funding', 'seed round', 'investment', 'valuation',
    
    // Legal & licensing
    'lawsuit', 'legal battle', 'controversy', 'ban', 'bans', 'policy', 'license debate',
    'copyright', 'no-llm', 'ai-generated code', 'philosophical', 'licensing crisis',
    'gpl', 'mit license', 'legal vs legitimate',
    
    // Industry drama
    'drama', 'conflict', 'walking away', 'exits', 'oracle', 'nvidia partnership', 
    'stock price', 'exploding', 'intensifying',
    
    // Academic-only research (no practical use)
    '3d reconstruction', 'deepmind', 'research advancement', 'new ai research',
    
    // General noise
    'yann lecun', 'redox', 'ethics debate', 'milestone', 'crisis'
];

function isSignal(text, link) {
    const lower = text.toLowerCase();
    
    // Immediate reject if has noise
    const hasNoise = NOISE_KEYWORDS.some(kw => lower.includes(kw));
    if (hasNoise) return false;
    
    // ALWAYS keep OpenClaw/Claude Code/Anthropic
    if (lower.includes('openclaw') || lower.includes('claude code') || lower.includes('anthropic')) {
        return true;
    }
    
    // Check for STRONG signal keywords
    const hasSignal = SIGNAL_KEYWORDS.some(kw => lower.includes(kw));
    
    // Boost if has actionable indicators
    const hasGitHub = link && link.includes('github.com');
    const hasDemo = lower.includes('demo') || lower.includes('show hn');
    const hasTutorial = lower.includes('tutorial') || lower.includes('guide') || lower.includes('how to');
    
    // Keep if: (has signal AND actionable) OR (has strong keywords)
    return (hasSignal && (hasGitHub || hasDemo || hasTutorial)) ||
           lower.includes('agent framework') ||
           lower.includes('coding agent') ||
           lower.includes('developer tool');
}

function parseResearchMarkdown(content, source) {
    const lines = content.split('\n');
    let i = 0;
    
    while (i < lines.length) {
        const line = lines[i];
        
        const headerMatch = line.match(/^###\s+(.+)/);
        if (headerMatch) {
            let title = headerMatch[1];
            title = title.replace(/🚨|📄|🔥|🤖|🌐|💰|🚫|🎨|🧠|⚖️|📊|🔬/g, '').trim();
            title = title.replace(/\*\*/g, '').trim();
            title = title.replace(/\(#\d+.*?\)/g, '').trim();
            
            let description = '';
            let link = null;
            let metrics = null;
            let category = 'breaking';
            
            i++;
            while (i < lines.length && !lines[i].match(/^##/)) {
                const contentLine = lines[i];
                
                const linkMatch = contentLine.match(/https?:\/\/[^\s)]+/);
                if (linkMatch && !link) {
                    link = linkMatch[0];
                }
                
                const arxivMatch = contentLine.match(/arXiv:(\d+\.\d+)|arxiv\.org\/abs\/(\d+\.\d+)/);
                if (arxivMatch) {
                    category = 'arxiv';
                    const arxivId = arxivMatch[1] || arxivMatch[2];
                    if (!link) link = `https://arxiv.org/abs/${arxivId}`;
                }
                
                const metricsMatch = contentLine.match(/(\d+)\s+(?:points|pts).*?(\d+)\s+comments/);
                if (metricsMatch) {
                    category = 'hn';
                    metrics = `${metricsMatch[1]} points • ${metricsMatch[2]} comments`;
                }
                
                if (contentLine.match(/anthropic|claude/i)) {
                    category = 'anthropic';
                }
                
                if (contentLine.match(/openclaw/i)) {
                    category = 'ecosystem';
                }
                
                if (contentLine.trim() && !contentLine.startsWith('#') && !contentLine.startsWith('---') && !contentLine.startsWith('📍')) {
                    description += contentLine.trim() + ' ';
                }
                
                i++;
            }
            
            // FILTER: Only include if it passes signal test
            const fullText = title + ' ' + description;
            if (title && description.length > 10 && isSignal(fullText, link)) {
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

// Parse files
try {
    const research = fs.readFileSync(researchPath, 'utf8');
    parseResearchMarkdown(research, 'research');
    console.log(`Parsed RESEARCH.md: ${items.length} relevant items (filtered)`);
} catch (error) {
    console.error('Could not parse RESEARCH.md:', error.message);
}

try {
    const breaking = fs.readFileSync(breakingPath, 'utf8');
    const beforeCount = items.length;
    parseResearchMarkdown(breaking, 'breaking');
    console.log(`Parsed BREAKING.md: +${items.length - beforeCount} items`);
} catch (error) {
    console.error('Could not parse BREAKING.md:', error.message);
}

// Sort by timestamp (newest first)
items.sort((a, b) => {
    const dateA = new Date(a.timestamp);
    const dateB = new Date(b.timestamp);
    return dateB - dateA;
});

const output = {
    lastUpdate: new Date().toISOString(),
    totalItems: items.length,
    items: items.slice(0, 50) // Top 50 RELEVANT items only
};

fs.writeFileSync(path.join(__dirname, 'data.json'), JSON.stringify(output, null, 2));
console.log(`✅ Generated data.json with ${output.items.length} ACTIONABLE items (noise filtered)`);
EOF

echo "Dashboard updated with signal-only filtering!"
