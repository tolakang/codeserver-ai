# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability within this project, please send an email to the maintainers. All security vulnerabilities will be promptly addressed.

## Security Best Practices

### Passwords and Secrets

- Never use default or weak passwords in production.
- Use strong, randomly generated passwords for all services.
- Set `CS_PASSWORD`, `GITEA_ADMIN_PASSWORD`, `POSTGRES_PASSWORD`, `RUSTFS_ROOT_PASSWORD`, and `OPENCODE_SERVER_PASSWORD` to unique values.
- Store secrets in Dokploy environment variables, Docker secrets, or another secret manager.
- Never commit `.env`, API keys, RustFS credentials, generated passwords, or database passwords.

### API Keys

- Never commit API keys to version control.
- Use environment variables or secret management systems.
- Rotate API keys regularly.

### Network Security

- Terminate TLS at the reverse proxy, not inside code-server or OpenCode WEB.
- Configure the reverse proxy upstream protocol for code-server as `HTTP` on port `8443`.
- Configure the reverse proxy upstream protocol for OpenCode WEB as `HTTP` on port `4001`.
- Restrict CORS origins to trusted domains.
- Use firewall rules to limit access to services.
- Keep RustFS and PostgreSQL on the internal Docker network unless explicitly exposed.

### Updates

- Keep all services updated to the latest secure versions.
- Monitor for security advisories.
- Apply security patches promptly.
- Back up workspace, configuration, and Gitea database before updates.
