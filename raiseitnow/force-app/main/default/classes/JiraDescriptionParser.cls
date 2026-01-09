/**
* @description       : JiraDescriptionParser Class is used to converts Jira description JSON (ADF doc format)
*                      into HTML that can be stored safely in Salesforce Rich Text fields.
*                      This parser supports paragraphs, lists, code blocks, media (images),
*                      mentions, emojis, inline styles (bold, italic, colors), and links.
*                      All unknown or unsupported nodes gracefully fall back to plain text rendering.
* author             : Minuscule Technologies 
* @group             : 
* @last modified on  : 07-10-2025
* last modified by   : 
**/
/**
 * @description  Utility class that converts Jira description JSON (ADF doc format)
 *               into HTML that can be stored safely in Salesforce Rich Text fields.
 *               This parser supports paragraphs, lists, code blocks, media (images),
 *               mentions, emojis, inline styles (bold, italic, colors), and links.
 *               All unknown or unsupported nodes gracefully fall back to plain text rendering.
 *
 *
 */
public with sharing class JiraDescriptionParser {

    /**
     * @description Processes a top-level Jira "block" node into HTML.
     *
     * @param block JSON object representing a block (paragraph, list, codeBlock, media, etc.).
     * @return HTML equivalent of the block.
     */
    public static String processBlockHtml(Map<String, Object> block) {
        if (block == null || !block.containsKey('type')) {
            return '';
        }

        String type = (String) block.get('type');
        switch on type {
            when 'paragraph' {
                return handleParagraph(block);
            }
            when 'bulletList' {
                return handleBulletList(block);
            }
            when 'orderedList' {
                return handleOrderedList(block);
            }
            when 'codeBlock' {
                return handleCodeBlock(block);
            }
            when 'mediaSingle' {
                return handleMedia(block);
            }
            when else {
                return handleFallback(block);
            }
        }
    }

    // ------------------------
    // Block Handlers
    // ------------------------

    private static String handleParagraph(Map<String, Object> block) {
        return '<p>' + appendInlineHtml(block) + '</p>';
    }

    private static String handleBulletList(Map<String, Object> block) {
        String html = '<ul>';
        for (Object item : (List<Object>) block.get('content')) {
            html += '<li>' + appendInlineHtml((Map<String, Object>) item) + '</li>';
        }
        return html + '</ul>';
    }

    private static String handleOrderedList(Map<String, Object> block) {
        String html = '<ol>';
        for (Object item : (List<Object>) block.get('content')) {
            html += '<li>' + appendInlineHtml((Map<String, Object>) item) + '</li>';
        }
        return html + '</ol>';
    }

    private static String handleCodeBlock(Map<String, Object> block) {
        List<Object> content = (List<Object>) block.get('content');
        if (content.isEmpty()) {return '';} 
        Map<String, Object> textNode = (Map<String, Object>) content[0];
        return '<pre><code>' + textNode.get('text') + '</code></pre>';
    }

    private static String handleMedia(Map<String, Object> block) {
        if (!block.containsKey('content')) {return '';} 
        Map<String, Object> media = (Map<String, Object>) ((List<Object>) block.get('content'))[0];
        Map<String, Object> attrs = (Map<String, Object>) media.get('attrs');

		return '<p>[Media: ' + (attrs.containsKey('alt') ? attrs.get('alt') : 'file') + ']</p>';
    }

    private static String handleFallback(Map<String, Object> block) {
        return block.containsKey('content') ? appendInlineHtml(block) : '';
    }

    // ------------------------
    // Inline Handlers
    // ------------------------

    private static String appendInlineHtml(Map<String, Object> block) {
        if (!block.containsKey('content')) {return '';} 
        List<Object> content = (List<Object>) block.get('content');
        String html = '';

        for (Object obj : content) {
            html += handleInlineItem((Map<String, Object>) obj);
        }
        return html;
    }

    private static String handleInlineItem(Map<String, Object> item) {
        String type = (String) item.get('type');
        if (type == 'text') {
            return handleTextItem(item);
        } else if (type == 'hardBreak') {
            return '<br/>';
        } else if (type == 'mention') {
            return handleMention(item);
        } else if (type == 'emoji') {
            return handleEmoji(item);
        } else if (type == 'link') {
            return handleLink(item);
        } else if (item.containsKey('content')) {
            return appendInlineHtml(item); 
        }
        return '';
    }

    private static String handleTextItem(Map<String, Object> item) {
        String textValue = String.valueOf(item.get('text'));
        if (item.containsKey('marks')) {
            for (Object markObj : (List<Object>) item.get('marks')) {
                textValue = applyMark(textValue, (Map<String, Object>) markObj);
            }
        }
        return textValue;
    }

    private static String applyMark(String text, Map<String, Object> mark) {
        String markType = (String) mark.get('type');
        if (markType == 'strong') {
            return '<b>' + text + '</b>';
        } else if (markType == 'em') {
            return '<i>' + text + '</i>';
        } else if (markType == 'textColor' && mark.containsKey('attrs')) {
            Map<String, Object> attrs = (Map<String, Object>) mark.get('attrs');
            return '<span style="color:' + attrs.get('color') + '">' + text + '</span>';
        }
        return text;
    }

    private static String handleMention(Map<String, Object> item) {
        Map<String, Object> attrs = (Map<String, Object>) item.get('attrs');
        return attrs.containsKey('text') ? String.valueOf(attrs.get('text')) : '@mention';
    }

    private static String handleEmoji(Map<String, Object> item) {
        Map<String, Object> attrs = (Map<String, Object>) item.get('attrs');
        return String.valueOf(attrs.get('text'));
    }

    private static String handleLink(Map<String, Object> item) {
        Map<String, Object> attrs = (Map<String, Object>) item.get('attrs');
        String linkText = item.containsKey('text')
            ? String.valueOf(item.get('text'))
            : String.valueOf(attrs.get('href'));
        return '<a href="' + attrs.get('href') + '">' + linkText + '</a>';
    }
}