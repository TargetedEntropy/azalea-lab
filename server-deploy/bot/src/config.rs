use std::env;

#[derive(Clone)]
pub struct Config {
    pub mc_host: String,
    pub mc_port: String,
    pub bot_username: String,
    pub openclaw_url: String,
    pub openclaw_token: String,
    pub http_listen_port: u16,
}

impl Config {
    pub fn from_env() -> Self {
        Self {
            mc_host: env::var("MC_HOST").unwrap_or_else(|_| "localhost".into()),
            mc_port: env::var("MC_PORT").unwrap_or_else(|_| "25566".into()),
            bot_username: env::var("BOT_USERNAME").unwrap_or_else(|_| "azalea_bot".into()),
            openclaw_url: env::var("OPENCLAW_URL")
                .unwrap_or_else(|_| "http://127.0.0.1:18789".into()),
            openclaw_token: env::var("OPENCLAW_TOKEN").unwrap_or_default(),
            http_listen_port: env::var("BOT_HTTP_PORT")
                .ok()
                .and_then(|s| s.parse().ok())
                .unwrap_or(3001),
        }
    }

    pub fn mc_address(&self) -> String {
        format!("{}:{}", self.mc_host, self.mc_port)
    }
}
