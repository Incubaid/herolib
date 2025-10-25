# Unpoly API – Complete Reference & Operational Guide for AI Coding Agents

## Introduction

This document serves as a complete, self-contained reference manual for the **Unpoly JavaScript API**. It is written explicitly for AI coding agents that need to generate, validate, or refactor Unpoly-enhanced HTML and JavaScript code.

Unpoly is a front-end framework for progressive enhancement. It allows HTML pages to update fragments instead of reloading the full document, enabling seamless transitions, modals, caching, and navigation while maintaining server-side rendering.

An AI agent should use this manual to:
- Understand each Unpoly module and its purpose.
- Generate correct `up-*` attributes and JavaScript calls.
- Detect configuration errors and provide correction suggestions.
- Apply Unpoly in automated scaffolding, validation, and optimization workflows.

---

## 1. The up.link Module

### Purpose
Handles Unpoly-enhanced navigation. Converts normal links into AJAX-based fragment updates rather than full-page reloads.

### Core Concepts
When a user clicks a link with certain attributes, Unpoly intercepts the event and fetches the new page in the background. It then replaces specified fragments in the current document with matching elements from the response.

### Common Attributes

| Attribute       | Description                                              |
| --------------- | -------------------------------------------------------- |
| `up-follow`     | Marks the link as handled by Unpoly. Usually implied.    |
| `up-target`     | CSS selector identifying which fragment(s) to replace.   |
| `up-method`     | Overrides HTTP method (e.g. `GET`, `POST`).              |
| `up-params`     | Adds query parameters to the request.                    |
| `up-headers`    | Adds or overrides HTTP headers.                          |
| `up-layer`      | Determines which layer (page, overlay, modal) to update. |
| `up-transition` | Defines animation during fragment replacement.           |
| `up-cache`      | Enables caching of the response.                         |
| `up-history`    | Controls browser history behavior.                       |

### JavaScript API Methods
- `up.link.isFollowable(element)` – Returns true if Unpoly will intercept the link.
- `up.link.follow(element, options)` – Programmatically follow the link via Unpoly.
- `up.link.preload(element, options)` – Preload the linked resource into the cache.

### Agent Reasoning & Validation
- Ensure that every `up-follow` element has a valid `up-target` selector.
- Validate that target elements exist in both the current DOM and the server response.
- Recommend `up-cache` for commonly visited links to improve performance.
- Prevent using `target="_blank"` or `download` attributes with Unpoly links.

### Example
```html
<a href="/profile" up-target="#main" up-transition="fade">View Profile</a>
```

---

## 2. The up.form Module

### Purpose
Handles progressive enhancement for forms. Submissions happen via AJAX and update only specific fragments.

### Core Attributes

| Attribute        | Description                             |
| ---------------- | --------------------------------------- |
| `up-submit`      | Marks form to be submitted via Unpoly.  |
| `up-target`      | Fragment selector to update on success. |
| `up-fail-target` | Selector to update if submission fails. |
| `up-validate`    | Enables live field validation.          |
| `up-autosubmit`  | Submits automatically on change.        |
| `up-disable-for` | Disables fields during request.         |
| `up-enable-for`  | Enables fields after request completes. |

### JavaScript API
- `up.form.submit(form, options)` – Submit programmatically.
- `up.validate(field, options)` – Trigger server validation.
- `up.form.fields(form)` – Returns all input fields.

### Agent Reasoning
- Always ensure form has both `action` and `method` attributes.
- Match `up-target` to an element existing in the rendered HTML.
- For validation, ensure server supports `X-Up-Validate` header.
- When generating forms, add `up-fail-target` to handle errors gracefully.

### Example
```html
<form action="/update" method="POST" up-submit up-target="#user-info" up-fail-target="#form-errors">
  <input name="email" up-validate required>
  <button type="submit">Save</button>
</form>
```

---

## 3. The up.layer Module

### Purpose
Manages overlays, modals, and stacked layers of navigation.

### Attributes

| Attribute        | Description                                        |
| ---------------- | -------------------------------------------------- |
| `up-layer="new"` | Opens content in a new overlay.                    |
| `up-size`        | Controls modal size (e.g., `small`, `large`).      |
| `up-dismissable` | Allows overlay to close by clicking outside.       |
| `up-history`     | Determines if the overlay updates browser history. |
| `up-title`       | Sets overlay title.                                |

### JavaScript API
- `up.layer.open(options)` – Opens a new layer.
- `up.layer.close(layer)` – Closes a given layer.
- `up.layer.on(event, callback)` – Hooks into lifecycle events.

### Agent Notes
- Ensure `up-layer="new"` only used with valid targets.
- For overlays, set `up-history="false"` unless explicitly required.
- Auto-generate dismiss buttons with `up-layer-close`.

### Example
```html
<a href="/settings" up-layer="new" up-size="large" up-target=".modal-content">Open Settings</a>
```

---

## 4. The up.fragment Module

### Purpose
Handles low-level fragment rendering, preserving, replacing, and merging.

### JavaScript API
- `up.render(options)` – Replace fragment(s) with new content.
- `up.fragment.config` – Configure defaults for rendering.
- `up.fragment.get(target)` – Retrieve a fragment.

### Example
```js
up.render({ target: '#main', url: '/dashboard', transition: 'fade' })
```

### Agent Notes
- Ensure only fragment HTML is sent from server (not full document).
- Use `preserve` for elements like forms where input state matters.

---

## 5. The up.network Module

### Purpose
Handles network requests, caching, and aborting background loads.

