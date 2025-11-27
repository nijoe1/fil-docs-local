/*
    GitBook.com compatibility plugin for gitbook-cli

    Supports:
    - Tabs: {% tabs %}{% tab title="..." %}...{% endtab %}{% endtabs %}
    - Embed: {% embed url="..." %} (self-closing or with {% endembed %})
*/

// ============ TABS ============

function createTab(block, i, isActive) {
    var title = (block.kwargs && block.kwargs.title) || 'Tab ' + (i + 1);
    return '<div class="tab' + (isActive ? ' active' : '') + '" data-tab="' + i + '">' + title + '</div>';
}

async function createTabBody(book, block, i, isActive) {
    var body = block.body || '';
    var rendered = body ? await book.renderBlock('markdown', body) : '';
    return '<div class="tab-content' + (isActive ? ' active' : '') + '" data-tab="' + i + '">'
        + rendered
        + '</div>';
}

// ============ EMBED ============

function getYouTubeId(url) {
    if (!url) return null;
    var regExp = /^.*(youtu.be\/|v\/|u\/\w\/|embed\/|watch\?v=|\&v=)([^#\&\?]*).*/;
    var match = url.match(regExp);
    return (match && match[2] && match[2].length === 11) ? match[2] : null;
}

function createEmbedHtml(url, caption) {
    if (!url) {
        return '<div class="embed-container generic"><p>Missing embed URL</p></div>';
    }

    var youtubeId = getYouTubeId(url);

    if (youtubeId) {
        // YouTube embed
        var html = '<div class="embed-container youtube">' +
            '<iframe src="https://www.youtube.com/embed/' + youtubeId + '" ' +
            'frameborder="0" allowfullscreen allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture">' +
            '</iframe>';
        if (caption) {
            html += '<p class="embed-caption">' + caption + '</p>';
        }
        html += '</div>';
        return html;
    }

    // Generic link fallback
    return '<div class="embed-container generic">' +
        '<a href="' + url + '" target="_blank" rel="noopener">' + url + '</a>' +
        (caption ? '<p class="embed-caption">' + caption + '</p>' : '') +
        '</div>';
}

// Process embed tags in raw markdown before nunjucks parsing
function processEmbeds(content) {
    // Match both self-closing embeds and embeds with endembed
    // Pattern 1: {% embed url="..." %}...{% endembed %}
    // Pattern 2: {% embed url="..." %} (self-closing, followed by newline or end)

    // First handle embeds with endembed
    content = content.replace(
        /\{%\s*embed\s+url="([^"]+)"\s*%\}([\s\S]*?)\{%\s*endembed\s*%\}/g,
        function(match, url, caption) {
            return createEmbedHtml(url, caption.trim());
        }
    );

    // Then handle self-closing embeds (no endembed following)
    content = content.replace(
        /\{%\s*embed\s+url="([^"]+)"\s*%\}(?!\s*[\s\S]*?\{%\s*endembed)/g,
        function(match, url) {
            return createEmbedHtml(url, '');
        }
    );

    return content;
}

// ============ PLUGIN EXPORT ============

module.exports = {
    book: {
        assets: './assets',
        css: [
            'tabs.css',
            'embed.css'
        ],
        js: [
            'tabs.js'
        ]
    },

    hooks: {
        // Process page content before template engine
        'page:before': function(page) {
            page.content = processEmbeds(page.content);
            return page;
        }
    },

    blocks: {
        // Tabs block
        tabs: {
            blocks: ['tab', 'endtab'],
            process: async function(parentBlock) {
                var blocks = (parentBlock.blocks || []).filter(function(block) {
                    return block.name === 'tab';
                });
                var tabsContent = '';
                var tabsHeader = '';
                var i = 0;

                for (const block of blocks) {
                    var isActive = (i == 0);

                    tabsHeader += createTab(block, i, isActive);
                    tabsContent += await createTabBody(this.book, block, i, isActive);
                    i++;
                }

                return '<div class="tabs-container">' +
                    '<div class="tabs-header">' + tabsHeader + '</div>' +
                    '<div class="tabs-body">' + tabsContent + '</div>' +
                '</div>';
            }
        }
    }
};
