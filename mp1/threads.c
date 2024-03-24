#include "kernel/types.h"
#include "user/setjmp.h"
#include "user/threads.h"
#include "user/user.h"
#define NULL 0


static struct thread* current_thread = NULL;
static int id = 1;
static jmp_buf env_st;
/*static jmp_buf env_tmp;*/

struct thread *thread_create(void (*f)(void *), void *arg){
    struct thread *t = (struct thread*) malloc(sizeof(struct thread));
    unsigned long new_stack_p;
    unsigned long new_stack_h;
    unsigned long new_stack;
    new_stack = (unsigned long) malloc(sizeof(unsigned long)*0x100);
    new_stack_p = new_stack +0x100*8-0x2*8;
    new_stack = (unsigned long) malloc(sizeof(unsigned long)*0x100);
    new_stack_h = new_stack +0x100*8-0x2*8;
    t->fp = f;
    t->arg = arg;
    t->ID  = id;
    t->buf_set = 0;
    t->stack = (void*) new_stack;
    t->stack_p = (void*) new_stack_p;
    t->stack_h = (void*) new_stack_h;
    id++;

    // part 2
    t->sig_handler[0] = NULL_FUNC;
    t->sig_handler[1] = NULL_FUNC;
    t->signo = -1;
    t->handler_buf_set = 0;
    return t;
}
void thread_add_runqueue(struct thread *t){
    if(current_thread == NULL){
		current_thread = t;
		current_thread->next = current_thread->previous = current_thread;
    }
    else{
		current_thread->previous->next = t;
		t->previous = current_thread->previous;
		t->next = current_thread;
		current_thread->previous = t;
		t->sig_handler[0] = current_thread->sig_handler[0];
		t->sig_handler[1] = current_thread->sig_handler[1];
    }
	/*printf("now printed list:\n");*/
	/*struct thread* head = current_thread;*/
	/*do{*/
	/*    printf("now iter to: %d\n", head);*/
	/*    head = head->next;*/
	/*} while(head != current_thread);*/
}
void thread_yield(void){
	if(current_thread->signo != -1){
		if(setjmp(current_thread->handler_env) == 0){
			schedule();
			dispatch();
		}
	} else{
		if(setjmp(current_thread->env) == 0){
			schedule();
			dispatch();
		}
	}
}
void dispatch(void){
	int signo = current_thread->signo;
	if(signo != -1){
		if(current_thread->sig_handler[current_thread->signo] == NULL_FUNC)
			thread_exit();
		else{
			if(!current_thread->handler_buf_set){
				if(setjmp(current_thread->handler_env) == 0){
					current_thread->handler_env->sp = (unsigned long)current_thread->stack_h;
					current_thread->handler_buf_set = 1;
					longjmp(current_thread->handler_env, 69);
				}
				current_thread->sig_handler[signo](signo);
				current_thread->signo = -1;
				dispatch();
			}
			longjmp(current_thread->handler_env, 69);
		}
	} else{
		if(!current_thread->buf_set){
			if(setjmp(current_thread->env) == 0){
				current_thread->env->sp = (unsigned long)current_thread->stack_p;
				current_thread->buf_set = 1;
				longjmp(current_thread->env, 69);
			}
			current_thread->fp(current_thread->arg);
			thread_exit();
		}
		longjmp(current_thread->env, 69);
	}	
}
void schedule(void){
	current_thread = current_thread->next;
}
void thread_exit(void){
	if(current_thread->next != current_thread){
		struct thread *t = current_thread;
		t->next->previous = t->previous;
		t->previous->next = t->next;
		current_thread = t->next;
		free(t);
		dispatch();
	}
	else{
		free(current_thread);
		current_thread = NULL;
		longjmp(env_st, 69);
    }
}
void thread_start_threading(void){
	if(setjmp(env_st) == 69 || current_thread == NULL)
		return;
	dispatch();
}
// part 2
void thread_register_handler(int signo, void (*handler)(int)){
	current_thread->sig_handler[signo] = handler;
}
void thread_kill(struct thread *t, int signo){
	t->signo = signo;
}
