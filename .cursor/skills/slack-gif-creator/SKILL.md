---
name: slack-gif-creator
description: Knowledge and utilities for creating animated GIFs optimized for Slack. Provides constraints, validation tools, and animation concepts. Use when users request animated GIFs for Slack like "make me a GIF of X doing Y for Slack."
---

# Slack GIF Creator

A toolkit providing utilities and knowledge for creating animated GIFs optimized for Slack.

## Slack Requirements

**Dimensions:**
- Emoji GIFs: 128x128 (recommended)
- Message GIFs: 480x480

**Parameters:**
- FPS: 10-30 (lower is smaller file size)
- Colors: 48-128 (fewer = smaller file size)
- Duration: Keep under 3 seconds for emoji GIFs

## Core Workflow

```python
from core.gif_builder import GIFBuilder
from PIL import Image, ImageDraw

# 1. Create builder
builder = GIFBuilder(width=128, height=128, fps=10)

# 2. Generate frames
for i in range(12):
    frame = Image.new('RGB', (128, 128), (240, 248, 255))
    draw = ImageDraw.Draw(frame)
    # Draw your animation using PIL primitives
    builder.add_frame(frame)

# 3. Save with optimization
builder.save('output.gif', num_colors=48, optimize_for_emoji=True)
```

## Drawing Graphics

### Working with User-Uploaded Images
If a user uploads an image, consider whether they want to:
- **Use it directly** (e.g., "animate this", "split this into frames")
- **Use it as inspiration** (e.g., "make something like this")

```python
from PIL import Image
uploaded = Image.open('file.png')
```

### Drawing from Scratch
When drawing graphics from scratch, use PIL ImageDraw primitives:

```python
from PIL import ImageDraw
draw = ImageDraw.Draw(frame)

# Circles/ovals
draw.ellipse([x1, y1, x2, y2], fill=(r, g, b), outline=(r, g, b), width=3)
# Polygons
points = [(x1, y1), (x2, y2), (x3, y3)]
draw.polygon(points, fill=(r, g, b), outline=(r, g, b), width=3)
# Lines
draw.line([(x1, y1), (x2, y2)], fill=(r, g, b), width=5)
# Rectangles
draw.rectangle([x1, y1, x2, y2], fill=(r, g, b), outline=(r, g, b), width=3)
```

**Making Graphics Look Good:**
- Use thicker lines - Always set `width=2` or higher
- Add visual depth with gradients and layered shapes
- Use vibrant, complementary colors
- Be creative and detailed - a good Slack GIF should look polished

## Available Utilities

### GIFBuilder (`core.gif_builder`)
```python
builder = GIFBuilder(width=128, height=128, fps=10)
builder.add_frame(frame)  # Add PIL Image
builder.add_frames(frames)  # Add list of frames
builder.save('out.gif', num_colors=48, optimize_for_emoji=True, remove_duplicates=True)
```

### Validators (`core.validators`)
```python
from core.validators import validate_gif, is_slack_ready
passes, info = validate_gif('my.gif', is_emoji=True, verbose=True)
if is_slack_ready('my.gif'):
    print("Ready!")
```

### Easing Functions (`core.easing`)
```python
from core.easing import interpolate
t = i / (num_frames - 1)  # Progress from 0.0 to 1.0
y = interpolate(start=0, end=400, t=t, easing='ease_out')
# Available: linear, ease_in, ease_out, ease_in_out, bounce_out, elastic_out, back_out
```

### Frame Helpers (`core.frame_composer`)
```python
from core.frame_composer import (
    create_blank_frame,         # Solid color background
    create_gradient_background,  # Vertical gradient
    draw_circle,                # Helper for circles
    draw_text,                  # Simple text rendering
    draw_star                   # 5-pointed star
)
```

## Animation Concepts

- **Shake/Vibrate**: Offset position with `math.sin()` oscillation
- **Pulse/Heartbeat**: Scale object size rhythmically with sine wave
- **Bounce**: Use `interpolate()` with `easing='bounce_out'`
- **Spin/Rotate**: `image.rotate(angle, resample=Image.BICUBIC)`
- **Fade In/Out**: Create RGBA image, adjust alpha channel
- **Slide**: Move from off-screen using `easing='ease_out'`
- **Explode/Particle Burst**: Generate particles radiating outward with gravity

## Optimization Strategies

Only when asked to make the file size smaller:

1. **Fewer frames** - Lower FPS (10 instead of 20) or shorter duration
2. **Fewer colors** - `num_colors=48` instead of 128
3. **Smaller dimensions** - 128x128 instead of 480x480
4. **Remove duplicates** - `remove_duplicates=True` in save()
5. **Emoji mode** - `optimize_for_emoji=True` auto-optimizes

```python
# Maximum optimization for emoji
builder.save('emoji.gif', num_colors=48, optimize_for_emoji=True, remove_duplicates=True)
```

## Philosophy

This skill provides:
- **Knowledge**: Slack's requirements and animation concepts
- **Utilities**: GIFBuilder, validators, easing functions
- **Flexibility**: Create the animation logic using PIL primitives

It does NOT provide:
- Rigid animation templates or pre-made functions
- Emoji font rendering (unreliable across platforms)
- A library of pre-packaged graphics built into the skill

Be creative! Combine concepts and use PIL's full capabilities.
