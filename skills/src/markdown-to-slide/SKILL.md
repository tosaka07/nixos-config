---
name: markdown-to-slide
description: Convert Markdown to PDF/PPTX presentations using Marp. Use when Claude needs to create presentation slides from Markdown files with Marp syntax.
---

# Marp Presentation Creation Guide

## Overview

Marp (Markdown Presentation Ecosystem) converts Markdown files into beautiful presentation slides (PDF, PPTX, HTML). This guide covers creating presentations using Marp CLI with custom themes and styling.

## Quick Start

### Basic Conversion

```bash
# Convert Markdown to PDF
npx @marp-team/marp-cli slides.md -o output.pdf

# Convert to PowerPoint
npx @marp-team/marp-cli slides.md -o output.pptx

# Convert to HTML
npx @marp-team/marp-cli slides.md -o output.html

# Watch mode (auto-reload on save)
npx @marp-team/marp-cli -w slides.md
```

## Markdown Syntax

### Basic Slide Structure

```markdown
---
marp: true
theme: default
paginate: true
---

# Title Slide

Your presentation title

---

## Second Slide

- Bullet point 1
- Bullet point 2

---

## Slide with Image

![width:600px](image.png)

---
```

### Slide Directives

Use `---` to separate slides. Directives control slide behavior:

```markdown
---
marp: true
theme: default
size: 16:9
paginate: true
backgroundColor: #fff
---

<!-- _class: lead -->

# Centered Lead Slide

---

<!-- _backgroundColor: #123456 -->

## Slide with Custom Background

---
```

### Text Formatting

```markdown
# Heading 1

## Heading 2

### Heading 3

**Bold text**
_Italic text_
~~Strikethrough~~

> Blockquote

`inline code`
```

### Lists

```markdown
## Bullet Lists

- Item 1
- Item 2
  - Nested item

## Numbered Lists

1. First item
2. Second item
3. Third item
```

### Images

```markdown
<!-- Default size -->

![](image.png)

<!-- Custom width -->

![width:500px](image.png)

<!-- Custom height -->

![height:300px](image.png)

<!-- Background image -->

![bg](background.png)

<!-- Background image with custom size -->

![bg fit](image.png)
![bg contain](image.png)
![bg cover](image.png)

<!-- Split background -->

![bg left](image1.png)
![bg right](image2.png)
```

### Code Blocks

````markdown
```python
def hello():
    print("Hello, Marp!")
```
````

```javascript
const greeting = "Hello, Marp!";
console.log(greeting);
```

````

### Two-Column Layout

```markdown
<div class="columns">
<div>

## Left Column
Content for left side

</div>
<div>

## Right Column
Content for right side

</div>
</div>
````

### Tables

```markdown
| Header 1 | Header 2 | Header 3 |
| -------- | -------- | -------- |
| Cell 1   | Cell 2   | Cell 3   |
| Cell 4   | Cell 5   | Cell 6   |
```

## Themes

### Built-in Themes

- `default`: Clean, professional design
- `gaia`: Modern, colorful theme
- `uncover`: Minimalist, elegant theme

```markdown
---
marp: true
theme: gaia
---
```

### Custom Themes

Create a custom CSS file (e.g., `custom-theme.css`):

```css
/* @theme custom */

@import "default";

section {
  background-color: #f5f5f5;
  color: #333;
  font-family: "Arial", sans-serif;
}

h1 {
  color: #2c3e50;
  border-bottom: 3px solid #3498db;
  padding-bottom: 10px;
}

h2 {
  color: #34495e;
}

a {
  color: #3498db;
}

code {
  background-color: #ecf0f1;
  padding: 2px 6px;
  border-radius: 3px;
}
```

Apply custom theme:

```bash
npx @marp-team/marp-cli slides.md --theme custom-theme.css -o output.pdf
```

Or reference in frontmatter:

```markdown
---
marp: true
theme: custom
---
```

## Advanced Features

### Slide Classes

```markdown
<!-- _class: lead -->

# Centered Title Slide

---

<!-- _class: invert -->

## Dark Background Slide
```

### Background Colors

```markdown
<!-- _backgroundColor: #e74c3c -->

# Red Background

---

<!-- _backgroundColor: aqua -->

# Aqua Background
```

### Header and Footer

```markdown
---
marp: true
header: "My Presentation"
footer: "Page %page%"
---
```

### Math (KaTeX)

```markdown
Inline math: $E = mc^2$

Block math:

$$
\int_{a}^{b} f(x) dx
$$
```

### Fragmented Lists (Step-by-step)

Not directly supported in Marp CLI, but you can create multiple slides:

```markdown
## Step 1

- First point

---

## Step 2

- First point
- Second point

---

## Step 3

- First point
- Second point
- Third point
```

## CLI Options

### Common Options

```bash
# Specify output format
npx @marp-team/marp-cli slides.md -o output.pdf
npx @marp-team/marp-cli slides.md -o output.pptx

