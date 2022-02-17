package main

import (
	"context"
	"fmt"
	"io/ioutil"
	"log"
	"math/rand"
	"os"
	"strconv"
	"sync"
	"time"

	"github.com/montanaflynn/stats"
	"github.com/oom-ai/oomstore/pkg/oomstore"
	"github.com/oom-ai/oomstore/pkg/oomstore/types"
	"gopkg.in/yaml.v2"
)

// go run <config> <requests> <concurrency> <max_key> <feature_count>
func main() {
	args := os.Args
	cfgFile := args[1]
	rand.Seed(time.Now().UnixNano())

	var oomStoreCfg types.OomStoreConfig
	cfgContent, err := ioutil.ReadFile(cfgFile)
	if err != nil {
		log.Fatal(err)
	}
	if err := yaml.Unmarshal(cfgContent, &oomStoreCfg); err != nil {
		log.Fatal(err)
	}

	requests, err := strconv.Atoi(args[2])
	if err != nil {
		log.Fatal(err)
	}

	concurrency, err := strconv.Atoi(args[3])
	if err != nil {
		log.Fatal(err)
	}

	maxKey, err := strconv.Atoi(args[4])
	if err != nil {
		log.Fatal(err)
	}

	featureCount, err := strconv.Atoi(args[5])
	if err != nil {
		log.Fatal(err)
	}

	ctx := context.Background()

	store, err := oomstore.Open(ctx, oomStoreCfg)
	if err != nil {
		log.Fatal(err)
	}
	bench(ctx, store, requests, concurrency, maxKey, featureCount)
	store.Close()
}

func bench(ctx context.Context, store *oomstore.OomStore, requests, concurrency int, maxEntitykey int, featureCount int) {
	features := genFeatureList(featureCount)

	var durations []float64
	ch := make(chan time.Duration, concurrency*10)
	var wgCounters sync.WaitGroup
	wgCounters.Add(1)
	go func() {
		defer wgCounters.Done()
		for d := range ch {
			durations = append(durations, float64(d)/float64(time.Millisecond))
		}
	}()

	var wgWorkers sync.WaitGroup
	part := requests / concurrency
	start := time.Now()
	for i := 0; i < concurrency; i++ {
		wgWorkers.Add(1)
		go func() {
			defer wgWorkers.Done()
			for i := 0; i < part; i++ {
				entityKey := strconv.Itoa(rand.Intn(maxEntitykey) + 1)
				t := time.Now()
				_, err := store.OnlineGet(ctx, types.OnlineGetOpt{
					FeatureNames: features,
					EntityKey:    entityKey,
				})
				ch <- time.Since(t)
				if err != nil {
					fmt.Println("failed to GetOnlineFeatureValues, error=", err)
				}
			}
		}()
	}

	wgWorkers.Wait()
	close(ch)
	totalTime := time.Now().Sub(start)
	wgCounters.Wait()

	avg, _ := stats.Mean(durations)
	min, _ := stats.Min(durations)
	max, _ := stats.Max(durations)
	med, _ := stats.Median(durations)
	p95, _ := stats.Percentile(durations, 95)
	p99, _ := stats.Percentile(durations, 99)
	qps := float64(requests) / totalTime.Seconds()

	fmt.Printf("Avg: %.2fms\n", avg)
	fmt.Printf("Min: %.2fms\n", min)
	fmt.Printf("Max: %.2fms\n", max)
	fmt.Printf("Med: %.2fms\n", med)
	fmt.Printf("P95: %.2fms\n", p95)
	fmt.Printf("P99: %.2fms\n", p99)
	fmt.Printf("QPS: %.2f\n", qps)
}

func genFeatureList(featureCount int) (rs []string) {
	for i := 1; i <= featureCount; i++ {
		rs = append(rs, fmt.Sprintf("group_%d.feature_%d", featureCount, i))
	}
	return
}
