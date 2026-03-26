use azalea::prelude::*;

#[tokio::main]
async fn main() {
    let account = Account::offline("azalea_bot");

    ClientBuilder::new()
        .set_handler(handle)
        .start(account, "localhost:25566")
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
