use std::sync::Arc;

use azalea::prelude::*;
use parking_lot::Mutex;
use tokio::sync::mpsc;

use crate::commands::BotAction;
use crate::config::Config;

pub type ActionTx = mpsc::UnboundedSender<BotAction>;
pub type ActionRx = mpsc::UnboundedReceiver<BotAction>;

/// Azalea requires State to be Component + Clone + Default.
/// We store an Arc to shared mutable state so both the event handler
/// and the HTTP server can access it.
#[derive(Component, Clone, Default)]
pub struct BotState {
    pub shared: Arc<SharedState>,
}

/// Interior-mutable state shared between the MC event handler and HTTP server.
pub struct SharedState {
    pub config: Config,
    pub http_client: reqwest::Client,
    /// The HTTP server sends actions through this channel.
    /// Set to Some after the channel is created in main().
    pub action_sender: Mutex<Option<ActionTx>>,
}

impl Default for SharedState {
    fn default() -> Self {
        Self {
            config: Config::from_env(),
            http_client: reqwest::Client::new(),
            action_sender: Mutex::new(None),
        }
    }
}

impl BotState {
    pub fn new(config: Config, action_tx: ActionTx) -> Self {
        Self {
            shared: Arc::new(SharedState {
                config,
                http_client: reqwest::Client::new(),
                action_sender: Mutex::new(Some(action_tx)),
            }),
        }
    }
}
