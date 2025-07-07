# Mind Fence Development Guidelines

## Overview

This directory contains comprehensive development guidelines for the Mind Fence social media blocking app project. These guidelines ensure high-quality, secure, and maintainable code while following Flutter best practices and addressing the unique requirements of a social media blocking application.

## Scoring System

All guidelines use a **1-10 scoring scale** where:
- **9-10**: Excellent - Industry best practices, fully optimized
- **7-8**: Good - Meets requirements with minor improvements possible
- **5-6**: Acceptable - Functional but needs improvements
- **3-4**: Below Standard - Requires significant refactoring
- **1-2**: Poor - Must be completely rewritten

**⚠️ Critical Rule: Any implementation scoring below 7/10 MUST be refactored before merging.**

## Guidelines Overview

### 1. [UI/UX Design Guidelines](./ui-ux-guidelines.md)
- Material Design 3 compliance
- Dark mode implementation
- Accessibility standards
- Responsive design principles
- User experience patterns for blocking apps

### 2. [Security Guidelines](./security-guidelines.md)
- Data encryption standards
- Authentication best practices
- Privacy protection measures
- Secure API communication
- System-level security considerations

### 3. [Clean Code Guidelines](./clean-code-guidelines.md)
- Code organization and structure
- Naming conventions
- Documentation standards
- Error handling practices
- Code review checklist

### 4. [Flutter Best Practices](./flutter-best-practices.md)
- Widget optimization
- State management with BLoC
- Performance considerations
- Platform-specific implementations
- Package management

### 5. [Architecture Guidelines](./architecture-guidelines.md)
- BLoC pattern implementation
- Dependency injection
- Layer separation
- Repository pattern
- Service architecture

### 6. [Testing Guidelines](./testing-guidelines.md)
- Unit testing standards
- Widget testing practices
- Integration testing
- Test coverage requirements
- Mocking strategies

### 7. [Performance Guidelines](./performance-guidelines.md)
- Memory management
- Network optimization
- Battery life considerations
- App startup time
- Rendering performance

### 8. [Accessibility Guidelines](./accessibility-guidelines.md)
- WCAG compliance
- Screen reader support
- Color contrast requirements
- Navigation patterns
- Inclusive design principles

### 9. [Documentation Standards](./documentation-standards.md)
- Code documentation
- API documentation
- User guides
- Technical specifications
- Change logs

## AI Developer Self-Assessment

When implementing features, AI developers should:

1. **Review Relevant Guidelines**: Read applicable guidelines before starting implementation
2. **Self-Score Implementation**: Evaluate code against each relevant guideline's criteria
3. **Refactor If Needed**: If any aspect scores below 7/10, refactor immediately
4. **Document Decisions**: Record architectural and implementation decisions
5. **Test Thoroughly**: Ensure all tests pass and coverage meets requirements

## Quick Reference Checklist

Before submitting any code:
- [ ] Security guidelines followed (encryption, authentication, privacy)
- [ ] Clean code principles applied (naming, structure, documentation)
- [ ] Flutter best practices implemented (widgets, state management, performance)
- [ ] Architecture patterns correctly used (BLoC, dependency injection, layers)
- [ ] Tests written and passing (unit, widget, integration)
- [ ] Performance optimized (memory, network, battery)
- [ ] Accessibility standards met (WCAG, screen readers, contrast)
- [ ] Documentation updated (code comments, API docs, user guides)
- [ ] UI/UX guidelines followed (Material Design, dark mode, responsiveness)

## Enforcement

These guidelines are **mandatory** for all code contributions to the Mind Fence project. Code reviews will strictly enforce these standards, and any submission not meeting the minimum 7/10 score will be rejected.

## Updates

Guidelines are living documents and will be updated as the project evolves. All developers must stay current with the latest versions.

---

*Last Updated: July 7, 2025*
*Version: 1.0*