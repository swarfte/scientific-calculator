# Smart Calculator

A modern, scientific calculator web app built with [Nuxt 3](https://nuxt.com/), featuring advanced calculation capabilities, persistent state, and offline support via PWA. Designed for both casual and scientific use, with a clean UI and AI-powered features.

## Features

- Scientific calculator with advanced math functions (powered by [mathjs](https://mathjs.org/))
- Progressive Web App (PWA): installable, offline support, and fast loading
- Responsive, mobile-friendly UI with [Nuxt UI](https://ui.nuxt.com/)
- Modular codebase with composables and stores
- ESLint integration for code quality
- Modern development workflow (TypeScript, hot reload, etc.)

## Getting Started

### Prerequisites

- [Node.js](https://nodejs.org/) (v18+ recommended)
- [npm](https://www.npmjs.com/), [pnpm](https://pnpm.io/), [yarn](https://yarnpkg.com/), or [bun](https://bun.sh/)

### Installation

Clone the repository and install dependencies:

```bash
# Clone the repo
git clone https://github.com/your-username/scientific-calculator.git
cd scientific-calculator

# Install dependencies (choose one)
npm install
# or
pnpm install
# or
yarn install
# or
bun install
```

### Development

Start the development server:

```bash
# npm
npm run dev
# pnpm
pnpm dev
# yarn
yarn dev
# bun
bun run dev
```

Visit [http://localhost:3000](http://localhost:3000) in your browser.

### Build for Production

Build the application:

```bash
# npm
npm run build
# pnpm
pnpm build
# yarn
yarn build
# bun
bun run build
```

Preview the production build locally:

```bash
# npm
npm run preview
# pnpm
pnpm preview
# yarn
yarn preview
# bun
bun run preview
```

### Deployment

You can deploy the generated `.output` directory to any static hosting or Node.js server. See the [Nuxt deployment documentation](https://nuxt.com/docs/getting-started/deployment) for more details.

## Project Structure

- `components/` — Vue components (e.g., calculator buttons)
- `composables/` — Reusable logic (math, state, etc.)
- `pages/` — Application pages (main calculator UI)
- `assets/` — CSS and static assets
- `public/` — Public files (PWA icons, etc.)
- `nuxt.config.ts` — Nuxt configuration (PWA, modules, aliases)

## PWA Features

- Installable on desktop and mobile
- Offline support (cache-first strategy)
- Auto-updates via service worker
- Custom icons and manifest

## Contributing

Contributions are welcome! Please open issues or pull requests for bug fixes, features, or improvements.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/YourFeature`)
3. Commit your changes (`npm run commit` for conventional commits)
4. Push to the branch (`git push origin feature/YourFeature`)
5. Open a pull request

## License

[MIT](LICENSE)

---

> Built with ❤️ using Nuxt 3, and modern web technologies.
