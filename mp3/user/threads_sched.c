#include "kernel/types.h"
#include "user/user.h"
#include "user/list.h"
#include "user/threads.h"
#include "user/threads_sched.h"

#define NULL 0

/* default scheduling algorithm */
struct threads_sched_result schedule_default(struct threads_sched_args args)
{
    struct thread *thread_with_smallest_id = NULL;
    struct thread *th = NULL;
    list_for_each_entry(th, args.run_queue, thread_list) {
        if (thread_with_smallest_id == NULL || th->ID < thread_with_smallest_id->ID) {
            thread_with_smallest_id = th;
        }
    }

    struct threads_sched_result r;
    if (thread_with_smallest_id != NULL) {
        r.scheduled_thread_list_member = &thread_with_smallest_id->thread_list;
        r.allocated_time = thread_with_smallest_id->remaining_time;
    } else {
        r.scheduled_thread_list_member = args.run_queue;
        r.allocated_time = 1;
    }

    return r;
}

void DE(struct thread* t){
	printf("thrdstop_context_id: %d\nprocessing_time: %d\nperiod: %d\nn: %d\nremaining_time: %d\ncurrentdeadline: %d\n", t->thrdstop_context_id, t->processing_time, t->period, t->n, t->remaining_time, t->current_deadline);
}

#define MIN(a, b) (a) < (b) ? (a) : (b)

/* Earliest-Deadline-First scheduling */
struct threads_sched_result schedule_edf(struct threads_sched_args args)
{
    struct thread *to_run = NULL;
    struct thread *th = NULL;
	struct threads_sched_result r;

	// check if there's something meet deadline
    list_for_each_entry(th, args.run_queue, thread_list) {
		if(th->current_deadline <= args.current_time)
			if(to_run == NULL || to_run->ID > th->ID)
				to_run = th;
	}
	if(to_run != NULL){
		r.scheduled_thread_list_member = &to_run->thread_list;
		r.allocated_time = 0;
		return r;
	}
	
	// find the run_queue min
    list_for_each_entry(th, args.run_queue, thread_list) {
		if (to_run == NULL ||\
			th->current_deadline < to_run->current_deadline ||\
			(th->current_deadline == to_run->current_deadline && th->ID < to_run->ID))
				to_run = th;
    }

	struct release_queue_entry *re = NULL;
	struct release_queue_entry *sr = NULL;
	if(to_run == NULL){
		list_for_each_entry(re, args.release_queue, thread_list){
			if(sr == NULL || re->release_time < sr->release_time)
				sr = re;
		}
		r.scheduled_thread_list_member = args.run_queue;
		r.allocated_time = sr->release_time - args.current_time;
	} else{
		r.scheduled_thread_list_member = &to_run->thread_list;
		list_for_each_entry(re, args.release_queue, thread_list){
			if(re->release_time < args.current_time + to_run->remaining_time &&\
				re->thrd->period + re->release_time < to_run->current_deadline)
					sr = re;
		}
		r.allocated_time = (sr != NULL) ? sr->release_time - args.current_time : MIN(to_run->remaining_time, to_run->current_deadline - args.current_time);
	}
    return r;
}

/* Rate-Monotonic Scheduling */
struct threads_sched_result schedule_rm(struct threads_sched_args args)
{
    struct thread *to_run = NULL;
    struct thread *th = NULL;
	struct threads_sched_result r;

	// check if there's something meet deadline
    list_for_each_entry(th, args.run_queue, thread_list) {
		if(th->current_deadline <= args.current_time)
			if(to_run == NULL || to_run->ID > th->ID)
				to_run = th;
	}
	if(to_run != NULL){
		r.scheduled_thread_list_member = &to_run->thread_list;
		r.allocated_time = 0;
		return r;
	}
	
	// find the run_queue min
    list_for_each_entry(th, args.run_queue, thread_list) {
		if (to_run == NULL ||\
			th->period < to_run->period ||\
			(th->period == to_run->period && th->ID < to_run->ID))
				to_run = th;
    }

	struct release_queue_entry *re = NULL;
	struct release_queue_entry *sr = NULL;
	if(to_run == NULL){
		list_for_each_entry(re, args.release_queue, thread_list){
			if(sr == NULL || re->release_time < sr->release_time)
				sr = re;
		}
		r.scheduled_thread_list_member = args.run_queue;
		r.allocated_time = sr->release_time - args.current_time;
	} else{
		r.scheduled_thread_list_member = &to_run->thread_list;
		list_for_each_entry(re, args.release_queue, thread_list){
			if(re->release_time < args.current_time + to_run->remaining_time &&\
				re->thrd->period < to_run->period)
					sr = re;
		}
		r.allocated_time = (sr != NULL) ? sr->release_time - args.current_time : MIN(to_run->remaining_time, to_run->current_deadline - args.current_time);
	}
    return r;
}
