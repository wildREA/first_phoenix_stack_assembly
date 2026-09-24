import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :first_phoenix_stack_assembly, FirstPhoenixStackAssemblyWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "UDKw+3D5v5a4el0B47pyl9ZsxN3Z7i4/z+Ioi/0LHzOG6bsbfm6O6vjULqwSnqkr",
  server: false

# In test we don't send emails
config :first_phoenix_stack_assembly, FirstPhoenixStackAssembly.Mailer,
  adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true
