# Contributing to LilithOS

## Development Guidelines

### Code Style
- Follow the Linux kernel coding style for kernel modifications
- Use shellcheck for shell scripts
- Follow PEP 8 for Python code
- Use consistent indentation (4 spaces for Python, 2 spaces for shell scripts)

### Documentation
- Update documentation for all changes
- Include inline comments for complex code
- Update README.md when adding new features
- Document all configuration options

### Testing
- Test all changes on actual Mac Pro 2009 hardware
- Include unit tests for new features
- Verify dual boot functionality
- Test security features

### Pull Request Process
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Update documentation
5. Submit a pull request

### Security Considerations
- Follow security-first development practices
- Document security implications
- Test security features thoroughly
- Maintain secure coding practices

## Development Environment Setup

### Required Tools
- Linux development environment
- Cross-compilation tools
- Virtual machine for testing
- Mac Pro 2009 for hardware testing

### Building from Source
1. Clone the repository
2. Install dependencies
3. Follow build instructions in BUILD.md
4. Test the build

## Code Review Process
- All code must be reviewed
- Security implications must be assessed
- Performance impact must be evaluated
- Documentation must be complete

## Release Process
1. Version bump
2. Update changelog
3. Create release notes
4. Build release packages
5. Test release
6. Deploy

## Contact
For questions or concerns, please open an issue in the repository. 