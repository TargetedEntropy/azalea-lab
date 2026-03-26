use azalea::prelude::*;

#[tokio::main]
async fn main() {
    let host = std::env::var("MC_HOST").unwrap_or_else(|_| "localhost".to_string());
    let port = std::env::var("MC_PORT").unwrap_or_else(|_| "25566".to_string());
    let address = format!("{}:{}", host, port);

    let account = Account::offline("azalea_bot");

    ClientBuilder::new()
        .set_handler(handle)
        .start(account, &address)
        .await;
}

#[derive(Default, Clone, Component)]
pub struct State;

async fn handle(bot: Client, event: Event, _state: State) -> anyhow::Result<()> {
    match event {
        Event::Login => {
            println!("[BOT] Logged in! Sending chat message in 3 seconds...");
            tokio::time::sleep(std::time::Duration::from_secs(3)).await;
            bot.chat("azalea-bot online");
            println!("[BOT] Chat message sent!");
            tokio::time::sleep(std::time::Duration::from_secs(2)).await;
            println!("[BOT] Done. Exiting.");
            std::process::exit(0);
        }
        _ => {}
    }
    Ok(())
}