### JavaScript API
- `up.network.loadPage(url, options)` – Load a page via Unpoly.
- `up.network.abort()` – Abort ongoing requests.
- `up.network.config.timeout` – Default timeout setting.

### Agent Tasks
- Preload probable links (`up.link.preload`).
- Use caching for frequent calls.
- Handle `up:network:late` event to show spinners.

---

## 6. The up.event Module

### Purpose
Manages custom events fired throughout Unpoly’s lifecycle.

### Common Events
- `up:link:follow`
- `up:form:submit`
- `up:layer:open`
- `up:layer:close`
- `up:rendered`
- `up:network:late`

### Example
```js
up.on('up:layer:close', (event) => {
  console.log('Overlay closed');
});
```

### Agent Actions
- Register listeners for key events.
- Prevent duplicate bindings.
- Offer analytics hooks for `up:rendered` or `up:location:changed`.

---

## 7. The up.motion Module

Handles animations and transitions.

### API
- `up.motion()` – Animate elements.
- `up.animate(element, keyframes, options)` – Custom animation.

### Agent Notes
- Suggest `up-transition="fade"` or similar for fragment changes.
- Avoid heavy animations for performance-sensitive devices.

---

## 8. The up.radio Module

Handles broadcasting and receiving cross-fragment events.

### Example
```js
up.radio.emit('user:updated', { id: 5 })
up.radio.on('user:updated', (data) => console.log(data))
```

### Agent Tasks
- Use for coordinating multiple fragments.
- Ensure channel names are namespaced (e.g., `form:valid`, `modal:open`).

---

## 9. The up.history Module

### Purpose
Manages URL history, titles, and restoration.

### API
- `up.history.push(url, options)` – Push new history entry.
- `up.history.restore()` – Restore previous state.

### Agent Guidance
- Disable history (`up-history="false"`) for temporary overlays.
- Ensure proper title update via `up-title`.

---

## 10. The up.viewport Module

### Purpose
Manages scrolling, focusing, and viewport restoration.

### API
- `up.viewport.scroll(element)` – Scroll to element.
- `up.viewport.restoreScroll()` – Restore previous position.

### Agent Tasks
- Restore scroll after fragment updates.
- Manage focus for accessibility after `up.render()`.

---

## 11. The up.protocol Module

Handles request headers and special HTTP status codes.

### Key Concepts
- Adds `X-Up-Target` and `X-Up-Validate` headers.
- Interprets redirect and validation responses.

### Agent Notes
- Ensure backend supports Unpoly headers.
- Warn if 204 or redirect status used without fragments.

---

## 12. The up.util Module

Contains helpers for arrays, strings, and timing.

### Examples
```js
up.util.escapeHTML("<script>") // "&lt;script&gt;"
up.util.copy(text)
```

### Agent Tasks
- Use helpers for DOM-safe generation.
- Avoid reimplementing basic utilities.

---

## 13. The up.framework and up.log Modules

- `up.framework.init()` – Initializes Unpoly.
- `up.log.enable()` – Enables debug logging.

### Agent Tasks
- Always call `up.framework.init()` once.
- Enable logging during debug sessions.

---

Good addition — including **Unpoly from a CDN** is essential for setup and automation.
Here’s the section you can append to the Markdown file (I can also regenerate the full file with it included if you prefer):

---

## 14. Including Unpoly from CDN

### Purpose

Before any Unpoly features or attributes (`up-*`) can work, the library must be loaded into the page.
For AI agents generating HTML pages or templates, always include Unpoly’s **CSS** and **JavaScript** assets early in the `<head>` section.

### Basic Setup (Latest Stable Version)

```html
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>My Unpoly Page</title>

  <!-- Unpoly Core Styles -->
  <link rel="stylesheet" href="https://unpkg.com/unpoly@3.7.2/unpoly.min.css">

  <!-- Optional Bootstrap integration -->
  <link rel="stylesheet" href="https://unpkg.com/unpoly@3.7.2/unpoly-bootstrap3.min.css">

  <!-- Unpoly Core Script -->
  <script src="https://unpkg.com/unpoly@3.7.2/unpoly.min.js"></script>

  <!-- Initialize framework -->
  <script>
    up.framework.init()
  </script>
</head>
<body>
  <!-- Page content -->
</body>
</html>
```

### AI Agent Notes

* Always include **`unpoly.min.css`** before any custom styles to ensure default animations and transitions function properly.
* **Never** load Unpoly twice; check if the page already has a `<script src="...unpoly.min.js">`.
* After loading, the agent may immediately use Unpoly JavaScript APIs (`up.render`, `up.link.follow`, etc.) or rely on HTML attributes.
* If dynamically injecting HTML pages, the agent should re-run `up.framework.init()` **only once globally**, not after every fragment load.

### Recommended CDN Sources

* `https://unpkg.com/unpoly@3.x/`
* `https://cdn.jsdelivr.net/npm/unpoly@3.x/`

### Offline Use

For fully offline or embedded environments, the agent can download both `.js` and `.css` files and reference them locally:

```html
<link rel="stylesheet" href="/assets/unpoly.min.css">
<script src="/assets/unpoly.min.js"></script>
```
---

## Agent Validation Checklist

1. Verify `up-*` attributes match existing fragments.  
2. Check backend returns valid fragment markup.  
3. Ensure forms use `up-submit` and `up-fail-target`.  
4. Overlay layers must have dismissable controls.  
5. Use caching wisely (`up-cache`, `up.link.preload`).  
6. Handle network and render events gracefully.  
7. Log events (`up.log`) for debugging.  
8. Confirm scroll/focus restoration after renders.  
9. Gracefully degrade if JavaScript disabled.  
10. Document reasoning and configuration.  




