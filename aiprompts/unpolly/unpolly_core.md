# Unpoly Quick Reference for AI Agents

## Installation

Include Unpoly from CDN in your HTML `<head>`:

```html
<script src="https://unpoly.com/unpoly.min.js"></script>
<link rel="stylesheet" href="https://unpoly.com/unpoly.min.css">
```

## Core Concept

Unpoly updates page fragments without full page reloads. Users click links/submit forms → server responds with HTML → Unpoly extracts and swaps matching fragments.

---

## 1. Following Links (Fragment Updates)

### Basic Link Following

```html
<a href="/users/5" up-follow>View User</a>
```

Updates the `<main>` element (or `<body>` if no main exists) with content from `/users/5`.

### Target Specific Fragment

```html
<a href="/users/5" up-target=".user-details">View User</a>

<div class="user-details">
  <!-- Content replaced here -->
</div>
```

### Multiple Fragments

```html
<a href="/users/5" up-target=".profile, .activity">View User</a>
```

Updates both `.profile` and `.activity` from single response.

### Append/Prepend Content

```html
<!-- Append to list -->
<a href="/items?page=2" up-target=".items:after">Load More</a>

<!-- Prepend to list -->
<a href="/latest" up-target=".items:before">Show Latest</a>
```

### Handle All Links Automatically

```js
up.link.config.followSelectors.push('a[href]')
```

Now all links update fragments by default.

---

## 2. Submitting Forms

### Basic Form Submission

```html
<form action="/users" method="post" up-submit>
  <input name="email">
  <button type="submit">Create</button>
</form>
```

Submits via AJAX and updates `<main>` with response.

### Target Specific Fragment

```html
<form action="/search" up-submit up-target=".results">
  <input name="query">
  <button>Search</button>
</form>

<div class="results">
  <!-- Search results appear here -->
</div>
```

### Handle Success vs. Error Responses

```html
<form action="/users" method="post" up-submit 
      up-target="#success"
      up-fail-target="form">
  <input name="email">
  <button>Create</button>
</form>

<div id="success">Success message here</div>
```

- **Success (2xx status)**: Updates `#success`
- **Error (4xx/5xx status)**: Re-renders `form` with validation errors

**Server must return HTTP 422** (or similar error code) for validation failures.

---

## 3. Opening Overlays (Modal, Drawer, Popup)

### Modal Dialog

```html
<a href="/details" up-layer="new">Open Modal</a>
```

Opens `/details` in a modal overlay.

### Drawer (Sidebar)

```html
<a href="/menu" up-layer="new drawer">Open Drawer</a>
```

### Popup (Anchored to Link)

```html
<a href="/help" up-layer="new popup">Help</a>
```

### Close Overlay When Condition Met

```html
<a href="/users/new" 
   up-layer="new"
   up-accept-location="/users/$id"
   up-on-accepted="console.log('Created user:', value.id)">
  New User
</a>
```

Overlay auto-closes when URL matches `/users/123`, passes `{ id: 123 }` to callback.

### Local Content (No Server Request)

```html
<a up-layer="new popup" up-content="<p>Help text here</p>">Help</a>
```

---

## 4. Validation

### Validate on Field Change

```html
<form action="/users" method="post">
  <input name="email" up-validate>
  <input name="password" up-validate>
  <button type="submit">Register</button>
</form>
```

When field loses focus → submits form with `X-Up-Validate: email` header → server re-renders form → Unpoly updates the field's parent `<fieldset>` (or closest form group).

**Server must return HTTP 422** for validation errors.

### Validate While Typing

```html
<input name="email" up-validate 
       up-watch-event="input" 
       up-watch-delay="300">
```

Validates 300ms after user stops typing.

---

## 5. Lazy Loading & Polling

### Load When Element Appears in DOM

```html
<div id="menu" up-defer up-href="/menu">
  Loading menu...
</div>
```

Immediately loads `/menu` when placeholder renders.

### Load When Scrolled Into View

```html
<div id="comments" up-defer="reveal" up-href="/comments">
  Loading comments...
</div>
```

Loads when element scrolls into viewport.

### Auto-Refresh (Polling)

```html
<div class="status" up-poll up-interval="5000">
  Current status
</div>
```

Reloads fragment every 5 seconds from original URL.

---

## 6. Caching & Revalidation

### Enable Caching