# Custom theme
npx @marp-team/marp-cli slides.md --theme custom.css -o output.pdf

# Allow local files
npx @marp-team/marp-cli slides.md --allow-local-files -o output.pdf

# PDF options
npx @marp-team/marp-cli slides.md --pdf --pdf-outlines -o output.pdf

# Watch mode
npx @marp-team/marp-cli -w slides.md

# Server mode with preview
npx @marp-team/marp-cli -s slides.md

# Multiple input files
npx @marp-team/marp-cli slides1.md slides2.md -o output-dir/
```

### Configuration File

Create `marp.config.js` or `.marprc.yml`:

```javascript
// marp.config.js
module.exports = {
  inputDir: "./slides",
  output: "./dist",
  themeSet: "./themes",
  pdf: true,
  allowLocalFiles: true,
};
```

Or YAML:

```yaml
# .marprc.yml
inputDir: ./slides
output: ./dist
themeSet: ./themes
pdf: true
allowLocalFiles: true
```

## Best Practices

### Content Guidelines

1. **One idea per slide**: Keep slides focused and simple
2. **Minimal text**: Use bullet points, not paragraphs
3. **Visual hierarchy**: Use headings and formatting consistently
4. **Images**: Use high-quality, relevant images
5. **Contrast**: Ensure text is readable against backgrounds

### Design Guidelines

1. **Consistent theme**: Stick to one theme throughout
2. **Color palette**: Use 2-3 main colors
3. **Font size**: Ensure text is readable (minimum 20pt)
4. **White space**: Don't overcrowd slides
5. **Alignment**: Keep elements aligned and organized

### Workflow

1. **Start with outline**: Plan your content structure
2. **Create Markdown**: Write content in Markdown format
3. **Add directives**: Apply themes and styling
4. **Preview**: Use watch mode to see changes live
5. **Export**: Generate final PDF/PPTX
6. **Review**: Check formatting and readability

## Example Presentation

````markdown
---
marp: true
theme: gaia
paginate: true
backgroundColor: #fff
---

<!-- _class: lead -->

# My Awesome Presentation

**Subtitle or Author Name**
Date

---

## Agenda

1. Introduction
2. Key Points
3. Conclusion

---

## Introduction

- Point 1: Context and background
- Point 2: Problem statement
- Point 3: Our approach

---

## Key Point 1

![bg right:40%](image1.png)

- Important detail
- Supporting evidence
- Example or case study

---

## Key Point 2

```python
def example():
    return "Code example"
```
````

- Technical explanation
- Benefits
- Use cases

---

<!-- _class: lead -->

# Questions?

<contact@example.com>

````

## Troubleshooting

### Common Issues

**Issue**: Images not loading
```bash
# Solution: Use --allow-local-files flag
npx @marp-team/marp-cli slides.md --allow-local-files -o output.pdf
````

**Issue**: Custom fonts not working

```css
/* Solution: Add to custom theme CSS */
@import url("https://fonts.googleapis.com/css2?family=Roboto:wght@400;700&display=swap");

section {
  font-family: "Roboto", sans-serif;
}
```

**Issue**: PDF generation fails

```bash
# Solution: Install Chrome/Chromium
# macOS
brew install chromium

# Ubuntu/Debian
sudo apt-get install chromium-browser
```

## Dependencies

Required:

- **Node.js**: v14 or later
- **npm** or **npx**: For package execution

Optional:

- **Chrome/Chromium**: For PDF generation (automatically downloaded if not present)
- **Custom fonts**: For advanced typography

## Installation

```bash
# Using npx (no installation needed)
npx @marp-team/marp-cli --version

# Global installation
npm install -g @marp-team/marp-cli

# Project-specific installation
npm install --save-dev @marp-team/marp-cli
```

## Resources

- Official documentation: <https://marp.app/>
- Marpit framework: <https://marpit.marp.app/>
- Theme gallery: <https://github.com/marp-team/marp-core/tree/main/themes>
- Examples: <https://github.com/marp-team/marp-cli/tree/main/examples>

## Quick Reference

| Task             | Command                                               |
| ---------------- | ----------------------------------------------------- |
| Convert to PDF   | `npx @marp-team/marp-cli slides.md -o output.pdf`     |
| Convert to PPTX  | `npx @marp-team/marp-cli slides.md -o output.pptx`    |
| Watch mode       | `npx @marp-team/marp-cli -w slides.md`                |
| Custom theme     | `npx @marp-team/marp-cli slides.md --theme theme.css` |
| New slide        | `---`                                                 |
| Image width      | `![width:500px](image.png)`                           |
| Background image | `![bg](image.png)`                                    |
| Center slide     | `<!-- _class: lead -->`                               |
| Page numbers     | `paginate: true` in frontmatter                       |
