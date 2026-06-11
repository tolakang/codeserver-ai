# Contributing to Code Server AI

Thank you for your interest in contributing! This document provides guidelines and information for contributors.

## Getting Started

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Commit your changes (`git commit -m 'Add amazing feature'`)
5. Push to the branch (`git push origin feature/amazing-feature`)
6. Open a Pull Request

## Development Setup

### Prerequisites

- Docker and Docker Compose
- Git

### Local Development

1. Clone your fork:
   ```bash
   git clone https://github.com/your-username/codeserver-ai.git
   cd codeserver-ai
   ```

2. Copy the environment file:
   ```bash
   cp .env.example .env
   ```

3. Edit `.env` with your configuration

4. Start the services:
   ```bash
   docker compose up -d
   ```

## Code Style

### Shell Scripts

- Use `#!/bin/bash` as the shebang
- Use `set -e` for error handling
- Quote variables: `"$VARIABLE"` not `$VARIABLE`
- Use meaningful variable names
- Add comments for complex logic

### Docker

- Use multi-stage builds when possible
- Minimize image size by combining RUN commands
- Use specific base image versions
- Add HEALTHCHECK instructions

### Documentation

- Update README.md for new features
- Add inline comments for complex code
- Keep documentation up to date

## Pull Request Guidelines

- Provide a clear description of changes
- Reference any related issues
- Ensure all tests pass
- Update documentation as needed
- Keep commits focused and atomic

## Reporting Issues

- Use the GitHub issue tracker
- Provide detailed reproduction steps
- Include environment information
- Attach relevant logs

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
