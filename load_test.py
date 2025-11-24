#!/usr/bin/env python3
"""
VMSS Autoscale Load Test Script
Generates HTTP load to trigger CPU-based autoscaling
"""

import requests
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime, timedelta

# Configuration
TARGET_URL = "http://20.184.139.83"
DURATION_MINUTES = 10
CONCURRENT_WORKERS = 100
REQUESTS_PER_WORKER = 500

def make_request(session, url, request_num):
    """Make a single HTTP POST request to vote"""
    try:
        response = session.post(url, data={'vote': 'Cats'}, timeout=5)
        return True
    except Exception as e:
        return False

def worker_thread(worker_id, end_time):
    """Worker thread that continuously sends requests until end_time"""
    session = requests.Session()
    success_count = 0
    failure_count = 0
    request_num = 0
    
    while datetime.now() < end_time:
        request_num += 1
        if make_request(session, TARGET_URL, request_num):
            success_count += 1
        else:
            failure_count += 1
        
        # Small delay to avoid overwhelming
        time.sleep(0.1)
    
    session.close()
    return {
        'worker_id': worker_id,
        'success': success_count,
        'failure': failure_count,
        'total': success_count + failure_count
    }

def main():
    print("=" * 50)
    print("VMSS Autoscale Load Test")
    print("=" * 50)
    print(f"\nTarget URL: {TARGET_URL}")
    print(f"Duration: {DURATION_MINUTES} minutes")
    print(f"Concurrent Workers: {CONCURRENT_WORKERS}")
    print("\nThis will generate high load to trigger autoscaling...")
    print("\nMonitor in Azure Portal:")
    print("  1. VM Scale Set -> Metrics -> Percentage CPU")
    print("  2. VM Scale Set -> Instances (watch for 'Creating' status)")
    print("  3. VM Scale Set -> Activity log (for scaling events)")
    print("\nStarting load test in 3 seconds...")
    time.sleep(3)
    
    start_time = datetime.now()
    end_time = start_time + timedelta(minutes=DURATION_MINUTES)
    
    print(f"\n[{start_time.strftime('%H:%M:%S')}] Load test started!")
    print(f"Will run until {end_time.strftime('%H:%M:%S')}\n")
    
    # Create thread pool and submit workers
    total_requests = 0
    total_success = 0
    total_failure = 0
    
    with ThreadPoolExecutor(max_workers=CONCURRENT_WORKERS) as executor:
        # Submit all worker threads
        futures = [executor.submit(worker_thread, i, end_time) 
                   for i in range(CONCURRENT_WORKERS)]
        
        # Monitor progress
        last_update = datetime.now()
        completed_workers = 0
        
        for future in as_completed(futures):
            completed_workers += 1
            result = future.result()
            total_requests += result['total']
            total_success += result['success']
            total_failure += result['failure']
            
            # Print status every 30 seconds
            now = datetime.now()
            if (now - last_update).total_seconds() >= 30 or completed_workers == CONCURRENT_WORKERS:
                elapsed = (now - start_time).total_seconds() / 60
                remaining = (end_time - now).total_seconds() / 60
                
                if remaining > 0:
                    print(f"[{now.strftime('%H:%M:%S')}] {elapsed:.1f} min elapsed, "
                          f"{remaining:.1f} min remaining | "
                          f"Requests: {total_requests} ({total_success} success, {total_failure} failed)")
                
                last_update = now
    
    print("\n" + "=" * 50)
    print("Load Test Complete!")
    print("=" * 50)
    print(f"\nTotal Requests: {total_requests}")
    print(f"  Successful: {total_success}")
    print(f"  Failed: {total_failure}")
    print(f"Duration: {DURATION_MINUTES} minutes")
    print(f"\nNext Steps:")
    print("  1. Check Azure Portal -> Metrics for CPU spike")
    print("  2. Check Activity Log for scaling events")
    print("  3. Check Instances for new instances")
    print("  4. Take screenshots with matching timestamps")
    print("\nNote: If autoscaling hasn't triggered yet, wait a few more minutes.")
    print("Azure evaluates CPU average over 5 minutes before scaling.\n")

if __name__ == "__main__":
    main()