```html
<a href="/users" up-cache="true">Users</a>
```

Caches response, instantly shows cached content, then revalidates with server.

### Disable Caching

```html
<a href="/stock" up-cache="false">Live Prices</a>
```

### Conditional Requests (Server-Side)

Server sends:

```http
HTTP/1.1 200 OK
ETag: "abc123"

<div class="data">Content</div>
```

Next reload, Unpoly sends:

```http
GET /path
If-None-Match: "abc123"
```

Server responds `304 Not Modified` if unchanged → saves bandwidth.

---

## 7. Navigation Bar (Current Link Highlighting)

```html
<nav>
  <a href="/home">Home</a>
  <a href="/about">About</a>
</nav>
```

Current page link gets `.up-current` class automatically.

**Style it:**

```css
.up-current {
  font-weight: bold;
  color: blue;
}
```

---

## 8. Loading State

### Feedback Classes

Automatically applied:

- `.up-active` on clicked link/button
- `.up-loading` on targeted fragment

**Style them:**

```css
.up-active { opacity: 0.6; }
.up-loading { opacity: 0.8; }
```

### Disable Form While Submitting

```html
<form up-submit up-disable>
  <input name="email">
  <button>Submit</button>
</form>
```

All fields disabled during submission.

### Show Placeholder While Loading

```html
<a href="/data" up-target=".data" 
   up-placeholder="<p>Loading...</p>">
  Load Data
</a>
```

---

## 9. Preloading

### Preload on Hover

```html
<a href="/users/5" up-preload>User Profile</a>
```

Starts loading when user hovers (90ms delay by default).

### Preload Immediately

```html
<a href="/menu" up-preload="insert">Menu</a>
```

Loads as soon as link appears in DOM.

---

## 10. Templates (Client-Side HTML)

### Define Template

```html
<template id="user-card">
  <div class="card">
    <h3>{{name}}</h3>
    <p>{{email}}</p>
  </div>
</template>
```

### Use Template

```html
<a up-fragment="#user-card" 
   up-use-data="{ name: 'Alice', email: 'alice@example.com' }">
  Show User
</a>
```

**Process variables with compiler:**

```js
up.compiler('.card', function(element, data) {
  element.innerHTML = element.innerHTML
    .replace(/{{name}}/g, data.name)
    .replace(/{{email}}/g, data.email)
})
```

---

## 11. JavaScript API

### Render Fragment

```js
up.render({ 
  url: '/users/5', 
  target: '.user-details' 
})
```

### Navigate (Updates History)

```js
up.navigate({ 
  url: '/users', 
  target: 'main' 
})
```

### Submit Form

```js
let form = document.querySelector('form')
up.submit(form)
```

### Open Overlay

```js
up.layer.open({ 
  url: '/users/new',
  onAccepted: (event) => {
    console.log('User created:', event.value)
  }
})
```

### Close Overlay with Value

```js
up.layer.accept({ id: 123, name: 'Alice' })
```

### Reload Fragment

```js
up.reload('.status')
```

---

## 12. Request Headers (Server Protocol)

Unpoly sends these headers with requests:

| Header          | Value    | Purpose                         |
| --------------- | -------- | ------------------------------- |
| `X-Up-Version`  | `1.0.0`  | Identifies Unpoly request       |
| `X-Up-Target`   | `.users` | Fragment selector being updated |
| `X-Up-Mode`     | `modal`  | Current layer mode              |
| `X-Up-Validate` | `email`  | Field being validated           |

**Server can respond with:**

| Header                   | Effect                   |
| ------------------------ | ------------------------ |
| `X-Up-Target: .other`    | Changes target selector  |
| `X-Up-Accept-Layer: {}`  | Closes overlay (success) |
| `X-Up-Dismiss-Layer: {}` | Closes overlay (cancel)  |

---

## 13. Common Patterns

### Infinite Scrolling

```html
<div id="items">
  <div>Item 1</div>
  <div>Item 2</div>
</div>

<a id="next" href="/items?page=2" 
   up-defer="reveal" 
   up-target="#items:after, #next">
  Load More
</a>
```

### Dependent Form Fields

```html
<form action="/order">
  <!-- Changing country updates city select -->
  <select name="country" up-validate="#city">
    <option>USA</option>
    <option>Canada</option>
  </select>
  
  <select name="city" id="city">
    <option>New York</option>
  </select>
</form>
```

