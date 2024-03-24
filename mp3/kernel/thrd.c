#include "types.h"
#include "riscv.h"
#include "defs.h"
#include "date.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "proc.h"

// for mp3
	uint64
sys_thrdstop(void)
{
	int delay;
	uint64 context_id_ptr;
	uint64 handler, handler_arg;
	if (argint(0, &delay) < 0)
		return -1;
	if (argaddr(1, &context_id_ptr) < 0)
		return -1;
	if (argaddr(2, &handler) < 0)
		return -1;
	if (argaddr(3, &handler_arg) < 0)
		return -1;

	struct proc *proc = myproc();

	//TODO: mp3
	int context_id;
	copyin(proc->pagetable, (char*)&context_id, context_id_ptr, sizeof(int));
	if(context_id >= 16 || context_id < -1) return -1;
	if(context_id == -1){
		int id = 0;
		for(id = 0; id < 16; id++)
			if(proc->is_use[id] == 0)
				break;
		if(id == 16) return -1;
		context_id = id;
		proc->is_use[id] = 1;
		copyout(proc->pagetable, context_id_ptr, (char*)&context_id, sizeof(int));
	} 
	proc->delay = delay;
	proc->tick_num = 0;
	proc->tid = context_id;
	proc->hd = handler;
	proc->hd_arg = handler_arg;

	return 0;
}
#define MAX(a, b) ((a) > (b)) ? (a) : (b)
// for mp3
	uint64
sys_cancelthrdstop(void)
{
	int context_id, is_exit;
	if (argint(0, &context_id) < 0)
		return -1;
	if (argint(1, &is_exit) < 0)
		return -1;

	if (context_id < 0 || context_id >= MAX_THRD_NUM) {
		return -1;
	}

	struct proc *proc = myproc();
	if(is_exit){
		proc->is_use[context_id] = 0;
	} else{
		memmove(&proc->t_trapframe[context_id], proc->trapframe, sizeof(struct trapframe));
	}

	proc->tid = -1;

	//TODO: mp3

	return MAX(proc->tick_num, proc->delay);
}

// for mp3
	uint64
sys_thrdresume(void)
{
	int context_id;
	if (argint(0, &context_id) < 0)
		return -1;

	struct proc *proc = myproc();

	//TODO: mp3
	if(context_id >= 16 || context_id < 0 || !proc->is_use[context_id]) return -1;
	memmove(proc->trapframe, &proc->t_trapframe[context_id], sizeof(struct trapframe));
	proc->tid = context_id;
	/*proc->is_use[proc->tid] = 0;*/

	return 0;
}
