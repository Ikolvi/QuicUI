# QuicUI Server

Backend infrastructure for [QuicUI](https://github.com/Ikolvi/QuicUI) - the open-source Flutter code push solution.

## Overview

QuicUI Server provides the backend services for managing Flutter app updates:

- **Edge Functions**: Serverless functions for patch management
- **Database**: PostgreSQL with migrations for storing patch metadata
- **Storage**: Supabase Storage for patch file hosting

## Architecture

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│   Flutter App   │────▶│  Edge Functions  │────▶│    Database     │
│  (quicui_cli)   │     │   (Supabase)     │     │  (PostgreSQL)   │
└─────────────────┘     └──────────────────┘     └─────────────────┘
                                │
                                ▼
                        ┌──────────────────┐
                        │     Storage      │
                        │  (Patch files)   │
                        └──────────────────┘
```

## Features

- ✅ **Patch Check API** - Clients check for available updates
- ✅ **Patch Registration** - CLI uploads new patches
- ✅ **Patch Download** - Clients download patch files
- ✅ **API Key Generation** - Auto-generate keys for new projects
- ✅ **Baseline Management** - Store and serve baseline binaries
- ✅ **Download Statistics** - Track downloads and success rates

## Project Structure

```
supabase/
├── config.toml              # Supabase configuration
├── .env.example             # Environment template
├── .gitignore               # Git ignore rules
├── functions/               # Edge Functions
│   ├── api-keys-cli/        # Generate API keys
│   ├── api-keys-create/     # Create user API keys
│   ├── patches-check/       # Check for updates
│   ├── patches-download/    # Download patches
│   ├── patches-register/    # Register new patches
│   └── _shared/             # Shared utilities
├── migrations/              # Database migrations
└── README.md                # This file
```

## Quick Start

### Prerequisites

- [Supabase CLI](https://supabase.com/docs/guides/cli)
- Supabase account

### Setup

1. **Clone the repository**
   ```bash
   git clone git@github.com:Ikolvi/QuicUiServer.git
   cd QuicUiServer
   ```

2. **Link to your Supabase project**
   ```bash
   supabase login
   supabase link --project-ref YOUR_PROJECT_REF
   ```

3. **Configure environment**
   ```bash
   cp .env.example .env
   # Edit .env with your values
   ```

4. **Apply migrations**
   ```bash
   supabase db push
   ```

5. **Deploy functions**
   ```bash
   supabase functions deploy
   ```

## API Endpoints

### Check for Updates
```bash
POST /functions/v1/patches-check
Content-Type: application/json

{
  "appId": "com.example.app",
  "currentVersion": "1.0.0",
  "architecture": "arm64-v8a"
}
```

### Generate API Key
```bash
POST /functions/v1/api-keys-cli
Content-Type: application/json

{
  "app_id": "com.example.app",
  "app_name": "My App"
}
```

## Environment Variables

| Variable | Description |
|----------|-------------|
| `SUPABASE_URL` | Supabase project URL |
| `SUPABASE_ANON_KEY` | Public anon key |
| `SUPABASE_SERVICE_ROLE_KEY` | Service role key (secret!) |

⚠️ **Never commit `.env` files with real credentials!**

## Related Projects

- [QuicUI](https://github.com/Ikolvi/QuicUI) - Main project repository
- [QuicUICodepush](https://github.com/Ikolvi/QuicUICodepush) - Flutter client library

## Security

- Row Level Security (RLS) enabled on all tables
- API keys are hashed before storage
- Service role key used only for admin operations
- Rate limiting configured in Supabase dashboard

## License

MIT License - see [LICENSE](LICENSE)

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

---

Made with ❤️ by the QuicUI team
