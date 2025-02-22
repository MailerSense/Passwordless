# Passwordless

![Checks](https://github.com/MailerSense/Passwordless/actions/workflows/check.yml/badge.svg)
![Deployment](https://github.com/MailerSense/Passwordless/actions/workflows/release.yml/badge.svg)

## Launching new projects

We recommend downloading the latest version from the "Releases" section. The `main` branch will be the most recent but there is a slightly higher chance of bugs (although we will endeavour to keep the `main` branch as stable as possible).

## Get up and running

**Assumptions:**

- You have Elixir & Erlang installed
- You have Postgres installed and running (optional - see "Using Docker for Postgres" below

If you don't meet this assumptions you can read our [comprehensive install instructions](https://docs.petal.build/passwordless-documentation/fundamentals/installation).

**The steps**

1. Add the "petal" repo so your local Hex is aware of our private packages. Simply run the command in step 1 in the ["Install Petal Framework"](https://petal.build/components/install-petal-framework) guide (make sure you're signed in so your license key is automatically insterted).
2. `mix setup` (this get dependencies, setup database, migrations, seeds, install esbuild + Tailwind)
3. `iex -S mix phx.server` (starts the server in IEX mode)
4. Now you can visit [`localhost:4000`](http://localhost:4000) from your browser. If you'd like to use a different port, set the `PORT` environment variable to your preference. Note that if you're using the VS Code dev container, you'll need to update the `"forwardPorts"` configuration accordingly.

**Moving forward:**

- Do a global search for `SETUP_TODO` and follow the instructions to mold the boilerplate to your brand
- Optional: Follow our tutorial ["Creating a web app from start to finish"](https://docs.petal.build/passwordless-documentation/guides/creating-a-web-app-from-start-to-finish) to get an overview of Petal Pro

## Using Docker for Postgres

If your system doesn't have Postgres you can use docker-compose to run it in a container (saves you having to install it).

| Command                                           | Description                                              |
| ------------------------------------------------- | -------------------------------------------------------- |
| `docker compose up`                               | Start in the foreground                                  |
| `docker compose up -d`                            | Start in the background                                  |
| `docker compose down`                             | Stop the containers                                      |
| `docker compose down -v`                          | Stop and delete all Postgres data by removing the volume |
| `docker compose exec db psql --username postgres` | Access through psql                                      |

The connection details for any local clients would be the following:

```
Host: localhost
Port: 5432
User: postgres
Password: postgres
```

## Renaming

Uses the `rename_project` lib to rename the project.

Run `mix rename CurrentName NewName`.

For example:

```
mix rename Passwordless MyTwitterClone
```

Then you can delete the `rename_project` lib from your `mix.exs` and run `mix clean_mix_lock` to fully remove it from your deps folder.

Note that it is not recommended to rename the project if you wish to keep pulling in Petal Pro updates. This is because it can be much harder to update after you have renamed. [Here is a guide](https://docs.saaspegasus.com/upgrading.html#using-branches-recommended) on how to keep up to date based on a similar framework in Python.

## Maintaining code quality as you develop

Run `mix quality` to look for issues with your code. This will run each of these tasks:

- `mix format` (formats your code)
- `mix sobelow --config` (security analysis)
- `mix coveralls` (test coverage)
- `mix credo` (code quality)

If the output is overwhelming, try running one at a time.

## Contributing

Petal Pro is a paid product but we welcome PR's if you find small bugs / typos / improvements. Let us know if you want to contribute in a more significant way and we can offer unlimited membership in return.
