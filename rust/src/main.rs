use futures::{stream, StreamExt};
use oomclient::{
    Client,
    OnlineGetFeatures::{self, *},
};
use rand::{thread_rng, Rng};
use statrs::statistics::{Data, OrderStatistics, Statistics};
use std::env;
use tokio::time::{Duration, Instant};

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let mut args = env::args();
    args.next();

    let cfg_path = args.next().unwrap();
    let requests: usize = args.next().unwrap().parse().unwrap();
    let concurrency: usize = args.next().unwrap().parse().unwrap();
    let key_space: usize = args.next().unwrap().parse().unwrap();
    let feature_count: usize = args.next().unwrap().parse().unwrap();

    let client = Client::with_embedded_oomagent::<&str, _>(None, Some(cfg_path)).await?;
    let group = GroupName(format!("group_{}", feature_count));

    bench(client, requests, concurrency, key_space, group).await;

    Ok(())
}

async fn bench(client: Client, requests: usize, concurrency: usize, key_space: usize, group: OnlineGetFeatures) {
    let part = requests / concurrency;
    let durations: Vec<Vec<Duration>> = stream::iter((0..concurrency).map(|_| {
        let mut client = client.clone();
        let group = group.clone();
        async move {
            let mut durations = Vec::with_capacity(part);
            let mut rng = thread_rng();
            for _ in 0..part {
                let entity_key: usize = rng.gen_range(1..=key_space);
                let entity_key = entity_key.to_string();
                let t = Instant::now();
                client.online_get_raw(entity_key, group.clone()).await.unwrap();
                durations.push(Instant::now().duration_since(t));
            }
            durations
        }
    }))
    .buffer_unordered(concurrency)
    .collect()
    .await;

    let durations: Vec<_> = durations
        .into_iter()
        .flatten()
        .map(|x| x.as_secs_f64() * 1000.0)
        .collect();

    let arr = &durations;
    println!("QPS: {:.2}", 1000.0 / arr.mean() * concurrency as f64);
    println!("Avg: {:.2}ms", arr.mean());
    println!("Min: {:.2}ms", arr.min());
    println!("Max: {:.2}ms", arr.max());
    let mut data = Data::new(durations);
    println!("Med: {:.2}ms", data.median());
    println!("P95: {:.2}ms", data.percentile(95));
    println!("P99: {:.2}ms", data.percentile(99));
}
