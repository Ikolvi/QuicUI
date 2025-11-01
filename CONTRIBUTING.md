# Contributing to QuicUI

Thank you for your interest in contributing to QuicUI! We welcome contributions from the community.

## Getting Started

1. **Fork the repository** on GitHub
2. **Clone your fork** locally
3. **Create a branch** for your feature: `git checkout -b feature/your-feature-name`
4. **Make your changes** following our code style
5. **Write tests** for new functionality
6. **Commit your changes** with clear, descriptive messages
7. **Push to your fork** and **submit a Pull Request**

## Development Setup

```bash
# Clone the repository
git clone https://github.com/Ikolvi/QuicUICodepush.git
cd QuicUICodepush

# Setup development environment
./scripts/setup.sh

# Run tests
dart pub global activate coverage
./scripts/test.sh
```

## Code Style

- Follow Dart style guide (analyze with `dart analyze`)
- Use meaningful variable and function names
- Write clear comments for complex logic
- Format code with `dart format`

## Testing

- Write tests for all new features
- Ensure all tests pass before submitting PR
- Aim for >80% code coverage

## Commit Messages

- Use clear, descriptive commit messages
- Start with a verb: "Add", "Fix", "Update", "Remove"
- Example: "Add patch verification with Ed25519 signatures"

## Pull Request Process

1. Update documentation if needed
2. Add tests for new features
3. Ensure all CI checks pass
4. Request review from maintainers
5. Respond to feedback promptly

## Issues

- Check if your issue already exists
- Provide clear reproduction steps for bugs
- Include error messages and logs
- Suggest enhancements with use cases

## License

By contributing, you agree that your contributions will be licensed under the Apache 2.0 and MIT licenses.

## Questions?

Feel free to open an issue or discussion for questions about the project.
