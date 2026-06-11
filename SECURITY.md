# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability within this project, please send an email to the maintainers. All security vulnerabilities will be promptly addressed.

## Security Best Practices

### Passwords

- Never use default or weak passwords in production
- Use strong, randomly generated passwords for all services
- Set `CS_PASSWORD`, `GITEA_ADMIN_PASSWORD`, and `RUSTFS_ROOT_PASSWORD` to unique values

### API Keys

- Never commit API keys to version control
- Use environment variables or secret management systems
- Rotate API keys regularly

### Network Security

- Use TLS termination at a reverse proxy (nginx, Traefik, etc.)
- Restrict CORS origins to trusted domains
- Use firewall rules to limit access to services

### Updates

- Keep all services updated to the latest versions
- Monitor for security advisories
- Apply security patches promptly
