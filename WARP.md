# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Commands to Use

### Testing
- **Run Tests**: Utilize `vtest ~/code/github/incubaid/herolib/lib/osal/package_test.v` to run specific tests.

## High-Level Architecture
- **Project Structure**: The project is organized into multiple modules located in `lib` and `src` directories. Prioritized compilation and caching strategies are utilized across modules.
- **Script Handling**: Vlang scripts are crucial and should follow instructions from `aiprompts/vlang_herolib_core.md`.

## Special Instructions
- **Documentation Reference**: Always refer to `aiprompts/vlang_herolib_core.md` for essential instructions regarding Vlang and Heroscript code generation and execution.
- **Environment Specifics**: Ensure Redis and other dependencies are configured as per scripts provided in the codebase.
