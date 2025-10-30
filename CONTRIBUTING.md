# Contributing to Fedora 42 Ultimate Tools

Thank you for your interest in contributing! We welcome contributions from the community.

## How to Contribute

### Reporting Bugs
- Use the GitHub Issues tab
- Include your Fedora version and system details
- Provide steps to reproduce the issue
- Include any error messages or logs

### Suggesting Features
- Open an issue with the "enhancement" label
- Clearly describe the feature and its benefits
- Explain the use case

### Submitting Changes

1. **Fork the repository**
2. **Create a feature branch:**
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. **Make your changes:**
   - Follow existing code style
   - Test your changes thoroughly
   - Update documentation if needed

4. **Commit your changes:**
   ```bash
   git commit -m "Add: brief description of changes"
   ```

5. **Push to your fork:**
   ```bash
   git push origin feature/your-feature-name
   ```

6. **Submit a Pull Request**

## Code Guidelines

- **Shell scripts:** Follow bash best practices
- **Comments:** Add clear comments for complex logic
- **Error handling:** Include proper error checking
- **Testing:** Test on a clean Fedora 42 installation
- **Documentation:** Update docs for new features

## Testing Requirements

Before submitting:
- [ ] Script runs without errors
- [ ] No syntax errors (use `shellcheck`)
- [ ] Tested on Fedora 42
- [ ] Documentation updated
- [ ] No breaking changes (or clearly documented)

## Code of Conduct

- Be respectful and constructive
- Focus on the issue, not the person
- Help create a welcoming environment
- Follow GitHub's Community Guidelines

## Questions?

Feel free to open an issue or start a discussion if you have questions about contributing.

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
