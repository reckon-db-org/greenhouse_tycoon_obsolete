# GEMINI Project Analysis: Greenhouse Tycoon

## Project Overview

This directory contains the Greenhouse Tycoon system, an Elixir-based, event-sourced application. The project is structured as an Elixir umbrella application, with separate applications for the core domain logic, the web interface, and external APIs.

The core of the architecture is based on **CQRS (Command Query Responsibility Segregation)** and **Event Sourcing**.

The main technologies used are:

*   **Elixir**: The primary programming language.
*   **Phoenix Framework**: Used for the web interface.
*   **Commanded**: A CQRS and event sourcing library for Elixir.
*   **ExESDB**: A custom-built event store database.
*   **Ecto**: A database wrapper and query language for Elixir.
*   **Cachex**: An in-memory cache used for read models.

## Architecture and Development Conventions

The following are the key architectural and development conventions observed in the codebase:

*   **Umbrella Project**: The system is organized as an umbrella project, with the following main applications:
    *   `greenhouse_tycoon`: The core application containing the business logic.
    *   `greenhouse_tycoon_web`: The Phoenix-based web interface.
    *   `apis`: An application for interacting with external services.
*   **Event Sourcing**: The state of the application is determined by a sequence of events, which are stored in ExESDB.
*   **CQRS**: The project follows the CQRS pattern, with commands being handled by aggregates and queries being served from read models stored in Cachex.
*   **Projections**: Read models are built from events using `Commanded.Projections`.
*   **Multi-App Architecture**: Each application has its own event store, configuration, and potentially its own cluster.
*   **Strict Naming Conventions**: There are strict naming conventions for files, modules, ports, environment variables, and store IDs.
*   **Configuration**: Each application has its own configuration, with support for environment-specific and runtime configurations.
*   **Status Fields**: Status fields should be stored as integers to allow for the use of bitwise flags to represent composite statuses.

## Building and Running

### Setup

To install all dependencies for the umbrella project, run:

```bash
mix setup
```

### Running the Application

To start the Phoenix server, you likely need to navigate to the web application's directory:

```bash
cd apps/greenhouse_tycoon_web
mix phx.server
```

### Testing

To run the test suite for all applications, run the following command from the project root:

```bash
mix test
```

### Building Assets

The `greenhouse_tycoon_web` application uses `esbuild` and `tailwind` for asset management.

To build assets for development:

```bash
# from the apps/greenhouse_tycoon_web directory
mix assets.build
```

To build assets for production:

```bash
# from the apps/greenhouse_tycoon_web directory
mix assets.deploy
```

### Rebuilding Read Models

The read models (projections) can be rebuilt using the following command:

```elixir
# From within an IEx session
Commanded.Projections.rebuild/2
```

The `REFACTORING_GUIDE.md` also mentions a helpful API call for this: `GreenhouseTycoon.API.rebuild_event_handlers/0`.
