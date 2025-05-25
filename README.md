## Table of contents

- [Table of contents](#table-of-contents)
- [Introduction](#introduction)
- [1. The Problem with Vite and Environment Variables](#1-the-problem-with-vite-and-environment-variables)
- [2. The Concept: Build Once, Inject Later](#2-the-concept-build-once-inject-later)
- [🔁 How It Works (Visual Recap)](#-how-it-works-visual-recap)
- [3. Step-by-Step Setup](#3-step-by-step-setup)
  - [Step 1: Define Placeholders in `.env.production`](#step-1-define-placeholders-in-envproduction)
  - [Step 2: Add the Runtime Script (`env.sh`)](#step-2-add-the-runtime-script-envsh)
  - [Step 3: Set Up Docker](#step-3-set-up-docker)
    - [🐳 Dockerfile – Explained](#-dockerfile--explained)
    - [🧩 docker-compose.yml – Explained](#-docker-composeyml--explained)
- [4. Advantages and Gotchas](#4-advantages-and-gotchas)
  - [✅ Pros](#-pros)
  - [⚠️ Gotchas](#️-gotchas)
- [🔗 Resources](#-resources)
- [✅ Final Thoughts](#-final-thoughts)

## Introduction

Stop me if this sounds familiar…

You’ve built a slick Vite frontend, bundled it into a Docker container, and you’re ready to deploy it across environments. Staging. QA. Production. You spin up a few containers with Docker Compose, pass in some environment variables, and… nothing. Your frontend still shows the old values. Or worse, hardcoded ones from build time.

Why? Because Vite bakes your environment variables into the JavaScript at build time. That means by the time your app hits the container, those variables are already locked in. If you want to change them, you’ve got to rebuild your app from scratch—for each environment. Which defeats the entire point of using Docker in the first place.

Here's the fix:
In this guide, you’ll learn how to build your Vite app once with environment placeholders, and inject the actual values at runtime using a simple script inside Docker. No more rebuilding for every deploy. Just plug in your config at startup, and let your container do the rest.

## 1. The Problem with Vite and Environment Variables

Vite makes development fast—but once you hit deployment, it locks you into a limitation that trips up a lot of devs:

> Environment variables are statically replaced **at build time**, not dynamically read at runtime.

That means when you run `npm run build`, Vite crawls through your code and literally replaces any reference like `import.meta.env.VITE_API_URL` with the value in `.env.production` at that moment. It becomes a hardcoded string in your final JS bundle.

If you want different values for staging or production? You’re stuck rebuilding your app for each environment. That’s time-consuming, error-prone, and kills the point of Docker’s "build once, run anywhere" philosophy.

---

## 2. The Concept: Build Once, Inject Later

Here’s the idea: instead of hardcoding real values into your build, you **bake in placeholders**—clearly identifiable markers like `PREFIX_API_URL`.

Then, when the container starts up, a small shell script scans the final JavaScript files and swaps those placeholders for actual values from your environment—using plain old `sed`. Just before Nginx serves the files.

Why this works:

- **Vite doesn’t know** your values at build time—it just drops in what you give it.
- At runtime, **Docker does know** your values, and you can use them to patch the final files.
- You still get a fully static, cacheable frontend bundle—but with runtime flexibility.

And no, it’s not a hack—it’s a pragmatic workaround that’s safe, production-ready, and used in many real-world pipelines.

---

## 🔁 How It Works (Visual Recap)

Here’s what’s happening behind the scenes:

1. **Build phase**

   - Vite replaces env references with placeholder strings like `"PREFIX_API_URL"` in your compiled JS.

2. **Runtime phase**

   - Your Docker container starts with the real environment variables (e.g. `PREFIX_API_URL=https://api.myapp.com`).
   - A shell script replaces every placeholder in the final JS/HTML files.
   - Nginx serves the updated files.

![How it works](https://mermaid.ink/img/pako:eNp9kt1q4zAQhV9FzLVrYsfOj6GFbpJlA7tQShNKMRTFmsYismTGcrNpnHevbEO9LWx1ITQjfeeMpDlDZgRCAi_KHLOck2UPy1QzN6p6tyde5uyOTIZV1WfbsTTZAWlhitJUyK6ubtiPWirRrprt-mH1vL39vVld392vfq4f-6Bh64Lv8RuN5t_j179QKcOOhpRo2KZkA9jpdADqV0lGF6itv-Wqxi-Om3KgnMRXD9bzLc5eOUm-U8gIS8UzFOwobc7yoQq2O7WAX-UNW2lLp9JIbQeDIfef2j7daGG05VIj9QKoBXiwJykgeeGqQg8KpIK3MZzbMynYHAtMIXFLwemQQqovDiq5fjKmgMRS7TAy9T7_EKlLwS0uJXcfWXxkydm1T19rC0kQR9NOBZIz_IUkDGI_mgTxJBgH03AWxbEHJ0gmU38ejcNZGM2DIIxH8cWDt8535M_CyXg0GodumrttD1BIa-hP31hdf13eAek8wtI)

---

## 3. Step-by-Step Setup

Let’s walk through how to set this up from scratch.

### Step 1: Define Placeholders in `.env.production`

Create a `.env.production` file in the root of your project. The `.env.production` file will be used by vite build for its environment variables. Inside your project, add this line to `.env.production`:

```env
VITE_API_URL=PREFIX_API_URL
```

The value `PREFIX_API_URL` is a placeholder that Vite will statically bake into your code. It doesn’t need to be real—just something unique and easy to find later.

### Step 2: Add the Runtime Script (`env.sh`)

> **This is the important part**

Drop this [env.sh](https://github.com/Dutchskull/Vite-Dynamic-Environment-Variables/blob/main/app/env.sh) script into your project root. Make sure it’s executable (`chmod +x env.sh`) and converted to Unix line endings (`dos2unix env.sh` if needed). If you don't want to do this every time you can also add those commands to your `Dockerfile`.

---

### Step 3: Set Up Docker

#### 🐳 Dockerfile – Explained

Here’s a Dockerfile that builds your Vite app and prepares it for runtime replacement:

```Dockerfile
# Step 1: Build the app using Node
FROM node:23-alpine AS builder

WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Step 2: Use a lightweight Nginx container to serve the files
FROM nginx:alpine

# Copy Nginx config if you have custom routing
COPY ./nginx.conf /etc/nginx/nginx.conf

# Copy the built app from the builder stage
COPY --from=builder /app/dist /var/www/html/

# Copy the runtime injection script into the container
COPY env.sh /docker-entrypoint.d/env.sh
RUN dos2unix /docker-entrypoint.d/env.sh
RUN chmod +x /docker-entrypoint.d/env.sh

# Let Docker run your script before starting Nginx
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
```

---

#### 🧩 docker-compose.yml – Explained

This Compose config shows how to inject the real values during container startup:

```yaml
services:
  app:
    image: app:latest
    build:
      context: app
    ports:
      - "8080:80"
    environment:
      # Where your built files live in the container
      ASSET_DIR: /var/www/html

      # Prefix used for placeholder detection
      APP_PREFIX: PREFIX_

      # Real values for your frontend to consume
      PREFIX_API_URL: "https://api.myapp.com"
```

Key things happening here:

- `ASSET_DIR` tells `env.sh` where to search for files.
- `APP_PREFIX` ensures we only replace the values we want.
- `PREFIX_API_URL` is the real value your app needs—matched to the placeholder in `.env.production`.

---

## 4. Advantages and Gotchas

### ✅ Pros

- **Single build for all environments**
  Build once. Deploy many times.

- **Static file friendly**
  Keeps your assets cacheable and CDN-ready.

- **Framework agnostic**
  Works with any static frontend—not just Vite.

### ⚠️ Gotchas

- **Pick a unique prefix**
  Avoid accidental replacements. `PREFIX_` is a good default.

- **Beware of quotes and special characters**
  Escape them properly if needed in shell scripts.

---

## 🔗 Resources

- 📂 GitHub Repo: [Dutchskull/Vite-Dynamic-Environment-Variables](https://github.com/Dutchskull/Vite-Dynamic-Environment-Variables)
- 🧰 Shell script: [`env.sh`](https://github.com/Dutchskull/Vite-Dynamic-Environment-Variables/blob/main/app/env.sh)

---

## ✅ Final Thoughts

This setup gives you flexibility without sacrificing speed or simplicity. You keep your frontend static, lightweight, and easy to cache—while still injecting environment-specific config at runtime.

It’s a clean bridge between how Vite works and how Docker deployments _need_ to work.

You no longer have to rebuild for every little config change. Just build once, inject on start, and move on.
