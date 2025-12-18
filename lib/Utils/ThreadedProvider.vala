/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Leonhard Kargl <leo.kargl@proton.me>
 */

public abstract class Detective.ThreadedProvider : SearchProvider {
    private class Job {
        public Query query;
        public ResultAggregator aggregator;
    }

    private AsyncQueue<Job> query_queue;
    private Thread worker_thread;

    construct {
        query_queue = new AsyncQueue<Job> ();
        worker_thread = new Thread<void> ("threaded provider worker", worker_loop);
    }

    private void worker_loop () {
        construct_threaded ();

        while (true) {
            var job = query_queue.pop ();

            if (job.query.cancelled) {
                continue;
            }

            search_threaded (job.query, job.aggregator);
        }
    }

    protected virtual void construct_threaded () {}

    protected abstract void search_threaded (Query query, ResultAggregator aggregator);

    public override void search (Query query, ResultAggregator aggregator) {
        var job = new Job ();
        job.query = query;
        job.aggregator = aggregator;

        query_queue.push (job);
    }
}