### Confirm Before Action

```html
<a href="/delete" up-method="delete" 
   up-confirm="Really delete?">
  Delete
</a>
```

### Auto-Submit on Change

```html
<form action="/search" up-autosubmit>
  <input name="query">
</form>
```

Submits form when any field changes.

---

## 14. Error Handling

### Handle Network Errors

```js
up.on('up:fragment:offline', function(event) {
  if (confirm('You are offline. Retry?')) {
    event.retry()
  }
})
```

### Handle Failed Responses

```js
try {
  await up.render({ url: '/path', target: '.data' })
} catch (error) {
  if (error instanceof up.RenderResult) {
    console.log('Server error:', error)
  }
}
```

---

## 15. Compilers (Enhance Elements)

### Basic Compiler

```js
up.compiler('.current-time', function(element) {
  element.textContent = new Date().toString()
})
```

Runs when `.current-time` is inserted (initial load OR fragment update).

### Compiler with Cleanup

```js
up.compiler('.auto-refresh', function(element) {
  let timer = setInterval(() => {
    element.textContent = new Date().toString()
  }, 1000)
  
  // Return destructor function
  return () => clearInterval(timer)
})
```

Destructor called when element is removed from DOM.

---

## Quick Reference Table

| Task            | HTML                         | JavaScript                 |
| --------------- | ---------------------------- | -------------------------- |
| Follow link     | `<a href="/path" up-follow>` | `up.follow(link)`          |
| Submit form     | `<form up-submit>`           | `up.submit(form)`          |
| Target fragment | `up-target=".foo"`           | `{ target: '.foo' }`       |
| Open modal      | `up-layer="new"`             | `up.layer.open({ url })`   |
| Validate field  | `up-validate`                | `up.validate(field)`       |
| Lazy load       | `up-defer`                   | —                          |
| Poll fragment   | `up-poll`                    | —                          |
| Preload link    | `up-preload`                 | `up.link.preload(link)`    |
| Local content   | `up-content="<p>Hi</p>"`     | `{ content: '<p>Hi</p>' }` |
| Append content  | `up-target=".list:after"`    | —                          |
| Confirm action  | `up-confirm="Sure?"`         | `{ confirm: 'Sure?' }`     |

---

## Key Defaults

- **Target**: Updates `<main>` (or `<body>`) if no `up-target` specified
- **Caching**: Auto-enabled for GET requests during navigation
- **History**: Auto-updated when rendering `<main>` or major fragments
- **Scrolling**: Auto-scrolls to top when updating `<main>`
- **Focus**: Auto-focuses new fragment
- **Validation**: Targets field's parent `<fieldset>` or form group

---

## Best Practices for AI Agents

1. **Always provide HTTP error codes**: Return 422 for validation errors, 404 for not found, etc.
2. **Send full HTML responses**: Include entire page structure; Unpoly extracts needed fragments
3. **Use semantic HTML**: `<main>`, `<nav>`, `<form>` elements work best
4. **Set IDs on fragments**: Makes targeting easier (e.g., `<div id="user-123">`)
5. **Return consistent selectors**: If request targets `.users`, response must contain `.users`

---

## Common Mistakes to Avoid

❌ **Don't**: Return only partial HTML without wrapper
```html
<h1>Title</h1>
<p>Content</p>
```

✅ **Do**: Wrap in target selector
```html
<div class="content">
  <h1>Title</h1>
  <p>Content</p>
</div>
```

❌ **Don't**: Return 200 OK for validation errors  
✅ **Do**: Return 422 Unprocessable Entity

❌ **Don't**: Use `onclick="up.follow(this)"`  
✅ **Do**: Use `up-follow` attribute (handles keyboard, accessibility)

---

## Server Response Examples

### Successful Form Submission

```http
HTTP/1.1 200 OK

<div id="success">
  User created successfully!
</div>
```

### Validation Error

```http
HTTP/1.1 422 Unprocessable Entity

<form action="/users" method="post" up-submit>
  <input name="email" value="invalid">
  <div class="error">Email is invalid</div>
  <button>Submit</button>
</form>
```

### Partial Response (Optimized)

```http
HTTP/1.1 200 OK
Vary: X-Up-Target

<div class="user-details">
  <!-- Only the targeted fragment -->
</div>
```