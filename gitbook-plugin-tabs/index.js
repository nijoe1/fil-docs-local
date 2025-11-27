/*
    Local gitbook-cli plugin that mimics GitBook.com's tabs syntax
    Uses {% tabs %} and {% tab title="..." %} blocks
*/

function createTab(block, i, isActive) {
    return '<div class="tab' + (isActive ? ' active' : '') + '" data-tab="' + i + '">' + block.kwargs.title + '</div>';
}

async function createTabBody(book, block, i, isActive) {
    let body = await book.renderBlock('markdown', block.body);
    return '<div class="tab-content' + (isActive ? ' active' : '') + '" data-tab="' + i + '">'
        + body
        + '</div>';
}

module.exports = {
    book: {
        assets: './assets',
        css: [
            'tabs.css'
        ],
        js: [
            'tabs.js'
        ]
    },

    blocks: {
        tabs: {
            blocks: ['tab'],
            process: async function(parentBlock) {
                var blocks = [parentBlock].concat(parentBlock.blocks);
                var tabsContent = '';
                var tabsHeader = '';
                var i = 0;

                for (const block of blocks) {
                    var isActive = (i == 0);

                    if (!block.kwargs.title) {
                        throw new Error('Tab requires a "title" property');
                    }

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
