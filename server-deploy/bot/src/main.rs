mod bridge;
mod commands;
mod config;
mod handler;
mod state;

use azalea::prelude::*;
use tracing::info;

use config::Config;
use state::BotState;

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt::init();

    let config = Config::from_env();
    let address = config.mc_address();

    info!(
        address = %address,
        username = %config.bot_username,
        openclaw = %config.openclaw_url,
        http_port = config.http_listen_port,
        "Starting azalea-bot"
    );

    // Create the action channel (HTTP server -> event handler)
    let (action_tx, action_rx) = tokio::sync::mpsc::unbounded_channel();
    handler::set_action_receiver(action_rx);

    // Build state with config and action sender
    let bot_state = BotState::new(config, action_tx);

    // Spawn HTTP server for inbound commands from OpenClaw
    let shared_for_http = bot_state.shared.clone();
    tokio::spawn(async move {
        bridge::inbound::run_server(shared_for_http).await;
    });

    // Connect to MC server (blocks forever)
    let account = Account::offline(&bot_state.shared.config.bot_username);

    let _ = ClientBuilder::new()
        .set_handler(handler::handle)
        .set_state(bot_state)
        .start(account, address.as_str())
        .await;
}
