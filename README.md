# Tide Mecha Wallet Codespace

This repository provides a Codespaces devcontainer configuration that automatically clones the [Tide Wallet](https://github.com/tide-foundation/tide-wallet) repository, installs its dependencies, and starts the development server.

## How It Works

- **Cloning the Repository:**On container creation, the devcontainer configuration clones the Tide Wallet repository into the container.
- **Installing Dependencies:**After cloning, it runs `npm install` to install all required dependencies.
- **Starting the Development Server:**
  Once the container starts, it runs `npm run dev` to launch the development server.

## Getting Started

1. **Open in Codespaces:**Create a new Codespace using this repository.
2. **Wait for Setup:**The devcontainer will automatically clone the Tide Wallet repo and install all dependencies.
3. **Access the App:**
   The development server is forwarded on port **3000** (or the port specified in the devcontainer configuration). You can open this port to view the running application.

Happy coding!
