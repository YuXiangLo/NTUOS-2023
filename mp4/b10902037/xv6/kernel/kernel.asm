
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	85013103          	ld	sp,-1968(sp) # 80008850 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	fee70713          	addi	a4,a4,-18 # 80009040 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	ddc78793          	addi	a5,a5,-548 # 80005e40 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	e0078793          	addi	a5,a5,-512 # 80000eae <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  timerinit();
    800000d8:	00000097          	auipc	ra,0x0
    800000dc:	f44080e7          	jalr	-188(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000e0:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000e4:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000e6:	823e                	mv	tp,a5
  asm volatile("mret");
    800000e8:	30200073          	mret
}
    800000ec:	60a2                	ld	ra,8(sp)
    800000ee:	6402                	ld	s0,0(sp)
    800000f0:	0141                	addi	sp,sp,16
    800000f2:	8082                	ret

00000000800000f4 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000f4:	715d                	addi	sp,sp,-80
    800000f6:	e486                	sd	ra,72(sp)
    800000f8:	e0a2                	sd	s0,64(sp)
    800000fa:	fc26                	sd	s1,56(sp)
    800000fc:	f84a                	sd	s2,48(sp)
    800000fe:	f44e                	sd	s3,40(sp)
    80000100:	f052                	sd	s4,32(sp)
    80000102:	ec56                	sd	s5,24(sp)
    80000104:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000106:	04c05663          	blez	a2,80000152 <consolewrite+0x5e>
    8000010a:	8a2a                	mv	s4,a0
    8000010c:	84ae                	mv	s1,a1
    8000010e:	89b2                	mv	s3,a2
    80000110:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000112:	5afd                	li	s5,-1
    80000114:	4685                	li	a3,1
    80000116:	8626                	mv	a2,s1
    80000118:	85d2                	mv	a1,s4
    8000011a:	fbf40513          	addi	a0,s0,-65
    8000011e:	00002097          	auipc	ra,0x2
    80000122:	360080e7          	jalr	864(ra) # 8000247e <either_copyin>
    80000126:	01550c63          	beq	a0,s5,8000013e <consolewrite+0x4a>
      break;
    uartputc(c);
    8000012a:	fbf44503          	lbu	a0,-65(s0)
    8000012e:	00000097          	auipc	ra,0x0
    80000132:	77a080e7          	jalr	1914(ra) # 800008a8 <uartputc>
  for(i = 0; i < n; i++){
    80000136:	2905                	addiw	s2,s2,1
    80000138:	0485                	addi	s1,s1,1
    8000013a:	fd299de3          	bne	s3,s2,80000114 <consolewrite+0x20>
  }

  return i;
}
    8000013e:	854a                	mv	a0,s2
    80000140:	60a6                	ld	ra,72(sp)
    80000142:	6406                	ld	s0,64(sp)
    80000144:	74e2                	ld	s1,56(sp)
    80000146:	7942                	ld	s2,48(sp)
    80000148:	79a2                	ld	s3,40(sp)
    8000014a:	7a02                	ld	s4,32(sp)
    8000014c:	6ae2                	ld	s5,24(sp)
    8000014e:	6161                	addi	sp,sp,80
    80000150:	8082                	ret
  for(i = 0; i < n; i++){
    80000152:	4901                	li	s2,0
    80000154:	b7ed                	j	8000013e <consolewrite+0x4a>

0000000080000156 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000156:	7159                	addi	sp,sp,-112
    80000158:	f486                	sd	ra,104(sp)
    8000015a:	f0a2                	sd	s0,96(sp)
    8000015c:	eca6                	sd	s1,88(sp)
    8000015e:	e8ca                	sd	s2,80(sp)
    80000160:	e4ce                	sd	s3,72(sp)
    80000162:	e0d2                	sd	s4,64(sp)
    80000164:	fc56                	sd	s5,56(sp)
    80000166:	f85a                	sd	s6,48(sp)
    80000168:	f45e                	sd	s7,40(sp)
    8000016a:	f062                	sd	s8,32(sp)
    8000016c:	ec66                	sd	s9,24(sp)
    8000016e:	e86a                	sd	s10,16(sp)
    80000170:	1880                	addi	s0,sp,112
    80000172:	8aaa                	mv	s5,a0
    80000174:	8a2e                	mv	s4,a1
    80000176:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000178:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000017c:	00011517          	auipc	a0,0x11
    80000180:	00450513          	addi	a0,a0,4 # 80011180 <cons>
    80000184:	00001097          	auipc	ra,0x1
    80000188:	a3e080e7          	jalr	-1474(ra) # 80000bc2 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000018c:	00011497          	auipc	s1,0x11
    80000190:	ff448493          	addi	s1,s1,-12 # 80011180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    80000194:	00011917          	auipc	s2,0x11
    80000198:	08490913          	addi	s2,s2,132 # 80011218 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    8000019c:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    8000019e:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001a0:	4ca9                	li	s9,10
  while(n > 0){
    800001a2:	07305863          	blez	s3,80000212 <consoleread+0xbc>
    while(cons.r == cons.w){
    800001a6:	0984a783          	lw	a5,152(s1)
    800001aa:	09c4a703          	lw	a4,156(s1)
    800001ae:	02f71463          	bne	a4,a5,800001d6 <consoleread+0x80>
      if(myproc()->killed){
    800001b2:	00002097          	auipc	ra,0x2
    800001b6:	80e080e7          	jalr	-2034(ra) # 800019c0 <myproc>
    800001ba:	551c                	lw	a5,40(a0)
    800001bc:	e7b5                	bnez	a5,80000228 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001be:	85a6                	mv	a1,s1
    800001c0:	854a                	mv	a0,s2
    800001c2:	00002097          	auipc	ra,0x2
    800001c6:	ec2080e7          	jalr	-318(ra) # 80002084 <sleep>
    while(cons.r == cons.w){
    800001ca:	0984a783          	lw	a5,152(s1)
    800001ce:	09c4a703          	lw	a4,156(s1)
    800001d2:	fef700e3          	beq	a4,a5,800001b2 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001d6:	0017871b          	addiw	a4,a5,1
    800001da:	08e4ac23          	sw	a4,152(s1)
    800001de:	07f7f713          	andi	a4,a5,127
    800001e2:	9726                	add	a4,a4,s1
    800001e4:	01874703          	lbu	a4,24(a4)
    800001e8:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    800001ec:	077d0563          	beq	s10,s7,80000256 <consoleread+0x100>
    cbuf = c;
    800001f0:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001f4:	4685                	li	a3,1
    800001f6:	f9f40613          	addi	a2,s0,-97
    800001fa:	85d2                	mv	a1,s4
    800001fc:	8556                	mv	a0,s5
    800001fe:	00002097          	auipc	ra,0x2
    80000202:	22a080e7          	jalr	554(ra) # 80002428 <either_copyout>
    80000206:	01850663          	beq	a0,s8,80000212 <consoleread+0xbc>
    dst++;
    8000020a:	0a05                	addi	s4,s4,1
    --n;
    8000020c:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    8000020e:	f99d1ae3          	bne	s10,s9,800001a2 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000212:	00011517          	auipc	a0,0x11
    80000216:	f6e50513          	addi	a0,a0,-146 # 80011180 <cons>
    8000021a:	00001097          	auipc	ra,0x1
    8000021e:	a5c080e7          	jalr	-1444(ra) # 80000c76 <release>

  return target - n;
    80000222:	413b053b          	subw	a0,s6,s3
    80000226:	a811                	j	8000023a <consoleread+0xe4>
        release(&cons.lock);
    80000228:	00011517          	auipc	a0,0x11
    8000022c:	f5850513          	addi	a0,a0,-168 # 80011180 <cons>
    80000230:	00001097          	auipc	ra,0x1
    80000234:	a46080e7          	jalr	-1466(ra) # 80000c76 <release>
        return -1;
    80000238:	557d                	li	a0,-1
}
    8000023a:	70a6                	ld	ra,104(sp)
    8000023c:	7406                	ld	s0,96(sp)
    8000023e:	64e6                	ld	s1,88(sp)
    80000240:	6946                	ld	s2,80(sp)
    80000242:	69a6                	ld	s3,72(sp)
    80000244:	6a06                	ld	s4,64(sp)
    80000246:	7ae2                	ld	s5,56(sp)
    80000248:	7b42                	ld	s6,48(sp)
    8000024a:	7ba2                	ld	s7,40(sp)
    8000024c:	7c02                	ld	s8,32(sp)
    8000024e:	6ce2                	ld	s9,24(sp)
    80000250:	6d42                	ld	s10,16(sp)
    80000252:	6165                	addi	sp,sp,112
    80000254:	8082                	ret
      if(n < target){
    80000256:	0009871b          	sext.w	a4,s3
    8000025a:	fb677ce3          	bgeu	a4,s6,80000212 <consoleread+0xbc>
        cons.r--;
    8000025e:	00011717          	auipc	a4,0x11
    80000262:	faf72d23          	sw	a5,-70(a4) # 80011218 <cons+0x98>
    80000266:	b775                	j	80000212 <consoleread+0xbc>

0000000080000268 <consputc>:
{
    80000268:	1141                	addi	sp,sp,-16
    8000026a:	e406                	sd	ra,8(sp)
    8000026c:	e022                	sd	s0,0(sp)
    8000026e:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000270:	10000793          	li	a5,256
    80000274:	00f50a63          	beq	a0,a5,80000288 <consputc+0x20>
    uartputc_sync(c);
    80000278:	00000097          	auipc	ra,0x0
    8000027c:	55e080e7          	jalr	1374(ra) # 800007d6 <uartputc_sync>
}
    80000280:	60a2                	ld	ra,8(sp)
    80000282:	6402                	ld	s0,0(sp)
    80000284:	0141                	addi	sp,sp,16
    80000286:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    80000288:	4521                	li	a0,8
    8000028a:	00000097          	auipc	ra,0x0
    8000028e:	54c080e7          	jalr	1356(ra) # 800007d6 <uartputc_sync>
    80000292:	02000513          	li	a0,32
    80000296:	00000097          	auipc	ra,0x0
    8000029a:	540080e7          	jalr	1344(ra) # 800007d6 <uartputc_sync>
    8000029e:	4521                	li	a0,8
    800002a0:	00000097          	auipc	ra,0x0
    800002a4:	536080e7          	jalr	1334(ra) # 800007d6 <uartputc_sync>
    800002a8:	bfe1                	j	80000280 <consputc+0x18>

00000000800002aa <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002aa:	1101                	addi	sp,sp,-32
    800002ac:	ec06                	sd	ra,24(sp)
    800002ae:	e822                	sd	s0,16(sp)
    800002b0:	e426                	sd	s1,8(sp)
    800002b2:	e04a                	sd	s2,0(sp)
    800002b4:	1000                	addi	s0,sp,32
    800002b6:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002b8:	00011517          	auipc	a0,0x11
    800002bc:	ec850513          	addi	a0,a0,-312 # 80011180 <cons>
    800002c0:	00001097          	auipc	ra,0x1
    800002c4:	902080e7          	jalr	-1790(ra) # 80000bc2 <acquire>

  switch(c){
    800002c8:	47d5                	li	a5,21
    800002ca:	0af48663          	beq	s1,a5,80000376 <consoleintr+0xcc>
    800002ce:	0297ca63          	blt	a5,s1,80000302 <consoleintr+0x58>
    800002d2:	47a1                	li	a5,8
    800002d4:	0ef48763          	beq	s1,a5,800003c2 <consoleintr+0x118>
    800002d8:	47c1                	li	a5,16
    800002da:	10f49a63          	bne	s1,a5,800003ee <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002de:	00002097          	auipc	ra,0x2
    800002e2:	1f6080e7          	jalr	502(ra) # 800024d4 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002e6:	00011517          	auipc	a0,0x11
    800002ea:	e9a50513          	addi	a0,a0,-358 # 80011180 <cons>
    800002ee:	00001097          	auipc	ra,0x1
    800002f2:	988080e7          	jalr	-1656(ra) # 80000c76 <release>
}
    800002f6:	60e2                	ld	ra,24(sp)
    800002f8:	6442                	ld	s0,16(sp)
    800002fa:	64a2                	ld	s1,8(sp)
    800002fc:	6902                	ld	s2,0(sp)
    800002fe:	6105                	addi	sp,sp,32
    80000300:	8082                	ret
  switch(c){
    80000302:	07f00793          	li	a5,127
    80000306:	0af48e63          	beq	s1,a5,800003c2 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000030a:	00011717          	auipc	a4,0x11
    8000030e:	e7670713          	addi	a4,a4,-394 # 80011180 <cons>
    80000312:	0a072783          	lw	a5,160(a4)
    80000316:	09872703          	lw	a4,152(a4)
    8000031a:	9f99                	subw	a5,a5,a4
    8000031c:	07f00713          	li	a4,127
    80000320:	fcf763e3          	bltu	a4,a5,800002e6 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000324:	47b5                	li	a5,13
    80000326:	0cf48763          	beq	s1,a5,800003f4 <consoleintr+0x14a>
      consputc(c);
    8000032a:	8526                	mv	a0,s1
    8000032c:	00000097          	auipc	ra,0x0
    80000330:	f3c080e7          	jalr	-196(ra) # 80000268 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000334:	00011797          	auipc	a5,0x11
    80000338:	e4c78793          	addi	a5,a5,-436 # 80011180 <cons>
    8000033c:	0a07a703          	lw	a4,160(a5)
    80000340:	0017069b          	addiw	a3,a4,1
    80000344:	0006861b          	sext.w	a2,a3
    80000348:	0ad7a023          	sw	a3,160(a5)
    8000034c:	07f77713          	andi	a4,a4,127
    80000350:	97ba                	add	a5,a5,a4
    80000352:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    80000356:	47a9                	li	a5,10
    80000358:	0cf48563          	beq	s1,a5,80000422 <consoleintr+0x178>
    8000035c:	4791                	li	a5,4
    8000035e:	0cf48263          	beq	s1,a5,80000422 <consoleintr+0x178>
    80000362:	00011797          	auipc	a5,0x11
    80000366:	eb67a783          	lw	a5,-330(a5) # 80011218 <cons+0x98>
    8000036a:	0807879b          	addiw	a5,a5,128
    8000036e:	f6f61ce3          	bne	a2,a5,800002e6 <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000372:	863e                	mv	a2,a5
    80000374:	a07d                	j	80000422 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000376:	00011717          	auipc	a4,0x11
    8000037a:	e0a70713          	addi	a4,a4,-502 # 80011180 <cons>
    8000037e:	0a072783          	lw	a5,160(a4)
    80000382:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    80000386:	00011497          	auipc	s1,0x11
    8000038a:	dfa48493          	addi	s1,s1,-518 # 80011180 <cons>
    while(cons.e != cons.w &&
    8000038e:	4929                	li	s2,10
    80000390:	f4f70be3          	beq	a4,a5,800002e6 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    80000394:	37fd                	addiw	a5,a5,-1
    80000396:	07f7f713          	andi	a4,a5,127
    8000039a:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    8000039c:	01874703          	lbu	a4,24(a4)
    800003a0:	f52703e3          	beq	a4,s2,800002e6 <consoleintr+0x3c>
      cons.e--;
    800003a4:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003a8:	10000513          	li	a0,256
    800003ac:	00000097          	auipc	ra,0x0
    800003b0:	ebc080e7          	jalr	-324(ra) # 80000268 <consputc>
    while(cons.e != cons.w &&
    800003b4:	0a04a783          	lw	a5,160(s1)
    800003b8:	09c4a703          	lw	a4,156(s1)
    800003bc:	fcf71ce3          	bne	a4,a5,80000394 <consoleintr+0xea>
    800003c0:	b71d                	j	800002e6 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003c2:	00011717          	auipc	a4,0x11
    800003c6:	dbe70713          	addi	a4,a4,-578 # 80011180 <cons>
    800003ca:	0a072783          	lw	a5,160(a4)
    800003ce:	09c72703          	lw	a4,156(a4)
    800003d2:	f0f70ae3          	beq	a4,a5,800002e6 <consoleintr+0x3c>
      cons.e--;
    800003d6:	37fd                	addiw	a5,a5,-1
    800003d8:	00011717          	auipc	a4,0x11
    800003dc:	e4f72423          	sw	a5,-440(a4) # 80011220 <cons+0xa0>
      consputc(BACKSPACE);
    800003e0:	10000513          	li	a0,256
    800003e4:	00000097          	auipc	ra,0x0
    800003e8:	e84080e7          	jalr	-380(ra) # 80000268 <consputc>
    800003ec:	bded                	j	800002e6 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    800003ee:	ee048ce3          	beqz	s1,800002e6 <consoleintr+0x3c>
    800003f2:	bf21                	j	8000030a <consoleintr+0x60>
      consputc(c);
    800003f4:	4529                	li	a0,10
    800003f6:	00000097          	auipc	ra,0x0
    800003fa:	e72080e7          	jalr	-398(ra) # 80000268 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    800003fe:	00011797          	auipc	a5,0x11
    80000402:	d8278793          	addi	a5,a5,-638 # 80011180 <cons>
    80000406:	0a07a703          	lw	a4,160(a5)
    8000040a:	0017069b          	addiw	a3,a4,1
    8000040e:	0006861b          	sext.w	a2,a3
    80000412:	0ad7a023          	sw	a3,160(a5)
    80000416:	07f77713          	andi	a4,a4,127
    8000041a:	97ba                	add	a5,a5,a4
    8000041c:	4729                	li	a4,10
    8000041e:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000422:	00011797          	auipc	a5,0x11
    80000426:	dec7ad23          	sw	a2,-518(a5) # 8001121c <cons+0x9c>
        wakeup(&cons.r);
    8000042a:	00011517          	auipc	a0,0x11
    8000042e:	dee50513          	addi	a0,a0,-530 # 80011218 <cons+0x98>
    80000432:	00002097          	auipc	ra,0x2
    80000436:	dde080e7          	jalr	-546(ra) # 80002210 <wakeup>
    8000043a:	b575                	j	800002e6 <consoleintr+0x3c>

000000008000043c <consoleinit>:

void
consoleinit(void)
{
    8000043c:	1141                	addi	sp,sp,-16
    8000043e:	e406                	sd	ra,8(sp)
    80000440:	e022                	sd	s0,0(sp)
    80000442:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000444:	00008597          	auipc	a1,0x8
    80000448:	bcc58593          	addi	a1,a1,-1076 # 80008010 <etext+0x10>
    8000044c:	00011517          	auipc	a0,0x11
    80000450:	d3450513          	addi	a0,a0,-716 # 80011180 <cons>
    80000454:	00000097          	auipc	ra,0x0
    80000458:	6de080e7          	jalr	1758(ra) # 80000b32 <initlock>

  uartinit();
    8000045c:	00000097          	auipc	ra,0x0
    80000460:	32a080e7          	jalr	810(ra) # 80000786 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000464:	00021797          	auipc	a5,0x21
    80000468:	eb478793          	addi	a5,a5,-332 # 80021318 <devsw>
    8000046c:	00000717          	auipc	a4,0x0
    80000470:	cea70713          	addi	a4,a4,-790 # 80000156 <consoleread>
    80000474:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000476:	00000717          	auipc	a4,0x0
    8000047a:	c7e70713          	addi	a4,a4,-898 # 800000f4 <consolewrite>
    8000047e:	ef98                	sd	a4,24(a5)
}
    80000480:	60a2                	ld	ra,8(sp)
    80000482:	6402                	ld	s0,0(sp)
    80000484:	0141                	addi	sp,sp,16
    80000486:	8082                	ret

0000000080000488 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    80000488:	7179                	addi	sp,sp,-48
    8000048a:	f406                	sd	ra,40(sp)
    8000048c:	f022                	sd	s0,32(sp)
    8000048e:	ec26                	sd	s1,24(sp)
    80000490:	e84a                	sd	s2,16(sp)
    80000492:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    80000494:	c219                	beqz	a2,8000049a <printint+0x12>
    80000496:	08054663          	bltz	a0,80000522 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    8000049a:	2501                	sext.w	a0,a0
    8000049c:	4881                	li	a7,0
    8000049e:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004a2:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004a4:	2581                	sext.w	a1,a1
    800004a6:	00008617          	auipc	a2,0x8
    800004aa:	b9a60613          	addi	a2,a2,-1126 # 80008040 <digits>
    800004ae:	883a                	mv	a6,a4
    800004b0:	2705                	addiw	a4,a4,1
    800004b2:	02b577bb          	remuw	a5,a0,a1
    800004b6:	1782                	slli	a5,a5,0x20
    800004b8:	9381                	srli	a5,a5,0x20
    800004ba:	97b2                	add	a5,a5,a2
    800004bc:	0007c783          	lbu	a5,0(a5)
    800004c0:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004c4:	0005079b          	sext.w	a5,a0
    800004c8:	02b5553b          	divuw	a0,a0,a1
    800004cc:	0685                	addi	a3,a3,1
    800004ce:	feb7f0e3          	bgeu	a5,a1,800004ae <printint+0x26>

  if(sign)
    800004d2:	00088b63          	beqz	a7,800004e8 <printint+0x60>
    buf[i++] = '-';
    800004d6:	fe040793          	addi	a5,s0,-32
    800004da:	973e                	add	a4,a4,a5
    800004dc:	02d00793          	li	a5,45
    800004e0:	fef70823          	sb	a5,-16(a4)
    800004e4:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004e8:	02e05763          	blez	a4,80000516 <printint+0x8e>
    800004ec:	fd040793          	addi	a5,s0,-48
    800004f0:	00e784b3          	add	s1,a5,a4
    800004f4:	fff78913          	addi	s2,a5,-1
    800004f8:	993a                	add	s2,s2,a4
    800004fa:	377d                	addiw	a4,a4,-1
    800004fc:	1702                	slli	a4,a4,0x20
    800004fe:	9301                	srli	a4,a4,0x20
    80000500:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000504:	fff4c503          	lbu	a0,-1(s1)
    80000508:	00000097          	auipc	ra,0x0
    8000050c:	d60080e7          	jalr	-672(ra) # 80000268 <consputc>
  while(--i >= 0)
    80000510:	14fd                	addi	s1,s1,-1
    80000512:	ff2499e3          	bne	s1,s2,80000504 <printint+0x7c>
}
    80000516:	70a2                	ld	ra,40(sp)
    80000518:	7402                	ld	s0,32(sp)
    8000051a:	64e2                	ld	s1,24(sp)
    8000051c:	6942                	ld	s2,16(sp)
    8000051e:	6145                	addi	sp,sp,48
    80000520:	8082                	ret
    x = -xx;
    80000522:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000526:	4885                	li	a7,1
    x = -xx;
    80000528:	bf9d                	j	8000049e <printint+0x16>

000000008000052a <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000052a:	1101                	addi	sp,sp,-32
    8000052c:	ec06                	sd	ra,24(sp)
    8000052e:	e822                	sd	s0,16(sp)
    80000530:	e426                	sd	s1,8(sp)
    80000532:	1000                	addi	s0,sp,32
    80000534:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000536:	00011797          	auipc	a5,0x11
    8000053a:	d007a523          	sw	zero,-758(a5) # 80011240 <pr+0x18>
  printf("panic: ");
    8000053e:	00008517          	auipc	a0,0x8
    80000542:	ada50513          	addi	a0,a0,-1318 # 80008018 <etext+0x18>
    80000546:	00000097          	auipc	ra,0x0
    8000054a:	02e080e7          	jalr	46(ra) # 80000574 <printf>
  printf(s);
    8000054e:	8526                	mv	a0,s1
    80000550:	00000097          	auipc	ra,0x0
    80000554:	024080e7          	jalr	36(ra) # 80000574 <printf>
  printf("\n");
    80000558:	00008517          	auipc	a0,0x8
    8000055c:	b7050513          	addi	a0,a0,-1168 # 800080c8 <digits+0x88>
    80000560:	00000097          	auipc	ra,0x0
    80000564:	014080e7          	jalr	20(ra) # 80000574 <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000568:	4785                	li	a5,1
    8000056a:	00009717          	auipc	a4,0x9
    8000056e:	a8f72b23          	sw	a5,-1386(a4) # 80009000 <panicked>
  for(;;)
    80000572:	a001                	j	80000572 <panic+0x48>

0000000080000574 <printf>:
{
    80000574:	7131                	addi	sp,sp,-192
    80000576:	fc86                	sd	ra,120(sp)
    80000578:	f8a2                	sd	s0,112(sp)
    8000057a:	f4a6                	sd	s1,104(sp)
    8000057c:	f0ca                	sd	s2,96(sp)
    8000057e:	ecce                	sd	s3,88(sp)
    80000580:	e8d2                	sd	s4,80(sp)
    80000582:	e4d6                	sd	s5,72(sp)
    80000584:	e0da                	sd	s6,64(sp)
    80000586:	fc5e                	sd	s7,56(sp)
    80000588:	f862                	sd	s8,48(sp)
    8000058a:	f466                	sd	s9,40(sp)
    8000058c:	f06a                	sd	s10,32(sp)
    8000058e:	ec6e                	sd	s11,24(sp)
    80000590:	0100                	addi	s0,sp,128
    80000592:	8a2a                	mv	s4,a0
    80000594:	e40c                	sd	a1,8(s0)
    80000596:	e810                	sd	a2,16(s0)
    80000598:	ec14                	sd	a3,24(s0)
    8000059a:	f018                	sd	a4,32(s0)
    8000059c:	f41c                	sd	a5,40(s0)
    8000059e:	03043823          	sd	a6,48(s0)
    800005a2:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005a6:	00011d97          	auipc	s11,0x11
    800005aa:	c9adad83          	lw	s11,-870(s11) # 80011240 <pr+0x18>
  if(locking)
    800005ae:	020d9b63          	bnez	s11,800005e4 <printf+0x70>
  if (fmt == 0)
    800005b2:	040a0263          	beqz	s4,800005f6 <printf+0x82>
  va_start(ap, fmt);
    800005b6:	00840793          	addi	a5,s0,8
    800005ba:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005be:	000a4503          	lbu	a0,0(s4)
    800005c2:	14050f63          	beqz	a0,80000720 <printf+0x1ac>
    800005c6:	4981                	li	s3,0
    if(c != '%'){
    800005c8:	02500a93          	li	s5,37
    switch(c){
    800005cc:	07000b93          	li	s7,112
  consputc('x');
    800005d0:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005d2:	00008b17          	auipc	s6,0x8
    800005d6:	a6eb0b13          	addi	s6,s6,-1426 # 80008040 <digits>
    switch(c){
    800005da:	07300c93          	li	s9,115
    800005de:	06400c13          	li	s8,100
    800005e2:	a82d                	j	8000061c <printf+0xa8>
    acquire(&pr.lock);
    800005e4:	00011517          	auipc	a0,0x11
    800005e8:	c4450513          	addi	a0,a0,-956 # 80011228 <pr>
    800005ec:	00000097          	auipc	ra,0x0
    800005f0:	5d6080e7          	jalr	1494(ra) # 80000bc2 <acquire>
    800005f4:	bf7d                	j	800005b2 <printf+0x3e>
    panic("null fmt");
    800005f6:	00008517          	auipc	a0,0x8
    800005fa:	a3250513          	addi	a0,a0,-1486 # 80008028 <etext+0x28>
    800005fe:	00000097          	auipc	ra,0x0
    80000602:	f2c080e7          	jalr	-212(ra) # 8000052a <panic>
      consputc(c);
    80000606:	00000097          	auipc	ra,0x0
    8000060a:	c62080e7          	jalr	-926(ra) # 80000268 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    8000060e:	2985                	addiw	s3,s3,1
    80000610:	013a07b3          	add	a5,s4,s3
    80000614:	0007c503          	lbu	a0,0(a5)
    80000618:	10050463          	beqz	a0,80000720 <printf+0x1ac>
    if(c != '%'){
    8000061c:	ff5515e3          	bne	a0,s5,80000606 <printf+0x92>
    c = fmt[++i] & 0xff;
    80000620:	2985                	addiw	s3,s3,1
    80000622:	013a07b3          	add	a5,s4,s3
    80000626:	0007c783          	lbu	a5,0(a5)
    8000062a:	0007849b          	sext.w	s1,a5
    if(c == 0)
    8000062e:	cbed                	beqz	a5,80000720 <printf+0x1ac>
    switch(c){
    80000630:	05778a63          	beq	a5,s7,80000684 <printf+0x110>
    80000634:	02fbf663          	bgeu	s7,a5,80000660 <printf+0xec>
    80000638:	09978863          	beq	a5,s9,800006c8 <printf+0x154>
    8000063c:	07800713          	li	a4,120
    80000640:	0ce79563          	bne	a5,a4,8000070a <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000644:	f8843783          	ld	a5,-120(s0)
    80000648:	00878713          	addi	a4,a5,8
    8000064c:	f8e43423          	sd	a4,-120(s0)
    80000650:	4605                	li	a2,1
    80000652:	85ea                	mv	a1,s10
    80000654:	4388                	lw	a0,0(a5)
    80000656:	00000097          	auipc	ra,0x0
    8000065a:	e32080e7          	jalr	-462(ra) # 80000488 <printint>
      break;
    8000065e:	bf45                	j	8000060e <printf+0x9a>
    switch(c){
    80000660:	09578f63          	beq	a5,s5,800006fe <printf+0x18a>
    80000664:	0b879363          	bne	a5,s8,8000070a <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    80000668:	f8843783          	ld	a5,-120(s0)
    8000066c:	00878713          	addi	a4,a5,8
    80000670:	f8e43423          	sd	a4,-120(s0)
    80000674:	4605                	li	a2,1
    80000676:	45a9                	li	a1,10
    80000678:	4388                	lw	a0,0(a5)
    8000067a:	00000097          	auipc	ra,0x0
    8000067e:	e0e080e7          	jalr	-498(ra) # 80000488 <printint>
      break;
    80000682:	b771                	j	8000060e <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000684:	f8843783          	ld	a5,-120(s0)
    80000688:	00878713          	addi	a4,a5,8
    8000068c:	f8e43423          	sd	a4,-120(s0)
    80000690:	0007b903          	ld	s2,0(a5)
  consputc('0');
    80000694:	03000513          	li	a0,48
    80000698:	00000097          	auipc	ra,0x0
    8000069c:	bd0080e7          	jalr	-1072(ra) # 80000268 <consputc>
  consputc('x');
    800006a0:	07800513          	li	a0,120
    800006a4:	00000097          	auipc	ra,0x0
    800006a8:	bc4080e7          	jalr	-1084(ra) # 80000268 <consputc>
    800006ac:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006ae:	03c95793          	srli	a5,s2,0x3c
    800006b2:	97da                	add	a5,a5,s6
    800006b4:	0007c503          	lbu	a0,0(a5)
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bb0080e7          	jalr	-1104(ra) # 80000268 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006c0:	0912                	slli	s2,s2,0x4
    800006c2:	34fd                	addiw	s1,s1,-1
    800006c4:	f4ed                	bnez	s1,800006ae <printf+0x13a>
    800006c6:	b7a1                	j	8000060e <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006c8:	f8843783          	ld	a5,-120(s0)
    800006cc:	00878713          	addi	a4,a5,8
    800006d0:	f8e43423          	sd	a4,-120(s0)
    800006d4:	6384                	ld	s1,0(a5)
    800006d6:	cc89                	beqz	s1,800006f0 <printf+0x17c>
      for(; *s; s++)
    800006d8:	0004c503          	lbu	a0,0(s1)
    800006dc:	d90d                	beqz	a0,8000060e <printf+0x9a>
        consputc(*s);
    800006de:	00000097          	auipc	ra,0x0
    800006e2:	b8a080e7          	jalr	-1142(ra) # 80000268 <consputc>
      for(; *s; s++)
    800006e6:	0485                	addi	s1,s1,1
    800006e8:	0004c503          	lbu	a0,0(s1)
    800006ec:	f96d                	bnez	a0,800006de <printf+0x16a>
    800006ee:	b705                	j	8000060e <printf+0x9a>
        s = "(null)";
    800006f0:	00008497          	auipc	s1,0x8
    800006f4:	93048493          	addi	s1,s1,-1744 # 80008020 <etext+0x20>
      for(; *s; s++)
    800006f8:	02800513          	li	a0,40
    800006fc:	b7cd                	j	800006de <printf+0x16a>
      consputc('%');
    800006fe:	8556                	mv	a0,s5
    80000700:	00000097          	auipc	ra,0x0
    80000704:	b68080e7          	jalr	-1176(ra) # 80000268 <consputc>
      break;
    80000708:	b719                	j	8000060e <printf+0x9a>
      consputc('%');
    8000070a:	8556                	mv	a0,s5
    8000070c:	00000097          	auipc	ra,0x0
    80000710:	b5c080e7          	jalr	-1188(ra) # 80000268 <consputc>
      consputc(c);
    80000714:	8526                	mv	a0,s1
    80000716:	00000097          	auipc	ra,0x0
    8000071a:	b52080e7          	jalr	-1198(ra) # 80000268 <consputc>
      break;
    8000071e:	bdc5                	j	8000060e <printf+0x9a>
  if(locking)
    80000720:	020d9163          	bnez	s11,80000742 <printf+0x1ce>
}
    80000724:	70e6                	ld	ra,120(sp)
    80000726:	7446                	ld	s0,112(sp)
    80000728:	74a6                	ld	s1,104(sp)
    8000072a:	7906                	ld	s2,96(sp)
    8000072c:	69e6                	ld	s3,88(sp)
    8000072e:	6a46                	ld	s4,80(sp)
    80000730:	6aa6                	ld	s5,72(sp)
    80000732:	6b06                	ld	s6,64(sp)
    80000734:	7be2                	ld	s7,56(sp)
    80000736:	7c42                	ld	s8,48(sp)
    80000738:	7ca2                	ld	s9,40(sp)
    8000073a:	7d02                	ld	s10,32(sp)
    8000073c:	6de2                	ld	s11,24(sp)
    8000073e:	6129                	addi	sp,sp,192
    80000740:	8082                	ret
    release(&pr.lock);
    80000742:	00011517          	auipc	a0,0x11
    80000746:	ae650513          	addi	a0,a0,-1306 # 80011228 <pr>
    8000074a:	00000097          	auipc	ra,0x0
    8000074e:	52c080e7          	jalr	1324(ra) # 80000c76 <release>
}
    80000752:	bfc9                	j	80000724 <printf+0x1b0>

0000000080000754 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000754:	1101                	addi	sp,sp,-32
    80000756:	ec06                	sd	ra,24(sp)
    80000758:	e822                	sd	s0,16(sp)
    8000075a:	e426                	sd	s1,8(sp)
    8000075c:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    8000075e:	00011497          	auipc	s1,0x11
    80000762:	aca48493          	addi	s1,s1,-1334 # 80011228 <pr>
    80000766:	00008597          	auipc	a1,0x8
    8000076a:	8d258593          	addi	a1,a1,-1838 # 80008038 <etext+0x38>
    8000076e:	8526                	mv	a0,s1
    80000770:	00000097          	auipc	ra,0x0
    80000774:	3c2080e7          	jalr	962(ra) # 80000b32 <initlock>
  pr.locking = 1;
    80000778:	4785                	li	a5,1
    8000077a:	cc9c                	sw	a5,24(s1)
}
    8000077c:	60e2                	ld	ra,24(sp)
    8000077e:	6442                	ld	s0,16(sp)
    80000780:	64a2                	ld	s1,8(sp)
    80000782:	6105                	addi	sp,sp,32
    80000784:	8082                	ret

0000000080000786 <uartinit>:

void uartstart();

void
uartinit(void)
{
    80000786:	1141                	addi	sp,sp,-16
    80000788:	e406                	sd	ra,8(sp)
    8000078a:	e022                	sd	s0,0(sp)
    8000078c:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    8000078e:	100007b7          	lui	a5,0x10000
    80000792:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    80000796:	f8000713          	li	a4,-128
    8000079a:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    8000079e:	470d                	li	a4,3
    800007a0:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007a4:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007a8:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007ac:	469d                	li	a3,7
    800007ae:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007b2:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007b6:	00008597          	auipc	a1,0x8
    800007ba:	8a258593          	addi	a1,a1,-1886 # 80008058 <digits+0x18>
    800007be:	00011517          	auipc	a0,0x11
    800007c2:	a8a50513          	addi	a0,a0,-1398 # 80011248 <uart_tx_lock>
    800007c6:	00000097          	auipc	ra,0x0
    800007ca:	36c080e7          	jalr	876(ra) # 80000b32 <initlock>
}
    800007ce:	60a2                	ld	ra,8(sp)
    800007d0:	6402                	ld	s0,0(sp)
    800007d2:	0141                	addi	sp,sp,16
    800007d4:	8082                	ret

00000000800007d6 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007d6:	1101                	addi	sp,sp,-32
    800007d8:	ec06                	sd	ra,24(sp)
    800007da:	e822                	sd	s0,16(sp)
    800007dc:	e426                	sd	s1,8(sp)
    800007de:	1000                	addi	s0,sp,32
    800007e0:	84aa                	mv	s1,a0
  push_off();
    800007e2:	00000097          	auipc	ra,0x0
    800007e6:	394080e7          	jalr	916(ra) # 80000b76 <push_off>

  if(panicked){
    800007ea:	00009797          	auipc	a5,0x9
    800007ee:	8167a783          	lw	a5,-2026(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    800007f2:	10000737          	lui	a4,0x10000
  if(panicked){
    800007f6:	c391                	beqz	a5,800007fa <uartputc_sync+0x24>
    for(;;)
    800007f8:	a001                	j	800007f8 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    800007fa:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    800007fe:	0207f793          	andi	a5,a5,32
    80000802:	dfe5                	beqz	a5,800007fa <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000804:	0ff4f513          	andi	a0,s1,255
    80000808:	100007b7          	lui	a5,0x10000
    8000080c:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000810:	00000097          	auipc	ra,0x0
    80000814:	406080e7          	jalr	1030(ra) # 80000c16 <pop_off>
}
    80000818:	60e2                	ld	ra,24(sp)
    8000081a:	6442                	ld	s0,16(sp)
    8000081c:	64a2                	ld	s1,8(sp)
    8000081e:	6105                	addi	sp,sp,32
    80000820:	8082                	ret

0000000080000822 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000822:	00008797          	auipc	a5,0x8
    80000826:	7e67b783          	ld	a5,2022(a5) # 80009008 <uart_tx_r>
    8000082a:	00008717          	auipc	a4,0x8
    8000082e:	7e673703          	ld	a4,2022(a4) # 80009010 <uart_tx_w>
    80000832:	06f70a63          	beq	a4,a5,800008a6 <uartstart+0x84>
{
    80000836:	7139                	addi	sp,sp,-64
    80000838:	fc06                	sd	ra,56(sp)
    8000083a:	f822                	sd	s0,48(sp)
    8000083c:	f426                	sd	s1,40(sp)
    8000083e:	f04a                	sd	s2,32(sp)
    80000840:	ec4e                	sd	s3,24(sp)
    80000842:	e852                	sd	s4,16(sp)
    80000844:	e456                	sd	s5,8(sp)
    80000846:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000848:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000084c:	00011a17          	auipc	s4,0x11
    80000850:	9fca0a13          	addi	s4,s4,-1540 # 80011248 <uart_tx_lock>
    uart_tx_r += 1;
    80000854:	00008497          	auipc	s1,0x8
    80000858:	7b448493          	addi	s1,s1,1972 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000085c:	00008997          	auipc	s3,0x8
    80000860:	7b498993          	addi	s3,s3,1972 # 80009010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000864:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000868:	02077713          	andi	a4,a4,32
    8000086c:	c705                	beqz	a4,80000894 <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000086e:	01f7f713          	andi	a4,a5,31
    80000872:	9752                	add	a4,a4,s4
    80000874:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    80000878:	0785                	addi	a5,a5,1
    8000087a:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000087c:	8526                	mv	a0,s1
    8000087e:	00002097          	auipc	ra,0x2
    80000882:	992080e7          	jalr	-1646(ra) # 80002210 <wakeup>
    
    WriteReg(THR, c);
    80000886:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    8000088a:	609c                	ld	a5,0(s1)
    8000088c:	0009b703          	ld	a4,0(s3)
    80000890:	fcf71ae3          	bne	a4,a5,80000864 <uartstart+0x42>
  }
}
    80000894:	70e2                	ld	ra,56(sp)
    80000896:	7442                	ld	s0,48(sp)
    80000898:	74a2                	ld	s1,40(sp)
    8000089a:	7902                	ld	s2,32(sp)
    8000089c:	69e2                	ld	s3,24(sp)
    8000089e:	6a42                	ld	s4,16(sp)
    800008a0:	6aa2                	ld	s5,8(sp)
    800008a2:	6121                	addi	sp,sp,64
    800008a4:	8082                	ret
    800008a6:	8082                	ret

00000000800008a8 <uartputc>:
{
    800008a8:	7179                	addi	sp,sp,-48
    800008aa:	f406                	sd	ra,40(sp)
    800008ac:	f022                	sd	s0,32(sp)
    800008ae:	ec26                	sd	s1,24(sp)
    800008b0:	e84a                	sd	s2,16(sp)
    800008b2:	e44e                	sd	s3,8(sp)
    800008b4:	e052                	sd	s4,0(sp)
    800008b6:	1800                	addi	s0,sp,48
    800008b8:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008ba:	00011517          	auipc	a0,0x11
    800008be:	98e50513          	addi	a0,a0,-1650 # 80011248 <uart_tx_lock>
    800008c2:	00000097          	auipc	ra,0x0
    800008c6:	300080e7          	jalr	768(ra) # 80000bc2 <acquire>
  if(panicked){
    800008ca:	00008797          	auipc	a5,0x8
    800008ce:	7367a783          	lw	a5,1846(a5) # 80009000 <panicked>
    800008d2:	c391                	beqz	a5,800008d6 <uartputc+0x2e>
    for(;;)
    800008d4:	a001                	j	800008d4 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008d6:	00008717          	auipc	a4,0x8
    800008da:	73a73703          	ld	a4,1850(a4) # 80009010 <uart_tx_w>
    800008de:	00008797          	auipc	a5,0x8
    800008e2:	72a7b783          	ld	a5,1834(a5) # 80009008 <uart_tx_r>
    800008e6:	02078793          	addi	a5,a5,32
    800008ea:	02e79b63          	bne	a5,a4,80000920 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    800008ee:	00011997          	auipc	s3,0x11
    800008f2:	95a98993          	addi	s3,s3,-1702 # 80011248 <uart_tx_lock>
    800008f6:	00008497          	auipc	s1,0x8
    800008fa:	71248493          	addi	s1,s1,1810 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008fe:	00008917          	auipc	s2,0x8
    80000902:	71290913          	addi	s2,s2,1810 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000906:	85ce                	mv	a1,s3
    80000908:	8526                	mv	a0,s1
    8000090a:	00001097          	auipc	ra,0x1
    8000090e:	77a080e7          	jalr	1914(ra) # 80002084 <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000912:	00093703          	ld	a4,0(s2)
    80000916:	609c                	ld	a5,0(s1)
    80000918:	02078793          	addi	a5,a5,32
    8000091c:	fee785e3          	beq	a5,a4,80000906 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000920:	00011497          	auipc	s1,0x11
    80000924:	92848493          	addi	s1,s1,-1752 # 80011248 <uart_tx_lock>
    80000928:	01f77793          	andi	a5,a4,31
    8000092c:	97a6                	add	a5,a5,s1
    8000092e:	01478c23          	sb	s4,24(a5)
      uart_tx_w += 1;
    80000932:	0705                	addi	a4,a4,1
    80000934:	00008797          	auipc	a5,0x8
    80000938:	6ce7be23          	sd	a4,1756(a5) # 80009010 <uart_tx_w>
      uartstart();
    8000093c:	00000097          	auipc	ra,0x0
    80000940:	ee6080e7          	jalr	-282(ra) # 80000822 <uartstart>
      release(&uart_tx_lock);
    80000944:	8526                	mv	a0,s1
    80000946:	00000097          	auipc	ra,0x0
    8000094a:	330080e7          	jalr	816(ra) # 80000c76 <release>
}
    8000094e:	70a2                	ld	ra,40(sp)
    80000950:	7402                	ld	s0,32(sp)
    80000952:	64e2                	ld	s1,24(sp)
    80000954:	6942                	ld	s2,16(sp)
    80000956:	69a2                	ld	s3,8(sp)
    80000958:	6a02                	ld	s4,0(sp)
    8000095a:	6145                	addi	sp,sp,48
    8000095c:	8082                	ret

000000008000095e <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    8000095e:	1141                	addi	sp,sp,-16
    80000960:	e422                	sd	s0,8(sp)
    80000962:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000964:	100007b7          	lui	a5,0x10000
    80000968:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000096c:	8b85                	andi	a5,a5,1
    8000096e:	cb91                	beqz	a5,80000982 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000970:	100007b7          	lui	a5,0x10000
    80000974:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    80000978:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    8000097c:	6422                	ld	s0,8(sp)
    8000097e:	0141                	addi	sp,sp,16
    80000980:	8082                	ret
    return -1;
    80000982:	557d                	li	a0,-1
    80000984:	bfe5                	j	8000097c <uartgetc+0x1e>

0000000080000986 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    80000986:	1101                	addi	sp,sp,-32
    80000988:	ec06                	sd	ra,24(sp)
    8000098a:	e822                	sd	s0,16(sp)
    8000098c:	e426                	sd	s1,8(sp)
    8000098e:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    80000990:	54fd                	li	s1,-1
    80000992:	a029                	j	8000099c <uartintr+0x16>
      break;
    consoleintr(c);
    80000994:	00000097          	auipc	ra,0x0
    80000998:	916080e7          	jalr	-1770(ra) # 800002aa <consoleintr>
    int c = uartgetc();
    8000099c:	00000097          	auipc	ra,0x0
    800009a0:	fc2080e7          	jalr	-62(ra) # 8000095e <uartgetc>
    if(c == -1)
    800009a4:	fe9518e3          	bne	a0,s1,80000994 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009a8:	00011497          	auipc	s1,0x11
    800009ac:	8a048493          	addi	s1,s1,-1888 # 80011248 <uart_tx_lock>
    800009b0:	8526                	mv	a0,s1
    800009b2:	00000097          	auipc	ra,0x0
    800009b6:	210080e7          	jalr	528(ra) # 80000bc2 <acquire>
  uartstart();
    800009ba:	00000097          	auipc	ra,0x0
    800009be:	e68080e7          	jalr	-408(ra) # 80000822 <uartstart>
  release(&uart_tx_lock);
    800009c2:	8526                	mv	a0,s1
    800009c4:	00000097          	auipc	ra,0x0
    800009c8:	2b2080e7          	jalr	690(ra) # 80000c76 <release>
}
    800009cc:	60e2                	ld	ra,24(sp)
    800009ce:	6442                	ld	s0,16(sp)
    800009d0:	64a2                	ld	s1,8(sp)
    800009d2:	6105                	addi	sp,sp,32
    800009d4:	8082                	ret

00000000800009d6 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009d6:	1101                	addi	sp,sp,-32
    800009d8:	ec06                	sd	ra,24(sp)
    800009da:	e822                	sd	s0,16(sp)
    800009dc:	e426                	sd	s1,8(sp)
    800009de:	e04a                	sd	s2,0(sp)
    800009e0:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009e2:	03451793          	slli	a5,a0,0x34
    800009e6:	ebb9                	bnez	a5,80000a3c <kfree+0x66>
    800009e8:	84aa                	mv	s1,a0
    800009ea:	00025797          	auipc	a5,0x25
    800009ee:	61678793          	addi	a5,a5,1558 # 80026000 <end>
    800009f2:	04f56563          	bltu	a0,a5,80000a3c <kfree+0x66>
    800009f6:	47c5                	li	a5,17
    800009f8:	07ee                	slli	a5,a5,0x1b
    800009fa:	04f57163          	bgeu	a0,a5,80000a3c <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    800009fe:	6605                	lui	a2,0x1
    80000a00:	4585                	li	a1,1
    80000a02:	00000097          	auipc	ra,0x0
    80000a06:	2bc080e7          	jalr	700(ra) # 80000cbe <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a0a:	00011917          	auipc	s2,0x11
    80000a0e:	87690913          	addi	s2,s2,-1930 # 80011280 <kmem>
    80000a12:	854a                	mv	a0,s2
    80000a14:	00000097          	auipc	ra,0x0
    80000a18:	1ae080e7          	jalr	430(ra) # 80000bc2 <acquire>
  r->next = kmem.freelist;
    80000a1c:	01893783          	ld	a5,24(s2)
    80000a20:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a22:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a26:	854a                	mv	a0,s2
    80000a28:	00000097          	auipc	ra,0x0
    80000a2c:	24e080e7          	jalr	590(ra) # 80000c76 <release>
}
    80000a30:	60e2                	ld	ra,24(sp)
    80000a32:	6442                	ld	s0,16(sp)
    80000a34:	64a2                	ld	s1,8(sp)
    80000a36:	6902                	ld	s2,0(sp)
    80000a38:	6105                	addi	sp,sp,32
    80000a3a:	8082                	ret
    panic("kfree");
    80000a3c:	00007517          	auipc	a0,0x7
    80000a40:	62450513          	addi	a0,a0,1572 # 80008060 <digits+0x20>
    80000a44:	00000097          	auipc	ra,0x0
    80000a48:	ae6080e7          	jalr	-1306(ra) # 8000052a <panic>

0000000080000a4c <freerange>:
{
    80000a4c:	7179                	addi	sp,sp,-48
    80000a4e:	f406                	sd	ra,40(sp)
    80000a50:	f022                	sd	s0,32(sp)
    80000a52:	ec26                	sd	s1,24(sp)
    80000a54:	e84a                	sd	s2,16(sp)
    80000a56:	e44e                	sd	s3,8(sp)
    80000a58:	e052                	sd	s4,0(sp)
    80000a5a:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a5c:	6785                	lui	a5,0x1
    80000a5e:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a62:	94aa                	add	s1,s1,a0
    80000a64:	757d                	lui	a0,0xfffff
    80000a66:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a68:	94be                	add	s1,s1,a5
    80000a6a:	0095ee63          	bltu	a1,s1,80000a86 <freerange+0x3a>
    80000a6e:	892e                	mv	s2,a1
    kfree(p);
    80000a70:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a72:	6985                	lui	s3,0x1
    kfree(p);
    80000a74:	01448533          	add	a0,s1,s4
    80000a78:	00000097          	auipc	ra,0x0
    80000a7c:	f5e080e7          	jalr	-162(ra) # 800009d6 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a80:	94ce                	add	s1,s1,s3
    80000a82:	fe9979e3          	bgeu	s2,s1,80000a74 <freerange+0x28>
}
    80000a86:	70a2                	ld	ra,40(sp)
    80000a88:	7402                	ld	s0,32(sp)
    80000a8a:	64e2                	ld	s1,24(sp)
    80000a8c:	6942                	ld	s2,16(sp)
    80000a8e:	69a2                	ld	s3,8(sp)
    80000a90:	6a02                	ld	s4,0(sp)
    80000a92:	6145                	addi	sp,sp,48
    80000a94:	8082                	ret

0000000080000a96 <kinit>:
{
    80000a96:	1141                	addi	sp,sp,-16
    80000a98:	e406                	sd	ra,8(sp)
    80000a9a:	e022                	sd	s0,0(sp)
    80000a9c:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000a9e:	00007597          	auipc	a1,0x7
    80000aa2:	5ca58593          	addi	a1,a1,1482 # 80008068 <digits+0x28>
    80000aa6:	00010517          	auipc	a0,0x10
    80000aaa:	7da50513          	addi	a0,a0,2010 # 80011280 <kmem>
    80000aae:	00000097          	auipc	ra,0x0
    80000ab2:	084080e7          	jalr	132(ra) # 80000b32 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ab6:	45c5                	li	a1,17
    80000ab8:	05ee                	slli	a1,a1,0x1b
    80000aba:	00025517          	auipc	a0,0x25
    80000abe:	54650513          	addi	a0,a0,1350 # 80026000 <end>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	f8a080e7          	jalr	-118(ra) # 80000a4c <freerange>
}
    80000aca:	60a2                	ld	ra,8(sp)
    80000acc:	6402                	ld	s0,0(sp)
    80000ace:	0141                	addi	sp,sp,16
    80000ad0:	8082                	ret

0000000080000ad2 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ad2:	1101                	addi	sp,sp,-32
    80000ad4:	ec06                	sd	ra,24(sp)
    80000ad6:	e822                	sd	s0,16(sp)
    80000ad8:	e426                	sd	s1,8(sp)
    80000ada:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000adc:	00010497          	auipc	s1,0x10
    80000ae0:	7a448493          	addi	s1,s1,1956 # 80011280 <kmem>
    80000ae4:	8526                	mv	a0,s1
    80000ae6:	00000097          	auipc	ra,0x0
    80000aea:	0dc080e7          	jalr	220(ra) # 80000bc2 <acquire>
  r = kmem.freelist;
    80000aee:	6c84                	ld	s1,24(s1)
  if(r)
    80000af0:	c885                	beqz	s1,80000b20 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000af2:	609c                	ld	a5,0(s1)
    80000af4:	00010517          	auipc	a0,0x10
    80000af8:	78c50513          	addi	a0,a0,1932 # 80011280 <kmem>
    80000afc:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000afe:	00000097          	auipc	ra,0x0
    80000b02:	178080e7          	jalr	376(ra) # 80000c76 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b06:	6605                	lui	a2,0x1
    80000b08:	4595                	li	a1,5
    80000b0a:	8526                	mv	a0,s1
    80000b0c:	00000097          	auipc	ra,0x0
    80000b10:	1b2080e7          	jalr	434(ra) # 80000cbe <memset>
  return (void*)r;
}
    80000b14:	8526                	mv	a0,s1
    80000b16:	60e2                	ld	ra,24(sp)
    80000b18:	6442                	ld	s0,16(sp)
    80000b1a:	64a2                	ld	s1,8(sp)
    80000b1c:	6105                	addi	sp,sp,32
    80000b1e:	8082                	ret
  release(&kmem.lock);
    80000b20:	00010517          	auipc	a0,0x10
    80000b24:	76050513          	addi	a0,a0,1888 # 80011280 <kmem>
    80000b28:	00000097          	auipc	ra,0x0
    80000b2c:	14e080e7          	jalr	334(ra) # 80000c76 <release>
  if(r)
    80000b30:	b7d5                	j	80000b14 <kalloc+0x42>

0000000080000b32 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b32:	1141                	addi	sp,sp,-16
    80000b34:	e422                	sd	s0,8(sp)
    80000b36:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b38:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b3a:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b3e:	00053823          	sd	zero,16(a0)
}
    80000b42:	6422                	ld	s0,8(sp)
    80000b44:	0141                	addi	sp,sp,16
    80000b46:	8082                	ret

0000000080000b48 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b48:	411c                	lw	a5,0(a0)
    80000b4a:	e399                	bnez	a5,80000b50 <holding+0x8>
    80000b4c:	4501                	li	a0,0
  return r;
}
    80000b4e:	8082                	ret
{
    80000b50:	1101                	addi	sp,sp,-32
    80000b52:	ec06                	sd	ra,24(sp)
    80000b54:	e822                	sd	s0,16(sp)
    80000b56:	e426                	sd	s1,8(sp)
    80000b58:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b5a:	6904                	ld	s1,16(a0)
    80000b5c:	00001097          	auipc	ra,0x1
    80000b60:	e48080e7          	jalr	-440(ra) # 800019a4 <mycpu>
    80000b64:	40a48533          	sub	a0,s1,a0
    80000b68:	00153513          	seqz	a0,a0
}
    80000b6c:	60e2                	ld	ra,24(sp)
    80000b6e:	6442                	ld	s0,16(sp)
    80000b70:	64a2                	ld	s1,8(sp)
    80000b72:	6105                	addi	sp,sp,32
    80000b74:	8082                	ret

0000000080000b76 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b76:	1101                	addi	sp,sp,-32
    80000b78:	ec06                	sd	ra,24(sp)
    80000b7a:	e822                	sd	s0,16(sp)
    80000b7c:	e426                	sd	s1,8(sp)
    80000b7e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b80:	100024f3          	csrr	s1,sstatus
    80000b84:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b88:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b8a:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000b8e:	00001097          	auipc	ra,0x1
    80000b92:	e16080e7          	jalr	-490(ra) # 800019a4 <mycpu>
    80000b96:	5d3c                	lw	a5,120(a0)
    80000b98:	cf89                	beqz	a5,80000bb2 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000b9a:	00001097          	auipc	ra,0x1
    80000b9e:	e0a080e7          	jalr	-502(ra) # 800019a4 <mycpu>
    80000ba2:	5d3c                	lw	a5,120(a0)
    80000ba4:	2785                	addiw	a5,a5,1
    80000ba6:	dd3c                	sw	a5,120(a0)
}
    80000ba8:	60e2                	ld	ra,24(sp)
    80000baa:	6442                	ld	s0,16(sp)
    80000bac:	64a2                	ld	s1,8(sp)
    80000bae:	6105                	addi	sp,sp,32
    80000bb0:	8082                	ret
    mycpu()->intena = old;
    80000bb2:	00001097          	auipc	ra,0x1
    80000bb6:	df2080e7          	jalr	-526(ra) # 800019a4 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bba:	8085                	srli	s1,s1,0x1
    80000bbc:	8885                	andi	s1,s1,1
    80000bbe:	dd64                	sw	s1,124(a0)
    80000bc0:	bfe9                	j	80000b9a <push_off+0x24>

0000000080000bc2 <acquire>:
{
    80000bc2:	1101                	addi	sp,sp,-32
    80000bc4:	ec06                	sd	ra,24(sp)
    80000bc6:	e822                	sd	s0,16(sp)
    80000bc8:	e426                	sd	s1,8(sp)
    80000bca:	1000                	addi	s0,sp,32
    80000bcc:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bce:	00000097          	auipc	ra,0x0
    80000bd2:	fa8080e7          	jalr	-88(ra) # 80000b76 <push_off>
  if(holding(lk))
    80000bd6:	8526                	mv	a0,s1
    80000bd8:	00000097          	auipc	ra,0x0
    80000bdc:	f70080e7          	jalr	-144(ra) # 80000b48 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000be0:	4705                	li	a4,1
  if(holding(lk))
    80000be2:	e115                	bnez	a0,80000c06 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000be4:	87ba                	mv	a5,a4
    80000be6:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bea:	2781                	sext.w	a5,a5
    80000bec:	ffe5                	bnez	a5,80000be4 <acquire+0x22>
  __sync_synchronize();
    80000bee:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000bf2:	00001097          	auipc	ra,0x1
    80000bf6:	db2080e7          	jalr	-590(ra) # 800019a4 <mycpu>
    80000bfa:	e888                	sd	a0,16(s1)
}
    80000bfc:	60e2                	ld	ra,24(sp)
    80000bfe:	6442                	ld	s0,16(sp)
    80000c00:	64a2                	ld	s1,8(sp)
    80000c02:	6105                	addi	sp,sp,32
    80000c04:	8082                	ret
    panic("acquire");
    80000c06:	00007517          	auipc	a0,0x7
    80000c0a:	46a50513          	addi	a0,a0,1130 # 80008070 <digits+0x30>
    80000c0e:	00000097          	auipc	ra,0x0
    80000c12:	91c080e7          	jalr	-1764(ra) # 8000052a <panic>

0000000080000c16 <pop_off>:

void
pop_off(void)
{
    80000c16:	1141                	addi	sp,sp,-16
    80000c18:	e406                	sd	ra,8(sp)
    80000c1a:	e022                	sd	s0,0(sp)
    80000c1c:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c1e:	00001097          	auipc	ra,0x1
    80000c22:	d86080e7          	jalr	-634(ra) # 800019a4 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c26:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c2a:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c2c:	e78d                	bnez	a5,80000c56 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c2e:	5d3c                	lw	a5,120(a0)
    80000c30:	02f05b63          	blez	a5,80000c66 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c34:	37fd                	addiw	a5,a5,-1
    80000c36:	0007871b          	sext.w	a4,a5
    80000c3a:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c3c:	eb09                	bnez	a4,80000c4e <pop_off+0x38>
    80000c3e:	5d7c                	lw	a5,124(a0)
    80000c40:	c799                	beqz	a5,80000c4e <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c42:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c46:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c4a:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c4e:	60a2                	ld	ra,8(sp)
    80000c50:	6402                	ld	s0,0(sp)
    80000c52:	0141                	addi	sp,sp,16
    80000c54:	8082                	ret
    panic("pop_off - interruptible");
    80000c56:	00007517          	auipc	a0,0x7
    80000c5a:	42250513          	addi	a0,a0,1058 # 80008078 <digits+0x38>
    80000c5e:	00000097          	auipc	ra,0x0
    80000c62:	8cc080e7          	jalr	-1844(ra) # 8000052a <panic>
    panic("pop_off");
    80000c66:	00007517          	auipc	a0,0x7
    80000c6a:	42a50513          	addi	a0,a0,1066 # 80008090 <digits+0x50>
    80000c6e:	00000097          	auipc	ra,0x0
    80000c72:	8bc080e7          	jalr	-1860(ra) # 8000052a <panic>

0000000080000c76 <release>:
{
    80000c76:	1101                	addi	sp,sp,-32
    80000c78:	ec06                	sd	ra,24(sp)
    80000c7a:	e822                	sd	s0,16(sp)
    80000c7c:	e426                	sd	s1,8(sp)
    80000c7e:	1000                	addi	s0,sp,32
    80000c80:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c82:	00000097          	auipc	ra,0x0
    80000c86:	ec6080e7          	jalr	-314(ra) # 80000b48 <holding>
    80000c8a:	c115                	beqz	a0,80000cae <release+0x38>
  lk->cpu = 0;
    80000c8c:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000c90:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000c94:	0f50000f          	fence	iorw,ow
    80000c98:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000c9c:	00000097          	auipc	ra,0x0
    80000ca0:	f7a080e7          	jalr	-134(ra) # 80000c16 <pop_off>
}
    80000ca4:	60e2                	ld	ra,24(sp)
    80000ca6:	6442                	ld	s0,16(sp)
    80000ca8:	64a2                	ld	s1,8(sp)
    80000caa:	6105                	addi	sp,sp,32
    80000cac:	8082                	ret
    panic("release");
    80000cae:	00007517          	auipc	a0,0x7
    80000cb2:	3ea50513          	addi	a0,a0,1002 # 80008098 <digits+0x58>
    80000cb6:	00000097          	auipc	ra,0x0
    80000cba:	874080e7          	jalr	-1932(ra) # 8000052a <panic>

0000000080000cbe <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cbe:	1141                	addi	sp,sp,-16
    80000cc0:	e422                	sd	s0,8(sp)
    80000cc2:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cc4:	ca19                	beqz	a2,80000cda <memset+0x1c>
    80000cc6:	87aa                	mv	a5,a0
    80000cc8:	1602                	slli	a2,a2,0x20
    80000cca:	9201                	srli	a2,a2,0x20
    80000ccc:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000cd0:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000cd4:	0785                	addi	a5,a5,1
    80000cd6:	fee79de3          	bne	a5,a4,80000cd0 <memset+0x12>
  }
  return dst;
}
    80000cda:	6422                	ld	s0,8(sp)
    80000cdc:	0141                	addi	sp,sp,16
    80000cde:	8082                	ret

0000000080000ce0 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000ce0:	1141                	addi	sp,sp,-16
    80000ce2:	e422                	sd	s0,8(sp)
    80000ce4:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000ce6:	ca05                	beqz	a2,80000d16 <memcmp+0x36>
    80000ce8:	fff6069b          	addiw	a3,a2,-1
    80000cec:	1682                	slli	a3,a3,0x20
    80000cee:	9281                	srli	a3,a3,0x20
    80000cf0:	0685                	addi	a3,a3,1
    80000cf2:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000cf4:	00054783          	lbu	a5,0(a0)
    80000cf8:	0005c703          	lbu	a4,0(a1)
    80000cfc:	00e79863          	bne	a5,a4,80000d0c <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d00:	0505                	addi	a0,a0,1
    80000d02:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d04:	fed518e3          	bne	a0,a3,80000cf4 <memcmp+0x14>
  }

  return 0;
    80000d08:	4501                	li	a0,0
    80000d0a:	a019                	j	80000d10 <memcmp+0x30>
      return *s1 - *s2;
    80000d0c:	40e7853b          	subw	a0,a5,a4
}
    80000d10:	6422                	ld	s0,8(sp)
    80000d12:	0141                	addi	sp,sp,16
    80000d14:	8082                	ret
  return 0;
    80000d16:	4501                	li	a0,0
    80000d18:	bfe5                	j	80000d10 <memcmp+0x30>

0000000080000d1a <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d1a:	1141                	addi	sp,sp,-16
    80000d1c:	e422                	sd	s0,8(sp)
    80000d1e:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d20:	02a5e563          	bltu	a1,a0,80000d4a <memmove+0x30>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d24:	fff6069b          	addiw	a3,a2,-1
    80000d28:	ce11                	beqz	a2,80000d44 <memmove+0x2a>
    80000d2a:	1682                	slli	a3,a3,0x20
    80000d2c:	9281                	srli	a3,a3,0x20
    80000d2e:	0685                	addi	a3,a3,1
    80000d30:	96ae                	add	a3,a3,a1
    80000d32:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000d34:	0585                	addi	a1,a1,1
    80000d36:	0785                	addi	a5,a5,1
    80000d38:	fff5c703          	lbu	a4,-1(a1)
    80000d3c:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000d40:	fed59ae3          	bne	a1,a3,80000d34 <memmove+0x1a>

  return dst;
}
    80000d44:	6422                	ld	s0,8(sp)
    80000d46:	0141                	addi	sp,sp,16
    80000d48:	8082                	ret
  if(s < d && s + n > d){
    80000d4a:	02061713          	slli	a4,a2,0x20
    80000d4e:	9301                	srli	a4,a4,0x20
    80000d50:	00e587b3          	add	a5,a1,a4
    80000d54:	fcf578e3          	bgeu	a0,a5,80000d24 <memmove+0xa>
    d += n;
    80000d58:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000d5a:	fff6069b          	addiw	a3,a2,-1
    80000d5e:	d27d                	beqz	a2,80000d44 <memmove+0x2a>
    80000d60:	02069613          	slli	a2,a3,0x20
    80000d64:	9201                	srli	a2,a2,0x20
    80000d66:	fff64613          	not	a2,a2
    80000d6a:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000d6c:	17fd                	addi	a5,a5,-1
    80000d6e:	177d                	addi	a4,a4,-1
    80000d70:	0007c683          	lbu	a3,0(a5)
    80000d74:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000d78:	fef61ae3          	bne	a2,a5,80000d6c <memmove+0x52>
    80000d7c:	b7e1                	j	80000d44 <memmove+0x2a>

0000000080000d7e <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d7e:	1141                	addi	sp,sp,-16
    80000d80:	e406                	sd	ra,8(sp)
    80000d82:	e022                	sd	s0,0(sp)
    80000d84:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d86:	00000097          	auipc	ra,0x0
    80000d8a:	f94080e7          	jalr	-108(ra) # 80000d1a <memmove>
}
    80000d8e:	60a2                	ld	ra,8(sp)
    80000d90:	6402                	ld	s0,0(sp)
    80000d92:	0141                	addi	sp,sp,16
    80000d94:	8082                	ret

0000000080000d96 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000d96:	1141                	addi	sp,sp,-16
    80000d98:	e422                	sd	s0,8(sp)
    80000d9a:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000d9c:	ce11                	beqz	a2,80000db8 <strncmp+0x22>
    80000d9e:	00054783          	lbu	a5,0(a0)
    80000da2:	cf89                	beqz	a5,80000dbc <strncmp+0x26>
    80000da4:	0005c703          	lbu	a4,0(a1)
    80000da8:	00f71a63          	bne	a4,a5,80000dbc <strncmp+0x26>
    n--, p++, q++;
    80000dac:	367d                	addiw	a2,a2,-1
    80000dae:	0505                	addi	a0,a0,1
    80000db0:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000db2:	f675                	bnez	a2,80000d9e <strncmp+0x8>
  if(n == 0)
    return 0;
    80000db4:	4501                	li	a0,0
    80000db6:	a809                	j	80000dc8 <strncmp+0x32>
    80000db8:	4501                	li	a0,0
    80000dba:	a039                	j	80000dc8 <strncmp+0x32>
  if(n == 0)
    80000dbc:	ca09                	beqz	a2,80000dce <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dbe:	00054503          	lbu	a0,0(a0)
    80000dc2:	0005c783          	lbu	a5,0(a1)
    80000dc6:	9d1d                	subw	a0,a0,a5
}
    80000dc8:	6422                	ld	s0,8(sp)
    80000dca:	0141                	addi	sp,sp,16
    80000dcc:	8082                	ret
    return 0;
    80000dce:	4501                	li	a0,0
    80000dd0:	bfe5                	j	80000dc8 <strncmp+0x32>

0000000080000dd2 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dd2:	1141                	addi	sp,sp,-16
    80000dd4:	e422                	sd	s0,8(sp)
    80000dd6:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000dd8:	872a                	mv	a4,a0
    80000dda:	8832                	mv	a6,a2
    80000ddc:	367d                	addiw	a2,a2,-1
    80000dde:	01005963          	blez	a6,80000df0 <strncpy+0x1e>
    80000de2:	0705                	addi	a4,a4,1
    80000de4:	0005c783          	lbu	a5,0(a1)
    80000de8:	fef70fa3          	sb	a5,-1(a4)
    80000dec:	0585                	addi	a1,a1,1
    80000dee:	f7f5                	bnez	a5,80000dda <strncpy+0x8>
    ;
  while(n-- > 0)
    80000df0:	86ba                	mv	a3,a4
    80000df2:	00c05c63          	blez	a2,80000e0a <strncpy+0x38>
    *s++ = 0;
    80000df6:	0685                	addi	a3,a3,1
    80000df8:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000dfc:	fff6c793          	not	a5,a3
    80000e00:	9fb9                	addw	a5,a5,a4
    80000e02:	010787bb          	addw	a5,a5,a6
    80000e06:	fef048e3          	bgtz	a5,80000df6 <strncpy+0x24>
  return os;
}
    80000e0a:	6422                	ld	s0,8(sp)
    80000e0c:	0141                	addi	sp,sp,16
    80000e0e:	8082                	ret

0000000080000e10 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e10:	1141                	addi	sp,sp,-16
    80000e12:	e422                	sd	s0,8(sp)
    80000e14:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e16:	02c05363          	blez	a2,80000e3c <safestrcpy+0x2c>
    80000e1a:	fff6069b          	addiw	a3,a2,-1
    80000e1e:	1682                	slli	a3,a3,0x20
    80000e20:	9281                	srli	a3,a3,0x20
    80000e22:	96ae                	add	a3,a3,a1
    80000e24:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e26:	00d58963          	beq	a1,a3,80000e38 <safestrcpy+0x28>
    80000e2a:	0585                	addi	a1,a1,1
    80000e2c:	0785                	addi	a5,a5,1
    80000e2e:	fff5c703          	lbu	a4,-1(a1)
    80000e32:	fee78fa3          	sb	a4,-1(a5)
    80000e36:	fb65                	bnez	a4,80000e26 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e38:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e3c:	6422                	ld	s0,8(sp)
    80000e3e:	0141                	addi	sp,sp,16
    80000e40:	8082                	ret

0000000080000e42 <strlen>:

int
strlen(const char *s)
{
    80000e42:	1141                	addi	sp,sp,-16
    80000e44:	e422                	sd	s0,8(sp)
    80000e46:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e48:	00054783          	lbu	a5,0(a0)
    80000e4c:	cf91                	beqz	a5,80000e68 <strlen+0x26>
    80000e4e:	0505                	addi	a0,a0,1
    80000e50:	87aa                	mv	a5,a0
    80000e52:	4685                	li	a3,1
    80000e54:	9e89                	subw	a3,a3,a0
    80000e56:	00f6853b          	addw	a0,a3,a5
    80000e5a:	0785                	addi	a5,a5,1
    80000e5c:	fff7c703          	lbu	a4,-1(a5)
    80000e60:	fb7d                	bnez	a4,80000e56 <strlen+0x14>
    ;
  return n;
}
    80000e62:	6422                	ld	s0,8(sp)
    80000e64:	0141                	addi	sp,sp,16
    80000e66:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e68:	4501                	li	a0,0
    80000e6a:	bfe5                	j	80000e62 <strlen+0x20>

0000000080000e6c <strcat>:

char* 
strcat(char* destination, const char* source)
{
    80000e6c:	1101                	addi	sp,sp,-32
    80000e6e:	ec06                	sd	ra,24(sp)
    80000e70:	e822                	sd	s0,16(sp)
    80000e72:	e426                	sd	s1,8(sp)
    80000e74:	e04a                	sd	s2,0(sp)
    80000e76:	1000                	addi	s0,sp,32
    80000e78:	892a                	mv	s2,a0
    80000e7a:	84ae                	mv	s1,a1
  char* ptr = destination + strlen(destination);
    80000e7c:	00000097          	auipc	ra,0x0
    80000e80:	fc6080e7          	jalr	-58(ra) # 80000e42 <strlen>
    80000e84:	00a907b3          	add	a5,s2,a0

  while (*source != '\0')
    80000e88:	0004c703          	lbu	a4,0(s1)
    80000e8c:	cb01                	beqz	a4,80000e9c <strcat+0x30>
    *ptr++ = *source++;
    80000e8e:	0485                	addi	s1,s1,1
    80000e90:	0785                	addi	a5,a5,1
    80000e92:	fee78fa3          	sb	a4,-1(a5)
  while (*source != '\0')
    80000e96:	0004c703          	lbu	a4,0(s1)
    80000e9a:	fb75                	bnez	a4,80000e8e <strcat+0x22>

  *ptr = '\0';
    80000e9c:	00078023          	sb	zero,0(a5)

  return destination;
}
    80000ea0:	854a                	mv	a0,s2
    80000ea2:	60e2                	ld	ra,24(sp)
    80000ea4:	6442                	ld	s0,16(sp)
    80000ea6:	64a2                	ld	s1,8(sp)
    80000ea8:	6902                	ld	s2,0(sp)
    80000eaa:	6105                	addi	sp,sp,32
    80000eac:	8082                	ret

0000000080000eae <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000eae:	1141                	addi	sp,sp,-16
    80000eb0:	e406                	sd	ra,8(sp)
    80000eb2:	e022                	sd	s0,0(sp)
    80000eb4:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000eb6:	00001097          	auipc	ra,0x1
    80000eba:	ade080e7          	jalr	-1314(ra) # 80001994 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000ebe:	00008717          	auipc	a4,0x8
    80000ec2:	15a70713          	addi	a4,a4,346 # 80009018 <started>
  if(cpuid() == 0){
    80000ec6:	c139                	beqz	a0,80000f0c <main+0x5e>
    while(started == 0)
    80000ec8:	431c                	lw	a5,0(a4)
    80000eca:	2781                	sext.w	a5,a5
    80000ecc:	dff5                	beqz	a5,80000ec8 <main+0x1a>
      ;
    __sync_synchronize();
    80000ece:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000ed2:	00001097          	auipc	ra,0x1
    80000ed6:	ac2080e7          	jalr	-1342(ra) # 80001994 <cpuid>
    80000eda:	85aa                	mv	a1,a0
    80000edc:	00007517          	auipc	a0,0x7
    80000ee0:	1dc50513          	addi	a0,a0,476 # 800080b8 <digits+0x78>
    80000ee4:	fffff097          	auipc	ra,0xfffff
    80000ee8:	690080e7          	jalr	1680(ra) # 80000574 <printf>
    kvminithart();    // turn on paging
    80000eec:	00000097          	auipc	ra,0x0
    80000ef0:	0d8080e7          	jalr	216(ra) # 80000fc4 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ef4:	00001097          	auipc	ra,0x1
    80000ef8:	720080e7          	jalr	1824(ra) # 80002614 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000efc:	00005097          	auipc	ra,0x5
    80000f00:	f84080e7          	jalr	-124(ra) # 80005e80 <plicinithart>
  }

  scheduler();        
    80000f04:	00001097          	auipc	ra,0x1
    80000f08:	fce080e7          	jalr	-50(ra) # 80001ed2 <scheduler>
    consoleinit();
    80000f0c:	fffff097          	auipc	ra,0xfffff
    80000f10:	530080e7          	jalr	1328(ra) # 8000043c <consoleinit>
    printfinit();
    80000f14:	00000097          	auipc	ra,0x0
    80000f18:	840080e7          	jalr	-1984(ra) # 80000754 <printfinit>
    printf("\n");
    80000f1c:	00007517          	auipc	a0,0x7
    80000f20:	1ac50513          	addi	a0,a0,428 # 800080c8 <digits+0x88>
    80000f24:	fffff097          	auipc	ra,0xfffff
    80000f28:	650080e7          	jalr	1616(ra) # 80000574 <printf>
    printf("xv6 kernel is booting\n");
    80000f2c:	00007517          	auipc	a0,0x7
    80000f30:	17450513          	addi	a0,a0,372 # 800080a0 <digits+0x60>
    80000f34:	fffff097          	auipc	ra,0xfffff
    80000f38:	640080e7          	jalr	1600(ra) # 80000574 <printf>
    printf("\n");
    80000f3c:	00007517          	auipc	a0,0x7
    80000f40:	18c50513          	addi	a0,a0,396 # 800080c8 <digits+0x88>
    80000f44:	fffff097          	auipc	ra,0xfffff
    80000f48:	630080e7          	jalr	1584(ra) # 80000574 <printf>
    kinit();         // physical page allocator
    80000f4c:	00000097          	auipc	ra,0x0
    80000f50:	b4a080e7          	jalr	-1206(ra) # 80000a96 <kinit>
    kvminit();       // create kernel page table
    80000f54:	00000097          	auipc	ra,0x0
    80000f58:	310080e7          	jalr	784(ra) # 80001264 <kvminit>
    kvminithart();   // turn on paging
    80000f5c:	00000097          	auipc	ra,0x0
    80000f60:	068080e7          	jalr	104(ra) # 80000fc4 <kvminithart>
    procinit();      // process table
    80000f64:	00001097          	auipc	ra,0x1
    80000f68:	980080e7          	jalr	-1664(ra) # 800018e4 <procinit>
    trapinit();      // trap vectors
    80000f6c:	00001097          	auipc	ra,0x1
    80000f70:	680080e7          	jalr	1664(ra) # 800025ec <trapinit>
    trapinithart();  // install kernel trap vector
    80000f74:	00001097          	auipc	ra,0x1
    80000f78:	6a0080e7          	jalr	1696(ra) # 80002614 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f7c:	00005097          	auipc	ra,0x5
    80000f80:	eee080e7          	jalr	-274(ra) # 80005e6a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	efc080e7          	jalr	-260(ra) # 80005e80 <plicinithart>
    binit();         // buffer cache
    80000f8c:	00002097          	auipc	ra,0x2
    80000f90:	dc8080e7          	jalr	-568(ra) # 80002d54 <binit>
    iinit();         // inode cache
    80000f94:	00002097          	auipc	ra,0x2
    80000f98:	524080e7          	jalr	1316(ra) # 800034b8 <iinit>
    fileinit();      // file table
    80000f9c:	00003097          	auipc	ra,0x3
    80000fa0:	62c080e7          	jalr	1580(ra) # 800045c8 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fa4:	00005097          	auipc	ra,0x5
    80000fa8:	ffe080e7          	jalr	-2(ra) # 80005fa2 <virtio_disk_init>
    userinit();      // first user process
    80000fac:	00001097          	auipc	ra,0x1
    80000fb0:	cec080e7          	jalr	-788(ra) # 80001c98 <userinit>
    __sync_synchronize();
    80000fb4:	0ff0000f          	fence
    started = 1;
    80000fb8:	4785                	li	a5,1
    80000fba:	00008717          	auipc	a4,0x8
    80000fbe:	04f72f23          	sw	a5,94(a4) # 80009018 <started>
    80000fc2:	b789                	j	80000f04 <main+0x56>

0000000080000fc4 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fc4:	1141                	addi	sp,sp,-16
    80000fc6:	e422                	sd	s0,8(sp)
    80000fc8:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000fca:	00008797          	auipc	a5,0x8
    80000fce:	0567b783          	ld	a5,86(a5) # 80009020 <kernel_pagetable>
    80000fd2:	83b1                	srli	a5,a5,0xc
    80000fd4:	577d                	li	a4,-1
    80000fd6:	177e                	slli	a4,a4,0x3f
    80000fd8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fda:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fde:	12000073          	sfence.vma
  sfence_vma();
}
    80000fe2:	6422                	ld	s0,8(sp)
    80000fe4:	0141                	addi	sp,sp,16
    80000fe6:	8082                	ret

0000000080000fe8 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fe8:	7139                	addi	sp,sp,-64
    80000fea:	fc06                	sd	ra,56(sp)
    80000fec:	f822                	sd	s0,48(sp)
    80000fee:	f426                	sd	s1,40(sp)
    80000ff0:	f04a                	sd	s2,32(sp)
    80000ff2:	ec4e                	sd	s3,24(sp)
    80000ff4:	e852                	sd	s4,16(sp)
    80000ff6:	e456                	sd	s5,8(sp)
    80000ff8:	e05a                	sd	s6,0(sp)
    80000ffa:	0080                	addi	s0,sp,64
    80000ffc:	84aa                	mv	s1,a0
    80000ffe:	89ae                	mv	s3,a1
    80001000:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001002:	57fd                	li	a5,-1
    80001004:	83e9                	srli	a5,a5,0x1a
    80001006:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001008:	4b31                	li	s6,12
  if(va >= MAXVA)
    8000100a:	04b7f263          	bgeu	a5,a1,8000104e <walk+0x66>
    panic("walk");
    8000100e:	00007517          	auipc	a0,0x7
    80001012:	0c250513          	addi	a0,a0,194 # 800080d0 <digits+0x90>
    80001016:	fffff097          	auipc	ra,0xfffff
    8000101a:	514080e7          	jalr	1300(ra) # 8000052a <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    8000101e:	060a8663          	beqz	s5,8000108a <walk+0xa2>
    80001022:	00000097          	auipc	ra,0x0
    80001026:	ab0080e7          	jalr	-1360(ra) # 80000ad2 <kalloc>
    8000102a:	84aa                	mv	s1,a0
    8000102c:	c529                	beqz	a0,80001076 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000102e:	6605                	lui	a2,0x1
    80001030:	4581                	li	a1,0
    80001032:	00000097          	auipc	ra,0x0
    80001036:	c8c080e7          	jalr	-884(ra) # 80000cbe <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000103a:	00c4d793          	srli	a5,s1,0xc
    8000103e:	07aa                	slli	a5,a5,0xa
    80001040:	0017e793          	ori	a5,a5,1
    80001044:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001048:	3a5d                	addiw	s4,s4,-9
    8000104a:	036a0063          	beq	s4,s6,8000106a <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000104e:	0149d933          	srl	s2,s3,s4
    80001052:	1ff97913          	andi	s2,s2,511
    80001056:	090e                	slli	s2,s2,0x3
    80001058:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000105a:	00093483          	ld	s1,0(s2)
    8000105e:	0014f793          	andi	a5,s1,1
    80001062:	dfd5                	beqz	a5,8000101e <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001064:	80a9                	srli	s1,s1,0xa
    80001066:	04b2                	slli	s1,s1,0xc
    80001068:	b7c5                	j	80001048 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000106a:	00c9d513          	srli	a0,s3,0xc
    8000106e:	1ff57513          	andi	a0,a0,511
    80001072:	050e                	slli	a0,a0,0x3
    80001074:	9526                	add	a0,a0,s1
}
    80001076:	70e2                	ld	ra,56(sp)
    80001078:	7442                	ld	s0,48(sp)
    8000107a:	74a2                	ld	s1,40(sp)
    8000107c:	7902                	ld	s2,32(sp)
    8000107e:	69e2                	ld	s3,24(sp)
    80001080:	6a42                	ld	s4,16(sp)
    80001082:	6aa2                	ld	s5,8(sp)
    80001084:	6b02                	ld	s6,0(sp)
    80001086:	6121                	addi	sp,sp,64
    80001088:	8082                	ret
        return 0;
    8000108a:	4501                	li	a0,0
    8000108c:	b7ed                	j	80001076 <walk+0x8e>

000000008000108e <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000108e:	57fd                	li	a5,-1
    80001090:	83e9                	srli	a5,a5,0x1a
    80001092:	00b7f463          	bgeu	a5,a1,8000109a <walkaddr+0xc>
    return 0;
    80001096:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001098:	8082                	ret
{
    8000109a:	1141                	addi	sp,sp,-16
    8000109c:	e406                	sd	ra,8(sp)
    8000109e:	e022                	sd	s0,0(sp)
    800010a0:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800010a2:	4601                	li	a2,0
    800010a4:	00000097          	auipc	ra,0x0
    800010a8:	f44080e7          	jalr	-188(ra) # 80000fe8 <walk>
  if(pte == 0)
    800010ac:	c105                	beqz	a0,800010cc <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    800010ae:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800010b0:	0117f693          	andi	a3,a5,17
    800010b4:	4745                	li	a4,17
    return 0;
    800010b6:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010b8:	00e68663          	beq	a3,a4,800010c4 <walkaddr+0x36>
}
    800010bc:	60a2                	ld	ra,8(sp)
    800010be:	6402                	ld	s0,0(sp)
    800010c0:	0141                	addi	sp,sp,16
    800010c2:	8082                	ret
  pa = PTE2PA(*pte);
    800010c4:	00a7d513          	srli	a0,a5,0xa
    800010c8:	0532                	slli	a0,a0,0xc
  return pa;
    800010ca:	bfcd                	j	800010bc <walkaddr+0x2e>
    return 0;
    800010cc:	4501                	li	a0,0
    800010ce:	b7fd                	j	800010bc <walkaddr+0x2e>

00000000800010d0 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010d0:	715d                	addi	sp,sp,-80
    800010d2:	e486                	sd	ra,72(sp)
    800010d4:	e0a2                	sd	s0,64(sp)
    800010d6:	fc26                	sd	s1,56(sp)
    800010d8:	f84a                	sd	s2,48(sp)
    800010da:	f44e                	sd	s3,40(sp)
    800010dc:	f052                	sd	s4,32(sp)
    800010de:	ec56                	sd	s5,24(sp)
    800010e0:	e85a                	sd	s6,16(sp)
    800010e2:	e45e                	sd	s7,8(sp)
    800010e4:	0880                	addi	s0,sp,80
    800010e6:	8aaa                	mv	s5,a0
    800010e8:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    800010ea:	777d                	lui	a4,0xfffff
    800010ec:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800010f0:	167d                	addi	a2,a2,-1
    800010f2:	00b609b3          	add	s3,a2,a1
    800010f6:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800010fa:	893e                	mv	s2,a5
    800010fc:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80001100:	6b85                	lui	s7,0x1
    80001102:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001106:	4605                	li	a2,1
    80001108:	85ca                	mv	a1,s2
    8000110a:	8556                	mv	a0,s5
    8000110c:	00000097          	auipc	ra,0x0
    80001110:	edc080e7          	jalr	-292(ra) # 80000fe8 <walk>
    80001114:	c51d                	beqz	a0,80001142 <mappages+0x72>
    if(*pte & PTE_V)
    80001116:	611c                	ld	a5,0(a0)
    80001118:	8b85                	andi	a5,a5,1
    8000111a:	ef81                	bnez	a5,80001132 <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    8000111c:	80b1                	srli	s1,s1,0xc
    8000111e:	04aa                	slli	s1,s1,0xa
    80001120:	0164e4b3          	or	s1,s1,s6
    80001124:	0014e493          	ori	s1,s1,1
    80001128:	e104                	sd	s1,0(a0)
    if(a == last)
    8000112a:	03390863          	beq	s2,s3,8000115a <mappages+0x8a>
    a += PGSIZE;
    8000112e:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001130:	bfc9                	j	80001102 <mappages+0x32>
      panic("remap");
    80001132:	00007517          	auipc	a0,0x7
    80001136:	fa650513          	addi	a0,a0,-90 # 800080d8 <digits+0x98>
    8000113a:	fffff097          	auipc	ra,0xfffff
    8000113e:	3f0080e7          	jalr	1008(ra) # 8000052a <panic>
      return -1;
    80001142:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001144:	60a6                	ld	ra,72(sp)
    80001146:	6406                	ld	s0,64(sp)
    80001148:	74e2                	ld	s1,56(sp)
    8000114a:	7942                	ld	s2,48(sp)
    8000114c:	79a2                	ld	s3,40(sp)
    8000114e:	7a02                	ld	s4,32(sp)
    80001150:	6ae2                	ld	s5,24(sp)
    80001152:	6b42                	ld	s6,16(sp)
    80001154:	6ba2                	ld	s7,8(sp)
    80001156:	6161                	addi	sp,sp,80
    80001158:	8082                	ret
  return 0;
    8000115a:	4501                	li	a0,0
    8000115c:	b7e5                	j	80001144 <mappages+0x74>

000000008000115e <kvmmap>:
{
    8000115e:	1141                	addi	sp,sp,-16
    80001160:	e406                	sd	ra,8(sp)
    80001162:	e022                	sd	s0,0(sp)
    80001164:	0800                	addi	s0,sp,16
    80001166:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001168:	86b2                	mv	a3,a2
    8000116a:	863e                	mv	a2,a5
    8000116c:	00000097          	auipc	ra,0x0
    80001170:	f64080e7          	jalr	-156(ra) # 800010d0 <mappages>
    80001174:	e509                	bnez	a0,8000117e <kvmmap+0x20>
}
    80001176:	60a2                	ld	ra,8(sp)
    80001178:	6402                	ld	s0,0(sp)
    8000117a:	0141                	addi	sp,sp,16
    8000117c:	8082                	ret
    panic("kvmmap");
    8000117e:	00007517          	auipc	a0,0x7
    80001182:	f6250513          	addi	a0,a0,-158 # 800080e0 <digits+0xa0>
    80001186:	fffff097          	auipc	ra,0xfffff
    8000118a:	3a4080e7          	jalr	932(ra) # 8000052a <panic>

000000008000118e <kvmmake>:
{
    8000118e:	1101                	addi	sp,sp,-32
    80001190:	ec06                	sd	ra,24(sp)
    80001192:	e822                	sd	s0,16(sp)
    80001194:	e426                	sd	s1,8(sp)
    80001196:	e04a                	sd	s2,0(sp)
    80001198:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000119a:	00000097          	auipc	ra,0x0
    8000119e:	938080e7          	jalr	-1736(ra) # 80000ad2 <kalloc>
    800011a2:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800011a4:	6605                	lui	a2,0x1
    800011a6:	4581                	li	a1,0
    800011a8:	00000097          	auipc	ra,0x0
    800011ac:	b16080e7          	jalr	-1258(ra) # 80000cbe <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011b0:	4719                	li	a4,6
    800011b2:	6685                	lui	a3,0x1
    800011b4:	10000637          	lui	a2,0x10000
    800011b8:	100005b7          	lui	a1,0x10000
    800011bc:	8526                	mv	a0,s1
    800011be:	00000097          	auipc	ra,0x0
    800011c2:	fa0080e7          	jalr	-96(ra) # 8000115e <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011c6:	4719                	li	a4,6
    800011c8:	6685                	lui	a3,0x1
    800011ca:	10001637          	lui	a2,0x10001
    800011ce:	100015b7          	lui	a1,0x10001
    800011d2:	8526                	mv	a0,s1
    800011d4:	00000097          	auipc	ra,0x0
    800011d8:	f8a080e7          	jalr	-118(ra) # 8000115e <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011dc:	4719                	li	a4,6
    800011de:	004006b7          	lui	a3,0x400
    800011e2:	0c000637          	lui	a2,0xc000
    800011e6:	0c0005b7          	lui	a1,0xc000
    800011ea:	8526                	mv	a0,s1
    800011ec:	00000097          	auipc	ra,0x0
    800011f0:	f72080e7          	jalr	-142(ra) # 8000115e <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011f4:	00007917          	auipc	s2,0x7
    800011f8:	e0c90913          	addi	s2,s2,-500 # 80008000 <etext>
    800011fc:	4729                	li	a4,10
    800011fe:	80007697          	auipc	a3,0x80007
    80001202:	e0268693          	addi	a3,a3,-510 # 8000 <_entry-0x7fff8000>
    80001206:	4605                	li	a2,1
    80001208:	067e                	slli	a2,a2,0x1f
    8000120a:	85b2                	mv	a1,a2
    8000120c:	8526                	mv	a0,s1
    8000120e:	00000097          	auipc	ra,0x0
    80001212:	f50080e7          	jalr	-176(ra) # 8000115e <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001216:	4719                	li	a4,6
    80001218:	46c5                	li	a3,17
    8000121a:	06ee                	slli	a3,a3,0x1b
    8000121c:	412686b3          	sub	a3,a3,s2
    80001220:	864a                	mv	a2,s2
    80001222:	85ca                	mv	a1,s2
    80001224:	8526                	mv	a0,s1
    80001226:	00000097          	auipc	ra,0x0
    8000122a:	f38080e7          	jalr	-200(ra) # 8000115e <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000122e:	4729                	li	a4,10
    80001230:	6685                	lui	a3,0x1
    80001232:	00006617          	auipc	a2,0x6
    80001236:	dce60613          	addi	a2,a2,-562 # 80007000 <_trampoline>
    8000123a:	040005b7          	lui	a1,0x4000
    8000123e:	15fd                	addi	a1,a1,-1
    80001240:	05b2                	slli	a1,a1,0xc
    80001242:	8526                	mv	a0,s1
    80001244:	00000097          	auipc	ra,0x0
    80001248:	f1a080e7          	jalr	-230(ra) # 8000115e <kvmmap>
  proc_mapstacks(kpgtbl);
    8000124c:	8526                	mv	a0,s1
    8000124e:	00000097          	auipc	ra,0x0
    80001252:	600080e7          	jalr	1536(ra) # 8000184e <proc_mapstacks>
}
    80001256:	8526                	mv	a0,s1
    80001258:	60e2                	ld	ra,24(sp)
    8000125a:	6442                	ld	s0,16(sp)
    8000125c:	64a2                	ld	s1,8(sp)
    8000125e:	6902                	ld	s2,0(sp)
    80001260:	6105                	addi	sp,sp,32
    80001262:	8082                	ret

0000000080001264 <kvminit>:
{
    80001264:	1141                	addi	sp,sp,-16
    80001266:	e406                	sd	ra,8(sp)
    80001268:	e022                	sd	s0,0(sp)
    8000126a:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000126c:	00000097          	auipc	ra,0x0
    80001270:	f22080e7          	jalr	-222(ra) # 8000118e <kvmmake>
    80001274:	00008797          	auipc	a5,0x8
    80001278:	daa7b623          	sd	a0,-596(a5) # 80009020 <kernel_pagetable>
}
    8000127c:	60a2                	ld	ra,8(sp)
    8000127e:	6402                	ld	s0,0(sp)
    80001280:	0141                	addi	sp,sp,16
    80001282:	8082                	ret

0000000080001284 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001284:	715d                	addi	sp,sp,-80
    80001286:	e486                	sd	ra,72(sp)
    80001288:	e0a2                	sd	s0,64(sp)
    8000128a:	fc26                	sd	s1,56(sp)
    8000128c:	f84a                	sd	s2,48(sp)
    8000128e:	f44e                	sd	s3,40(sp)
    80001290:	f052                	sd	s4,32(sp)
    80001292:	ec56                	sd	s5,24(sp)
    80001294:	e85a                	sd	s6,16(sp)
    80001296:	e45e                	sd	s7,8(sp)
    80001298:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000129a:	03459793          	slli	a5,a1,0x34
    8000129e:	e795                	bnez	a5,800012ca <uvmunmap+0x46>
    800012a0:	8a2a                	mv	s4,a0
    800012a2:	892e                	mv	s2,a1
    800012a4:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012a6:	0632                	slli	a2,a2,0xc
    800012a8:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800012ac:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012ae:	6b05                	lui	s6,0x1
    800012b0:	0735e263          	bltu	a1,s3,80001314 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012b4:	60a6                	ld	ra,72(sp)
    800012b6:	6406                	ld	s0,64(sp)
    800012b8:	74e2                	ld	s1,56(sp)
    800012ba:	7942                	ld	s2,48(sp)
    800012bc:	79a2                	ld	s3,40(sp)
    800012be:	7a02                	ld	s4,32(sp)
    800012c0:	6ae2                	ld	s5,24(sp)
    800012c2:	6b42                	ld	s6,16(sp)
    800012c4:	6ba2                	ld	s7,8(sp)
    800012c6:	6161                	addi	sp,sp,80
    800012c8:	8082                	ret
    panic("uvmunmap: not aligned");
    800012ca:	00007517          	auipc	a0,0x7
    800012ce:	e1e50513          	addi	a0,a0,-482 # 800080e8 <digits+0xa8>
    800012d2:	fffff097          	auipc	ra,0xfffff
    800012d6:	258080e7          	jalr	600(ra) # 8000052a <panic>
      panic("uvmunmap: walk");
    800012da:	00007517          	auipc	a0,0x7
    800012de:	e2650513          	addi	a0,a0,-474 # 80008100 <digits+0xc0>
    800012e2:	fffff097          	auipc	ra,0xfffff
    800012e6:	248080e7          	jalr	584(ra) # 8000052a <panic>
      panic("uvmunmap: not mapped");
    800012ea:	00007517          	auipc	a0,0x7
    800012ee:	e2650513          	addi	a0,a0,-474 # 80008110 <digits+0xd0>
    800012f2:	fffff097          	auipc	ra,0xfffff
    800012f6:	238080e7          	jalr	568(ra) # 8000052a <panic>
      panic("uvmunmap: not a leaf");
    800012fa:	00007517          	auipc	a0,0x7
    800012fe:	e2e50513          	addi	a0,a0,-466 # 80008128 <digits+0xe8>
    80001302:	fffff097          	auipc	ra,0xfffff
    80001306:	228080e7          	jalr	552(ra) # 8000052a <panic>
    *pte = 0;
    8000130a:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000130e:	995a                	add	s2,s2,s6
    80001310:	fb3972e3          	bgeu	s2,s3,800012b4 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001314:	4601                	li	a2,0
    80001316:	85ca                	mv	a1,s2
    80001318:	8552                	mv	a0,s4
    8000131a:	00000097          	auipc	ra,0x0
    8000131e:	cce080e7          	jalr	-818(ra) # 80000fe8 <walk>
    80001322:	84aa                	mv	s1,a0
    80001324:	d95d                	beqz	a0,800012da <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001326:	6108                	ld	a0,0(a0)
    80001328:	00157793          	andi	a5,a0,1
    8000132c:	dfdd                	beqz	a5,800012ea <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000132e:	3ff57793          	andi	a5,a0,1023
    80001332:	fd7784e3          	beq	a5,s7,800012fa <uvmunmap+0x76>
    if(do_free){
    80001336:	fc0a8ae3          	beqz	s5,8000130a <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    8000133a:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    8000133c:	0532                	slli	a0,a0,0xc
    8000133e:	fffff097          	auipc	ra,0xfffff
    80001342:	698080e7          	jalr	1688(ra) # 800009d6 <kfree>
    80001346:	b7d1                	j	8000130a <uvmunmap+0x86>

0000000080001348 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001348:	1101                	addi	sp,sp,-32
    8000134a:	ec06                	sd	ra,24(sp)
    8000134c:	e822                	sd	s0,16(sp)
    8000134e:	e426                	sd	s1,8(sp)
    80001350:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001352:	fffff097          	auipc	ra,0xfffff
    80001356:	780080e7          	jalr	1920(ra) # 80000ad2 <kalloc>
    8000135a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000135c:	c519                	beqz	a0,8000136a <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000135e:	6605                	lui	a2,0x1
    80001360:	4581                	li	a1,0
    80001362:	00000097          	auipc	ra,0x0
    80001366:	95c080e7          	jalr	-1700(ra) # 80000cbe <memset>
  return pagetable;
}
    8000136a:	8526                	mv	a0,s1
    8000136c:	60e2                	ld	ra,24(sp)
    8000136e:	6442                	ld	s0,16(sp)
    80001370:	64a2                	ld	s1,8(sp)
    80001372:	6105                	addi	sp,sp,32
    80001374:	8082                	ret

0000000080001376 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001376:	7179                	addi	sp,sp,-48
    80001378:	f406                	sd	ra,40(sp)
    8000137a:	f022                	sd	s0,32(sp)
    8000137c:	ec26                	sd	s1,24(sp)
    8000137e:	e84a                	sd	s2,16(sp)
    80001380:	e44e                	sd	s3,8(sp)
    80001382:	e052                	sd	s4,0(sp)
    80001384:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001386:	6785                	lui	a5,0x1
    80001388:	04f67863          	bgeu	a2,a5,800013d8 <uvminit+0x62>
    8000138c:	8a2a                	mv	s4,a0
    8000138e:	89ae                	mv	s3,a1
    80001390:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001392:	fffff097          	auipc	ra,0xfffff
    80001396:	740080e7          	jalr	1856(ra) # 80000ad2 <kalloc>
    8000139a:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000139c:	6605                	lui	a2,0x1
    8000139e:	4581                	li	a1,0
    800013a0:	00000097          	auipc	ra,0x0
    800013a4:	91e080e7          	jalr	-1762(ra) # 80000cbe <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800013a8:	4779                	li	a4,30
    800013aa:	86ca                	mv	a3,s2
    800013ac:	6605                	lui	a2,0x1
    800013ae:	4581                	li	a1,0
    800013b0:	8552                	mv	a0,s4
    800013b2:	00000097          	auipc	ra,0x0
    800013b6:	d1e080e7          	jalr	-738(ra) # 800010d0 <mappages>
  memmove(mem, src, sz);
    800013ba:	8626                	mv	a2,s1
    800013bc:	85ce                	mv	a1,s3
    800013be:	854a                	mv	a0,s2
    800013c0:	00000097          	auipc	ra,0x0
    800013c4:	95a080e7          	jalr	-1702(ra) # 80000d1a <memmove>
}
    800013c8:	70a2                	ld	ra,40(sp)
    800013ca:	7402                	ld	s0,32(sp)
    800013cc:	64e2                	ld	s1,24(sp)
    800013ce:	6942                	ld	s2,16(sp)
    800013d0:	69a2                	ld	s3,8(sp)
    800013d2:	6a02                	ld	s4,0(sp)
    800013d4:	6145                	addi	sp,sp,48
    800013d6:	8082                	ret
    panic("inituvm: more than a page");
    800013d8:	00007517          	auipc	a0,0x7
    800013dc:	d6850513          	addi	a0,a0,-664 # 80008140 <digits+0x100>
    800013e0:	fffff097          	auipc	ra,0xfffff
    800013e4:	14a080e7          	jalr	330(ra) # 8000052a <panic>

00000000800013e8 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013e8:	1101                	addi	sp,sp,-32
    800013ea:	ec06                	sd	ra,24(sp)
    800013ec:	e822                	sd	s0,16(sp)
    800013ee:	e426                	sd	s1,8(sp)
    800013f0:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013f2:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013f4:	00b67d63          	bgeu	a2,a1,8000140e <uvmdealloc+0x26>
    800013f8:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013fa:	6785                	lui	a5,0x1
    800013fc:	17fd                	addi	a5,a5,-1
    800013fe:	00f60733          	add	a4,a2,a5
    80001402:	767d                	lui	a2,0xfffff
    80001404:	8f71                	and	a4,a4,a2
    80001406:	97ae                	add	a5,a5,a1
    80001408:	8ff1                	and	a5,a5,a2
    8000140a:	00f76863          	bltu	a4,a5,8000141a <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    8000140e:	8526                	mv	a0,s1
    80001410:	60e2                	ld	ra,24(sp)
    80001412:	6442                	ld	s0,16(sp)
    80001414:	64a2                	ld	s1,8(sp)
    80001416:	6105                	addi	sp,sp,32
    80001418:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000141a:	8f99                	sub	a5,a5,a4
    8000141c:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    8000141e:	4685                	li	a3,1
    80001420:	0007861b          	sext.w	a2,a5
    80001424:	85ba                	mv	a1,a4
    80001426:	00000097          	auipc	ra,0x0
    8000142a:	e5e080e7          	jalr	-418(ra) # 80001284 <uvmunmap>
    8000142e:	b7c5                	j	8000140e <uvmdealloc+0x26>

0000000080001430 <uvmalloc>:
  if(newsz < oldsz)
    80001430:	0ab66163          	bltu	a2,a1,800014d2 <uvmalloc+0xa2>
{
    80001434:	7139                	addi	sp,sp,-64
    80001436:	fc06                	sd	ra,56(sp)
    80001438:	f822                	sd	s0,48(sp)
    8000143a:	f426                	sd	s1,40(sp)
    8000143c:	f04a                	sd	s2,32(sp)
    8000143e:	ec4e                	sd	s3,24(sp)
    80001440:	e852                	sd	s4,16(sp)
    80001442:	e456                	sd	s5,8(sp)
    80001444:	0080                	addi	s0,sp,64
    80001446:	8aaa                	mv	s5,a0
    80001448:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000144a:	6985                	lui	s3,0x1
    8000144c:	19fd                	addi	s3,s3,-1
    8000144e:	95ce                	add	a1,a1,s3
    80001450:	79fd                	lui	s3,0xfffff
    80001452:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001456:	08c9f063          	bgeu	s3,a2,800014d6 <uvmalloc+0xa6>
    8000145a:	894e                	mv	s2,s3
    mem = kalloc();
    8000145c:	fffff097          	auipc	ra,0xfffff
    80001460:	676080e7          	jalr	1654(ra) # 80000ad2 <kalloc>
    80001464:	84aa                	mv	s1,a0
    if(mem == 0){
    80001466:	c51d                	beqz	a0,80001494 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    80001468:	6605                	lui	a2,0x1
    8000146a:	4581                	li	a1,0
    8000146c:	00000097          	auipc	ra,0x0
    80001470:	852080e7          	jalr	-1966(ra) # 80000cbe <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001474:	4779                	li	a4,30
    80001476:	86a6                	mv	a3,s1
    80001478:	6605                	lui	a2,0x1
    8000147a:	85ca                	mv	a1,s2
    8000147c:	8556                	mv	a0,s5
    8000147e:	00000097          	auipc	ra,0x0
    80001482:	c52080e7          	jalr	-942(ra) # 800010d0 <mappages>
    80001486:	e905                	bnez	a0,800014b6 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001488:	6785                	lui	a5,0x1
    8000148a:	993e                	add	s2,s2,a5
    8000148c:	fd4968e3          	bltu	s2,s4,8000145c <uvmalloc+0x2c>
  return newsz;
    80001490:	8552                	mv	a0,s4
    80001492:	a809                	j	800014a4 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001494:	864e                	mv	a2,s3
    80001496:	85ca                	mv	a1,s2
    80001498:	8556                	mv	a0,s5
    8000149a:	00000097          	auipc	ra,0x0
    8000149e:	f4e080e7          	jalr	-178(ra) # 800013e8 <uvmdealloc>
      return 0;
    800014a2:	4501                	li	a0,0
}
    800014a4:	70e2                	ld	ra,56(sp)
    800014a6:	7442                	ld	s0,48(sp)
    800014a8:	74a2                	ld	s1,40(sp)
    800014aa:	7902                	ld	s2,32(sp)
    800014ac:	69e2                	ld	s3,24(sp)
    800014ae:	6a42                	ld	s4,16(sp)
    800014b0:	6aa2                	ld	s5,8(sp)
    800014b2:	6121                	addi	sp,sp,64
    800014b4:	8082                	ret
      kfree(mem);
    800014b6:	8526                	mv	a0,s1
    800014b8:	fffff097          	auipc	ra,0xfffff
    800014bc:	51e080e7          	jalr	1310(ra) # 800009d6 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014c0:	864e                	mv	a2,s3
    800014c2:	85ca                	mv	a1,s2
    800014c4:	8556                	mv	a0,s5
    800014c6:	00000097          	auipc	ra,0x0
    800014ca:	f22080e7          	jalr	-222(ra) # 800013e8 <uvmdealloc>
      return 0;
    800014ce:	4501                	li	a0,0
    800014d0:	bfd1                	j	800014a4 <uvmalloc+0x74>
    return oldsz;
    800014d2:	852e                	mv	a0,a1
}
    800014d4:	8082                	ret
  return newsz;
    800014d6:	8532                	mv	a0,a2
    800014d8:	b7f1                	j	800014a4 <uvmalloc+0x74>

00000000800014da <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014da:	7179                	addi	sp,sp,-48
    800014dc:	f406                	sd	ra,40(sp)
    800014de:	f022                	sd	s0,32(sp)
    800014e0:	ec26                	sd	s1,24(sp)
    800014e2:	e84a                	sd	s2,16(sp)
    800014e4:	e44e                	sd	s3,8(sp)
    800014e6:	e052                	sd	s4,0(sp)
    800014e8:	1800                	addi	s0,sp,48
    800014ea:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014ec:	84aa                	mv	s1,a0
    800014ee:	6905                	lui	s2,0x1
    800014f0:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014f2:	4985                	li	s3,1
    800014f4:	a821                	j	8000150c <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014f6:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014f8:	0532                	slli	a0,a0,0xc
    800014fa:	00000097          	auipc	ra,0x0
    800014fe:	fe0080e7          	jalr	-32(ra) # 800014da <freewalk>
      pagetable[i] = 0;
    80001502:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001506:	04a1                	addi	s1,s1,8
    80001508:	03248163          	beq	s1,s2,8000152a <freewalk+0x50>
    pte_t pte = pagetable[i];
    8000150c:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000150e:	00f57793          	andi	a5,a0,15
    80001512:	ff3782e3          	beq	a5,s3,800014f6 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001516:	8905                	andi	a0,a0,1
    80001518:	d57d                	beqz	a0,80001506 <freewalk+0x2c>
      panic("freewalk: leaf");
    8000151a:	00007517          	auipc	a0,0x7
    8000151e:	c4650513          	addi	a0,a0,-954 # 80008160 <digits+0x120>
    80001522:	fffff097          	auipc	ra,0xfffff
    80001526:	008080e7          	jalr	8(ra) # 8000052a <panic>
    }
  }
  kfree((void*)pagetable);
    8000152a:	8552                	mv	a0,s4
    8000152c:	fffff097          	auipc	ra,0xfffff
    80001530:	4aa080e7          	jalr	1194(ra) # 800009d6 <kfree>
}
    80001534:	70a2                	ld	ra,40(sp)
    80001536:	7402                	ld	s0,32(sp)
    80001538:	64e2                	ld	s1,24(sp)
    8000153a:	6942                	ld	s2,16(sp)
    8000153c:	69a2                	ld	s3,8(sp)
    8000153e:	6a02                	ld	s4,0(sp)
    80001540:	6145                	addi	sp,sp,48
    80001542:	8082                	ret

0000000080001544 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001544:	1101                	addi	sp,sp,-32
    80001546:	ec06                	sd	ra,24(sp)
    80001548:	e822                	sd	s0,16(sp)
    8000154a:	e426                	sd	s1,8(sp)
    8000154c:	1000                	addi	s0,sp,32
    8000154e:	84aa                	mv	s1,a0
  if(sz > 0)
    80001550:	e999                	bnez	a1,80001566 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001552:	8526                	mv	a0,s1
    80001554:	00000097          	auipc	ra,0x0
    80001558:	f86080e7          	jalr	-122(ra) # 800014da <freewalk>
}
    8000155c:	60e2                	ld	ra,24(sp)
    8000155e:	6442                	ld	s0,16(sp)
    80001560:	64a2                	ld	s1,8(sp)
    80001562:	6105                	addi	sp,sp,32
    80001564:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001566:	6605                	lui	a2,0x1
    80001568:	167d                	addi	a2,a2,-1
    8000156a:	962e                	add	a2,a2,a1
    8000156c:	4685                	li	a3,1
    8000156e:	8231                	srli	a2,a2,0xc
    80001570:	4581                	li	a1,0
    80001572:	00000097          	auipc	ra,0x0
    80001576:	d12080e7          	jalr	-750(ra) # 80001284 <uvmunmap>
    8000157a:	bfe1                	j	80001552 <uvmfree+0xe>

000000008000157c <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000157c:	c679                	beqz	a2,8000164a <uvmcopy+0xce>
{
    8000157e:	715d                	addi	sp,sp,-80
    80001580:	e486                	sd	ra,72(sp)
    80001582:	e0a2                	sd	s0,64(sp)
    80001584:	fc26                	sd	s1,56(sp)
    80001586:	f84a                	sd	s2,48(sp)
    80001588:	f44e                	sd	s3,40(sp)
    8000158a:	f052                	sd	s4,32(sp)
    8000158c:	ec56                	sd	s5,24(sp)
    8000158e:	e85a                	sd	s6,16(sp)
    80001590:	e45e                	sd	s7,8(sp)
    80001592:	0880                	addi	s0,sp,80
    80001594:	8b2a                	mv	s6,a0
    80001596:	8aae                	mv	s5,a1
    80001598:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000159a:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000159c:	4601                	li	a2,0
    8000159e:	85ce                	mv	a1,s3
    800015a0:	855a                	mv	a0,s6
    800015a2:	00000097          	auipc	ra,0x0
    800015a6:	a46080e7          	jalr	-1466(ra) # 80000fe8 <walk>
    800015aa:	c531                	beqz	a0,800015f6 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800015ac:	6118                	ld	a4,0(a0)
    800015ae:	00177793          	andi	a5,a4,1
    800015b2:	cbb1                	beqz	a5,80001606 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015b4:	00a75593          	srli	a1,a4,0xa
    800015b8:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015bc:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015c0:	fffff097          	auipc	ra,0xfffff
    800015c4:	512080e7          	jalr	1298(ra) # 80000ad2 <kalloc>
    800015c8:	892a                	mv	s2,a0
    800015ca:	c939                	beqz	a0,80001620 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015cc:	6605                	lui	a2,0x1
    800015ce:	85de                	mv	a1,s7
    800015d0:	fffff097          	auipc	ra,0xfffff
    800015d4:	74a080e7          	jalr	1866(ra) # 80000d1a <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015d8:	8726                	mv	a4,s1
    800015da:	86ca                	mv	a3,s2
    800015dc:	6605                	lui	a2,0x1
    800015de:	85ce                	mv	a1,s3
    800015e0:	8556                	mv	a0,s5
    800015e2:	00000097          	auipc	ra,0x0
    800015e6:	aee080e7          	jalr	-1298(ra) # 800010d0 <mappages>
    800015ea:	e515                	bnez	a0,80001616 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015ec:	6785                	lui	a5,0x1
    800015ee:	99be                	add	s3,s3,a5
    800015f0:	fb49e6e3          	bltu	s3,s4,8000159c <uvmcopy+0x20>
    800015f4:	a081                	j	80001634 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015f6:	00007517          	auipc	a0,0x7
    800015fa:	b7a50513          	addi	a0,a0,-1158 # 80008170 <digits+0x130>
    800015fe:	fffff097          	auipc	ra,0xfffff
    80001602:	f2c080e7          	jalr	-212(ra) # 8000052a <panic>
      panic("uvmcopy: page not present");
    80001606:	00007517          	auipc	a0,0x7
    8000160a:	b8a50513          	addi	a0,a0,-1142 # 80008190 <digits+0x150>
    8000160e:	fffff097          	auipc	ra,0xfffff
    80001612:	f1c080e7          	jalr	-228(ra) # 8000052a <panic>
      kfree(mem);
    80001616:	854a                	mv	a0,s2
    80001618:	fffff097          	auipc	ra,0xfffff
    8000161c:	3be080e7          	jalr	958(ra) # 800009d6 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001620:	4685                	li	a3,1
    80001622:	00c9d613          	srli	a2,s3,0xc
    80001626:	4581                	li	a1,0
    80001628:	8556                	mv	a0,s5
    8000162a:	00000097          	auipc	ra,0x0
    8000162e:	c5a080e7          	jalr	-934(ra) # 80001284 <uvmunmap>
  return -1;
    80001632:	557d                	li	a0,-1
}
    80001634:	60a6                	ld	ra,72(sp)
    80001636:	6406                	ld	s0,64(sp)
    80001638:	74e2                	ld	s1,56(sp)
    8000163a:	7942                	ld	s2,48(sp)
    8000163c:	79a2                	ld	s3,40(sp)
    8000163e:	7a02                	ld	s4,32(sp)
    80001640:	6ae2                	ld	s5,24(sp)
    80001642:	6b42                	ld	s6,16(sp)
    80001644:	6ba2                	ld	s7,8(sp)
    80001646:	6161                	addi	sp,sp,80
    80001648:	8082                	ret
  return 0;
    8000164a:	4501                	li	a0,0
}
    8000164c:	8082                	ret

000000008000164e <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000164e:	1141                	addi	sp,sp,-16
    80001650:	e406                	sd	ra,8(sp)
    80001652:	e022                	sd	s0,0(sp)
    80001654:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001656:	4601                	li	a2,0
    80001658:	00000097          	auipc	ra,0x0
    8000165c:	990080e7          	jalr	-1648(ra) # 80000fe8 <walk>
  if(pte == 0)
    80001660:	c901                	beqz	a0,80001670 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001662:	611c                	ld	a5,0(a0)
    80001664:	9bbd                	andi	a5,a5,-17
    80001666:	e11c                	sd	a5,0(a0)
}
    80001668:	60a2                	ld	ra,8(sp)
    8000166a:	6402                	ld	s0,0(sp)
    8000166c:	0141                	addi	sp,sp,16
    8000166e:	8082                	ret
    panic("uvmclear");
    80001670:	00007517          	auipc	a0,0x7
    80001674:	b4050513          	addi	a0,a0,-1216 # 800081b0 <digits+0x170>
    80001678:	fffff097          	auipc	ra,0xfffff
    8000167c:	eb2080e7          	jalr	-334(ra) # 8000052a <panic>

0000000080001680 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001680:	c6bd                	beqz	a3,800016ee <copyout+0x6e>
{
    80001682:	715d                	addi	sp,sp,-80
    80001684:	e486                	sd	ra,72(sp)
    80001686:	e0a2                	sd	s0,64(sp)
    80001688:	fc26                	sd	s1,56(sp)
    8000168a:	f84a                	sd	s2,48(sp)
    8000168c:	f44e                	sd	s3,40(sp)
    8000168e:	f052                	sd	s4,32(sp)
    80001690:	ec56                	sd	s5,24(sp)
    80001692:	e85a                	sd	s6,16(sp)
    80001694:	e45e                	sd	s7,8(sp)
    80001696:	e062                	sd	s8,0(sp)
    80001698:	0880                	addi	s0,sp,80
    8000169a:	8b2a                	mv	s6,a0
    8000169c:	8c2e                	mv	s8,a1
    8000169e:	8a32                	mv	s4,a2
    800016a0:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800016a2:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800016a4:	6a85                	lui	s5,0x1
    800016a6:	a015                	j	800016ca <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800016a8:	9562                	add	a0,a0,s8
    800016aa:	0004861b          	sext.w	a2,s1
    800016ae:	85d2                	mv	a1,s4
    800016b0:	41250533          	sub	a0,a0,s2
    800016b4:	fffff097          	auipc	ra,0xfffff
    800016b8:	666080e7          	jalr	1638(ra) # 80000d1a <memmove>

    len -= n;
    800016bc:	409989b3          	sub	s3,s3,s1
    src += n;
    800016c0:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016c2:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016c6:	02098263          	beqz	s3,800016ea <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016ca:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016ce:	85ca                	mv	a1,s2
    800016d0:	855a                	mv	a0,s6
    800016d2:	00000097          	auipc	ra,0x0
    800016d6:	9bc080e7          	jalr	-1604(ra) # 8000108e <walkaddr>
    if(pa0 == 0)
    800016da:	cd01                	beqz	a0,800016f2 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016dc:	418904b3          	sub	s1,s2,s8
    800016e0:	94d6                	add	s1,s1,s5
    if(n > len)
    800016e2:	fc99f3e3          	bgeu	s3,s1,800016a8 <copyout+0x28>
    800016e6:	84ce                	mv	s1,s3
    800016e8:	b7c1                	j	800016a8 <copyout+0x28>
  }
  return 0;
    800016ea:	4501                	li	a0,0
    800016ec:	a021                	j	800016f4 <copyout+0x74>
    800016ee:	4501                	li	a0,0
}
    800016f0:	8082                	ret
      return -1;
    800016f2:	557d                	li	a0,-1
}
    800016f4:	60a6                	ld	ra,72(sp)
    800016f6:	6406                	ld	s0,64(sp)
    800016f8:	74e2                	ld	s1,56(sp)
    800016fa:	7942                	ld	s2,48(sp)
    800016fc:	79a2                	ld	s3,40(sp)
    800016fe:	7a02                	ld	s4,32(sp)
    80001700:	6ae2                	ld	s5,24(sp)
    80001702:	6b42                	ld	s6,16(sp)
    80001704:	6ba2                	ld	s7,8(sp)
    80001706:	6c02                	ld	s8,0(sp)
    80001708:	6161                	addi	sp,sp,80
    8000170a:	8082                	ret

000000008000170c <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000170c:	caa5                	beqz	a3,8000177c <copyin+0x70>
{
    8000170e:	715d                	addi	sp,sp,-80
    80001710:	e486                	sd	ra,72(sp)
    80001712:	e0a2                	sd	s0,64(sp)
    80001714:	fc26                	sd	s1,56(sp)
    80001716:	f84a                	sd	s2,48(sp)
    80001718:	f44e                	sd	s3,40(sp)
    8000171a:	f052                	sd	s4,32(sp)
    8000171c:	ec56                	sd	s5,24(sp)
    8000171e:	e85a                	sd	s6,16(sp)
    80001720:	e45e                	sd	s7,8(sp)
    80001722:	e062                	sd	s8,0(sp)
    80001724:	0880                	addi	s0,sp,80
    80001726:	8b2a                	mv	s6,a0
    80001728:	8a2e                	mv	s4,a1
    8000172a:	8c32                	mv	s8,a2
    8000172c:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    8000172e:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001730:	6a85                	lui	s5,0x1
    80001732:	a01d                	j	80001758 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001734:	018505b3          	add	a1,a0,s8
    80001738:	0004861b          	sext.w	a2,s1
    8000173c:	412585b3          	sub	a1,a1,s2
    80001740:	8552                	mv	a0,s4
    80001742:	fffff097          	auipc	ra,0xfffff
    80001746:	5d8080e7          	jalr	1496(ra) # 80000d1a <memmove>

    len -= n;
    8000174a:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000174e:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001750:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001754:	02098263          	beqz	s3,80001778 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001758:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000175c:	85ca                	mv	a1,s2
    8000175e:	855a                	mv	a0,s6
    80001760:	00000097          	auipc	ra,0x0
    80001764:	92e080e7          	jalr	-1746(ra) # 8000108e <walkaddr>
    if(pa0 == 0)
    80001768:	cd01                	beqz	a0,80001780 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    8000176a:	418904b3          	sub	s1,s2,s8
    8000176e:	94d6                	add	s1,s1,s5
    if(n > len)
    80001770:	fc99f2e3          	bgeu	s3,s1,80001734 <copyin+0x28>
    80001774:	84ce                	mv	s1,s3
    80001776:	bf7d                	j	80001734 <copyin+0x28>
  }
  return 0;
    80001778:	4501                	li	a0,0
    8000177a:	a021                	j	80001782 <copyin+0x76>
    8000177c:	4501                	li	a0,0
}
    8000177e:	8082                	ret
      return -1;
    80001780:	557d                	li	a0,-1
}
    80001782:	60a6                	ld	ra,72(sp)
    80001784:	6406                	ld	s0,64(sp)
    80001786:	74e2                	ld	s1,56(sp)
    80001788:	7942                	ld	s2,48(sp)
    8000178a:	79a2                	ld	s3,40(sp)
    8000178c:	7a02                	ld	s4,32(sp)
    8000178e:	6ae2                	ld	s5,24(sp)
    80001790:	6b42                	ld	s6,16(sp)
    80001792:	6ba2                	ld	s7,8(sp)
    80001794:	6c02                	ld	s8,0(sp)
    80001796:	6161                	addi	sp,sp,80
    80001798:	8082                	ret

000000008000179a <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000179a:	c6c5                	beqz	a3,80001842 <copyinstr+0xa8>
{
    8000179c:	715d                	addi	sp,sp,-80
    8000179e:	e486                	sd	ra,72(sp)
    800017a0:	e0a2                	sd	s0,64(sp)
    800017a2:	fc26                	sd	s1,56(sp)
    800017a4:	f84a                	sd	s2,48(sp)
    800017a6:	f44e                	sd	s3,40(sp)
    800017a8:	f052                	sd	s4,32(sp)
    800017aa:	ec56                	sd	s5,24(sp)
    800017ac:	e85a                	sd	s6,16(sp)
    800017ae:	e45e                	sd	s7,8(sp)
    800017b0:	0880                	addi	s0,sp,80
    800017b2:	8a2a                	mv	s4,a0
    800017b4:	8b2e                	mv	s6,a1
    800017b6:	8bb2                	mv	s7,a2
    800017b8:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017ba:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017bc:	6985                	lui	s3,0x1
    800017be:	a035                	j	800017ea <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017c0:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017c4:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017c6:	0017b793          	seqz	a5,a5
    800017ca:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017ce:	60a6                	ld	ra,72(sp)
    800017d0:	6406                	ld	s0,64(sp)
    800017d2:	74e2                	ld	s1,56(sp)
    800017d4:	7942                	ld	s2,48(sp)
    800017d6:	79a2                	ld	s3,40(sp)
    800017d8:	7a02                	ld	s4,32(sp)
    800017da:	6ae2                	ld	s5,24(sp)
    800017dc:	6b42                	ld	s6,16(sp)
    800017de:	6ba2                	ld	s7,8(sp)
    800017e0:	6161                	addi	sp,sp,80
    800017e2:	8082                	ret
    srcva = va0 + PGSIZE;
    800017e4:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017e8:	c8a9                	beqz	s1,8000183a <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017ea:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017ee:	85ca                	mv	a1,s2
    800017f0:	8552                	mv	a0,s4
    800017f2:	00000097          	auipc	ra,0x0
    800017f6:	89c080e7          	jalr	-1892(ra) # 8000108e <walkaddr>
    if(pa0 == 0)
    800017fa:	c131                	beqz	a0,8000183e <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017fc:	41790833          	sub	a6,s2,s7
    80001800:	984e                	add	a6,a6,s3
    if(n > max)
    80001802:	0104f363          	bgeu	s1,a6,80001808 <copyinstr+0x6e>
    80001806:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001808:	955e                	add	a0,a0,s7
    8000180a:	41250533          	sub	a0,a0,s2
    while(n > 0){
    8000180e:	fc080be3          	beqz	a6,800017e4 <copyinstr+0x4a>
    80001812:	985a                	add	a6,a6,s6
    80001814:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001816:	41650633          	sub	a2,a0,s6
    8000181a:	14fd                	addi	s1,s1,-1
    8000181c:	9b26                	add	s6,s6,s1
    8000181e:	00f60733          	add	a4,a2,a5
    80001822:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd9000>
    80001826:	df49                	beqz	a4,800017c0 <copyinstr+0x26>
        *dst = *p;
    80001828:	00e78023          	sb	a4,0(a5)
      --max;
    8000182c:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001830:	0785                	addi	a5,a5,1
    while(n > 0){
    80001832:	ff0796e3          	bne	a5,a6,8000181e <copyinstr+0x84>
      dst++;
    80001836:	8b42                	mv	s6,a6
    80001838:	b775                	j	800017e4 <copyinstr+0x4a>
    8000183a:	4781                	li	a5,0
    8000183c:	b769                	j	800017c6 <copyinstr+0x2c>
      return -1;
    8000183e:	557d                	li	a0,-1
    80001840:	b779                	j	800017ce <copyinstr+0x34>
  int got_null = 0;
    80001842:	4781                	li	a5,0
  if(got_null){
    80001844:	0017b793          	seqz	a5,a5
    80001848:	40f00533          	neg	a0,a5
}
    8000184c:	8082                	ret

000000008000184e <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    8000184e:	7139                	addi	sp,sp,-64
    80001850:	fc06                	sd	ra,56(sp)
    80001852:	f822                	sd	s0,48(sp)
    80001854:	f426                	sd	s1,40(sp)
    80001856:	f04a                	sd	s2,32(sp)
    80001858:	ec4e                	sd	s3,24(sp)
    8000185a:	e852                	sd	s4,16(sp)
    8000185c:	e456                	sd	s5,8(sp)
    8000185e:	e05a                	sd	s6,0(sp)
    80001860:	0080                	addi	s0,sp,64
    80001862:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001864:	00010497          	auipc	s1,0x10
    80001868:	e6c48493          	addi	s1,s1,-404 # 800116d0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    8000186c:	8b26                	mv	s6,s1
    8000186e:	00006a97          	auipc	s5,0x6
    80001872:	792a8a93          	addi	s5,s5,1938 # 80008000 <etext>
    80001876:	04000937          	lui	s2,0x4000
    8000187a:	197d                	addi	s2,s2,-1
    8000187c:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000187e:	00016a17          	auipc	s4,0x16
    80001882:	852a0a13          	addi	s4,s4,-1966 # 800170d0 <tickslock>
    char *pa = kalloc();
    80001886:	fffff097          	auipc	ra,0xfffff
    8000188a:	24c080e7          	jalr	588(ra) # 80000ad2 <kalloc>
    8000188e:	862a                	mv	a2,a0
    if(pa == 0)
    80001890:	c131                	beqz	a0,800018d4 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001892:	416485b3          	sub	a1,s1,s6
    80001896:	858d                	srai	a1,a1,0x3
    80001898:	000ab783          	ld	a5,0(s5)
    8000189c:	02f585b3          	mul	a1,a1,a5
    800018a0:	2585                	addiw	a1,a1,1
    800018a2:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800018a6:	4719                	li	a4,6
    800018a8:	6685                	lui	a3,0x1
    800018aa:	40b905b3          	sub	a1,s2,a1
    800018ae:	854e                	mv	a0,s3
    800018b0:	00000097          	auipc	ra,0x0
    800018b4:	8ae080e7          	jalr	-1874(ra) # 8000115e <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018b8:	16848493          	addi	s1,s1,360
    800018bc:	fd4495e3          	bne	s1,s4,80001886 <proc_mapstacks+0x38>
  }
}
    800018c0:	70e2                	ld	ra,56(sp)
    800018c2:	7442                	ld	s0,48(sp)
    800018c4:	74a2                	ld	s1,40(sp)
    800018c6:	7902                	ld	s2,32(sp)
    800018c8:	69e2                	ld	s3,24(sp)
    800018ca:	6a42                	ld	s4,16(sp)
    800018cc:	6aa2                	ld	s5,8(sp)
    800018ce:	6b02                	ld	s6,0(sp)
    800018d0:	6121                	addi	sp,sp,64
    800018d2:	8082                	ret
      panic("kalloc");
    800018d4:	00007517          	auipc	a0,0x7
    800018d8:	8ec50513          	addi	a0,a0,-1812 # 800081c0 <digits+0x180>
    800018dc:	fffff097          	auipc	ra,0xfffff
    800018e0:	c4e080e7          	jalr	-946(ra) # 8000052a <panic>

00000000800018e4 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    800018e4:	7139                	addi	sp,sp,-64
    800018e6:	fc06                	sd	ra,56(sp)
    800018e8:	f822                	sd	s0,48(sp)
    800018ea:	f426                	sd	s1,40(sp)
    800018ec:	f04a                	sd	s2,32(sp)
    800018ee:	ec4e                	sd	s3,24(sp)
    800018f0:	e852                	sd	s4,16(sp)
    800018f2:	e456                	sd	s5,8(sp)
    800018f4:	e05a                	sd	s6,0(sp)
    800018f6:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800018f8:	00007597          	auipc	a1,0x7
    800018fc:	8d058593          	addi	a1,a1,-1840 # 800081c8 <digits+0x188>
    80001900:	00010517          	auipc	a0,0x10
    80001904:	9a050513          	addi	a0,a0,-1632 # 800112a0 <pid_lock>
    80001908:	fffff097          	auipc	ra,0xfffff
    8000190c:	22a080e7          	jalr	554(ra) # 80000b32 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001910:	00007597          	auipc	a1,0x7
    80001914:	8c058593          	addi	a1,a1,-1856 # 800081d0 <digits+0x190>
    80001918:	00010517          	auipc	a0,0x10
    8000191c:	9a050513          	addi	a0,a0,-1632 # 800112b8 <wait_lock>
    80001920:	fffff097          	auipc	ra,0xfffff
    80001924:	212080e7          	jalr	530(ra) # 80000b32 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001928:	00010497          	auipc	s1,0x10
    8000192c:	da848493          	addi	s1,s1,-600 # 800116d0 <proc>
      initlock(&p->lock, "proc");
    80001930:	00007b17          	auipc	s6,0x7
    80001934:	8b0b0b13          	addi	s6,s6,-1872 # 800081e0 <digits+0x1a0>
      p->kstack = KSTACK((int) (p - proc));
    80001938:	8aa6                	mv	s5,s1
    8000193a:	00006a17          	auipc	s4,0x6
    8000193e:	6c6a0a13          	addi	s4,s4,1734 # 80008000 <etext>
    80001942:	04000937          	lui	s2,0x4000
    80001946:	197d                	addi	s2,s2,-1
    80001948:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000194a:	00015997          	auipc	s3,0x15
    8000194e:	78698993          	addi	s3,s3,1926 # 800170d0 <tickslock>
      initlock(&p->lock, "proc");
    80001952:	85da                	mv	a1,s6
    80001954:	8526                	mv	a0,s1
    80001956:	fffff097          	auipc	ra,0xfffff
    8000195a:	1dc080e7          	jalr	476(ra) # 80000b32 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    8000195e:	415487b3          	sub	a5,s1,s5
    80001962:	878d                	srai	a5,a5,0x3
    80001964:	000a3703          	ld	a4,0(s4)
    80001968:	02e787b3          	mul	a5,a5,a4
    8000196c:	2785                	addiw	a5,a5,1
    8000196e:	00d7979b          	slliw	a5,a5,0xd
    80001972:	40f907b3          	sub	a5,s2,a5
    80001976:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001978:	16848493          	addi	s1,s1,360
    8000197c:	fd349be3          	bne	s1,s3,80001952 <procinit+0x6e>
  }
}
    80001980:	70e2                	ld	ra,56(sp)
    80001982:	7442                	ld	s0,48(sp)
    80001984:	74a2                	ld	s1,40(sp)
    80001986:	7902                	ld	s2,32(sp)
    80001988:	69e2                	ld	s3,24(sp)
    8000198a:	6a42                	ld	s4,16(sp)
    8000198c:	6aa2                	ld	s5,8(sp)
    8000198e:	6b02                	ld	s6,0(sp)
    80001990:	6121                	addi	sp,sp,64
    80001992:	8082                	ret

0000000080001994 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001994:	1141                	addi	sp,sp,-16
    80001996:	e422                	sd	s0,8(sp)
    80001998:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    8000199a:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    8000199c:	2501                	sext.w	a0,a0
    8000199e:	6422                	ld	s0,8(sp)
    800019a0:	0141                	addi	sp,sp,16
    800019a2:	8082                	ret

00000000800019a4 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    800019a4:	1141                	addi	sp,sp,-16
    800019a6:	e422                	sd	s0,8(sp)
    800019a8:	0800                	addi	s0,sp,16
    800019aa:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800019ac:	2781                	sext.w	a5,a5
    800019ae:	079e                	slli	a5,a5,0x7
  return c;
}
    800019b0:	00010517          	auipc	a0,0x10
    800019b4:	92050513          	addi	a0,a0,-1760 # 800112d0 <cpus>
    800019b8:	953e                	add	a0,a0,a5
    800019ba:	6422                	ld	s0,8(sp)
    800019bc:	0141                	addi	sp,sp,16
    800019be:	8082                	ret

00000000800019c0 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    800019c0:	1101                	addi	sp,sp,-32
    800019c2:	ec06                	sd	ra,24(sp)
    800019c4:	e822                	sd	s0,16(sp)
    800019c6:	e426                	sd	s1,8(sp)
    800019c8:	1000                	addi	s0,sp,32
  push_off();
    800019ca:	fffff097          	auipc	ra,0xfffff
    800019ce:	1ac080e7          	jalr	428(ra) # 80000b76 <push_off>
    800019d2:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019d4:	2781                	sext.w	a5,a5
    800019d6:	079e                	slli	a5,a5,0x7
    800019d8:	00010717          	auipc	a4,0x10
    800019dc:	8c870713          	addi	a4,a4,-1848 # 800112a0 <pid_lock>
    800019e0:	97ba                	add	a5,a5,a4
    800019e2:	7b84                	ld	s1,48(a5)
  pop_off();
    800019e4:	fffff097          	auipc	ra,0xfffff
    800019e8:	232080e7          	jalr	562(ra) # 80000c16 <pop_off>
  return p;
}
    800019ec:	8526                	mv	a0,s1
    800019ee:	60e2                	ld	ra,24(sp)
    800019f0:	6442                	ld	s0,16(sp)
    800019f2:	64a2                	ld	s1,8(sp)
    800019f4:	6105                	addi	sp,sp,32
    800019f6:	8082                	ret

00000000800019f8 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    800019f8:	1141                	addi	sp,sp,-16
    800019fa:	e406                	sd	ra,8(sp)
    800019fc:	e022                	sd	s0,0(sp)
    800019fe:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001a00:	00000097          	auipc	ra,0x0
    80001a04:	fc0080e7          	jalr	-64(ra) # 800019c0 <myproc>
    80001a08:	fffff097          	auipc	ra,0xfffff
    80001a0c:	26e080e7          	jalr	622(ra) # 80000c76 <release>

  if (first) {
    80001a10:	00007797          	auipc	a5,0x7
    80001a14:	df07a783          	lw	a5,-528(a5) # 80008800 <first.1>
    80001a18:	eb89                	bnez	a5,80001a2a <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a1a:	00001097          	auipc	ra,0x1
    80001a1e:	c12080e7          	jalr	-1006(ra) # 8000262c <usertrapret>
}
    80001a22:	60a2                	ld	ra,8(sp)
    80001a24:	6402                	ld	s0,0(sp)
    80001a26:	0141                	addi	sp,sp,16
    80001a28:	8082                	ret
    first = 0;
    80001a2a:	00007797          	auipc	a5,0x7
    80001a2e:	dc07ab23          	sw	zero,-554(a5) # 80008800 <first.1>
    fsinit(ROOTDEV);
    80001a32:	4505                	li	a0,1
    80001a34:	00002097          	auipc	ra,0x2
    80001a38:	a04080e7          	jalr	-1532(ra) # 80003438 <fsinit>
    80001a3c:	bff9                	j	80001a1a <forkret+0x22>

0000000080001a3e <allocpid>:
allocpid() {
    80001a3e:	1101                	addi	sp,sp,-32
    80001a40:	ec06                	sd	ra,24(sp)
    80001a42:	e822                	sd	s0,16(sp)
    80001a44:	e426                	sd	s1,8(sp)
    80001a46:	e04a                	sd	s2,0(sp)
    80001a48:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a4a:	00010917          	auipc	s2,0x10
    80001a4e:	85690913          	addi	s2,s2,-1962 # 800112a0 <pid_lock>
    80001a52:	854a                	mv	a0,s2
    80001a54:	fffff097          	auipc	ra,0xfffff
    80001a58:	16e080e7          	jalr	366(ra) # 80000bc2 <acquire>
  pid = nextpid;
    80001a5c:	00007797          	auipc	a5,0x7
    80001a60:	da878793          	addi	a5,a5,-600 # 80008804 <nextpid>
    80001a64:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a66:	0014871b          	addiw	a4,s1,1
    80001a6a:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a6c:	854a                	mv	a0,s2
    80001a6e:	fffff097          	auipc	ra,0xfffff
    80001a72:	208080e7          	jalr	520(ra) # 80000c76 <release>
}
    80001a76:	8526                	mv	a0,s1
    80001a78:	60e2                	ld	ra,24(sp)
    80001a7a:	6442                	ld	s0,16(sp)
    80001a7c:	64a2                	ld	s1,8(sp)
    80001a7e:	6902                	ld	s2,0(sp)
    80001a80:	6105                	addi	sp,sp,32
    80001a82:	8082                	ret

0000000080001a84 <proc_pagetable>:
{
    80001a84:	1101                	addi	sp,sp,-32
    80001a86:	ec06                	sd	ra,24(sp)
    80001a88:	e822                	sd	s0,16(sp)
    80001a8a:	e426                	sd	s1,8(sp)
    80001a8c:	e04a                	sd	s2,0(sp)
    80001a8e:	1000                	addi	s0,sp,32
    80001a90:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a92:	00000097          	auipc	ra,0x0
    80001a96:	8b6080e7          	jalr	-1866(ra) # 80001348 <uvmcreate>
    80001a9a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001a9c:	c121                	beqz	a0,80001adc <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a9e:	4729                	li	a4,10
    80001aa0:	00005697          	auipc	a3,0x5
    80001aa4:	56068693          	addi	a3,a3,1376 # 80007000 <_trampoline>
    80001aa8:	6605                	lui	a2,0x1
    80001aaa:	040005b7          	lui	a1,0x4000
    80001aae:	15fd                	addi	a1,a1,-1
    80001ab0:	05b2                	slli	a1,a1,0xc
    80001ab2:	fffff097          	auipc	ra,0xfffff
    80001ab6:	61e080e7          	jalr	1566(ra) # 800010d0 <mappages>
    80001aba:	02054863          	bltz	a0,80001aea <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001abe:	4719                	li	a4,6
    80001ac0:	05893683          	ld	a3,88(s2)
    80001ac4:	6605                	lui	a2,0x1
    80001ac6:	020005b7          	lui	a1,0x2000
    80001aca:	15fd                	addi	a1,a1,-1
    80001acc:	05b6                	slli	a1,a1,0xd
    80001ace:	8526                	mv	a0,s1
    80001ad0:	fffff097          	auipc	ra,0xfffff
    80001ad4:	600080e7          	jalr	1536(ra) # 800010d0 <mappages>
    80001ad8:	02054163          	bltz	a0,80001afa <proc_pagetable+0x76>
}
    80001adc:	8526                	mv	a0,s1
    80001ade:	60e2                	ld	ra,24(sp)
    80001ae0:	6442                	ld	s0,16(sp)
    80001ae2:	64a2                	ld	s1,8(sp)
    80001ae4:	6902                	ld	s2,0(sp)
    80001ae6:	6105                	addi	sp,sp,32
    80001ae8:	8082                	ret
    uvmfree(pagetable, 0);
    80001aea:	4581                	li	a1,0
    80001aec:	8526                	mv	a0,s1
    80001aee:	00000097          	auipc	ra,0x0
    80001af2:	a56080e7          	jalr	-1450(ra) # 80001544 <uvmfree>
    return 0;
    80001af6:	4481                	li	s1,0
    80001af8:	b7d5                	j	80001adc <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001afa:	4681                	li	a3,0
    80001afc:	4605                	li	a2,1
    80001afe:	040005b7          	lui	a1,0x4000
    80001b02:	15fd                	addi	a1,a1,-1
    80001b04:	05b2                	slli	a1,a1,0xc
    80001b06:	8526                	mv	a0,s1
    80001b08:	fffff097          	auipc	ra,0xfffff
    80001b0c:	77c080e7          	jalr	1916(ra) # 80001284 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b10:	4581                	li	a1,0
    80001b12:	8526                	mv	a0,s1
    80001b14:	00000097          	auipc	ra,0x0
    80001b18:	a30080e7          	jalr	-1488(ra) # 80001544 <uvmfree>
    return 0;
    80001b1c:	4481                	li	s1,0
    80001b1e:	bf7d                	j	80001adc <proc_pagetable+0x58>

0000000080001b20 <proc_freepagetable>:
{
    80001b20:	1101                	addi	sp,sp,-32
    80001b22:	ec06                	sd	ra,24(sp)
    80001b24:	e822                	sd	s0,16(sp)
    80001b26:	e426                	sd	s1,8(sp)
    80001b28:	e04a                	sd	s2,0(sp)
    80001b2a:	1000                	addi	s0,sp,32
    80001b2c:	84aa                	mv	s1,a0
    80001b2e:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b30:	4681                	li	a3,0
    80001b32:	4605                	li	a2,1
    80001b34:	040005b7          	lui	a1,0x4000
    80001b38:	15fd                	addi	a1,a1,-1
    80001b3a:	05b2                	slli	a1,a1,0xc
    80001b3c:	fffff097          	auipc	ra,0xfffff
    80001b40:	748080e7          	jalr	1864(ra) # 80001284 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b44:	4681                	li	a3,0
    80001b46:	4605                	li	a2,1
    80001b48:	020005b7          	lui	a1,0x2000
    80001b4c:	15fd                	addi	a1,a1,-1
    80001b4e:	05b6                	slli	a1,a1,0xd
    80001b50:	8526                	mv	a0,s1
    80001b52:	fffff097          	auipc	ra,0xfffff
    80001b56:	732080e7          	jalr	1842(ra) # 80001284 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b5a:	85ca                	mv	a1,s2
    80001b5c:	8526                	mv	a0,s1
    80001b5e:	00000097          	auipc	ra,0x0
    80001b62:	9e6080e7          	jalr	-1562(ra) # 80001544 <uvmfree>
}
    80001b66:	60e2                	ld	ra,24(sp)
    80001b68:	6442                	ld	s0,16(sp)
    80001b6a:	64a2                	ld	s1,8(sp)
    80001b6c:	6902                	ld	s2,0(sp)
    80001b6e:	6105                	addi	sp,sp,32
    80001b70:	8082                	ret

0000000080001b72 <freeproc>:
{
    80001b72:	1101                	addi	sp,sp,-32
    80001b74:	ec06                	sd	ra,24(sp)
    80001b76:	e822                	sd	s0,16(sp)
    80001b78:	e426                	sd	s1,8(sp)
    80001b7a:	1000                	addi	s0,sp,32
    80001b7c:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b7e:	6d28                	ld	a0,88(a0)
    80001b80:	c509                	beqz	a0,80001b8a <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b82:	fffff097          	auipc	ra,0xfffff
    80001b86:	e54080e7          	jalr	-428(ra) # 800009d6 <kfree>
  p->trapframe = 0;
    80001b8a:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001b8e:	68a8                	ld	a0,80(s1)
    80001b90:	c511                	beqz	a0,80001b9c <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b92:	64ac                	ld	a1,72(s1)
    80001b94:	00000097          	auipc	ra,0x0
    80001b98:	f8c080e7          	jalr	-116(ra) # 80001b20 <proc_freepagetable>
  p->pagetable = 0;
    80001b9c:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001ba0:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001ba4:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001ba8:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001bac:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001bb0:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001bb4:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001bb8:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001bbc:	0004ac23          	sw	zero,24(s1)
}
    80001bc0:	60e2                	ld	ra,24(sp)
    80001bc2:	6442                	ld	s0,16(sp)
    80001bc4:	64a2                	ld	s1,8(sp)
    80001bc6:	6105                	addi	sp,sp,32
    80001bc8:	8082                	ret

0000000080001bca <allocproc>:
{
    80001bca:	1101                	addi	sp,sp,-32
    80001bcc:	ec06                	sd	ra,24(sp)
    80001bce:	e822                	sd	s0,16(sp)
    80001bd0:	e426                	sd	s1,8(sp)
    80001bd2:	e04a                	sd	s2,0(sp)
    80001bd4:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bd6:	00010497          	auipc	s1,0x10
    80001bda:	afa48493          	addi	s1,s1,-1286 # 800116d0 <proc>
    80001bde:	00015917          	auipc	s2,0x15
    80001be2:	4f290913          	addi	s2,s2,1266 # 800170d0 <tickslock>
    acquire(&p->lock);
    80001be6:	8526                	mv	a0,s1
    80001be8:	fffff097          	auipc	ra,0xfffff
    80001bec:	fda080e7          	jalr	-38(ra) # 80000bc2 <acquire>
    if(p->state == UNUSED) {
    80001bf0:	4c9c                	lw	a5,24(s1)
    80001bf2:	cf81                	beqz	a5,80001c0a <allocproc+0x40>
      release(&p->lock);
    80001bf4:	8526                	mv	a0,s1
    80001bf6:	fffff097          	auipc	ra,0xfffff
    80001bfa:	080080e7          	jalr	128(ra) # 80000c76 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bfe:	16848493          	addi	s1,s1,360
    80001c02:	ff2492e3          	bne	s1,s2,80001be6 <allocproc+0x1c>
  return 0;
    80001c06:	4481                	li	s1,0
    80001c08:	a889                	j	80001c5a <allocproc+0x90>
  p->pid = allocpid();
    80001c0a:	00000097          	auipc	ra,0x0
    80001c0e:	e34080e7          	jalr	-460(ra) # 80001a3e <allocpid>
    80001c12:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c14:	4785                	li	a5,1
    80001c16:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c18:	fffff097          	auipc	ra,0xfffff
    80001c1c:	eba080e7          	jalr	-326(ra) # 80000ad2 <kalloc>
    80001c20:	892a                	mv	s2,a0
    80001c22:	eca8                	sd	a0,88(s1)
    80001c24:	c131                	beqz	a0,80001c68 <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001c26:	8526                	mv	a0,s1
    80001c28:	00000097          	auipc	ra,0x0
    80001c2c:	e5c080e7          	jalr	-420(ra) # 80001a84 <proc_pagetable>
    80001c30:	892a                	mv	s2,a0
    80001c32:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c34:	c531                	beqz	a0,80001c80 <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001c36:	07000613          	li	a2,112
    80001c3a:	4581                	li	a1,0
    80001c3c:	06048513          	addi	a0,s1,96
    80001c40:	fffff097          	auipc	ra,0xfffff
    80001c44:	07e080e7          	jalr	126(ra) # 80000cbe <memset>
  p->context.ra = (uint64)forkret;
    80001c48:	00000797          	auipc	a5,0x0
    80001c4c:	db078793          	addi	a5,a5,-592 # 800019f8 <forkret>
    80001c50:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c52:	60bc                	ld	a5,64(s1)
    80001c54:	6705                	lui	a4,0x1
    80001c56:	97ba                	add	a5,a5,a4
    80001c58:	f4bc                	sd	a5,104(s1)
}
    80001c5a:	8526                	mv	a0,s1
    80001c5c:	60e2                	ld	ra,24(sp)
    80001c5e:	6442                	ld	s0,16(sp)
    80001c60:	64a2                	ld	s1,8(sp)
    80001c62:	6902                	ld	s2,0(sp)
    80001c64:	6105                	addi	sp,sp,32
    80001c66:	8082                	ret
    freeproc(p);
    80001c68:	8526                	mv	a0,s1
    80001c6a:	00000097          	auipc	ra,0x0
    80001c6e:	f08080e7          	jalr	-248(ra) # 80001b72 <freeproc>
    release(&p->lock);
    80001c72:	8526                	mv	a0,s1
    80001c74:	fffff097          	auipc	ra,0xfffff
    80001c78:	002080e7          	jalr	2(ra) # 80000c76 <release>
    return 0;
    80001c7c:	84ca                	mv	s1,s2
    80001c7e:	bff1                	j	80001c5a <allocproc+0x90>
    freeproc(p);
    80001c80:	8526                	mv	a0,s1
    80001c82:	00000097          	auipc	ra,0x0
    80001c86:	ef0080e7          	jalr	-272(ra) # 80001b72 <freeproc>
    release(&p->lock);
    80001c8a:	8526                	mv	a0,s1
    80001c8c:	fffff097          	auipc	ra,0xfffff
    80001c90:	fea080e7          	jalr	-22(ra) # 80000c76 <release>
    return 0;
    80001c94:	84ca                	mv	s1,s2
    80001c96:	b7d1                	j	80001c5a <allocproc+0x90>

0000000080001c98 <userinit>:
{
    80001c98:	1101                	addi	sp,sp,-32
    80001c9a:	ec06                	sd	ra,24(sp)
    80001c9c:	e822                	sd	s0,16(sp)
    80001c9e:	e426                	sd	s1,8(sp)
    80001ca0:	1000                	addi	s0,sp,32
  p = allocproc();
    80001ca2:	00000097          	auipc	ra,0x0
    80001ca6:	f28080e7          	jalr	-216(ra) # 80001bca <allocproc>
    80001caa:	84aa                	mv	s1,a0
  initproc = p;
    80001cac:	00007797          	auipc	a5,0x7
    80001cb0:	36a7be23          	sd	a0,892(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001cb4:	03400613          	li	a2,52
    80001cb8:	00007597          	auipc	a1,0x7
    80001cbc:	b5858593          	addi	a1,a1,-1192 # 80008810 <initcode>
    80001cc0:	6928                	ld	a0,80(a0)
    80001cc2:	fffff097          	auipc	ra,0xfffff
    80001cc6:	6b4080e7          	jalr	1716(ra) # 80001376 <uvminit>
  p->sz = PGSIZE;
    80001cca:	6785                	lui	a5,0x1
    80001ccc:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001cce:	6cb8                	ld	a4,88(s1)
    80001cd0:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001cd4:	6cb8                	ld	a4,88(s1)
    80001cd6:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cd8:	4641                	li	a2,16
    80001cda:	00006597          	auipc	a1,0x6
    80001cde:	50e58593          	addi	a1,a1,1294 # 800081e8 <digits+0x1a8>
    80001ce2:	15848513          	addi	a0,s1,344
    80001ce6:	fffff097          	auipc	ra,0xfffff
    80001cea:	12a080e7          	jalr	298(ra) # 80000e10 <safestrcpy>
  p->cwd = namei("/", 1, 0);
    80001cee:	4601                	li	a2,0
    80001cf0:	4585                	li	a1,1
    80001cf2:	00006517          	auipc	a0,0x6
    80001cf6:	50650513          	addi	a0,a0,1286 # 800081f8 <digits+0x1b8>
    80001cfa:	00002097          	auipc	ra,0x2
    80001cfe:	2c2080e7          	jalr	706(ra) # 80003fbc <namei>
    80001d02:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d06:	478d                	li	a5,3
    80001d08:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d0a:	8526                	mv	a0,s1
    80001d0c:	fffff097          	auipc	ra,0xfffff
    80001d10:	f6a080e7          	jalr	-150(ra) # 80000c76 <release>
}
    80001d14:	60e2                	ld	ra,24(sp)
    80001d16:	6442                	ld	s0,16(sp)
    80001d18:	64a2                	ld	s1,8(sp)
    80001d1a:	6105                	addi	sp,sp,32
    80001d1c:	8082                	ret

0000000080001d1e <growproc>:
{
    80001d1e:	1101                	addi	sp,sp,-32
    80001d20:	ec06                	sd	ra,24(sp)
    80001d22:	e822                	sd	s0,16(sp)
    80001d24:	e426                	sd	s1,8(sp)
    80001d26:	e04a                	sd	s2,0(sp)
    80001d28:	1000                	addi	s0,sp,32
    80001d2a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d2c:	00000097          	auipc	ra,0x0
    80001d30:	c94080e7          	jalr	-876(ra) # 800019c0 <myproc>
    80001d34:	892a                	mv	s2,a0
  sz = p->sz;
    80001d36:	652c                	ld	a1,72(a0)
    80001d38:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001d3c:	00904f63          	bgtz	s1,80001d5a <growproc+0x3c>
  } else if(n < 0){
    80001d40:	0204cc63          	bltz	s1,80001d78 <growproc+0x5a>
  p->sz = sz;
    80001d44:	1602                	slli	a2,a2,0x20
    80001d46:	9201                	srli	a2,a2,0x20
    80001d48:	04c93423          	sd	a2,72(s2)
  return 0;
    80001d4c:	4501                	li	a0,0
}
    80001d4e:	60e2                	ld	ra,24(sp)
    80001d50:	6442                	ld	s0,16(sp)
    80001d52:	64a2                	ld	s1,8(sp)
    80001d54:	6902                	ld	s2,0(sp)
    80001d56:	6105                	addi	sp,sp,32
    80001d58:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d5a:	9e25                	addw	a2,a2,s1
    80001d5c:	1602                	slli	a2,a2,0x20
    80001d5e:	9201                	srli	a2,a2,0x20
    80001d60:	1582                	slli	a1,a1,0x20
    80001d62:	9181                	srli	a1,a1,0x20
    80001d64:	6928                	ld	a0,80(a0)
    80001d66:	fffff097          	auipc	ra,0xfffff
    80001d6a:	6ca080e7          	jalr	1738(ra) # 80001430 <uvmalloc>
    80001d6e:	0005061b          	sext.w	a2,a0
    80001d72:	fa69                	bnez	a2,80001d44 <growproc+0x26>
      return -1;
    80001d74:	557d                	li	a0,-1
    80001d76:	bfe1                	j	80001d4e <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d78:	9e25                	addw	a2,a2,s1
    80001d7a:	1602                	slli	a2,a2,0x20
    80001d7c:	9201                	srli	a2,a2,0x20
    80001d7e:	1582                	slli	a1,a1,0x20
    80001d80:	9181                	srli	a1,a1,0x20
    80001d82:	6928                	ld	a0,80(a0)
    80001d84:	fffff097          	auipc	ra,0xfffff
    80001d88:	664080e7          	jalr	1636(ra) # 800013e8 <uvmdealloc>
    80001d8c:	0005061b          	sext.w	a2,a0
    80001d90:	bf55                	j	80001d44 <growproc+0x26>

0000000080001d92 <fork>:
{
    80001d92:	7139                	addi	sp,sp,-64
    80001d94:	fc06                	sd	ra,56(sp)
    80001d96:	f822                	sd	s0,48(sp)
    80001d98:	f426                	sd	s1,40(sp)
    80001d9a:	f04a                	sd	s2,32(sp)
    80001d9c:	ec4e                	sd	s3,24(sp)
    80001d9e:	e852                	sd	s4,16(sp)
    80001da0:	e456                	sd	s5,8(sp)
    80001da2:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001da4:	00000097          	auipc	ra,0x0
    80001da8:	c1c080e7          	jalr	-996(ra) # 800019c0 <myproc>
    80001dac:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001dae:	00000097          	auipc	ra,0x0
    80001db2:	e1c080e7          	jalr	-484(ra) # 80001bca <allocproc>
    80001db6:	10050c63          	beqz	a0,80001ece <fork+0x13c>
    80001dba:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001dbc:	048ab603          	ld	a2,72(s5)
    80001dc0:	692c                	ld	a1,80(a0)
    80001dc2:	050ab503          	ld	a0,80(s5)
    80001dc6:	fffff097          	auipc	ra,0xfffff
    80001dca:	7b6080e7          	jalr	1974(ra) # 8000157c <uvmcopy>
    80001dce:	04054863          	bltz	a0,80001e1e <fork+0x8c>
  np->sz = p->sz;
    80001dd2:	048ab783          	ld	a5,72(s5)
    80001dd6:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001dda:	058ab683          	ld	a3,88(s5)
    80001dde:	87b6                	mv	a5,a3
    80001de0:	058a3703          	ld	a4,88(s4)
    80001de4:	12068693          	addi	a3,a3,288
    80001de8:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001dec:	6788                	ld	a0,8(a5)
    80001dee:	6b8c                	ld	a1,16(a5)
    80001df0:	6f90                	ld	a2,24(a5)
    80001df2:	01073023          	sd	a6,0(a4)
    80001df6:	e708                	sd	a0,8(a4)
    80001df8:	eb0c                	sd	a1,16(a4)
    80001dfa:	ef10                	sd	a2,24(a4)
    80001dfc:	02078793          	addi	a5,a5,32
    80001e00:	02070713          	addi	a4,a4,32
    80001e04:	fed792e3          	bne	a5,a3,80001de8 <fork+0x56>
  np->trapframe->a0 = 0;
    80001e08:	058a3783          	ld	a5,88(s4)
    80001e0c:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001e10:	0d0a8493          	addi	s1,s5,208
    80001e14:	0d0a0913          	addi	s2,s4,208
    80001e18:	150a8993          	addi	s3,s5,336
    80001e1c:	a00d                	j	80001e3e <fork+0xac>
    freeproc(np);
    80001e1e:	8552                	mv	a0,s4
    80001e20:	00000097          	auipc	ra,0x0
    80001e24:	d52080e7          	jalr	-686(ra) # 80001b72 <freeproc>
    release(&np->lock);
    80001e28:	8552                	mv	a0,s4
    80001e2a:	fffff097          	auipc	ra,0xfffff
    80001e2e:	e4c080e7          	jalr	-436(ra) # 80000c76 <release>
    return -1;
    80001e32:	597d                	li	s2,-1
    80001e34:	a059                	j	80001eba <fork+0x128>
  for(i = 0; i < NOFILE; i++)
    80001e36:	04a1                	addi	s1,s1,8
    80001e38:	0921                	addi	s2,s2,8
    80001e3a:	01348b63          	beq	s1,s3,80001e50 <fork+0xbe>
    if(p->ofile[i])
    80001e3e:	6088                	ld	a0,0(s1)
    80001e40:	d97d                	beqz	a0,80001e36 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e42:	00003097          	auipc	ra,0x3
    80001e46:	818080e7          	jalr	-2024(ra) # 8000465a <filedup>
    80001e4a:	00a93023          	sd	a0,0(s2)
    80001e4e:	b7e5                	j	80001e36 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e50:	150ab503          	ld	a0,336(s5)
    80001e54:	00002097          	auipc	ra,0x2
    80001e58:	81e080e7          	jalr	-2018(ra) # 80003672 <idup>
    80001e5c:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e60:	4641                	li	a2,16
    80001e62:	158a8593          	addi	a1,s5,344
    80001e66:	158a0513          	addi	a0,s4,344
    80001e6a:	fffff097          	auipc	ra,0xfffff
    80001e6e:	fa6080e7          	jalr	-90(ra) # 80000e10 <safestrcpy>
  pid = np->pid;
    80001e72:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001e76:	8552                	mv	a0,s4
    80001e78:	fffff097          	auipc	ra,0xfffff
    80001e7c:	dfe080e7          	jalr	-514(ra) # 80000c76 <release>
  acquire(&wait_lock);
    80001e80:	0000f497          	auipc	s1,0xf
    80001e84:	43848493          	addi	s1,s1,1080 # 800112b8 <wait_lock>
    80001e88:	8526                	mv	a0,s1
    80001e8a:	fffff097          	auipc	ra,0xfffff
    80001e8e:	d38080e7          	jalr	-712(ra) # 80000bc2 <acquire>
  np->parent = p;
    80001e92:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001e96:	8526                	mv	a0,s1
    80001e98:	fffff097          	auipc	ra,0xfffff
    80001e9c:	dde080e7          	jalr	-546(ra) # 80000c76 <release>
  acquire(&np->lock);
    80001ea0:	8552                	mv	a0,s4
    80001ea2:	fffff097          	auipc	ra,0xfffff
    80001ea6:	d20080e7          	jalr	-736(ra) # 80000bc2 <acquire>
  np->state = RUNNABLE;
    80001eaa:	478d                	li	a5,3
    80001eac:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001eb0:	8552                	mv	a0,s4
    80001eb2:	fffff097          	auipc	ra,0xfffff
    80001eb6:	dc4080e7          	jalr	-572(ra) # 80000c76 <release>
}
    80001eba:	854a                	mv	a0,s2
    80001ebc:	70e2                	ld	ra,56(sp)
    80001ebe:	7442                	ld	s0,48(sp)
    80001ec0:	74a2                	ld	s1,40(sp)
    80001ec2:	7902                	ld	s2,32(sp)
    80001ec4:	69e2                	ld	s3,24(sp)
    80001ec6:	6a42                	ld	s4,16(sp)
    80001ec8:	6aa2                	ld	s5,8(sp)
    80001eca:	6121                	addi	sp,sp,64
    80001ecc:	8082                	ret
    return -1;
    80001ece:	597d                	li	s2,-1
    80001ed0:	b7ed                	j	80001eba <fork+0x128>

0000000080001ed2 <scheduler>:
{
    80001ed2:	7139                	addi	sp,sp,-64
    80001ed4:	fc06                	sd	ra,56(sp)
    80001ed6:	f822                	sd	s0,48(sp)
    80001ed8:	f426                	sd	s1,40(sp)
    80001eda:	f04a                	sd	s2,32(sp)
    80001edc:	ec4e                	sd	s3,24(sp)
    80001ede:	e852                	sd	s4,16(sp)
    80001ee0:	e456                	sd	s5,8(sp)
    80001ee2:	e05a                	sd	s6,0(sp)
    80001ee4:	0080                	addi	s0,sp,64
    80001ee6:	8792                	mv	a5,tp
  int id = r_tp();
    80001ee8:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001eea:	00779a93          	slli	s5,a5,0x7
    80001eee:	0000f717          	auipc	a4,0xf
    80001ef2:	3b270713          	addi	a4,a4,946 # 800112a0 <pid_lock>
    80001ef6:	9756                	add	a4,a4,s5
    80001ef8:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001efc:	0000f717          	auipc	a4,0xf
    80001f00:	3dc70713          	addi	a4,a4,988 # 800112d8 <cpus+0x8>
    80001f04:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001f06:	498d                	li	s3,3
        p->state = RUNNING;
    80001f08:	4b11                	li	s6,4
        c->proc = p;
    80001f0a:	079e                	slli	a5,a5,0x7
    80001f0c:	0000fa17          	auipc	s4,0xf
    80001f10:	394a0a13          	addi	s4,s4,916 # 800112a0 <pid_lock>
    80001f14:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f16:	00015917          	auipc	s2,0x15
    80001f1a:	1ba90913          	addi	s2,s2,442 # 800170d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f1e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f22:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f26:	10079073          	csrw	sstatus,a5
    80001f2a:	0000f497          	auipc	s1,0xf
    80001f2e:	7a648493          	addi	s1,s1,1958 # 800116d0 <proc>
    80001f32:	a811                	j	80001f46 <scheduler+0x74>
      release(&p->lock);
    80001f34:	8526                	mv	a0,s1
    80001f36:	fffff097          	auipc	ra,0xfffff
    80001f3a:	d40080e7          	jalr	-704(ra) # 80000c76 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f3e:	16848493          	addi	s1,s1,360
    80001f42:	fd248ee3          	beq	s1,s2,80001f1e <scheduler+0x4c>
      acquire(&p->lock);
    80001f46:	8526                	mv	a0,s1
    80001f48:	fffff097          	auipc	ra,0xfffff
    80001f4c:	c7a080e7          	jalr	-902(ra) # 80000bc2 <acquire>
      if(p->state == RUNNABLE) {
    80001f50:	4c9c                	lw	a5,24(s1)
    80001f52:	ff3791e3          	bne	a5,s3,80001f34 <scheduler+0x62>
        p->state = RUNNING;
    80001f56:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f5a:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f5e:	06048593          	addi	a1,s1,96
    80001f62:	8556                	mv	a0,s5
    80001f64:	00000097          	auipc	ra,0x0
    80001f68:	61e080e7          	jalr	1566(ra) # 80002582 <swtch>
        c->proc = 0;
    80001f6c:	020a3823          	sd	zero,48(s4)
    80001f70:	b7d1                	j	80001f34 <scheduler+0x62>

0000000080001f72 <sched>:
{
    80001f72:	7179                	addi	sp,sp,-48
    80001f74:	f406                	sd	ra,40(sp)
    80001f76:	f022                	sd	s0,32(sp)
    80001f78:	ec26                	sd	s1,24(sp)
    80001f7a:	e84a                	sd	s2,16(sp)
    80001f7c:	e44e                	sd	s3,8(sp)
    80001f7e:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f80:	00000097          	auipc	ra,0x0
    80001f84:	a40080e7          	jalr	-1472(ra) # 800019c0 <myproc>
    80001f88:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001f8a:	fffff097          	auipc	ra,0xfffff
    80001f8e:	bbe080e7          	jalr	-1090(ra) # 80000b48 <holding>
    80001f92:	c93d                	beqz	a0,80002008 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f94:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001f96:	2781                	sext.w	a5,a5
    80001f98:	079e                	slli	a5,a5,0x7
    80001f9a:	0000f717          	auipc	a4,0xf
    80001f9e:	30670713          	addi	a4,a4,774 # 800112a0 <pid_lock>
    80001fa2:	97ba                	add	a5,a5,a4
    80001fa4:	0a87a703          	lw	a4,168(a5)
    80001fa8:	4785                	li	a5,1
    80001faa:	06f71763          	bne	a4,a5,80002018 <sched+0xa6>
  if(p->state == RUNNING)
    80001fae:	4c98                	lw	a4,24(s1)
    80001fb0:	4791                	li	a5,4
    80001fb2:	06f70b63          	beq	a4,a5,80002028 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fb6:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001fba:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001fbc:	efb5                	bnez	a5,80002038 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fbe:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001fc0:	0000f917          	auipc	s2,0xf
    80001fc4:	2e090913          	addi	s2,s2,736 # 800112a0 <pid_lock>
    80001fc8:	2781                	sext.w	a5,a5
    80001fca:	079e                	slli	a5,a5,0x7
    80001fcc:	97ca                	add	a5,a5,s2
    80001fce:	0ac7a983          	lw	s3,172(a5)
    80001fd2:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001fd4:	2781                	sext.w	a5,a5
    80001fd6:	079e                	slli	a5,a5,0x7
    80001fd8:	0000f597          	auipc	a1,0xf
    80001fdc:	30058593          	addi	a1,a1,768 # 800112d8 <cpus+0x8>
    80001fe0:	95be                	add	a1,a1,a5
    80001fe2:	06048513          	addi	a0,s1,96
    80001fe6:	00000097          	auipc	ra,0x0
    80001fea:	59c080e7          	jalr	1436(ra) # 80002582 <swtch>
    80001fee:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001ff0:	2781                	sext.w	a5,a5
    80001ff2:	079e                	slli	a5,a5,0x7
    80001ff4:	97ca                	add	a5,a5,s2
    80001ff6:	0b37a623          	sw	s3,172(a5)
}
    80001ffa:	70a2                	ld	ra,40(sp)
    80001ffc:	7402                	ld	s0,32(sp)
    80001ffe:	64e2                	ld	s1,24(sp)
    80002000:	6942                	ld	s2,16(sp)
    80002002:	69a2                	ld	s3,8(sp)
    80002004:	6145                	addi	sp,sp,48
    80002006:	8082                	ret
    panic("sched p->lock");
    80002008:	00006517          	auipc	a0,0x6
    8000200c:	1f850513          	addi	a0,a0,504 # 80008200 <digits+0x1c0>
    80002010:	ffffe097          	auipc	ra,0xffffe
    80002014:	51a080e7          	jalr	1306(ra) # 8000052a <panic>
    panic("sched locks");
    80002018:	00006517          	auipc	a0,0x6
    8000201c:	1f850513          	addi	a0,a0,504 # 80008210 <digits+0x1d0>
    80002020:	ffffe097          	auipc	ra,0xffffe
    80002024:	50a080e7          	jalr	1290(ra) # 8000052a <panic>
    panic("sched running");
    80002028:	00006517          	auipc	a0,0x6
    8000202c:	1f850513          	addi	a0,a0,504 # 80008220 <digits+0x1e0>
    80002030:	ffffe097          	auipc	ra,0xffffe
    80002034:	4fa080e7          	jalr	1274(ra) # 8000052a <panic>
    panic("sched interruptible");
    80002038:	00006517          	auipc	a0,0x6
    8000203c:	1f850513          	addi	a0,a0,504 # 80008230 <digits+0x1f0>
    80002040:	ffffe097          	auipc	ra,0xffffe
    80002044:	4ea080e7          	jalr	1258(ra) # 8000052a <panic>

0000000080002048 <yield>:
{
    80002048:	1101                	addi	sp,sp,-32
    8000204a:	ec06                	sd	ra,24(sp)
    8000204c:	e822                	sd	s0,16(sp)
    8000204e:	e426                	sd	s1,8(sp)
    80002050:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002052:	00000097          	auipc	ra,0x0
    80002056:	96e080e7          	jalr	-1682(ra) # 800019c0 <myproc>
    8000205a:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000205c:	fffff097          	auipc	ra,0xfffff
    80002060:	b66080e7          	jalr	-1178(ra) # 80000bc2 <acquire>
  p->state = RUNNABLE;
    80002064:	478d                	li	a5,3
    80002066:	cc9c                	sw	a5,24(s1)
  sched();
    80002068:	00000097          	auipc	ra,0x0
    8000206c:	f0a080e7          	jalr	-246(ra) # 80001f72 <sched>
  release(&p->lock);
    80002070:	8526                	mv	a0,s1
    80002072:	fffff097          	auipc	ra,0xfffff
    80002076:	c04080e7          	jalr	-1020(ra) # 80000c76 <release>
}
    8000207a:	60e2                	ld	ra,24(sp)
    8000207c:	6442                	ld	s0,16(sp)
    8000207e:	64a2                	ld	s1,8(sp)
    80002080:	6105                	addi	sp,sp,32
    80002082:	8082                	ret

0000000080002084 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002084:	7179                	addi	sp,sp,-48
    80002086:	f406                	sd	ra,40(sp)
    80002088:	f022                	sd	s0,32(sp)
    8000208a:	ec26                	sd	s1,24(sp)
    8000208c:	e84a                	sd	s2,16(sp)
    8000208e:	e44e                	sd	s3,8(sp)
    80002090:	1800                	addi	s0,sp,48
    80002092:	89aa                	mv	s3,a0
    80002094:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002096:	00000097          	auipc	ra,0x0
    8000209a:	92a080e7          	jalr	-1750(ra) # 800019c0 <myproc>
    8000209e:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    800020a0:	fffff097          	auipc	ra,0xfffff
    800020a4:	b22080e7          	jalr	-1246(ra) # 80000bc2 <acquire>
  release(lk);
    800020a8:	854a                	mv	a0,s2
    800020aa:	fffff097          	auipc	ra,0xfffff
    800020ae:	bcc080e7          	jalr	-1076(ra) # 80000c76 <release>

  // Go to sleep.
  p->chan = chan;
    800020b2:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800020b6:	4789                	li	a5,2
    800020b8:	cc9c                	sw	a5,24(s1)

  sched();
    800020ba:	00000097          	auipc	ra,0x0
    800020be:	eb8080e7          	jalr	-328(ra) # 80001f72 <sched>

  // Tidy up.
  p->chan = 0;
    800020c2:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800020c6:	8526                	mv	a0,s1
    800020c8:	fffff097          	auipc	ra,0xfffff
    800020cc:	bae080e7          	jalr	-1106(ra) # 80000c76 <release>
  acquire(lk);
    800020d0:	854a                	mv	a0,s2
    800020d2:	fffff097          	auipc	ra,0xfffff
    800020d6:	af0080e7          	jalr	-1296(ra) # 80000bc2 <acquire>
}
    800020da:	70a2                	ld	ra,40(sp)
    800020dc:	7402                	ld	s0,32(sp)
    800020de:	64e2                	ld	s1,24(sp)
    800020e0:	6942                	ld	s2,16(sp)
    800020e2:	69a2                	ld	s3,8(sp)
    800020e4:	6145                	addi	sp,sp,48
    800020e6:	8082                	ret

00000000800020e8 <wait>:
{
    800020e8:	715d                	addi	sp,sp,-80
    800020ea:	e486                	sd	ra,72(sp)
    800020ec:	e0a2                	sd	s0,64(sp)
    800020ee:	fc26                	sd	s1,56(sp)
    800020f0:	f84a                	sd	s2,48(sp)
    800020f2:	f44e                	sd	s3,40(sp)
    800020f4:	f052                	sd	s4,32(sp)
    800020f6:	ec56                	sd	s5,24(sp)
    800020f8:	e85a                	sd	s6,16(sp)
    800020fa:	e45e                	sd	s7,8(sp)
    800020fc:	e062                	sd	s8,0(sp)
    800020fe:	0880                	addi	s0,sp,80
    80002100:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002102:	00000097          	auipc	ra,0x0
    80002106:	8be080e7          	jalr	-1858(ra) # 800019c0 <myproc>
    8000210a:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000210c:	0000f517          	auipc	a0,0xf
    80002110:	1ac50513          	addi	a0,a0,428 # 800112b8 <wait_lock>
    80002114:	fffff097          	auipc	ra,0xfffff
    80002118:	aae080e7          	jalr	-1362(ra) # 80000bc2 <acquire>
    havekids = 0;
    8000211c:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    8000211e:	4a15                	li	s4,5
        havekids = 1;
    80002120:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    80002122:	00015997          	auipc	s3,0x15
    80002126:	fae98993          	addi	s3,s3,-82 # 800170d0 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000212a:	0000fc17          	auipc	s8,0xf
    8000212e:	18ec0c13          	addi	s8,s8,398 # 800112b8 <wait_lock>
    havekids = 0;
    80002132:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002134:	0000f497          	auipc	s1,0xf
    80002138:	59c48493          	addi	s1,s1,1436 # 800116d0 <proc>
    8000213c:	a0bd                	j	800021aa <wait+0xc2>
          pid = np->pid;
    8000213e:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002142:	000b0e63          	beqz	s6,8000215e <wait+0x76>
    80002146:	4691                	li	a3,4
    80002148:	02c48613          	addi	a2,s1,44
    8000214c:	85da                	mv	a1,s6
    8000214e:	05093503          	ld	a0,80(s2)
    80002152:	fffff097          	auipc	ra,0xfffff
    80002156:	52e080e7          	jalr	1326(ra) # 80001680 <copyout>
    8000215a:	02054563          	bltz	a0,80002184 <wait+0x9c>
          freeproc(np);
    8000215e:	8526                	mv	a0,s1
    80002160:	00000097          	auipc	ra,0x0
    80002164:	a12080e7          	jalr	-1518(ra) # 80001b72 <freeproc>
          release(&np->lock);
    80002168:	8526                	mv	a0,s1
    8000216a:	fffff097          	auipc	ra,0xfffff
    8000216e:	b0c080e7          	jalr	-1268(ra) # 80000c76 <release>
          release(&wait_lock);
    80002172:	0000f517          	auipc	a0,0xf
    80002176:	14650513          	addi	a0,a0,326 # 800112b8 <wait_lock>
    8000217a:	fffff097          	auipc	ra,0xfffff
    8000217e:	afc080e7          	jalr	-1284(ra) # 80000c76 <release>
          return pid;
    80002182:	a09d                	j	800021e8 <wait+0x100>
            release(&np->lock);
    80002184:	8526                	mv	a0,s1
    80002186:	fffff097          	auipc	ra,0xfffff
    8000218a:	af0080e7          	jalr	-1296(ra) # 80000c76 <release>
            release(&wait_lock);
    8000218e:	0000f517          	auipc	a0,0xf
    80002192:	12a50513          	addi	a0,a0,298 # 800112b8 <wait_lock>
    80002196:	fffff097          	auipc	ra,0xfffff
    8000219a:	ae0080e7          	jalr	-1312(ra) # 80000c76 <release>
            return -1;
    8000219e:	59fd                	li	s3,-1
    800021a0:	a0a1                	j	800021e8 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    800021a2:	16848493          	addi	s1,s1,360
    800021a6:	03348463          	beq	s1,s3,800021ce <wait+0xe6>
      if(np->parent == p){
    800021aa:	7c9c                	ld	a5,56(s1)
    800021ac:	ff279be3          	bne	a5,s2,800021a2 <wait+0xba>
        acquire(&np->lock);
    800021b0:	8526                	mv	a0,s1
    800021b2:	fffff097          	auipc	ra,0xfffff
    800021b6:	a10080e7          	jalr	-1520(ra) # 80000bc2 <acquire>
        if(np->state == ZOMBIE){
    800021ba:	4c9c                	lw	a5,24(s1)
    800021bc:	f94781e3          	beq	a5,s4,8000213e <wait+0x56>
        release(&np->lock);
    800021c0:	8526                	mv	a0,s1
    800021c2:	fffff097          	auipc	ra,0xfffff
    800021c6:	ab4080e7          	jalr	-1356(ra) # 80000c76 <release>
        havekids = 1;
    800021ca:	8756                	mv	a4,s5
    800021cc:	bfd9                	j	800021a2 <wait+0xba>
    if(!havekids || p->killed){
    800021ce:	c701                	beqz	a4,800021d6 <wait+0xee>
    800021d0:	02892783          	lw	a5,40(s2)
    800021d4:	c79d                	beqz	a5,80002202 <wait+0x11a>
      release(&wait_lock);
    800021d6:	0000f517          	auipc	a0,0xf
    800021da:	0e250513          	addi	a0,a0,226 # 800112b8 <wait_lock>
    800021de:	fffff097          	auipc	ra,0xfffff
    800021e2:	a98080e7          	jalr	-1384(ra) # 80000c76 <release>
      return -1;
    800021e6:	59fd                	li	s3,-1
}
    800021e8:	854e                	mv	a0,s3
    800021ea:	60a6                	ld	ra,72(sp)
    800021ec:	6406                	ld	s0,64(sp)
    800021ee:	74e2                	ld	s1,56(sp)
    800021f0:	7942                	ld	s2,48(sp)
    800021f2:	79a2                	ld	s3,40(sp)
    800021f4:	7a02                	ld	s4,32(sp)
    800021f6:	6ae2                	ld	s5,24(sp)
    800021f8:	6b42                	ld	s6,16(sp)
    800021fa:	6ba2                	ld	s7,8(sp)
    800021fc:	6c02                	ld	s8,0(sp)
    800021fe:	6161                	addi	sp,sp,80
    80002200:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002202:	85e2                	mv	a1,s8
    80002204:	854a                	mv	a0,s2
    80002206:	00000097          	auipc	ra,0x0
    8000220a:	e7e080e7          	jalr	-386(ra) # 80002084 <sleep>
    havekids = 0;
    8000220e:	b715                	j	80002132 <wait+0x4a>

0000000080002210 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    80002210:	7139                	addi	sp,sp,-64
    80002212:	fc06                	sd	ra,56(sp)
    80002214:	f822                	sd	s0,48(sp)
    80002216:	f426                	sd	s1,40(sp)
    80002218:	f04a                	sd	s2,32(sp)
    8000221a:	ec4e                	sd	s3,24(sp)
    8000221c:	e852                	sd	s4,16(sp)
    8000221e:	e456                	sd	s5,8(sp)
    80002220:	0080                	addi	s0,sp,64
    80002222:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80002224:	0000f497          	auipc	s1,0xf
    80002228:	4ac48493          	addi	s1,s1,1196 # 800116d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    8000222c:	4989                	li	s3,2
        p->state = RUNNABLE;
    8000222e:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80002230:	00015917          	auipc	s2,0x15
    80002234:	ea090913          	addi	s2,s2,-352 # 800170d0 <tickslock>
    80002238:	a811                	j	8000224c <wakeup+0x3c>
      }
      release(&p->lock);
    8000223a:	8526                	mv	a0,s1
    8000223c:	fffff097          	auipc	ra,0xfffff
    80002240:	a3a080e7          	jalr	-1478(ra) # 80000c76 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002244:	16848493          	addi	s1,s1,360
    80002248:	03248663          	beq	s1,s2,80002274 <wakeup+0x64>
    if(p != myproc()){
    8000224c:	fffff097          	auipc	ra,0xfffff
    80002250:	774080e7          	jalr	1908(ra) # 800019c0 <myproc>
    80002254:	fea488e3          	beq	s1,a0,80002244 <wakeup+0x34>
      acquire(&p->lock);
    80002258:	8526                	mv	a0,s1
    8000225a:	fffff097          	auipc	ra,0xfffff
    8000225e:	968080e7          	jalr	-1688(ra) # 80000bc2 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002262:	4c9c                	lw	a5,24(s1)
    80002264:	fd379be3          	bne	a5,s3,8000223a <wakeup+0x2a>
    80002268:	709c                	ld	a5,32(s1)
    8000226a:	fd4798e3          	bne	a5,s4,8000223a <wakeup+0x2a>
        p->state = RUNNABLE;
    8000226e:	0154ac23          	sw	s5,24(s1)
    80002272:	b7e1                	j	8000223a <wakeup+0x2a>
    }
  }
}
    80002274:	70e2                	ld	ra,56(sp)
    80002276:	7442                	ld	s0,48(sp)
    80002278:	74a2                	ld	s1,40(sp)
    8000227a:	7902                	ld	s2,32(sp)
    8000227c:	69e2                	ld	s3,24(sp)
    8000227e:	6a42                	ld	s4,16(sp)
    80002280:	6aa2                	ld	s5,8(sp)
    80002282:	6121                	addi	sp,sp,64
    80002284:	8082                	ret

0000000080002286 <reparent>:
{
    80002286:	7179                	addi	sp,sp,-48
    80002288:	f406                	sd	ra,40(sp)
    8000228a:	f022                	sd	s0,32(sp)
    8000228c:	ec26                	sd	s1,24(sp)
    8000228e:	e84a                	sd	s2,16(sp)
    80002290:	e44e                	sd	s3,8(sp)
    80002292:	e052                	sd	s4,0(sp)
    80002294:	1800                	addi	s0,sp,48
    80002296:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002298:	0000f497          	auipc	s1,0xf
    8000229c:	43848493          	addi	s1,s1,1080 # 800116d0 <proc>
      pp->parent = initproc;
    800022a0:	00007a17          	auipc	s4,0x7
    800022a4:	d88a0a13          	addi	s4,s4,-632 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800022a8:	00015997          	auipc	s3,0x15
    800022ac:	e2898993          	addi	s3,s3,-472 # 800170d0 <tickslock>
    800022b0:	a029                	j	800022ba <reparent+0x34>
    800022b2:	16848493          	addi	s1,s1,360
    800022b6:	01348d63          	beq	s1,s3,800022d0 <reparent+0x4a>
    if(pp->parent == p){
    800022ba:	7c9c                	ld	a5,56(s1)
    800022bc:	ff279be3          	bne	a5,s2,800022b2 <reparent+0x2c>
      pp->parent = initproc;
    800022c0:	000a3503          	ld	a0,0(s4)
    800022c4:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800022c6:	00000097          	auipc	ra,0x0
    800022ca:	f4a080e7          	jalr	-182(ra) # 80002210 <wakeup>
    800022ce:	b7d5                	j	800022b2 <reparent+0x2c>
}
    800022d0:	70a2                	ld	ra,40(sp)
    800022d2:	7402                	ld	s0,32(sp)
    800022d4:	64e2                	ld	s1,24(sp)
    800022d6:	6942                	ld	s2,16(sp)
    800022d8:	69a2                	ld	s3,8(sp)
    800022da:	6a02                	ld	s4,0(sp)
    800022dc:	6145                	addi	sp,sp,48
    800022de:	8082                	ret

00000000800022e0 <exit>:
{
    800022e0:	7179                	addi	sp,sp,-48
    800022e2:	f406                	sd	ra,40(sp)
    800022e4:	f022                	sd	s0,32(sp)
    800022e6:	ec26                	sd	s1,24(sp)
    800022e8:	e84a                	sd	s2,16(sp)
    800022ea:	e44e                	sd	s3,8(sp)
    800022ec:	e052                	sd	s4,0(sp)
    800022ee:	1800                	addi	s0,sp,48
    800022f0:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800022f2:	fffff097          	auipc	ra,0xfffff
    800022f6:	6ce080e7          	jalr	1742(ra) # 800019c0 <myproc>
    800022fa:	89aa                	mv	s3,a0
  if(p == initproc)
    800022fc:	00007797          	auipc	a5,0x7
    80002300:	d2c7b783          	ld	a5,-724(a5) # 80009028 <initproc>
    80002304:	0d050493          	addi	s1,a0,208
    80002308:	15050913          	addi	s2,a0,336
    8000230c:	02a79363          	bne	a5,a0,80002332 <exit+0x52>
    panic("init exiting");
    80002310:	00006517          	auipc	a0,0x6
    80002314:	f3850513          	addi	a0,a0,-200 # 80008248 <digits+0x208>
    80002318:	ffffe097          	auipc	ra,0xffffe
    8000231c:	212080e7          	jalr	530(ra) # 8000052a <panic>
      fileclose(f);
    80002320:	00002097          	auipc	ra,0x2
    80002324:	38c080e7          	jalr	908(ra) # 800046ac <fileclose>
      p->ofile[fd] = 0;
    80002328:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    8000232c:	04a1                	addi	s1,s1,8
    8000232e:	01248563          	beq	s1,s2,80002338 <exit+0x58>
    if(p->ofile[fd]){
    80002332:	6088                	ld	a0,0(s1)
    80002334:	f575                	bnez	a0,80002320 <exit+0x40>
    80002336:	bfdd                	j	8000232c <exit+0x4c>
  begin_op();
    80002338:	00002097          	auipc	ra,0x2
    8000233c:	ea8080e7          	jalr	-344(ra) # 800041e0 <begin_op>
  iput(p->cwd);
    80002340:	1509b503          	ld	a0,336(s3)
    80002344:	00001097          	auipc	ra,0x1
    80002348:	5e8080e7          	jalr	1512(ra) # 8000392c <iput>
  end_op();
    8000234c:	00002097          	auipc	ra,0x2
    80002350:	f14080e7          	jalr	-236(ra) # 80004260 <end_op>
  p->cwd = 0;
    80002354:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002358:	0000f497          	auipc	s1,0xf
    8000235c:	f6048493          	addi	s1,s1,-160 # 800112b8 <wait_lock>
    80002360:	8526                	mv	a0,s1
    80002362:	fffff097          	auipc	ra,0xfffff
    80002366:	860080e7          	jalr	-1952(ra) # 80000bc2 <acquire>
  reparent(p);
    8000236a:	854e                	mv	a0,s3
    8000236c:	00000097          	auipc	ra,0x0
    80002370:	f1a080e7          	jalr	-230(ra) # 80002286 <reparent>
  wakeup(p->parent);
    80002374:	0389b503          	ld	a0,56(s3)
    80002378:	00000097          	auipc	ra,0x0
    8000237c:	e98080e7          	jalr	-360(ra) # 80002210 <wakeup>
  acquire(&p->lock);
    80002380:	854e                	mv	a0,s3
    80002382:	fffff097          	auipc	ra,0xfffff
    80002386:	840080e7          	jalr	-1984(ra) # 80000bc2 <acquire>
  p->xstate = status;
    8000238a:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    8000238e:	4795                	li	a5,5
    80002390:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002394:	8526                	mv	a0,s1
    80002396:	fffff097          	auipc	ra,0xfffff
    8000239a:	8e0080e7          	jalr	-1824(ra) # 80000c76 <release>
  sched();
    8000239e:	00000097          	auipc	ra,0x0
    800023a2:	bd4080e7          	jalr	-1068(ra) # 80001f72 <sched>
  panic("zombie exit");
    800023a6:	00006517          	auipc	a0,0x6
    800023aa:	eb250513          	addi	a0,a0,-334 # 80008258 <digits+0x218>
    800023ae:	ffffe097          	auipc	ra,0xffffe
    800023b2:	17c080e7          	jalr	380(ra) # 8000052a <panic>

00000000800023b6 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800023b6:	7179                	addi	sp,sp,-48
    800023b8:	f406                	sd	ra,40(sp)
    800023ba:	f022                	sd	s0,32(sp)
    800023bc:	ec26                	sd	s1,24(sp)
    800023be:	e84a                	sd	s2,16(sp)
    800023c0:	e44e                	sd	s3,8(sp)
    800023c2:	1800                	addi	s0,sp,48
    800023c4:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800023c6:	0000f497          	auipc	s1,0xf
    800023ca:	30a48493          	addi	s1,s1,778 # 800116d0 <proc>
    800023ce:	00015997          	auipc	s3,0x15
    800023d2:	d0298993          	addi	s3,s3,-766 # 800170d0 <tickslock>
    acquire(&p->lock);
    800023d6:	8526                	mv	a0,s1
    800023d8:	ffffe097          	auipc	ra,0xffffe
    800023dc:	7ea080e7          	jalr	2026(ra) # 80000bc2 <acquire>
    if(p->pid == pid){
    800023e0:	589c                	lw	a5,48(s1)
    800023e2:	01278d63          	beq	a5,s2,800023fc <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800023e6:	8526                	mv	a0,s1
    800023e8:	fffff097          	auipc	ra,0xfffff
    800023ec:	88e080e7          	jalr	-1906(ra) # 80000c76 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800023f0:	16848493          	addi	s1,s1,360
    800023f4:	ff3491e3          	bne	s1,s3,800023d6 <kill+0x20>
  }
  return -1;
    800023f8:	557d                	li	a0,-1
    800023fa:	a829                	j	80002414 <kill+0x5e>
      p->killed = 1;
    800023fc:	4785                	li	a5,1
    800023fe:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002400:	4c98                	lw	a4,24(s1)
    80002402:	4789                	li	a5,2
    80002404:	00f70f63          	beq	a4,a5,80002422 <kill+0x6c>
      release(&p->lock);
    80002408:	8526                	mv	a0,s1
    8000240a:	fffff097          	auipc	ra,0xfffff
    8000240e:	86c080e7          	jalr	-1940(ra) # 80000c76 <release>
      return 0;
    80002412:	4501                	li	a0,0
}
    80002414:	70a2                	ld	ra,40(sp)
    80002416:	7402                	ld	s0,32(sp)
    80002418:	64e2                	ld	s1,24(sp)
    8000241a:	6942                	ld	s2,16(sp)
    8000241c:	69a2                	ld	s3,8(sp)
    8000241e:	6145                	addi	sp,sp,48
    80002420:	8082                	ret
        p->state = RUNNABLE;
    80002422:	478d                	li	a5,3
    80002424:	cc9c                	sw	a5,24(s1)
    80002426:	b7cd                	j	80002408 <kill+0x52>

0000000080002428 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002428:	7179                	addi	sp,sp,-48
    8000242a:	f406                	sd	ra,40(sp)
    8000242c:	f022                	sd	s0,32(sp)
    8000242e:	ec26                	sd	s1,24(sp)
    80002430:	e84a                	sd	s2,16(sp)
    80002432:	e44e                	sd	s3,8(sp)
    80002434:	e052                	sd	s4,0(sp)
    80002436:	1800                	addi	s0,sp,48
    80002438:	84aa                	mv	s1,a0
    8000243a:	892e                	mv	s2,a1
    8000243c:	89b2                	mv	s3,a2
    8000243e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002440:	fffff097          	auipc	ra,0xfffff
    80002444:	580080e7          	jalr	1408(ra) # 800019c0 <myproc>
  if(user_dst){
    80002448:	c08d                	beqz	s1,8000246a <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000244a:	86d2                	mv	a3,s4
    8000244c:	864e                	mv	a2,s3
    8000244e:	85ca                	mv	a1,s2
    80002450:	6928                	ld	a0,80(a0)
    80002452:	fffff097          	auipc	ra,0xfffff
    80002456:	22e080e7          	jalr	558(ra) # 80001680 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000245a:	70a2                	ld	ra,40(sp)
    8000245c:	7402                	ld	s0,32(sp)
    8000245e:	64e2                	ld	s1,24(sp)
    80002460:	6942                	ld	s2,16(sp)
    80002462:	69a2                	ld	s3,8(sp)
    80002464:	6a02                	ld	s4,0(sp)
    80002466:	6145                	addi	sp,sp,48
    80002468:	8082                	ret
    memmove((char *)dst, src, len);
    8000246a:	000a061b          	sext.w	a2,s4
    8000246e:	85ce                	mv	a1,s3
    80002470:	854a                	mv	a0,s2
    80002472:	fffff097          	auipc	ra,0xfffff
    80002476:	8a8080e7          	jalr	-1880(ra) # 80000d1a <memmove>
    return 0;
    8000247a:	8526                	mv	a0,s1
    8000247c:	bff9                	j	8000245a <either_copyout+0x32>

000000008000247e <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000247e:	7179                	addi	sp,sp,-48
    80002480:	f406                	sd	ra,40(sp)
    80002482:	f022                	sd	s0,32(sp)
    80002484:	ec26                	sd	s1,24(sp)
    80002486:	e84a                	sd	s2,16(sp)
    80002488:	e44e                	sd	s3,8(sp)
    8000248a:	e052                	sd	s4,0(sp)
    8000248c:	1800                	addi	s0,sp,48
    8000248e:	892a                	mv	s2,a0
    80002490:	84ae                	mv	s1,a1
    80002492:	89b2                	mv	s3,a2
    80002494:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002496:	fffff097          	auipc	ra,0xfffff
    8000249a:	52a080e7          	jalr	1322(ra) # 800019c0 <myproc>
  if(user_src){
    8000249e:	c08d                	beqz	s1,800024c0 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800024a0:	86d2                	mv	a3,s4
    800024a2:	864e                	mv	a2,s3
    800024a4:	85ca                	mv	a1,s2
    800024a6:	6928                	ld	a0,80(a0)
    800024a8:	fffff097          	auipc	ra,0xfffff
    800024ac:	264080e7          	jalr	612(ra) # 8000170c <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800024b0:	70a2                	ld	ra,40(sp)
    800024b2:	7402                	ld	s0,32(sp)
    800024b4:	64e2                	ld	s1,24(sp)
    800024b6:	6942                	ld	s2,16(sp)
    800024b8:	69a2                	ld	s3,8(sp)
    800024ba:	6a02                	ld	s4,0(sp)
    800024bc:	6145                	addi	sp,sp,48
    800024be:	8082                	ret
    memmove(dst, (char*)src, len);
    800024c0:	000a061b          	sext.w	a2,s4
    800024c4:	85ce                	mv	a1,s3
    800024c6:	854a                	mv	a0,s2
    800024c8:	fffff097          	auipc	ra,0xfffff
    800024cc:	852080e7          	jalr	-1966(ra) # 80000d1a <memmove>
    return 0;
    800024d0:	8526                	mv	a0,s1
    800024d2:	bff9                	j	800024b0 <either_copyin+0x32>

00000000800024d4 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800024d4:	715d                	addi	sp,sp,-80
    800024d6:	e486                	sd	ra,72(sp)
    800024d8:	e0a2                	sd	s0,64(sp)
    800024da:	fc26                	sd	s1,56(sp)
    800024dc:	f84a                	sd	s2,48(sp)
    800024de:	f44e                	sd	s3,40(sp)
    800024e0:	f052                	sd	s4,32(sp)
    800024e2:	ec56                	sd	s5,24(sp)
    800024e4:	e85a                	sd	s6,16(sp)
    800024e6:	e45e                	sd	s7,8(sp)
    800024e8:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800024ea:	00006517          	auipc	a0,0x6
    800024ee:	bde50513          	addi	a0,a0,-1058 # 800080c8 <digits+0x88>
    800024f2:	ffffe097          	auipc	ra,0xffffe
    800024f6:	082080e7          	jalr	130(ra) # 80000574 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800024fa:	0000f497          	auipc	s1,0xf
    800024fe:	32e48493          	addi	s1,s1,814 # 80011828 <proc+0x158>
    80002502:	00015917          	auipc	s2,0x15
    80002506:	d2690913          	addi	s2,s2,-730 # 80017228 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000250a:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    8000250c:	00006997          	auipc	s3,0x6
    80002510:	d5c98993          	addi	s3,s3,-676 # 80008268 <digits+0x228>
    printf("%d %s %s", p->pid, state, p->name);
    80002514:	00006a97          	auipc	s5,0x6
    80002518:	d5ca8a93          	addi	s5,s5,-676 # 80008270 <digits+0x230>
    printf("\n");
    8000251c:	00006a17          	auipc	s4,0x6
    80002520:	baca0a13          	addi	s4,s4,-1108 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002524:	00006b97          	auipc	s7,0x6
    80002528:	d84b8b93          	addi	s7,s7,-636 # 800082a8 <states.0>
    8000252c:	a00d                	j	8000254e <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    8000252e:	ed86a583          	lw	a1,-296(a3)
    80002532:	8556                	mv	a0,s5
    80002534:	ffffe097          	auipc	ra,0xffffe
    80002538:	040080e7          	jalr	64(ra) # 80000574 <printf>
    printf("\n");
    8000253c:	8552                	mv	a0,s4
    8000253e:	ffffe097          	auipc	ra,0xffffe
    80002542:	036080e7          	jalr	54(ra) # 80000574 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002546:	16848493          	addi	s1,s1,360
    8000254a:	03248163          	beq	s1,s2,8000256c <procdump+0x98>
    if(p->state == UNUSED)
    8000254e:	86a6                	mv	a3,s1
    80002550:	ec04a783          	lw	a5,-320(s1)
    80002554:	dbed                	beqz	a5,80002546 <procdump+0x72>
      state = "???";
    80002556:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002558:	fcfb6be3          	bltu	s6,a5,8000252e <procdump+0x5a>
    8000255c:	1782                	slli	a5,a5,0x20
    8000255e:	9381                	srli	a5,a5,0x20
    80002560:	078e                	slli	a5,a5,0x3
    80002562:	97de                	add	a5,a5,s7
    80002564:	6390                	ld	a2,0(a5)
    80002566:	f661                	bnez	a2,8000252e <procdump+0x5a>
      state = "???";
    80002568:	864e                	mv	a2,s3
    8000256a:	b7d1                	j	8000252e <procdump+0x5a>
  }
}
    8000256c:	60a6                	ld	ra,72(sp)
    8000256e:	6406                	ld	s0,64(sp)
    80002570:	74e2                	ld	s1,56(sp)
    80002572:	7942                	ld	s2,48(sp)
    80002574:	79a2                	ld	s3,40(sp)
    80002576:	7a02                	ld	s4,32(sp)
    80002578:	6ae2                	ld	s5,24(sp)
    8000257a:	6b42                	ld	s6,16(sp)
    8000257c:	6ba2                	ld	s7,8(sp)
    8000257e:	6161                	addi	sp,sp,80
    80002580:	8082                	ret

0000000080002582 <swtch>:
    80002582:	00153023          	sd	ra,0(a0)
    80002586:	00253423          	sd	sp,8(a0)
    8000258a:	e900                	sd	s0,16(a0)
    8000258c:	ed04                	sd	s1,24(a0)
    8000258e:	03253023          	sd	s2,32(a0)
    80002592:	03353423          	sd	s3,40(a0)
    80002596:	03453823          	sd	s4,48(a0)
    8000259a:	03553c23          	sd	s5,56(a0)
    8000259e:	05653023          	sd	s6,64(a0)
    800025a2:	05753423          	sd	s7,72(a0)
    800025a6:	05853823          	sd	s8,80(a0)
    800025aa:	05953c23          	sd	s9,88(a0)
    800025ae:	07a53023          	sd	s10,96(a0)
    800025b2:	07b53423          	sd	s11,104(a0)
    800025b6:	0005b083          	ld	ra,0(a1)
    800025ba:	0085b103          	ld	sp,8(a1)
    800025be:	6980                	ld	s0,16(a1)
    800025c0:	6d84                	ld	s1,24(a1)
    800025c2:	0205b903          	ld	s2,32(a1)
    800025c6:	0285b983          	ld	s3,40(a1)
    800025ca:	0305ba03          	ld	s4,48(a1)
    800025ce:	0385ba83          	ld	s5,56(a1)
    800025d2:	0405bb03          	ld	s6,64(a1)
    800025d6:	0485bb83          	ld	s7,72(a1)
    800025da:	0505bc03          	ld	s8,80(a1)
    800025de:	0585bc83          	ld	s9,88(a1)
    800025e2:	0605bd03          	ld	s10,96(a1)
    800025e6:	0685bd83          	ld	s11,104(a1)
    800025ea:	8082                	ret

00000000800025ec <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800025ec:	1141                	addi	sp,sp,-16
    800025ee:	e406                	sd	ra,8(sp)
    800025f0:	e022                	sd	s0,0(sp)
    800025f2:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800025f4:	00006597          	auipc	a1,0x6
    800025f8:	ce458593          	addi	a1,a1,-796 # 800082d8 <states.0+0x30>
    800025fc:	00015517          	auipc	a0,0x15
    80002600:	ad450513          	addi	a0,a0,-1324 # 800170d0 <tickslock>
    80002604:	ffffe097          	auipc	ra,0xffffe
    80002608:	52e080e7          	jalr	1326(ra) # 80000b32 <initlock>
}
    8000260c:	60a2                	ld	ra,8(sp)
    8000260e:	6402                	ld	s0,0(sp)
    80002610:	0141                	addi	sp,sp,16
    80002612:	8082                	ret

0000000080002614 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002614:	1141                	addi	sp,sp,-16
    80002616:	e422                	sd	s0,8(sp)
    80002618:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000261a:	00003797          	auipc	a5,0x3
    8000261e:	79678793          	addi	a5,a5,1942 # 80005db0 <kernelvec>
    80002622:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002626:	6422                	ld	s0,8(sp)
    80002628:	0141                	addi	sp,sp,16
    8000262a:	8082                	ret

000000008000262c <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    8000262c:	1141                	addi	sp,sp,-16
    8000262e:	e406                	sd	ra,8(sp)
    80002630:	e022                	sd	s0,0(sp)
    80002632:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002634:	fffff097          	auipc	ra,0xfffff
    80002638:	38c080e7          	jalr	908(ra) # 800019c0 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000263c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002640:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002642:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002646:	00005617          	auipc	a2,0x5
    8000264a:	9ba60613          	addi	a2,a2,-1606 # 80007000 <_trampoline>
    8000264e:	00005697          	auipc	a3,0x5
    80002652:	9b268693          	addi	a3,a3,-1614 # 80007000 <_trampoline>
    80002656:	8e91                	sub	a3,a3,a2
    80002658:	040007b7          	lui	a5,0x4000
    8000265c:	17fd                	addi	a5,a5,-1
    8000265e:	07b2                	slli	a5,a5,0xc
    80002660:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002662:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002666:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002668:	180026f3          	csrr	a3,satp
    8000266c:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000266e:	6d38                	ld	a4,88(a0)
    80002670:	6134                	ld	a3,64(a0)
    80002672:	6585                	lui	a1,0x1
    80002674:	96ae                	add	a3,a3,a1
    80002676:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002678:	6d38                	ld	a4,88(a0)
    8000267a:	00000697          	auipc	a3,0x0
    8000267e:	13868693          	addi	a3,a3,312 # 800027b2 <usertrap>
    80002682:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002684:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002686:	8692                	mv	a3,tp
    80002688:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000268a:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    8000268e:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002692:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002696:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    8000269a:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000269c:	6f18                	ld	a4,24(a4)
    8000269e:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800026a2:	692c                	ld	a1,80(a0)
    800026a4:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800026a6:	00005717          	auipc	a4,0x5
    800026aa:	9ea70713          	addi	a4,a4,-1558 # 80007090 <userret>
    800026ae:	8f11                	sub	a4,a4,a2
    800026b0:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800026b2:	577d                	li	a4,-1
    800026b4:	177e                	slli	a4,a4,0x3f
    800026b6:	8dd9                	or	a1,a1,a4
    800026b8:	02000537          	lui	a0,0x2000
    800026bc:	157d                	addi	a0,a0,-1
    800026be:	0536                	slli	a0,a0,0xd
    800026c0:	9782                	jalr	a5
}
    800026c2:	60a2                	ld	ra,8(sp)
    800026c4:	6402                	ld	s0,0(sp)
    800026c6:	0141                	addi	sp,sp,16
    800026c8:	8082                	ret

00000000800026ca <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800026ca:	1101                	addi	sp,sp,-32
    800026cc:	ec06                	sd	ra,24(sp)
    800026ce:	e822                	sd	s0,16(sp)
    800026d0:	e426                	sd	s1,8(sp)
    800026d2:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800026d4:	00015497          	auipc	s1,0x15
    800026d8:	9fc48493          	addi	s1,s1,-1540 # 800170d0 <tickslock>
    800026dc:	8526                	mv	a0,s1
    800026de:	ffffe097          	auipc	ra,0xffffe
    800026e2:	4e4080e7          	jalr	1252(ra) # 80000bc2 <acquire>
  ticks++;
    800026e6:	00007517          	auipc	a0,0x7
    800026ea:	94a50513          	addi	a0,a0,-1718 # 80009030 <ticks>
    800026ee:	411c                	lw	a5,0(a0)
    800026f0:	2785                	addiw	a5,a5,1
    800026f2:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800026f4:	00000097          	auipc	ra,0x0
    800026f8:	b1c080e7          	jalr	-1252(ra) # 80002210 <wakeup>
  release(&tickslock);
    800026fc:	8526                	mv	a0,s1
    800026fe:	ffffe097          	auipc	ra,0xffffe
    80002702:	578080e7          	jalr	1400(ra) # 80000c76 <release>
}
    80002706:	60e2                	ld	ra,24(sp)
    80002708:	6442                	ld	s0,16(sp)
    8000270a:	64a2                	ld	s1,8(sp)
    8000270c:	6105                	addi	sp,sp,32
    8000270e:	8082                	ret

0000000080002710 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002710:	1101                	addi	sp,sp,-32
    80002712:	ec06                	sd	ra,24(sp)
    80002714:	e822                	sd	s0,16(sp)
    80002716:	e426                	sd	s1,8(sp)
    80002718:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000271a:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    8000271e:	00074d63          	bltz	a4,80002738 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002722:	57fd                	li	a5,-1
    80002724:	17fe                	slli	a5,a5,0x3f
    80002726:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002728:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    8000272a:	06f70363          	beq	a4,a5,80002790 <devintr+0x80>
  }
}
    8000272e:	60e2                	ld	ra,24(sp)
    80002730:	6442                	ld	s0,16(sp)
    80002732:	64a2                	ld	s1,8(sp)
    80002734:	6105                	addi	sp,sp,32
    80002736:	8082                	ret
     (scause & 0xff) == 9){
    80002738:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    8000273c:	46a5                	li	a3,9
    8000273e:	fed792e3          	bne	a5,a3,80002722 <devintr+0x12>
    int irq = plic_claim();
    80002742:	00003097          	auipc	ra,0x3
    80002746:	776080e7          	jalr	1910(ra) # 80005eb8 <plic_claim>
    8000274a:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    8000274c:	47a9                	li	a5,10
    8000274e:	02f50763          	beq	a0,a5,8000277c <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002752:	4785                	li	a5,1
    80002754:	02f50963          	beq	a0,a5,80002786 <devintr+0x76>
    return 1;
    80002758:	4505                	li	a0,1
    } else if(irq){
    8000275a:	d8f1                	beqz	s1,8000272e <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    8000275c:	85a6                	mv	a1,s1
    8000275e:	00006517          	auipc	a0,0x6
    80002762:	b8250513          	addi	a0,a0,-1150 # 800082e0 <states.0+0x38>
    80002766:	ffffe097          	auipc	ra,0xffffe
    8000276a:	e0e080e7          	jalr	-498(ra) # 80000574 <printf>
      plic_complete(irq);
    8000276e:	8526                	mv	a0,s1
    80002770:	00003097          	auipc	ra,0x3
    80002774:	76c080e7          	jalr	1900(ra) # 80005edc <plic_complete>
    return 1;
    80002778:	4505                	li	a0,1
    8000277a:	bf55                	j	8000272e <devintr+0x1e>
      uartintr();
    8000277c:	ffffe097          	auipc	ra,0xffffe
    80002780:	20a080e7          	jalr	522(ra) # 80000986 <uartintr>
    80002784:	b7ed                	j	8000276e <devintr+0x5e>
      virtio_disk_intr();
    80002786:	00004097          	auipc	ra,0x4
    8000278a:	be8080e7          	jalr	-1048(ra) # 8000636e <virtio_disk_intr>
    8000278e:	b7c5                	j	8000276e <devintr+0x5e>
    if(cpuid() == 0){
    80002790:	fffff097          	auipc	ra,0xfffff
    80002794:	204080e7          	jalr	516(ra) # 80001994 <cpuid>
    80002798:	c901                	beqz	a0,800027a8 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    8000279a:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    8000279e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800027a0:	14479073          	csrw	sip,a5
    return 2;
    800027a4:	4509                	li	a0,2
    800027a6:	b761                	j	8000272e <devintr+0x1e>
      clockintr();
    800027a8:	00000097          	auipc	ra,0x0
    800027ac:	f22080e7          	jalr	-222(ra) # 800026ca <clockintr>
    800027b0:	b7ed                	j	8000279a <devintr+0x8a>

00000000800027b2 <usertrap>:
{
    800027b2:	1101                	addi	sp,sp,-32
    800027b4:	ec06                	sd	ra,24(sp)
    800027b6:	e822                	sd	s0,16(sp)
    800027b8:	e426                	sd	s1,8(sp)
    800027ba:	e04a                	sd	s2,0(sp)
    800027bc:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027be:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800027c2:	1007f793          	andi	a5,a5,256
    800027c6:	e3ad                	bnez	a5,80002828 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800027c8:	00003797          	auipc	a5,0x3
    800027cc:	5e878793          	addi	a5,a5,1512 # 80005db0 <kernelvec>
    800027d0:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800027d4:	fffff097          	auipc	ra,0xfffff
    800027d8:	1ec080e7          	jalr	492(ra) # 800019c0 <myproc>
    800027dc:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800027de:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800027e0:	14102773          	csrr	a4,sepc
    800027e4:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800027e6:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800027ea:	47a1                	li	a5,8
    800027ec:	04f71c63          	bne	a4,a5,80002844 <usertrap+0x92>
    if(p->killed)
    800027f0:	551c                	lw	a5,40(a0)
    800027f2:	e3b9                	bnez	a5,80002838 <usertrap+0x86>
    p->trapframe->epc += 4;
    800027f4:	6cb8                	ld	a4,88(s1)
    800027f6:	6f1c                	ld	a5,24(a4)
    800027f8:	0791                	addi	a5,a5,4
    800027fa:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027fc:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002800:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002804:	10079073          	csrw	sstatus,a5
    syscall();
    80002808:	00000097          	auipc	ra,0x0
    8000280c:	2e0080e7          	jalr	736(ra) # 80002ae8 <syscall>
  if(p->killed)
    80002810:	549c                	lw	a5,40(s1)
    80002812:	ebc1                	bnez	a5,800028a2 <usertrap+0xf0>
  usertrapret();
    80002814:	00000097          	auipc	ra,0x0
    80002818:	e18080e7          	jalr	-488(ra) # 8000262c <usertrapret>
}
    8000281c:	60e2                	ld	ra,24(sp)
    8000281e:	6442                	ld	s0,16(sp)
    80002820:	64a2                	ld	s1,8(sp)
    80002822:	6902                	ld	s2,0(sp)
    80002824:	6105                	addi	sp,sp,32
    80002826:	8082                	ret
    panic("usertrap: not from user mode");
    80002828:	00006517          	auipc	a0,0x6
    8000282c:	ad850513          	addi	a0,a0,-1320 # 80008300 <states.0+0x58>
    80002830:	ffffe097          	auipc	ra,0xffffe
    80002834:	cfa080e7          	jalr	-774(ra) # 8000052a <panic>
      exit(-1);
    80002838:	557d                	li	a0,-1
    8000283a:	00000097          	auipc	ra,0x0
    8000283e:	aa6080e7          	jalr	-1370(ra) # 800022e0 <exit>
    80002842:	bf4d                	j	800027f4 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002844:	00000097          	auipc	ra,0x0
    80002848:	ecc080e7          	jalr	-308(ra) # 80002710 <devintr>
    8000284c:	892a                	mv	s2,a0
    8000284e:	c501                	beqz	a0,80002856 <usertrap+0xa4>
  if(p->killed)
    80002850:	549c                	lw	a5,40(s1)
    80002852:	c3a1                	beqz	a5,80002892 <usertrap+0xe0>
    80002854:	a815                	j	80002888 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002856:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    8000285a:	5890                	lw	a2,48(s1)
    8000285c:	00006517          	auipc	a0,0x6
    80002860:	ac450513          	addi	a0,a0,-1340 # 80008320 <states.0+0x78>
    80002864:	ffffe097          	auipc	ra,0xffffe
    80002868:	d10080e7          	jalr	-752(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000286c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002870:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002874:	00006517          	auipc	a0,0x6
    80002878:	adc50513          	addi	a0,a0,-1316 # 80008350 <states.0+0xa8>
    8000287c:	ffffe097          	auipc	ra,0xffffe
    80002880:	cf8080e7          	jalr	-776(ra) # 80000574 <printf>
    p->killed = 1;
    80002884:	4785                	li	a5,1
    80002886:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002888:	557d                	li	a0,-1
    8000288a:	00000097          	auipc	ra,0x0
    8000288e:	a56080e7          	jalr	-1450(ra) # 800022e0 <exit>
  if(which_dev == 2)
    80002892:	4789                	li	a5,2
    80002894:	f8f910e3          	bne	s2,a5,80002814 <usertrap+0x62>
    yield();
    80002898:	fffff097          	auipc	ra,0xfffff
    8000289c:	7b0080e7          	jalr	1968(ra) # 80002048 <yield>
    800028a0:	bf95                	j	80002814 <usertrap+0x62>
  int which_dev = 0;
    800028a2:	4901                	li	s2,0
    800028a4:	b7d5                	j	80002888 <usertrap+0xd6>

00000000800028a6 <kerneltrap>:
{
    800028a6:	7179                	addi	sp,sp,-48
    800028a8:	f406                	sd	ra,40(sp)
    800028aa:	f022                	sd	s0,32(sp)
    800028ac:	ec26                	sd	s1,24(sp)
    800028ae:	e84a                	sd	s2,16(sp)
    800028b0:	e44e                	sd	s3,8(sp)
    800028b2:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028b4:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028b8:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028bc:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800028c0:	1004f793          	andi	a5,s1,256
    800028c4:	cb85                	beqz	a5,800028f4 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028c6:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800028ca:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800028cc:	ef85                	bnez	a5,80002904 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800028ce:	00000097          	auipc	ra,0x0
    800028d2:	e42080e7          	jalr	-446(ra) # 80002710 <devintr>
    800028d6:	cd1d                	beqz	a0,80002914 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800028d8:	4789                	li	a5,2
    800028da:	06f50a63          	beq	a0,a5,8000294e <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800028de:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028e2:	10049073          	csrw	sstatus,s1
}
    800028e6:	70a2                	ld	ra,40(sp)
    800028e8:	7402                	ld	s0,32(sp)
    800028ea:	64e2                	ld	s1,24(sp)
    800028ec:	6942                	ld	s2,16(sp)
    800028ee:	69a2                	ld	s3,8(sp)
    800028f0:	6145                	addi	sp,sp,48
    800028f2:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800028f4:	00006517          	auipc	a0,0x6
    800028f8:	a7c50513          	addi	a0,a0,-1412 # 80008370 <states.0+0xc8>
    800028fc:	ffffe097          	auipc	ra,0xffffe
    80002900:	c2e080e7          	jalr	-978(ra) # 8000052a <panic>
    panic("kerneltrap: interrupts enabled");
    80002904:	00006517          	auipc	a0,0x6
    80002908:	a9450513          	addi	a0,a0,-1388 # 80008398 <states.0+0xf0>
    8000290c:	ffffe097          	auipc	ra,0xffffe
    80002910:	c1e080e7          	jalr	-994(ra) # 8000052a <panic>
    printf("scause %p\n", scause);
    80002914:	85ce                	mv	a1,s3
    80002916:	00006517          	auipc	a0,0x6
    8000291a:	aa250513          	addi	a0,a0,-1374 # 800083b8 <states.0+0x110>
    8000291e:	ffffe097          	auipc	ra,0xffffe
    80002922:	c56080e7          	jalr	-938(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002926:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000292a:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000292e:	00006517          	auipc	a0,0x6
    80002932:	a9a50513          	addi	a0,a0,-1382 # 800083c8 <states.0+0x120>
    80002936:	ffffe097          	auipc	ra,0xffffe
    8000293a:	c3e080e7          	jalr	-962(ra) # 80000574 <printf>
    panic("kerneltrap");
    8000293e:	00006517          	auipc	a0,0x6
    80002942:	aa250513          	addi	a0,a0,-1374 # 800083e0 <states.0+0x138>
    80002946:	ffffe097          	auipc	ra,0xffffe
    8000294a:	be4080e7          	jalr	-1052(ra) # 8000052a <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    8000294e:	fffff097          	auipc	ra,0xfffff
    80002952:	072080e7          	jalr	114(ra) # 800019c0 <myproc>
    80002956:	d541                	beqz	a0,800028de <kerneltrap+0x38>
    80002958:	fffff097          	auipc	ra,0xfffff
    8000295c:	068080e7          	jalr	104(ra) # 800019c0 <myproc>
    80002960:	4d18                	lw	a4,24(a0)
    80002962:	4791                	li	a5,4
    80002964:	f6f71de3          	bne	a4,a5,800028de <kerneltrap+0x38>
    yield();
    80002968:	fffff097          	auipc	ra,0xfffff
    8000296c:	6e0080e7          	jalr	1760(ra) # 80002048 <yield>
    80002970:	b7bd                	j	800028de <kerneltrap+0x38>

0000000080002972 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002972:	1101                	addi	sp,sp,-32
    80002974:	ec06                	sd	ra,24(sp)
    80002976:	e822                	sd	s0,16(sp)
    80002978:	e426                	sd	s1,8(sp)
    8000297a:	1000                	addi	s0,sp,32
    8000297c:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    8000297e:	fffff097          	auipc	ra,0xfffff
    80002982:	042080e7          	jalr	66(ra) # 800019c0 <myproc>
  switch (n) {
    80002986:	4795                	li	a5,5
    80002988:	0497e163          	bltu	a5,s1,800029ca <argraw+0x58>
    8000298c:	048a                	slli	s1,s1,0x2
    8000298e:	00006717          	auipc	a4,0x6
    80002992:	a8a70713          	addi	a4,a4,-1398 # 80008418 <states.0+0x170>
    80002996:	94ba                	add	s1,s1,a4
    80002998:	409c                	lw	a5,0(s1)
    8000299a:	97ba                	add	a5,a5,a4
    8000299c:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    8000299e:	6d3c                	ld	a5,88(a0)
    800029a0:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    800029a2:	60e2                	ld	ra,24(sp)
    800029a4:	6442                	ld	s0,16(sp)
    800029a6:	64a2                	ld	s1,8(sp)
    800029a8:	6105                	addi	sp,sp,32
    800029aa:	8082                	ret
    return p->trapframe->a1;
    800029ac:	6d3c                	ld	a5,88(a0)
    800029ae:	7fa8                	ld	a0,120(a5)
    800029b0:	bfcd                	j	800029a2 <argraw+0x30>
    return p->trapframe->a2;
    800029b2:	6d3c                	ld	a5,88(a0)
    800029b4:	63c8                	ld	a0,128(a5)
    800029b6:	b7f5                	j	800029a2 <argraw+0x30>
    return p->trapframe->a3;
    800029b8:	6d3c                	ld	a5,88(a0)
    800029ba:	67c8                	ld	a0,136(a5)
    800029bc:	b7dd                	j	800029a2 <argraw+0x30>
    return p->trapframe->a4;
    800029be:	6d3c                	ld	a5,88(a0)
    800029c0:	6bc8                	ld	a0,144(a5)
    800029c2:	b7c5                	j	800029a2 <argraw+0x30>
    return p->trapframe->a5;
    800029c4:	6d3c                	ld	a5,88(a0)
    800029c6:	6fc8                	ld	a0,152(a5)
    800029c8:	bfe9                	j	800029a2 <argraw+0x30>
  panic("argraw");
    800029ca:	00006517          	auipc	a0,0x6
    800029ce:	a2650513          	addi	a0,a0,-1498 # 800083f0 <states.0+0x148>
    800029d2:	ffffe097          	auipc	ra,0xffffe
    800029d6:	b58080e7          	jalr	-1192(ra) # 8000052a <panic>

00000000800029da <fetchaddr>:
{
    800029da:	1101                	addi	sp,sp,-32
    800029dc:	ec06                	sd	ra,24(sp)
    800029de:	e822                	sd	s0,16(sp)
    800029e0:	e426                	sd	s1,8(sp)
    800029e2:	e04a                	sd	s2,0(sp)
    800029e4:	1000                	addi	s0,sp,32
    800029e6:	84aa                	mv	s1,a0
    800029e8:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800029ea:	fffff097          	auipc	ra,0xfffff
    800029ee:	fd6080e7          	jalr	-42(ra) # 800019c0 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    800029f2:	653c                	ld	a5,72(a0)
    800029f4:	02f4f863          	bgeu	s1,a5,80002a24 <fetchaddr+0x4a>
    800029f8:	00848713          	addi	a4,s1,8
    800029fc:	02e7e663          	bltu	a5,a4,80002a28 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002a00:	46a1                	li	a3,8
    80002a02:	8626                	mv	a2,s1
    80002a04:	85ca                	mv	a1,s2
    80002a06:	6928                	ld	a0,80(a0)
    80002a08:	fffff097          	auipc	ra,0xfffff
    80002a0c:	d04080e7          	jalr	-764(ra) # 8000170c <copyin>
    80002a10:	00a03533          	snez	a0,a0
    80002a14:	40a00533          	neg	a0,a0
}
    80002a18:	60e2                	ld	ra,24(sp)
    80002a1a:	6442                	ld	s0,16(sp)
    80002a1c:	64a2                	ld	s1,8(sp)
    80002a1e:	6902                	ld	s2,0(sp)
    80002a20:	6105                	addi	sp,sp,32
    80002a22:	8082                	ret
    return -1;
    80002a24:	557d                	li	a0,-1
    80002a26:	bfcd                	j	80002a18 <fetchaddr+0x3e>
    80002a28:	557d                	li	a0,-1
    80002a2a:	b7fd                	j	80002a18 <fetchaddr+0x3e>

0000000080002a2c <fetchstr>:
{
    80002a2c:	7179                	addi	sp,sp,-48
    80002a2e:	f406                	sd	ra,40(sp)
    80002a30:	f022                	sd	s0,32(sp)
    80002a32:	ec26                	sd	s1,24(sp)
    80002a34:	e84a                	sd	s2,16(sp)
    80002a36:	e44e                	sd	s3,8(sp)
    80002a38:	1800                	addi	s0,sp,48
    80002a3a:	892a                	mv	s2,a0
    80002a3c:	84ae                	mv	s1,a1
    80002a3e:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002a40:	fffff097          	auipc	ra,0xfffff
    80002a44:	f80080e7          	jalr	-128(ra) # 800019c0 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002a48:	86ce                	mv	a3,s3
    80002a4a:	864a                	mv	a2,s2
    80002a4c:	85a6                	mv	a1,s1
    80002a4e:	6928                	ld	a0,80(a0)
    80002a50:	fffff097          	auipc	ra,0xfffff
    80002a54:	d4a080e7          	jalr	-694(ra) # 8000179a <copyinstr>
  if(err < 0)
    80002a58:	00054763          	bltz	a0,80002a66 <fetchstr+0x3a>
  return strlen(buf);
    80002a5c:	8526                	mv	a0,s1
    80002a5e:	ffffe097          	auipc	ra,0xffffe
    80002a62:	3e4080e7          	jalr	996(ra) # 80000e42 <strlen>
}
    80002a66:	70a2                	ld	ra,40(sp)
    80002a68:	7402                	ld	s0,32(sp)
    80002a6a:	64e2                	ld	s1,24(sp)
    80002a6c:	6942                	ld	s2,16(sp)
    80002a6e:	69a2                	ld	s3,8(sp)
    80002a70:	6145                	addi	sp,sp,48
    80002a72:	8082                	ret

0000000080002a74 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002a74:	1101                	addi	sp,sp,-32
    80002a76:	ec06                	sd	ra,24(sp)
    80002a78:	e822                	sd	s0,16(sp)
    80002a7a:	e426                	sd	s1,8(sp)
    80002a7c:	1000                	addi	s0,sp,32
    80002a7e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002a80:	00000097          	auipc	ra,0x0
    80002a84:	ef2080e7          	jalr	-270(ra) # 80002972 <argraw>
    80002a88:	c088                	sw	a0,0(s1)
  return 0;
}
    80002a8a:	4501                	li	a0,0
    80002a8c:	60e2                	ld	ra,24(sp)
    80002a8e:	6442                	ld	s0,16(sp)
    80002a90:	64a2                	ld	s1,8(sp)
    80002a92:	6105                	addi	sp,sp,32
    80002a94:	8082                	ret

0000000080002a96 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002a96:	1101                	addi	sp,sp,-32
    80002a98:	ec06                	sd	ra,24(sp)
    80002a9a:	e822                	sd	s0,16(sp)
    80002a9c:	e426                	sd	s1,8(sp)
    80002a9e:	1000                	addi	s0,sp,32
    80002aa0:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002aa2:	00000097          	auipc	ra,0x0
    80002aa6:	ed0080e7          	jalr	-304(ra) # 80002972 <argraw>
    80002aaa:	e088                	sd	a0,0(s1)
  return 0;
}
    80002aac:	4501                	li	a0,0
    80002aae:	60e2                	ld	ra,24(sp)
    80002ab0:	6442                	ld	s0,16(sp)
    80002ab2:	64a2                	ld	s1,8(sp)
    80002ab4:	6105                	addi	sp,sp,32
    80002ab6:	8082                	ret

0000000080002ab8 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002ab8:	1101                	addi	sp,sp,-32
    80002aba:	ec06                	sd	ra,24(sp)
    80002abc:	e822                	sd	s0,16(sp)
    80002abe:	e426                	sd	s1,8(sp)
    80002ac0:	e04a                	sd	s2,0(sp)
    80002ac2:	1000                	addi	s0,sp,32
    80002ac4:	84ae                	mv	s1,a1
    80002ac6:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002ac8:	00000097          	auipc	ra,0x0
    80002acc:	eaa080e7          	jalr	-342(ra) # 80002972 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002ad0:	864a                	mv	a2,s2
    80002ad2:	85a6                	mv	a1,s1
    80002ad4:	00000097          	auipc	ra,0x0
    80002ad8:	f58080e7          	jalr	-168(ra) # 80002a2c <fetchstr>
}
    80002adc:	60e2                	ld	ra,24(sp)
    80002ade:	6442                	ld	s0,16(sp)
    80002ae0:	64a2                	ld	s1,8(sp)
    80002ae2:	6902                	ld	s2,0(sp)
    80002ae4:	6105                	addi	sp,sp,32
    80002ae6:	8082                	ret

0000000080002ae8 <syscall>:
[SYS_symlink]   sys_symlink,
};

void
syscall(void)
{
    80002ae8:	1101                	addi	sp,sp,-32
    80002aea:	ec06                	sd	ra,24(sp)
    80002aec:	e822                	sd	s0,16(sp)
    80002aee:	e426                	sd	s1,8(sp)
    80002af0:	e04a                	sd	s2,0(sp)
    80002af2:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002af4:	fffff097          	auipc	ra,0xfffff
    80002af8:	ecc080e7          	jalr	-308(ra) # 800019c0 <myproc>
    80002afc:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002afe:	05853903          	ld	s2,88(a0)
    80002b02:	0a893783          	ld	a5,168(s2)
    80002b06:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002b0a:	37fd                	addiw	a5,a5,-1
    80002b0c:	4755                	li	a4,21
    80002b0e:	00f76f63          	bltu	a4,a5,80002b2c <syscall+0x44>
    80002b12:	00369713          	slli	a4,a3,0x3
    80002b16:	00006797          	auipc	a5,0x6
    80002b1a:	91a78793          	addi	a5,a5,-1766 # 80008430 <syscalls>
    80002b1e:	97ba                	add	a5,a5,a4
    80002b20:	639c                	ld	a5,0(a5)
    80002b22:	c789                	beqz	a5,80002b2c <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002b24:	9782                	jalr	a5
    80002b26:	06a93823          	sd	a0,112(s2)
    80002b2a:	a839                	j	80002b48 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002b2c:	15848613          	addi	a2,s1,344
    80002b30:	588c                	lw	a1,48(s1)
    80002b32:	00006517          	auipc	a0,0x6
    80002b36:	8c650513          	addi	a0,a0,-1850 # 800083f8 <states.0+0x150>
    80002b3a:	ffffe097          	auipc	ra,0xffffe
    80002b3e:	a3a080e7          	jalr	-1478(ra) # 80000574 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002b42:	6cbc                	ld	a5,88(s1)
    80002b44:	577d                	li	a4,-1
    80002b46:	fbb8                	sd	a4,112(a5)
  }
}
    80002b48:	60e2                	ld	ra,24(sp)
    80002b4a:	6442                	ld	s0,16(sp)
    80002b4c:	64a2                	ld	s1,8(sp)
    80002b4e:	6902                	ld	s2,0(sp)
    80002b50:	6105                	addi	sp,sp,32
    80002b52:	8082                	ret

0000000080002b54 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002b54:	1101                	addi	sp,sp,-32
    80002b56:	ec06                	sd	ra,24(sp)
    80002b58:	e822                	sd	s0,16(sp)
    80002b5a:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002b5c:	fec40593          	addi	a1,s0,-20
    80002b60:	4501                	li	a0,0
    80002b62:	00000097          	auipc	ra,0x0
    80002b66:	f12080e7          	jalr	-238(ra) # 80002a74 <argint>
    return -1;
    80002b6a:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002b6c:	00054963          	bltz	a0,80002b7e <sys_exit+0x2a>
  exit(n);
    80002b70:	fec42503          	lw	a0,-20(s0)
    80002b74:	fffff097          	auipc	ra,0xfffff
    80002b78:	76c080e7          	jalr	1900(ra) # 800022e0 <exit>
  return 0;  // not reached
    80002b7c:	4781                	li	a5,0
}
    80002b7e:	853e                	mv	a0,a5
    80002b80:	60e2                	ld	ra,24(sp)
    80002b82:	6442                	ld	s0,16(sp)
    80002b84:	6105                	addi	sp,sp,32
    80002b86:	8082                	ret

0000000080002b88 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002b88:	1141                	addi	sp,sp,-16
    80002b8a:	e406                	sd	ra,8(sp)
    80002b8c:	e022                	sd	s0,0(sp)
    80002b8e:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002b90:	fffff097          	auipc	ra,0xfffff
    80002b94:	e30080e7          	jalr	-464(ra) # 800019c0 <myproc>
}
    80002b98:	5908                	lw	a0,48(a0)
    80002b9a:	60a2                	ld	ra,8(sp)
    80002b9c:	6402                	ld	s0,0(sp)
    80002b9e:	0141                	addi	sp,sp,16
    80002ba0:	8082                	ret

0000000080002ba2 <sys_fork>:

uint64
sys_fork(void)
{
    80002ba2:	1141                	addi	sp,sp,-16
    80002ba4:	e406                	sd	ra,8(sp)
    80002ba6:	e022                	sd	s0,0(sp)
    80002ba8:	0800                	addi	s0,sp,16
  return fork();
    80002baa:	fffff097          	auipc	ra,0xfffff
    80002bae:	1e8080e7          	jalr	488(ra) # 80001d92 <fork>
}
    80002bb2:	60a2                	ld	ra,8(sp)
    80002bb4:	6402                	ld	s0,0(sp)
    80002bb6:	0141                	addi	sp,sp,16
    80002bb8:	8082                	ret

0000000080002bba <sys_wait>:

uint64
sys_wait(void)
{
    80002bba:	1101                	addi	sp,sp,-32
    80002bbc:	ec06                	sd	ra,24(sp)
    80002bbe:	e822                	sd	s0,16(sp)
    80002bc0:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002bc2:	fe840593          	addi	a1,s0,-24
    80002bc6:	4501                	li	a0,0
    80002bc8:	00000097          	auipc	ra,0x0
    80002bcc:	ece080e7          	jalr	-306(ra) # 80002a96 <argaddr>
    80002bd0:	87aa                	mv	a5,a0
    return -1;
    80002bd2:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002bd4:	0007c863          	bltz	a5,80002be4 <sys_wait+0x2a>
  return wait(p);
    80002bd8:	fe843503          	ld	a0,-24(s0)
    80002bdc:	fffff097          	auipc	ra,0xfffff
    80002be0:	50c080e7          	jalr	1292(ra) # 800020e8 <wait>
}
    80002be4:	60e2                	ld	ra,24(sp)
    80002be6:	6442                	ld	s0,16(sp)
    80002be8:	6105                	addi	sp,sp,32
    80002bea:	8082                	ret

0000000080002bec <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002bec:	7179                	addi	sp,sp,-48
    80002bee:	f406                	sd	ra,40(sp)
    80002bf0:	f022                	sd	s0,32(sp)
    80002bf2:	ec26                	sd	s1,24(sp)
    80002bf4:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002bf6:	fdc40593          	addi	a1,s0,-36
    80002bfa:	4501                	li	a0,0
    80002bfc:	00000097          	auipc	ra,0x0
    80002c00:	e78080e7          	jalr	-392(ra) # 80002a74 <argint>
    return -1;
    80002c04:	54fd                	li	s1,-1
  if(argint(0, &n) < 0)
    80002c06:	00054f63          	bltz	a0,80002c24 <sys_sbrk+0x38>
  addr = myproc()->sz;
    80002c0a:	fffff097          	auipc	ra,0xfffff
    80002c0e:	db6080e7          	jalr	-586(ra) # 800019c0 <myproc>
    80002c12:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002c14:	fdc42503          	lw	a0,-36(s0)
    80002c18:	fffff097          	auipc	ra,0xfffff
    80002c1c:	106080e7          	jalr	262(ra) # 80001d1e <growproc>
    80002c20:	00054863          	bltz	a0,80002c30 <sys_sbrk+0x44>
    return -1;
  return addr;
}
    80002c24:	8526                	mv	a0,s1
    80002c26:	70a2                	ld	ra,40(sp)
    80002c28:	7402                	ld	s0,32(sp)
    80002c2a:	64e2                	ld	s1,24(sp)
    80002c2c:	6145                	addi	sp,sp,48
    80002c2e:	8082                	ret
    return -1;
    80002c30:	54fd                	li	s1,-1
    80002c32:	bfcd                	j	80002c24 <sys_sbrk+0x38>

0000000080002c34 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002c34:	7139                	addi	sp,sp,-64
    80002c36:	fc06                	sd	ra,56(sp)
    80002c38:	f822                	sd	s0,48(sp)
    80002c3a:	f426                	sd	s1,40(sp)
    80002c3c:	f04a                	sd	s2,32(sp)
    80002c3e:	ec4e                	sd	s3,24(sp)
    80002c40:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002c42:	fcc40593          	addi	a1,s0,-52
    80002c46:	4501                	li	a0,0
    80002c48:	00000097          	auipc	ra,0x0
    80002c4c:	e2c080e7          	jalr	-468(ra) # 80002a74 <argint>
    return -1;
    80002c50:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002c52:	06054563          	bltz	a0,80002cbc <sys_sleep+0x88>
  acquire(&tickslock);
    80002c56:	00014517          	auipc	a0,0x14
    80002c5a:	47a50513          	addi	a0,a0,1146 # 800170d0 <tickslock>
    80002c5e:	ffffe097          	auipc	ra,0xffffe
    80002c62:	f64080e7          	jalr	-156(ra) # 80000bc2 <acquire>
  ticks0 = ticks;
    80002c66:	00006917          	auipc	s2,0x6
    80002c6a:	3ca92903          	lw	s2,970(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80002c6e:	fcc42783          	lw	a5,-52(s0)
    80002c72:	cf85                	beqz	a5,80002caa <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002c74:	00014997          	auipc	s3,0x14
    80002c78:	45c98993          	addi	s3,s3,1116 # 800170d0 <tickslock>
    80002c7c:	00006497          	auipc	s1,0x6
    80002c80:	3b448493          	addi	s1,s1,948 # 80009030 <ticks>
    if(myproc()->killed){
    80002c84:	fffff097          	auipc	ra,0xfffff
    80002c88:	d3c080e7          	jalr	-708(ra) # 800019c0 <myproc>
    80002c8c:	551c                	lw	a5,40(a0)
    80002c8e:	ef9d                	bnez	a5,80002ccc <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002c90:	85ce                	mv	a1,s3
    80002c92:	8526                	mv	a0,s1
    80002c94:	fffff097          	auipc	ra,0xfffff
    80002c98:	3f0080e7          	jalr	1008(ra) # 80002084 <sleep>
  while(ticks - ticks0 < n){
    80002c9c:	409c                	lw	a5,0(s1)
    80002c9e:	412787bb          	subw	a5,a5,s2
    80002ca2:	fcc42703          	lw	a4,-52(s0)
    80002ca6:	fce7efe3          	bltu	a5,a4,80002c84 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002caa:	00014517          	auipc	a0,0x14
    80002cae:	42650513          	addi	a0,a0,1062 # 800170d0 <tickslock>
    80002cb2:	ffffe097          	auipc	ra,0xffffe
    80002cb6:	fc4080e7          	jalr	-60(ra) # 80000c76 <release>
  return 0;
    80002cba:	4781                	li	a5,0
}
    80002cbc:	853e                	mv	a0,a5
    80002cbe:	70e2                	ld	ra,56(sp)
    80002cc0:	7442                	ld	s0,48(sp)
    80002cc2:	74a2                	ld	s1,40(sp)
    80002cc4:	7902                	ld	s2,32(sp)
    80002cc6:	69e2                	ld	s3,24(sp)
    80002cc8:	6121                	addi	sp,sp,64
    80002cca:	8082                	ret
      release(&tickslock);
    80002ccc:	00014517          	auipc	a0,0x14
    80002cd0:	40450513          	addi	a0,a0,1028 # 800170d0 <tickslock>
    80002cd4:	ffffe097          	auipc	ra,0xffffe
    80002cd8:	fa2080e7          	jalr	-94(ra) # 80000c76 <release>
      return -1;
    80002cdc:	57fd                	li	a5,-1
    80002cde:	bff9                	j	80002cbc <sys_sleep+0x88>

0000000080002ce0 <sys_kill>:

uint64
sys_kill(void)
{
    80002ce0:	1101                	addi	sp,sp,-32
    80002ce2:	ec06                	sd	ra,24(sp)
    80002ce4:	e822                	sd	s0,16(sp)
    80002ce6:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002ce8:	fec40593          	addi	a1,s0,-20
    80002cec:	4501                	li	a0,0
    80002cee:	00000097          	auipc	ra,0x0
    80002cf2:	d86080e7          	jalr	-634(ra) # 80002a74 <argint>
    80002cf6:	87aa                	mv	a5,a0
    return -1;
    80002cf8:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002cfa:	0007c863          	bltz	a5,80002d0a <sys_kill+0x2a>
  return kill(pid);
    80002cfe:	fec42503          	lw	a0,-20(s0)
    80002d02:	fffff097          	auipc	ra,0xfffff
    80002d06:	6b4080e7          	jalr	1716(ra) # 800023b6 <kill>
}
    80002d0a:	60e2                	ld	ra,24(sp)
    80002d0c:	6442                	ld	s0,16(sp)
    80002d0e:	6105                	addi	sp,sp,32
    80002d10:	8082                	ret

0000000080002d12 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002d12:	1101                	addi	sp,sp,-32
    80002d14:	ec06                	sd	ra,24(sp)
    80002d16:	e822                	sd	s0,16(sp)
    80002d18:	e426                	sd	s1,8(sp)
    80002d1a:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002d1c:	00014517          	auipc	a0,0x14
    80002d20:	3b450513          	addi	a0,a0,948 # 800170d0 <tickslock>
    80002d24:	ffffe097          	auipc	ra,0xffffe
    80002d28:	e9e080e7          	jalr	-354(ra) # 80000bc2 <acquire>
  xticks = ticks;
    80002d2c:	00006497          	auipc	s1,0x6
    80002d30:	3044a483          	lw	s1,772(s1) # 80009030 <ticks>
  release(&tickslock);
    80002d34:	00014517          	auipc	a0,0x14
    80002d38:	39c50513          	addi	a0,a0,924 # 800170d0 <tickslock>
    80002d3c:	ffffe097          	auipc	ra,0xffffe
    80002d40:	f3a080e7          	jalr	-198(ra) # 80000c76 <release>
  return xticks;
}
    80002d44:	02049513          	slli	a0,s1,0x20
    80002d48:	9101                	srli	a0,a0,0x20
    80002d4a:	60e2                	ld	ra,24(sp)
    80002d4c:	6442                	ld	s0,16(sp)
    80002d4e:	64a2                	ld	s1,8(sp)
    80002d50:	6105                	addi	sp,sp,32
    80002d52:	8082                	ret

0000000080002d54 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002d54:	7179                	addi	sp,sp,-48
    80002d56:	f406                	sd	ra,40(sp)
    80002d58:	f022                	sd	s0,32(sp)
    80002d5a:	ec26                	sd	s1,24(sp)
    80002d5c:	e84a                	sd	s2,16(sp)
    80002d5e:	e44e                	sd	s3,8(sp)
    80002d60:	e052                	sd	s4,0(sp)
    80002d62:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002d64:	00005597          	auipc	a1,0x5
    80002d68:	78458593          	addi	a1,a1,1924 # 800084e8 <syscalls+0xb8>
    80002d6c:	00014517          	auipc	a0,0x14
    80002d70:	37c50513          	addi	a0,a0,892 # 800170e8 <bcache>
    80002d74:	ffffe097          	auipc	ra,0xffffe
    80002d78:	dbe080e7          	jalr	-578(ra) # 80000b32 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002d7c:	0001c797          	auipc	a5,0x1c
    80002d80:	36c78793          	addi	a5,a5,876 # 8001f0e8 <bcache+0x8000>
    80002d84:	0001c717          	auipc	a4,0x1c
    80002d88:	5cc70713          	addi	a4,a4,1484 # 8001f350 <bcache+0x8268>
    80002d8c:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002d90:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002d94:	00014497          	auipc	s1,0x14
    80002d98:	36c48493          	addi	s1,s1,876 # 80017100 <bcache+0x18>
    b->next = bcache.head.next;
    80002d9c:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002d9e:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002da0:	00005a17          	auipc	s4,0x5
    80002da4:	750a0a13          	addi	s4,s4,1872 # 800084f0 <syscalls+0xc0>
    b->next = bcache.head.next;
    80002da8:	2b893783          	ld	a5,696(s2)
    80002dac:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002dae:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002db2:	85d2                	mv	a1,s4
    80002db4:	01048513          	addi	a0,s1,16
    80002db8:	00001097          	auipc	ra,0x1
    80002dbc:	6e6080e7          	jalr	1766(ra) # 8000449e <initsleeplock>
    bcache.head.next->prev = b;
    80002dc0:	2b893783          	ld	a5,696(s2)
    80002dc4:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002dc6:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002dca:	45848493          	addi	s1,s1,1112
    80002dce:	fd349de3          	bne	s1,s3,80002da8 <binit+0x54>
  }
}
    80002dd2:	70a2                	ld	ra,40(sp)
    80002dd4:	7402                	ld	s0,32(sp)
    80002dd6:	64e2                	ld	s1,24(sp)
    80002dd8:	6942                	ld	s2,16(sp)
    80002dda:	69a2                	ld	s3,8(sp)
    80002ddc:	6a02                	ld	s4,0(sp)
    80002dde:	6145                	addi	sp,sp,48
    80002de0:	8082                	ret

0000000080002de2 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002de2:	7179                	addi	sp,sp,-48
    80002de4:	f406                	sd	ra,40(sp)
    80002de6:	f022                	sd	s0,32(sp)
    80002de8:	ec26                	sd	s1,24(sp)
    80002dea:	e84a                	sd	s2,16(sp)
    80002dec:	e44e                	sd	s3,8(sp)
    80002dee:	1800                	addi	s0,sp,48
    80002df0:	892a                	mv	s2,a0
    80002df2:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002df4:	00014517          	auipc	a0,0x14
    80002df8:	2f450513          	addi	a0,a0,756 # 800170e8 <bcache>
    80002dfc:	ffffe097          	auipc	ra,0xffffe
    80002e00:	dc6080e7          	jalr	-570(ra) # 80000bc2 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002e04:	0001c497          	auipc	s1,0x1c
    80002e08:	59c4b483          	ld	s1,1436(s1) # 8001f3a0 <bcache+0x82b8>
    80002e0c:	0001c797          	auipc	a5,0x1c
    80002e10:	54478793          	addi	a5,a5,1348 # 8001f350 <bcache+0x8268>
    80002e14:	02f48f63          	beq	s1,a5,80002e52 <bread+0x70>
    80002e18:	873e                	mv	a4,a5
    80002e1a:	a021                	j	80002e22 <bread+0x40>
    80002e1c:	68a4                	ld	s1,80(s1)
    80002e1e:	02e48a63          	beq	s1,a4,80002e52 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002e22:	449c                	lw	a5,8(s1)
    80002e24:	ff279ce3          	bne	a5,s2,80002e1c <bread+0x3a>
    80002e28:	44dc                	lw	a5,12(s1)
    80002e2a:	ff3799e3          	bne	a5,s3,80002e1c <bread+0x3a>
      b->refcnt++;
    80002e2e:	40bc                	lw	a5,64(s1)
    80002e30:	2785                	addiw	a5,a5,1
    80002e32:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002e34:	00014517          	auipc	a0,0x14
    80002e38:	2b450513          	addi	a0,a0,692 # 800170e8 <bcache>
    80002e3c:	ffffe097          	auipc	ra,0xffffe
    80002e40:	e3a080e7          	jalr	-454(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    80002e44:	01048513          	addi	a0,s1,16
    80002e48:	00001097          	auipc	ra,0x1
    80002e4c:	690080e7          	jalr	1680(ra) # 800044d8 <acquiresleep>
      return b;
    80002e50:	a8b9                	j	80002eae <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002e52:	0001c497          	auipc	s1,0x1c
    80002e56:	5464b483          	ld	s1,1350(s1) # 8001f398 <bcache+0x82b0>
    80002e5a:	0001c797          	auipc	a5,0x1c
    80002e5e:	4f678793          	addi	a5,a5,1270 # 8001f350 <bcache+0x8268>
    80002e62:	00f48863          	beq	s1,a5,80002e72 <bread+0x90>
    80002e66:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002e68:	40bc                	lw	a5,64(s1)
    80002e6a:	cf81                	beqz	a5,80002e82 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002e6c:	64a4                	ld	s1,72(s1)
    80002e6e:	fee49de3          	bne	s1,a4,80002e68 <bread+0x86>
  panic("bget: no buffers");
    80002e72:	00005517          	auipc	a0,0x5
    80002e76:	68650513          	addi	a0,a0,1670 # 800084f8 <syscalls+0xc8>
    80002e7a:	ffffd097          	auipc	ra,0xffffd
    80002e7e:	6b0080e7          	jalr	1712(ra) # 8000052a <panic>
      b->dev = dev;
    80002e82:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80002e86:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80002e8a:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002e8e:	4785                	li	a5,1
    80002e90:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002e92:	00014517          	auipc	a0,0x14
    80002e96:	25650513          	addi	a0,a0,598 # 800170e8 <bcache>
    80002e9a:	ffffe097          	auipc	ra,0xffffe
    80002e9e:	ddc080e7          	jalr	-548(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    80002ea2:	01048513          	addi	a0,s1,16
    80002ea6:	00001097          	auipc	ra,0x1
    80002eaa:	632080e7          	jalr	1586(ra) # 800044d8 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002eae:	409c                	lw	a5,0(s1)
    80002eb0:	cb89                	beqz	a5,80002ec2 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002eb2:	8526                	mv	a0,s1
    80002eb4:	70a2                	ld	ra,40(sp)
    80002eb6:	7402                	ld	s0,32(sp)
    80002eb8:	64e2                	ld	s1,24(sp)
    80002eba:	6942                	ld	s2,16(sp)
    80002ebc:	69a2                	ld	s3,8(sp)
    80002ebe:	6145                	addi	sp,sp,48
    80002ec0:	8082                	ret
    virtio_disk_rw(b, 0);
    80002ec2:	4581                	li	a1,0
    80002ec4:	8526                	mv	a0,s1
    80002ec6:	00003097          	auipc	ra,0x3
    80002eca:	220080e7          	jalr	544(ra) # 800060e6 <virtio_disk_rw>
    b->valid = 1;
    80002ece:	4785                	li	a5,1
    80002ed0:	c09c                	sw	a5,0(s1)
  return b;
    80002ed2:	b7c5                	j	80002eb2 <bread+0xd0>

0000000080002ed4 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80002ed4:	1101                	addi	sp,sp,-32
    80002ed6:	ec06                	sd	ra,24(sp)
    80002ed8:	e822                	sd	s0,16(sp)
    80002eda:	e426                	sd	s1,8(sp)
    80002edc:	1000                	addi	s0,sp,32
    80002ede:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002ee0:	0541                	addi	a0,a0,16
    80002ee2:	00001097          	auipc	ra,0x1
    80002ee6:	690080e7          	jalr	1680(ra) # 80004572 <holdingsleep>
    80002eea:	cd01                	beqz	a0,80002f02 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80002eec:	4585                	li	a1,1
    80002eee:	8526                	mv	a0,s1
    80002ef0:	00003097          	auipc	ra,0x3
    80002ef4:	1f6080e7          	jalr	502(ra) # 800060e6 <virtio_disk_rw>
}
    80002ef8:	60e2                	ld	ra,24(sp)
    80002efa:	6442                	ld	s0,16(sp)
    80002efc:	64a2                	ld	s1,8(sp)
    80002efe:	6105                	addi	sp,sp,32
    80002f00:	8082                	ret
    panic("bwrite");
    80002f02:	00005517          	auipc	a0,0x5
    80002f06:	60e50513          	addi	a0,a0,1550 # 80008510 <syscalls+0xe0>
    80002f0a:	ffffd097          	auipc	ra,0xffffd
    80002f0e:	620080e7          	jalr	1568(ra) # 8000052a <panic>

0000000080002f12 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80002f12:	1101                	addi	sp,sp,-32
    80002f14:	ec06                	sd	ra,24(sp)
    80002f16:	e822                	sd	s0,16(sp)
    80002f18:	e426                	sd	s1,8(sp)
    80002f1a:	e04a                	sd	s2,0(sp)
    80002f1c:	1000                	addi	s0,sp,32
    80002f1e:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002f20:	01050913          	addi	s2,a0,16
    80002f24:	854a                	mv	a0,s2
    80002f26:	00001097          	auipc	ra,0x1
    80002f2a:	64c080e7          	jalr	1612(ra) # 80004572 <holdingsleep>
    80002f2e:	c92d                	beqz	a0,80002fa0 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80002f30:	854a                	mv	a0,s2
    80002f32:	00001097          	auipc	ra,0x1
    80002f36:	5fc080e7          	jalr	1532(ra) # 8000452e <releasesleep>

  acquire(&bcache.lock);
    80002f3a:	00014517          	auipc	a0,0x14
    80002f3e:	1ae50513          	addi	a0,a0,430 # 800170e8 <bcache>
    80002f42:	ffffe097          	auipc	ra,0xffffe
    80002f46:	c80080e7          	jalr	-896(ra) # 80000bc2 <acquire>
  b->refcnt--;
    80002f4a:	40bc                	lw	a5,64(s1)
    80002f4c:	37fd                	addiw	a5,a5,-1
    80002f4e:	0007871b          	sext.w	a4,a5
    80002f52:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80002f54:	eb05                	bnez	a4,80002f84 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80002f56:	68bc                	ld	a5,80(s1)
    80002f58:	64b8                	ld	a4,72(s1)
    80002f5a:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80002f5c:	64bc                	ld	a5,72(s1)
    80002f5e:	68b8                	ld	a4,80(s1)
    80002f60:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80002f62:	0001c797          	auipc	a5,0x1c
    80002f66:	18678793          	addi	a5,a5,390 # 8001f0e8 <bcache+0x8000>
    80002f6a:	2b87b703          	ld	a4,696(a5)
    80002f6e:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80002f70:	0001c717          	auipc	a4,0x1c
    80002f74:	3e070713          	addi	a4,a4,992 # 8001f350 <bcache+0x8268>
    80002f78:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80002f7a:	2b87b703          	ld	a4,696(a5)
    80002f7e:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80002f80:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80002f84:	00014517          	auipc	a0,0x14
    80002f88:	16450513          	addi	a0,a0,356 # 800170e8 <bcache>
    80002f8c:	ffffe097          	auipc	ra,0xffffe
    80002f90:	cea080e7          	jalr	-790(ra) # 80000c76 <release>
}
    80002f94:	60e2                	ld	ra,24(sp)
    80002f96:	6442                	ld	s0,16(sp)
    80002f98:	64a2                	ld	s1,8(sp)
    80002f9a:	6902                	ld	s2,0(sp)
    80002f9c:	6105                	addi	sp,sp,32
    80002f9e:	8082                	ret
    panic("brelse");
    80002fa0:	00005517          	auipc	a0,0x5
    80002fa4:	57850513          	addi	a0,a0,1400 # 80008518 <syscalls+0xe8>
    80002fa8:	ffffd097          	auipc	ra,0xffffd
    80002fac:	582080e7          	jalr	1410(ra) # 8000052a <panic>

0000000080002fb0 <bpin>:

void
bpin(struct buf *b) {
    80002fb0:	1101                	addi	sp,sp,-32
    80002fb2:	ec06                	sd	ra,24(sp)
    80002fb4:	e822                	sd	s0,16(sp)
    80002fb6:	e426                	sd	s1,8(sp)
    80002fb8:	1000                	addi	s0,sp,32
    80002fba:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80002fbc:	00014517          	auipc	a0,0x14
    80002fc0:	12c50513          	addi	a0,a0,300 # 800170e8 <bcache>
    80002fc4:	ffffe097          	auipc	ra,0xffffe
    80002fc8:	bfe080e7          	jalr	-1026(ra) # 80000bc2 <acquire>
  b->refcnt++;
    80002fcc:	40bc                	lw	a5,64(s1)
    80002fce:	2785                	addiw	a5,a5,1
    80002fd0:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80002fd2:	00014517          	auipc	a0,0x14
    80002fd6:	11650513          	addi	a0,a0,278 # 800170e8 <bcache>
    80002fda:	ffffe097          	auipc	ra,0xffffe
    80002fde:	c9c080e7          	jalr	-868(ra) # 80000c76 <release>
}
    80002fe2:	60e2                	ld	ra,24(sp)
    80002fe4:	6442                	ld	s0,16(sp)
    80002fe6:	64a2                	ld	s1,8(sp)
    80002fe8:	6105                	addi	sp,sp,32
    80002fea:	8082                	ret

0000000080002fec <bunpin>:

void
bunpin(struct buf *b) {
    80002fec:	1101                	addi	sp,sp,-32
    80002fee:	ec06                	sd	ra,24(sp)
    80002ff0:	e822                	sd	s0,16(sp)
    80002ff2:	e426                	sd	s1,8(sp)
    80002ff4:	1000                	addi	s0,sp,32
    80002ff6:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80002ff8:	00014517          	auipc	a0,0x14
    80002ffc:	0f050513          	addi	a0,a0,240 # 800170e8 <bcache>
    80003000:	ffffe097          	auipc	ra,0xffffe
    80003004:	bc2080e7          	jalr	-1086(ra) # 80000bc2 <acquire>
  b->refcnt--;
    80003008:	40bc                	lw	a5,64(s1)
    8000300a:	37fd                	addiw	a5,a5,-1
    8000300c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000300e:	00014517          	auipc	a0,0x14
    80003012:	0da50513          	addi	a0,a0,218 # 800170e8 <bcache>
    80003016:	ffffe097          	auipc	ra,0xffffe
    8000301a:	c60080e7          	jalr	-928(ra) # 80000c76 <release>
}
    8000301e:	60e2                	ld	ra,24(sp)
    80003020:	6442                	ld	s0,16(sp)
    80003022:	64a2                	ld	s1,8(sp)
    80003024:	6105                	addi	sp,sp,32
    80003026:	8082                	ret

0000000080003028 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003028:	1101                	addi	sp,sp,-32
    8000302a:	ec06                	sd	ra,24(sp)
    8000302c:	e822                	sd	s0,16(sp)
    8000302e:	e426                	sd	s1,8(sp)
    80003030:	e04a                	sd	s2,0(sp)
    80003032:	1000                	addi	s0,sp,32
    80003034:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003036:	00d5d59b          	srliw	a1,a1,0xd
    8000303a:	0001c797          	auipc	a5,0x1c
    8000303e:	78a7a783          	lw	a5,1930(a5) # 8001f7c4 <sb+0x1c>
    80003042:	9dbd                	addw	a1,a1,a5
    80003044:	00000097          	auipc	ra,0x0
    80003048:	d9e080e7          	jalr	-610(ra) # 80002de2 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000304c:	0074f713          	andi	a4,s1,7
    80003050:	4785                	li	a5,1
    80003052:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003056:	14ce                	slli	s1,s1,0x33
    80003058:	90d9                	srli	s1,s1,0x36
    8000305a:	00950733          	add	a4,a0,s1
    8000305e:	05874703          	lbu	a4,88(a4)
    80003062:	00e7f6b3          	and	a3,a5,a4
    80003066:	c69d                	beqz	a3,80003094 <bfree+0x6c>
    80003068:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000306a:	94aa                	add	s1,s1,a0
    8000306c:	fff7c793          	not	a5,a5
    80003070:	8ff9                	and	a5,a5,a4
    80003072:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003076:	00001097          	auipc	ra,0x1
    8000307a:	342080e7          	jalr	834(ra) # 800043b8 <log_write>
  brelse(bp);
    8000307e:	854a                	mv	a0,s2
    80003080:	00000097          	auipc	ra,0x0
    80003084:	e92080e7          	jalr	-366(ra) # 80002f12 <brelse>
}
    80003088:	60e2                	ld	ra,24(sp)
    8000308a:	6442                	ld	s0,16(sp)
    8000308c:	64a2                	ld	s1,8(sp)
    8000308e:	6902                	ld	s2,0(sp)
    80003090:	6105                	addi	sp,sp,32
    80003092:	8082                	ret
    panic("freeing free block");
    80003094:	00005517          	auipc	a0,0x5
    80003098:	48c50513          	addi	a0,a0,1164 # 80008520 <syscalls+0xf0>
    8000309c:	ffffd097          	auipc	ra,0xffffd
    800030a0:	48e080e7          	jalr	1166(ra) # 8000052a <panic>

00000000800030a4 <balloc>:
{
    800030a4:	711d                	addi	sp,sp,-96
    800030a6:	ec86                	sd	ra,88(sp)
    800030a8:	e8a2                	sd	s0,80(sp)
    800030aa:	e4a6                	sd	s1,72(sp)
    800030ac:	e0ca                	sd	s2,64(sp)
    800030ae:	fc4e                	sd	s3,56(sp)
    800030b0:	f852                	sd	s4,48(sp)
    800030b2:	f456                	sd	s5,40(sp)
    800030b4:	f05a                	sd	s6,32(sp)
    800030b6:	ec5e                	sd	s7,24(sp)
    800030b8:	e862                	sd	s8,16(sp)
    800030ba:	e466                	sd	s9,8(sp)
    800030bc:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800030be:	0001c797          	auipc	a5,0x1c
    800030c2:	6ee7a783          	lw	a5,1774(a5) # 8001f7ac <sb+0x4>
    800030c6:	cbd1                	beqz	a5,8000315a <balloc+0xb6>
    800030c8:	8baa                	mv	s7,a0
    800030ca:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800030cc:	0001cb17          	auipc	s6,0x1c
    800030d0:	6dcb0b13          	addi	s6,s6,1756 # 8001f7a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800030d4:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800030d6:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800030d8:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800030da:	6c89                	lui	s9,0x2
    800030dc:	a831                	j	800030f8 <balloc+0x54>
    brelse(bp);
    800030de:	854a                	mv	a0,s2
    800030e0:	00000097          	auipc	ra,0x0
    800030e4:	e32080e7          	jalr	-462(ra) # 80002f12 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800030e8:	015c87bb          	addw	a5,s9,s5
    800030ec:	00078a9b          	sext.w	s5,a5
    800030f0:	004b2703          	lw	a4,4(s6)
    800030f4:	06eaf363          	bgeu	s5,a4,8000315a <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800030f8:	41fad79b          	sraiw	a5,s5,0x1f
    800030fc:	0137d79b          	srliw	a5,a5,0x13
    80003100:	015787bb          	addw	a5,a5,s5
    80003104:	40d7d79b          	sraiw	a5,a5,0xd
    80003108:	01cb2583          	lw	a1,28(s6)
    8000310c:	9dbd                	addw	a1,a1,a5
    8000310e:	855e                	mv	a0,s7
    80003110:	00000097          	auipc	ra,0x0
    80003114:	cd2080e7          	jalr	-814(ra) # 80002de2 <bread>
    80003118:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000311a:	004b2503          	lw	a0,4(s6)
    8000311e:	000a849b          	sext.w	s1,s5
    80003122:	8662                	mv	a2,s8
    80003124:	faa4fde3          	bgeu	s1,a0,800030de <balloc+0x3a>
      m = 1 << (bi % 8);
    80003128:	41f6579b          	sraiw	a5,a2,0x1f
    8000312c:	01d7d69b          	srliw	a3,a5,0x1d
    80003130:	00c6873b          	addw	a4,a3,a2
    80003134:	00777793          	andi	a5,a4,7
    80003138:	9f95                	subw	a5,a5,a3
    8000313a:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000313e:	4037571b          	sraiw	a4,a4,0x3
    80003142:	00e906b3          	add	a3,s2,a4
    80003146:	0586c683          	lbu	a3,88(a3)
    8000314a:	00d7f5b3          	and	a1,a5,a3
    8000314e:	cd91                	beqz	a1,8000316a <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003150:	2605                	addiw	a2,a2,1
    80003152:	2485                	addiw	s1,s1,1
    80003154:	fd4618e3          	bne	a2,s4,80003124 <balloc+0x80>
    80003158:	b759                	j	800030de <balloc+0x3a>
  panic("balloc: out of blocks");
    8000315a:	00005517          	auipc	a0,0x5
    8000315e:	3de50513          	addi	a0,a0,990 # 80008538 <syscalls+0x108>
    80003162:	ffffd097          	auipc	ra,0xffffd
    80003166:	3c8080e7          	jalr	968(ra) # 8000052a <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000316a:	974a                	add	a4,a4,s2
    8000316c:	8fd5                	or	a5,a5,a3
    8000316e:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003172:	854a                	mv	a0,s2
    80003174:	00001097          	auipc	ra,0x1
    80003178:	244080e7          	jalr	580(ra) # 800043b8 <log_write>
        brelse(bp);
    8000317c:	854a                	mv	a0,s2
    8000317e:	00000097          	auipc	ra,0x0
    80003182:	d94080e7          	jalr	-620(ra) # 80002f12 <brelse>
  bp = bread(dev, bno);
    80003186:	85a6                	mv	a1,s1
    80003188:	855e                	mv	a0,s7
    8000318a:	00000097          	auipc	ra,0x0
    8000318e:	c58080e7          	jalr	-936(ra) # 80002de2 <bread>
    80003192:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003194:	40000613          	li	a2,1024
    80003198:	4581                	li	a1,0
    8000319a:	05850513          	addi	a0,a0,88
    8000319e:	ffffe097          	auipc	ra,0xffffe
    800031a2:	b20080e7          	jalr	-1248(ra) # 80000cbe <memset>
  log_write(bp);
    800031a6:	854a                	mv	a0,s2
    800031a8:	00001097          	auipc	ra,0x1
    800031ac:	210080e7          	jalr	528(ra) # 800043b8 <log_write>
  brelse(bp);
    800031b0:	854a                	mv	a0,s2
    800031b2:	00000097          	auipc	ra,0x0
    800031b6:	d60080e7          	jalr	-672(ra) # 80002f12 <brelse>
}
    800031ba:	8526                	mv	a0,s1
    800031bc:	60e6                	ld	ra,88(sp)
    800031be:	6446                	ld	s0,80(sp)
    800031c0:	64a6                	ld	s1,72(sp)
    800031c2:	6906                	ld	s2,64(sp)
    800031c4:	79e2                	ld	s3,56(sp)
    800031c6:	7a42                	ld	s4,48(sp)
    800031c8:	7aa2                	ld	s5,40(sp)
    800031ca:	7b02                	ld	s6,32(sp)
    800031cc:	6be2                	ld	s7,24(sp)
    800031ce:	6c42                	ld	s8,16(sp)
    800031d0:	6ca2                	ld	s9,8(sp)
    800031d2:	6125                	addi	sp,sp,96
    800031d4:	8082                	ret

00000000800031d6 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800031d6:	7139                	addi	sp,sp,-64
    800031d8:	fc06                	sd	ra,56(sp)
    800031da:	f822                	sd	s0,48(sp)
    800031dc:	f426                	sd	s1,40(sp)
    800031de:	f04a                	sd	s2,32(sp)
    800031e0:	ec4e                	sd	s3,24(sp)
    800031e2:	e852                	sd	s4,16(sp)
    800031e4:	e456                	sd	s5,8(sp)
    800031e6:	0080                	addi	s0,sp,64
    800031e8:	892a                	mv	s2,a0
  // You should modify bmap(),
  // so that it can handle doubly indrect inode.
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800031ea:	47a5                	li	a5,9
    800031ec:	08b7ff63          	bgeu	a5,a1,8000328a <bmap+0xb4>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800031f0:	ff65849b          	addiw	s1,a1,-10
    800031f4:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800031f8:	0ff00793          	li	a5,255
    800031fc:	0ae7fa63          	bgeu	a5,a4,800032b0 <bmap+0xda>
    }
    brelse(bp);
    return addr;
  }

  bn -= NINDIRECT;
    80003200:	ef65849b          	addiw	s1,a1,-266

  if(bn >= NDOUBLY_INDIRECT)
    80003204:	67c1                	lui	a5,0x10
    80003206:	00f4e863          	bltu	s1,a5,80003216 <bmap+0x40>
	  bn -= NDOUBLY_INDIRECT;
    8000320a:	74c1                	lui	s1,0xffff0
    8000320c:	ef64849b          	addiw	s1,s1,-266
    80003210:	9cad                	addw	s1,s1,a1
  if( bn < NINDIRECT*NINDIRECT){
    80003212:	14f4fd63          	bgeu	s1,a5,8000336c <bmap+0x196>
	  // Load indirect block, allocating if necessary.
	  if((addr = ip->addrs[NDIRECT+1]) == 0)
    80003216:	07c92583          	lw	a1,124(s2)
    8000321a:	cdf5                	beqz	a1,80003316 <bmap+0x140>
		  ip->addrs[NDIRECT+1] = addr = balloc(ip->dev);
	  bp = bread(ip->dev, addr);
    8000321c:	00092503          	lw	a0,0(s2)
    80003220:	00000097          	auipc	ra,0x0
    80003224:	bc2080e7          	jalr	-1086(ra) # 80002de2 <bread>
    80003228:	89aa                	mv	s3,a0
	  a = (uint*)bp->data;
    8000322a:	05850a13          	addi	s4,a0,88
	  if((addr = a[bn/(NINDIRECT)]) == 0){
    8000322e:	0084d79b          	srliw	a5,s1,0x8
    80003232:	078a                	slli	a5,a5,0x2
    80003234:	9a3e                	add	s4,s4,a5
    80003236:	000a2a83          	lw	s5,0(s4) # 2000 <_entry-0x7fffe000>
    8000323a:	0e0a8963          	beqz	s5,8000332c <bmap+0x156>
		  a[(bn/NINDIRECT)] = addr = balloc(ip->dev);
		  log_write(bp);
	  }
	  brelse(bp);
    8000323e:	854e                	mv	a0,s3
    80003240:	00000097          	auipc	ra,0x0
    80003244:	cd2080e7          	jalr	-814(ra) # 80002f12 <brelse>
	  bp = bread(ip->dev, addr);
    80003248:	85d6                	mv	a1,s5
    8000324a:	00092503          	lw	a0,0(s2)
    8000324e:	00000097          	auipc	ra,0x0
    80003252:	b94080e7          	jalr	-1132(ra) # 80002de2 <bread>
    80003256:	8a2a                	mv	s4,a0
	  a = (uint*)bp->data;
    80003258:	05850793          	addi	a5,a0,88
	  //load doubly indirect block, allocating if necessary
	  if((addr = a[bn%(NINDIRECT)]) == 0){
    8000325c:	0ff4f493          	andi	s1,s1,255
    80003260:	048a                	slli	s1,s1,0x2
    80003262:	94be                	add	s1,s1,a5
    80003264:	0004a983          	lw	s3,0(s1) # ffffffffffff0000 <end+0xffffffff7ffca000>
    80003268:	0e098263          	beqz	s3,8000334c <bmap+0x176>
		  a[(bn%NINDIRECT)] = addr = balloc(ip->dev);
		  log_write(bp);
	  }
	  brelse(bp);
    8000326c:	8552                	mv	a0,s4
    8000326e:	00000097          	auipc	ra,0x0
    80003272:	ca4080e7          	jalr	-860(ra) # 80002f12 <brelse>
	  return addr;
  }

  panic("bmap: out of range");
}
    80003276:	854e                	mv	a0,s3
    80003278:	70e2                	ld	ra,56(sp)
    8000327a:	7442                	ld	s0,48(sp)
    8000327c:	74a2                	ld	s1,40(sp)
    8000327e:	7902                	ld	s2,32(sp)
    80003280:	69e2                	ld	s3,24(sp)
    80003282:	6a42                	ld	s4,16(sp)
    80003284:	6aa2                	ld	s5,8(sp)
    80003286:	6121                	addi	sp,sp,64
    80003288:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    8000328a:	02059493          	slli	s1,a1,0x20
    8000328e:	9081                	srli	s1,s1,0x20
    80003290:	048a                	slli	s1,s1,0x2
    80003292:	94aa                	add	s1,s1,a0
    80003294:	0504a983          	lw	s3,80(s1)
    80003298:	fc099fe3          	bnez	s3,80003276 <bmap+0xa0>
      ip->addrs[bn] = addr = balloc(ip->dev);
    8000329c:	4108                	lw	a0,0(a0)
    8000329e:	00000097          	auipc	ra,0x0
    800032a2:	e06080e7          	jalr	-506(ra) # 800030a4 <balloc>
    800032a6:	0005099b          	sext.w	s3,a0
    800032aa:	0534a823          	sw	s3,80(s1)
    800032ae:	b7e1                	j	80003276 <bmap+0xa0>
    if((addr = ip->addrs[NDIRECT]) == 0)
    800032b0:	5d2c                	lw	a1,120(a0)
    800032b2:	c985                	beqz	a1,800032e2 <bmap+0x10c>
    bp = bread(ip->dev, addr);
    800032b4:	00092503          	lw	a0,0(s2)
    800032b8:	00000097          	auipc	ra,0x0
    800032bc:	b2a080e7          	jalr	-1238(ra) # 80002de2 <bread>
    800032c0:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800032c2:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800032c6:	1482                	slli	s1,s1,0x20
    800032c8:	9081                	srli	s1,s1,0x20
    800032ca:	048a                	slli	s1,s1,0x2
    800032cc:	94be                	add	s1,s1,a5
    800032ce:	0004a983          	lw	s3,0(s1)
    800032d2:	02098263          	beqz	s3,800032f6 <bmap+0x120>
    brelse(bp);
    800032d6:	8552                	mv	a0,s4
    800032d8:	00000097          	auipc	ra,0x0
    800032dc:	c3a080e7          	jalr	-966(ra) # 80002f12 <brelse>
    return addr;
    800032e0:	bf59                	j	80003276 <bmap+0xa0>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800032e2:	4108                	lw	a0,0(a0)
    800032e4:	00000097          	auipc	ra,0x0
    800032e8:	dc0080e7          	jalr	-576(ra) # 800030a4 <balloc>
    800032ec:	0005059b          	sext.w	a1,a0
    800032f0:	06b92c23          	sw	a1,120(s2)
    800032f4:	b7c1                	j	800032b4 <bmap+0xde>
      a[bn] = addr = balloc(ip->dev);
    800032f6:	00092503          	lw	a0,0(s2)
    800032fa:	00000097          	auipc	ra,0x0
    800032fe:	daa080e7          	jalr	-598(ra) # 800030a4 <balloc>
    80003302:	0005099b          	sext.w	s3,a0
    80003306:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    8000330a:	8552                	mv	a0,s4
    8000330c:	00001097          	auipc	ra,0x1
    80003310:	0ac080e7          	jalr	172(ra) # 800043b8 <log_write>
    80003314:	b7c9                	j	800032d6 <bmap+0x100>
		  ip->addrs[NDIRECT+1] = addr = balloc(ip->dev);
    80003316:	00092503          	lw	a0,0(s2)
    8000331a:	00000097          	auipc	ra,0x0
    8000331e:	d8a080e7          	jalr	-630(ra) # 800030a4 <balloc>
    80003322:	0005059b          	sext.w	a1,a0
    80003326:	06b92e23          	sw	a1,124(s2)
    8000332a:	bdcd                	j	8000321c <bmap+0x46>
		  a[(bn/NINDIRECT)] = addr = balloc(ip->dev);
    8000332c:	00092503          	lw	a0,0(s2)
    80003330:	00000097          	auipc	ra,0x0
    80003334:	d74080e7          	jalr	-652(ra) # 800030a4 <balloc>
    80003338:	00050a9b          	sext.w	s5,a0
    8000333c:	015a2023          	sw	s5,0(s4)
		  log_write(bp);
    80003340:	854e                	mv	a0,s3
    80003342:	00001097          	auipc	ra,0x1
    80003346:	076080e7          	jalr	118(ra) # 800043b8 <log_write>
    8000334a:	bdd5                	j	8000323e <bmap+0x68>
		  a[(bn%NINDIRECT)] = addr = balloc(ip->dev);
    8000334c:	00092503          	lw	a0,0(s2)
    80003350:	00000097          	auipc	ra,0x0
    80003354:	d54080e7          	jalr	-684(ra) # 800030a4 <balloc>
    80003358:	0005099b          	sext.w	s3,a0
    8000335c:	0134a023          	sw	s3,0(s1)
		  log_write(bp);
    80003360:	8552                	mv	a0,s4
    80003362:	00001097          	auipc	ra,0x1
    80003366:	056080e7          	jalr	86(ra) # 800043b8 <log_write>
    8000336a:	b709                	j	8000326c <bmap+0x96>
  panic("bmap: out of range");
    8000336c:	00005517          	auipc	a0,0x5
    80003370:	1e450513          	addi	a0,a0,484 # 80008550 <syscalls+0x120>
    80003374:	ffffd097          	auipc	ra,0xffffd
    80003378:	1b6080e7          	jalr	438(ra) # 8000052a <panic>

000000008000337c <iget>:
{
    8000337c:	7179                	addi	sp,sp,-48
    8000337e:	f406                	sd	ra,40(sp)
    80003380:	f022                	sd	s0,32(sp)
    80003382:	ec26                	sd	s1,24(sp)
    80003384:	e84a                	sd	s2,16(sp)
    80003386:	e44e                	sd	s3,8(sp)
    80003388:	e052                	sd	s4,0(sp)
    8000338a:	1800                	addi	s0,sp,48
    8000338c:	89aa                	mv	s3,a0
    8000338e:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003390:	0001c517          	auipc	a0,0x1c
    80003394:	43850513          	addi	a0,a0,1080 # 8001f7c8 <itable>
    80003398:	ffffe097          	auipc	ra,0xffffe
    8000339c:	82a080e7          	jalr	-2006(ra) # 80000bc2 <acquire>
  empty = 0;
    800033a0:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800033a2:	0001c497          	auipc	s1,0x1c
    800033a6:	43e48493          	addi	s1,s1,1086 # 8001f7e0 <itable+0x18>
    800033aa:	0001e697          	auipc	a3,0x1e
    800033ae:	ec668693          	addi	a3,a3,-314 # 80021270 <log>
    800033b2:	a039                	j	800033c0 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800033b4:	02090b63          	beqz	s2,800033ea <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800033b8:	08848493          	addi	s1,s1,136
    800033bc:	02d48a63          	beq	s1,a3,800033f0 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800033c0:	449c                	lw	a5,8(s1)
    800033c2:	fef059e3          	blez	a5,800033b4 <iget+0x38>
    800033c6:	4098                	lw	a4,0(s1)
    800033c8:	ff3716e3          	bne	a4,s3,800033b4 <iget+0x38>
    800033cc:	40d8                	lw	a4,4(s1)
    800033ce:	ff4713e3          	bne	a4,s4,800033b4 <iget+0x38>
      ip->ref++;
    800033d2:	2785                	addiw	a5,a5,1
    800033d4:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800033d6:	0001c517          	auipc	a0,0x1c
    800033da:	3f250513          	addi	a0,a0,1010 # 8001f7c8 <itable>
    800033de:	ffffe097          	auipc	ra,0xffffe
    800033e2:	898080e7          	jalr	-1896(ra) # 80000c76 <release>
      return ip;
    800033e6:	8926                	mv	s2,s1
    800033e8:	a03d                	j	80003416 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800033ea:	f7f9                	bnez	a5,800033b8 <iget+0x3c>
    800033ec:	8926                	mv	s2,s1
    800033ee:	b7e9                	j	800033b8 <iget+0x3c>
  if(empty == 0)
    800033f0:	02090c63          	beqz	s2,80003428 <iget+0xac>
  ip->dev = dev;
    800033f4:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800033f8:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800033fc:	4785                	li	a5,1
    800033fe:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003402:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003406:	0001c517          	auipc	a0,0x1c
    8000340a:	3c250513          	addi	a0,a0,962 # 8001f7c8 <itable>
    8000340e:	ffffe097          	auipc	ra,0xffffe
    80003412:	868080e7          	jalr	-1944(ra) # 80000c76 <release>
}
    80003416:	854a                	mv	a0,s2
    80003418:	70a2                	ld	ra,40(sp)
    8000341a:	7402                	ld	s0,32(sp)
    8000341c:	64e2                	ld	s1,24(sp)
    8000341e:	6942                	ld	s2,16(sp)
    80003420:	69a2                	ld	s3,8(sp)
    80003422:	6a02                	ld	s4,0(sp)
    80003424:	6145                	addi	sp,sp,48
    80003426:	8082                	ret
    panic("iget: no inodes");
    80003428:	00005517          	auipc	a0,0x5
    8000342c:	14050513          	addi	a0,a0,320 # 80008568 <syscalls+0x138>
    80003430:	ffffd097          	auipc	ra,0xffffd
    80003434:	0fa080e7          	jalr	250(ra) # 8000052a <panic>

0000000080003438 <fsinit>:
fsinit(int dev) {
    80003438:	7179                	addi	sp,sp,-48
    8000343a:	f406                	sd	ra,40(sp)
    8000343c:	f022                	sd	s0,32(sp)
    8000343e:	ec26                	sd	s1,24(sp)
    80003440:	e84a                	sd	s2,16(sp)
    80003442:	e44e                	sd	s3,8(sp)
    80003444:	1800                	addi	s0,sp,48
    80003446:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003448:	4585                	li	a1,1
    8000344a:	00000097          	auipc	ra,0x0
    8000344e:	998080e7          	jalr	-1640(ra) # 80002de2 <bread>
    80003452:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003454:	0001c997          	auipc	s3,0x1c
    80003458:	35498993          	addi	s3,s3,852 # 8001f7a8 <sb>
    8000345c:	02000613          	li	a2,32
    80003460:	05850593          	addi	a1,a0,88
    80003464:	854e                	mv	a0,s3
    80003466:	ffffe097          	auipc	ra,0xffffe
    8000346a:	8b4080e7          	jalr	-1868(ra) # 80000d1a <memmove>
  brelse(bp);
    8000346e:	8526                	mv	a0,s1
    80003470:	00000097          	auipc	ra,0x0
    80003474:	aa2080e7          	jalr	-1374(ra) # 80002f12 <brelse>
  if(sb.magic != FSMAGIC)
    80003478:	0009a703          	lw	a4,0(s3)
    8000347c:	102037b7          	lui	a5,0x10203
    80003480:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003484:	02f71263          	bne	a4,a5,800034a8 <fsinit+0x70>
  initlog(dev, &sb);
    80003488:	0001c597          	auipc	a1,0x1c
    8000348c:	32058593          	addi	a1,a1,800 # 8001f7a8 <sb>
    80003490:	854a                	mv	a0,s2
    80003492:	00001097          	auipc	ra,0x1
    80003496:	caa080e7          	jalr	-854(ra) # 8000413c <initlog>
}
    8000349a:	70a2                	ld	ra,40(sp)
    8000349c:	7402                	ld	s0,32(sp)
    8000349e:	64e2                	ld	s1,24(sp)
    800034a0:	6942                	ld	s2,16(sp)
    800034a2:	69a2                	ld	s3,8(sp)
    800034a4:	6145                	addi	sp,sp,48
    800034a6:	8082                	ret
    panic("invalid file system");
    800034a8:	00005517          	auipc	a0,0x5
    800034ac:	0d050513          	addi	a0,a0,208 # 80008578 <syscalls+0x148>
    800034b0:	ffffd097          	auipc	ra,0xffffd
    800034b4:	07a080e7          	jalr	122(ra) # 8000052a <panic>

00000000800034b8 <iinit>:
{
    800034b8:	7179                	addi	sp,sp,-48
    800034ba:	f406                	sd	ra,40(sp)
    800034bc:	f022                	sd	s0,32(sp)
    800034be:	ec26                	sd	s1,24(sp)
    800034c0:	e84a                	sd	s2,16(sp)
    800034c2:	e44e                	sd	s3,8(sp)
    800034c4:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800034c6:	00005597          	auipc	a1,0x5
    800034ca:	0ca58593          	addi	a1,a1,202 # 80008590 <syscalls+0x160>
    800034ce:	0001c517          	auipc	a0,0x1c
    800034d2:	2fa50513          	addi	a0,a0,762 # 8001f7c8 <itable>
    800034d6:	ffffd097          	auipc	ra,0xffffd
    800034da:	65c080e7          	jalr	1628(ra) # 80000b32 <initlock>
  for(i = 0; i < NINODE; i++) {
    800034de:	0001c497          	auipc	s1,0x1c
    800034e2:	31248493          	addi	s1,s1,786 # 8001f7f0 <itable+0x28>
    800034e6:	0001e997          	auipc	s3,0x1e
    800034ea:	d9a98993          	addi	s3,s3,-614 # 80021280 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800034ee:	00005917          	auipc	s2,0x5
    800034f2:	0aa90913          	addi	s2,s2,170 # 80008598 <syscalls+0x168>
    800034f6:	85ca                	mv	a1,s2
    800034f8:	8526                	mv	a0,s1
    800034fa:	00001097          	auipc	ra,0x1
    800034fe:	fa4080e7          	jalr	-92(ra) # 8000449e <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003502:	08848493          	addi	s1,s1,136
    80003506:	ff3498e3          	bne	s1,s3,800034f6 <iinit+0x3e>
}
    8000350a:	70a2                	ld	ra,40(sp)
    8000350c:	7402                	ld	s0,32(sp)
    8000350e:	64e2                	ld	s1,24(sp)
    80003510:	6942                	ld	s2,16(sp)
    80003512:	69a2                	ld	s3,8(sp)
    80003514:	6145                	addi	sp,sp,48
    80003516:	8082                	ret

0000000080003518 <ialloc>:
{
    80003518:	715d                	addi	sp,sp,-80
    8000351a:	e486                	sd	ra,72(sp)
    8000351c:	e0a2                	sd	s0,64(sp)
    8000351e:	fc26                	sd	s1,56(sp)
    80003520:	f84a                	sd	s2,48(sp)
    80003522:	f44e                	sd	s3,40(sp)
    80003524:	f052                	sd	s4,32(sp)
    80003526:	ec56                	sd	s5,24(sp)
    80003528:	e85a                	sd	s6,16(sp)
    8000352a:	e45e                	sd	s7,8(sp)
    8000352c:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000352e:	0001c717          	auipc	a4,0x1c
    80003532:	28672703          	lw	a4,646(a4) # 8001f7b4 <sb+0xc>
    80003536:	4785                	li	a5,1
    80003538:	04e7fa63          	bgeu	a5,a4,8000358c <ialloc+0x74>
    8000353c:	8aaa                	mv	s5,a0
    8000353e:	8bae                	mv	s7,a1
    80003540:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003542:	0001ca17          	auipc	s4,0x1c
    80003546:	266a0a13          	addi	s4,s4,614 # 8001f7a8 <sb>
    8000354a:	00048b1b          	sext.w	s6,s1
    8000354e:	0044d793          	srli	a5,s1,0x4
    80003552:	018a2583          	lw	a1,24(s4)
    80003556:	9dbd                	addw	a1,a1,a5
    80003558:	8556                	mv	a0,s5
    8000355a:	00000097          	auipc	ra,0x0
    8000355e:	888080e7          	jalr	-1912(ra) # 80002de2 <bread>
    80003562:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003564:	05850993          	addi	s3,a0,88
    80003568:	00f4f793          	andi	a5,s1,15
    8000356c:	079a                	slli	a5,a5,0x6
    8000356e:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003570:	00099783          	lh	a5,0(s3)
    80003574:	c785                	beqz	a5,8000359c <ialloc+0x84>
    brelse(bp);
    80003576:	00000097          	auipc	ra,0x0
    8000357a:	99c080e7          	jalr	-1636(ra) # 80002f12 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000357e:	0485                	addi	s1,s1,1
    80003580:	00ca2703          	lw	a4,12(s4)
    80003584:	0004879b          	sext.w	a5,s1
    80003588:	fce7e1e3          	bltu	a5,a4,8000354a <ialloc+0x32>
  panic("ialloc: no inodes");
    8000358c:	00005517          	auipc	a0,0x5
    80003590:	01450513          	addi	a0,a0,20 # 800085a0 <syscalls+0x170>
    80003594:	ffffd097          	auipc	ra,0xffffd
    80003598:	f96080e7          	jalr	-106(ra) # 8000052a <panic>
      memset(dip, 0, sizeof(*dip));
    8000359c:	04000613          	li	a2,64
    800035a0:	4581                	li	a1,0
    800035a2:	854e                	mv	a0,s3
    800035a4:	ffffd097          	auipc	ra,0xffffd
    800035a8:	71a080e7          	jalr	1818(ra) # 80000cbe <memset>
      dip->type = type;
    800035ac:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800035b0:	854a                	mv	a0,s2
    800035b2:	00001097          	auipc	ra,0x1
    800035b6:	e06080e7          	jalr	-506(ra) # 800043b8 <log_write>
      brelse(bp);
    800035ba:	854a                	mv	a0,s2
    800035bc:	00000097          	auipc	ra,0x0
    800035c0:	956080e7          	jalr	-1706(ra) # 80002f12 <brelse>
      return iget(dev, inum);
    800035c4:	85da                	mv	a1,s6
    800035c6:	8556                	mv	a0,s5
    800035c8:	00000097          	auipc	ra,0x0
    800035cc:	db4080e7          	jalr	-588(ra) # 8000337c <iget>
}
    800035d0:	60a6                	ld	ra,72(sp)
    800035d2:	6406                	ld	s0,64(sp)
    800035d4:	74e2                	ld	s1,56(sp)
    800035d6:	7942                	ld	s2,48(sp)
    800035d8:	79a2                	ld	s3,40(sp)
    800035da:	7a02                	ld	s4,32(sp)
    800035dc:	6ae2                	ld	s5,24(sp)
    800035de:	6b42                	ld	s6,16(sp)
    800035e0:	6ba2                	ld	s7,8(sp)
    800035e2:	6161                	addi	sp,sp,80
    800035e4:	8082                	ret

00000000800035e6 <iupdate>:
{
    800035e6:	1101                	addi	sp,sp,-32
    800035e8:	ec06                	sd	ra,24(sp)
    800035ea:	e822                	sd	s0,16(sp)
    800035ec:	e426                	sd	s1,8(sp)
    800035ee:	e04a                	sd	s2,0(sp)
    800035f0:	1000                	addi	s0,sp,32
    800035f2:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800035f4:	415c                	lw	a5,4(a0)
    800035f6:	0047d79b          	srliw	a5,a5,0x4
    800035fa:	0001c597          	auipc	a1,0x1c
    800035fe:	1c65a583          	lw	a1,454(a1) # 8001f7c0 <sb+0x18>
    80003602:	9dbd                	addw	a1,a1,a5
    80003604:	4108                	lw	a0,0(a0)
    80003606:	fffff097          	auipc	ra,0xfffff
    8000360a:	7dc080e7          	jalr	2012(ra) # 80002de2 <bread>
    8000360e:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003610:	05850793          	addi	a5,a0,88
    80003614:	40c8                	lw	a0,4(s1)
    80003616:	893d                	andi	a0,a0,15
    80003618:	051a                	slli	a0,a0,0x6
    8000361a:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    8000361c:	04449703          	lh	a4,68(s1)
    80003620:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003624:	04649703          	lh	a4,70(s1)
    80003628:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    8000362c:	04849703          	lh	a4,72(s1)
    80003630:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003634:	04a49703          	lh	a4,74(s1)
    80003638:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    8000363c:	44f8                	lw	a4,76(s1)
    8000363e:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003640:	03400613          	li	a2,52
    80003644:	05048593          	addi	a1,s1,80
    80003648:	0531                	addi	a0,a0,12
    8000364a:	ffffd097          	auipc	ra,0xffffd
    8000364e:	6d0080e7          	jalr	1744(ra) # 80000d1a <memmove>
  log_write(bp);
    80003652:	854a                	mv	a0,s2
    80003654:	00001097          	auipc	ra,0x1
    80003658:	d64080e7          	jalr	-668(ra) # 800043b8 <log_write>
  brelse(bp);
    8000365c:	854a                	mv	a0,s2
    8000365e:	00000097          	auipc	ra,0x0
    80003662:	8b4080e7          	jalr	-1868(ra) # 80002f12 <brelse>
}
    80003666:	60e2                	ld	ra,24(sp)
    80003668:	6442                	ld	s0,16(sp)
    8000366a:	64a2                	ld	s1,8(sp)
    8000366c:	6902                	ld	s2,0(sp)
    8000366e:	6105                	addi	sp,sp,32
    80003670:	8082                	ret

0000000080003672 <idup>:
{
    80003672:	1101                	addi	sp,sp,-32
    80003674:	ec06                	sd	ra,24(sp)
    80003676:	e822                	sd	s0,16(sp)
    80003678:	e426                	sd	s1,8(sp)
    8000367a:	1000                	addi	s0,sp,32
    8000367c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000367e:	0001c517          	auipc	a0,0x1c
    80003682:	14a50513          	addi	a0,a0,330 # 8001f7c8 <itable>
    80003686:	ffffd097          	auipc	ra,0xffffd
    8000368a:	53c080e7          	jalr	1340(ra) # 80000bc2 <acquire>
  ip->ref++;
    8000368e:	449c                	lw	a5,8(s1)
    80003690:	2785                	addiw	a5,a5,1
    80003692:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003694:	0001c517          	auipc	a0,0x1c
    80003698:	13450513          	addi	a0,a0,308 # 8001f7c8 <itable>
    8000369c:	ffffd097          	auipc	ra,0xffffd
    800036a0:	5da080e7          	jalr	1498(ra) # 80000c76 <release>
}
    800036a4:	8526                	mv	a0,s1
    800036a6:	60e2                	ld	ra,24(sp)
    800036a8:	6442                	ld	s0,16(sp)
    800036aa:	64a2                	ld	s1,8(sp)
    800036ac:	6105                	addi	sp,sp,32
    800036ae:	8082                	ret

00000000800036b0 <ilock>:
{
    800036b0:	1101                	addi	sp,sp,-32
    800036b2:	ec06                	sd	ra,24(sp)
    800036b4:	e822                	sd	s0,16(sp)
    800036b6:	e426                	sd	s1,8(sp)
    800036b8:	e04a                	sd	s2,0(sp)
    800036ba:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800036bc:	c115                	beqz	a0,800036e0 <ilock+0x30>
    800036be:	84aa                	mv	s1,a0
    800036c0:	451c                	lw	a5,8(a0)
    800036c2:	00f05f63          	blez	a5,800036e0 <ilock+0x30>
  acquiresleep(&ip->lock);
    800036c6:	0541                	addi	a0,a0,16
    800036c8:	00001097          	auipc	ra,0x1
    800036cc:	e10080e7          	jalr	-496(ra) # 800044d8 <acquiresleep>
  if(ip->valid == 0){
    800036d0:	40bc                	lw	a5,64(s1)
    800036d2:	cf99                	beqz	a5,800036f0 <ilock+0x40>
}
    800036d4:	60e2                	ld	ra,24(sp)
    800036d6:	6442                	ld	s0,16(sp)
    800036d8:	64a2                	ld	s1,8(sp)
    800036da:	6902                	ld	s2,0(sp)
    800036dc:	6105                	addi	sp,sp,32
    800036de:	8082                	ret
    panic("ilock");
    800036e0:	00005517          	auipc	a0,0x5
    800036e4:	ed850513          	addi	a0,a0,-296 # 800085b8 <syscalls+0x188>
    800036e8:	ffffd097          	auipc	ra,0xffffd
    800036ec:	e42080e7          	jalr	-446(ra) # 8000052a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800036f0:	40dc                	lw	a5,4(s1)
    800036f2:	0047d79b          	srliw	a5,a5,0x4
    800036f6:	0001c597          	auipc	a1,0x1c
    800036fa:	0ca5a583          	lw	a1,202(a1) # 8001f7c0 <sb+0x18>
    800036fe:	9dbd                	addw	a1,a1,a5
    80003700:	4088                	lw	a0,0(s1)
    80003702:	fffff097          	auipc	ra,0xfffff
    80003706:	6e0080e7          	jalr	1760(ra) # 80002de2 <bread>
    8000370a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000370c:	05850593          	addi	a1,a0,88
    80003710:	40dc                	lw	a5,4(s1)
    80003712:	8bbd                	andi	a5,a5,15
    80003714:	079a                	slli	a5,a5,0x6
    80003716:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003718:	00059783          	lh	a5,0(a1)
    8000371c:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003720:	00259783          	lh	a5,2(a1)
    80003724:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003728:	00459783          	lh	a5,4(a1)
    8000372c:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003730:	00659783          	lh	a5,6(a1)
    80003734:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003738:	459c                	lw	a5,8(a1)
    8000373a:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    8000373c:	03400613          	li	a2,52
    80003740:	05b1                	addi	a1,a1,12
    80003742:	05048513          	addi	a0,s1,80
    80003746:	ffffd097          	auipc	ra,0xffffd
    8000374a:	5d4080e7          	jalr	1492(ra) # 80000d1a <memmove>
    brelse(bp);
    8000374e:	854a                	mv	a0,s2
    80003750:	fffff097          	auipc	ra,0xfffff
    80003754:	7c2080e7          	jalr	1986(ra) # 80002f12 <brelse>
    ip->valid = 1;
    80003758:	4785                	li	a5,1
    8000375a:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    8000375c:	04449783          	lh	a5,68(s1)
    80003760:	fbb5                	bnez	a5,800036d4 <ilock+0x24>
      panic("ilock: no type");
    80003762:	00005517          	auipc	a0,0x5
    80003766:	e5e50513          	addi	a0,a0,-418 # 800085c0 <syscalls+0x190>
    8000376a:	ffffd097          	auipc	ra,0xffffd
    8000376e:	dc0080e7          	jalr	-576(ra) # 8000052a <panic>

0000000080003772 <iunlock>:
{
    80003772:	1101                	addi	sp,sp,-32
    80003774:	ec06                	sd	ra,24(sp)
    80003776:	e822                	sd	s0,16(sp)
    80003778:	e426                	sd	s1,8(sp)
    8000377a:	e04a                	sd	s2,0(sp)
    8000377c:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    8000377e:	c905                	beqz	a0,800037ae <iunlock+0x3c>
    80003780:	84aa                	mv	s1,a0
    80003782:	01050913          	addi	s2,a0,16
    80003786:	854a                	mv	a0,s2
    80003788:	00001097          	auipc	ra,0x1
    8000378c:	dea080e7          	jalr	-534(ra) # 80004572 <holdingsleep>
    80003790:	cd19                	beqz	a0,800037ae <iunlock+0x3c>
    80003792:	449c                	lw	a5,8(s1)
    80003794:	00f05d63          	blez	a5,800037ae <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003798:	854a                	mv	a0,s2
    8000379a:	00001097          	auipc	ra,0x1
    8000379e:	d94080e7          	jalr	-620(ra) # 8000452e <releasesleep>
}
    800037a2:	60e2                	ld	ra,24(sp)
    800037a4:	6442                	ld	s0,16(sp)
    800037a6:	64a2                	ld	s1,8(sp)
    800037a8:	6902                	ld	s2,0(sp)
    800037aa:	6105                	addi	sp,sp,32
    800037ac:	8082                	ret
    panic("iunlock");
    800037ae:	00005517          	auipc	a0,0x5
    800037b2:	e2250513          	addi	a0,a0,-478 # 800085d0 <syscalls+0x1a0>
    800037b6:	ffffd097          	auipc	ra,0xffffd
    800037ba:	d74080e7          	jalr	-652(ra) # 8000052a <panic>

00000000800037be <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800037be:	7159                	addi	sp,sp,-112
    800037c0:	f486                	sd	ra,104(sp)
    800037c2:	f0a2                	sd	s0,96(sp)
    800037c4:	eca6                	sd	s1,88(sp)
    800037c6:	e8ca                	sd	s2,80(sp)
    800037c8:	e4ce                	sd	s3,72(sp)
    800037ca:	e0d2                	sd	s4,64(sp)
    800037cc:	fc56                	sd	s5,56(sp)
    800037ce:	f85a                	sd	s6,48(sp)
    800037d0:	f45e                	sd	s7,40(sp)
    800037d2:	f062                	sd	s8,32(sp)
    800037d4:	ec66                	sd	s9,24(sp)
    800037d6:	e86a                	sd	s10,16(sp)
    800037d8:	e46e                	sd	s11,8(sp)
    800037da:	1880                	addi	s0,sp,112
    800037dc:	89aa                	mv	s3,a0
  // so that it can handle doubly indrect inode.
  int i, j;
  struct buf *bp, *bp2;
  uint *a, *a2;

  for(i = 0; i < NDIRECT; i++){
    800037de:	05050493          	addi	s1,a0,80
    800037e2:	07850913          	addi	s2,a0,120
    800037e6:	a021                	j	800037ee <itrunc+0x30>
    800037e8:	0491                	addi	s1,s1,4
    800037ea:	01248d63          	beq	s1,s2,80003804 <itrunc+0x46>
    if(ip->addrs[i]){
    800037ee:	408c                	lw	a1,0(s1)
    800037f0:	dde5                	beqz	a1,800037e8 <itrunc+0x2a>
      bfree(ip->dev, ip->addrs[i]);
    800037f2:	0009a503          	lw	a0,0(s3)
    800037f6:	00000097          	auipc	ra,0x0
    800037fa:	832080e7          	jalr	-1998(ra) # 80003028 <bfree>
      ip->addrs[i] = 0;
    800037fe:	0004a023          	sw	zero,0(s1)
    80003802:	b7dd                	j	800037e8 <itrunc+0x2a>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003804:	0789a583          	lw	a1,120(s3)
    80003808:	e1b1                	bnez	a1,8000384c <itrunc+0x8e>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  for(int i = 1; i <= 2; i++){
    8000380a:	07c98c13          	addi	s8,s3,124
    8000380e:	08498c93          	addi	s9,s3,132
	  if(ip->addrs[NDIRECT+i]){
    80003812:	8d62                	mv	s10,s8
    80003814:	000c2583          	lw	a1,0(s8)
    80003818:	e1d1                	bnez	a1,8000389c <itrunc+0xde>
  for(int i = 1; i <= 2; i++){
    8000381a:	0c11                	addi	s8,s8,4
    8000381c:	ff9c1be3          	bne	s8,s9,80003812 <itrunc+0x54>
		  bfree(ip->dev, ip->addrs[NDIRECT+i]);
		  ip->addrs[NDIRECT+i] = 0;
	  }
  }

  ip->size = 0;
    80003820:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003824:	854e                	mv	a0,s3
    80003826:	00000097          	auipc	ra,0x0
    8000382a:	dc0080e7          	jalr	-576(ra) # 800035e6 <iupdate>
}
    8000382e:	70a6                	ld	ra,104(sp)
    80003830:	7406                	ld	s0,96(sp)
    80003832:	64e6                	ld	s1,88(sp)
    80003834:	6946                	ld	s2,80(sp)
    80003836:	69a6                	ld	s3,72(sp)
    80003838:	6a06                	ld	s4,64(sp)
    8000383a:	7ae2                	ld	s5,56(sp)
    8000383c:	7b42                	ld	s6,48(sp)
    8000383e:	7ba2                	ld	s7,40(sp)
    80003840:	7c02                	ld	s8,32(sp)
    80003842:	6ce2                	ld	s9,24(sp)
    80003844:	6d42                	ld	s10,16(sp)
    80003846:	6da2                	ld	s11,8(sp)
    80003848:	6165                	addi	sp,sp,112
    8000384a:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    8000384c:	0009a503          	lw	a0,0(s3)
    80003850:	fffff097          	auipc	ra,0xfffff
    80003854:	592080e7          	jalr	1426(ra) # 80002de2 <bread>
    80003858:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    8000385a:	05850493          	addi	s1,a0,88
    8000385e:	45850913          	addi	s2,a0,1112
    80003862:	a811                	j	80003876 <itrunc+0xb8>
        bfree(ip->dev, a[j]);
    80003864:	0009a503          	lw	a0,0(s3)
    80003868:	fffff097          	auipc	ra,0xfffff
    8000386c:	7c0080e7          	jalr	1984(ra) # 80003028 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003870:	0491                	addi	s1,s1,4
    80003872:	01248563          	beq	s1,s2,8000387c <itrunc+0xbe>
      if(a[j])
    80003876:	408c                	lw	a1,0(s1)
    80003878:	dde5                	beqz	a1,80003870 <itrunc+0xb2>
    8000387a:	b7ed                	j	80003864 <itrunc+0xa6>
    brelse(bp);
    8000387c:	8552                	mv	a0,s4
    8000387e:	fffff097          	auipc	ra,0xfffff
    80003882:	694080e7          	jalr	1684(ra) # 80002f12 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003886:	0789a583          	lw	a1,120(s3)
    8000388a:	0009a503          	lw	a0,0(s3)
    8000388e:	fffff097          	auipc	ra,0xfffff
    80003892:	79a080e7          	jalr	1946(ra) # 80003028 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003896:	0609ac23          	sw	zero,120(s3)
    8000389a:	bf85                	j	8000380a <itrunc+0x4c>
		  bp = bread(ip->dev, ip->addrs[NDIRECT+i]);
    8000389c:	0009a503          	lw	a0,0(s3)
    800038a0:	fffff097          	auipc	ra,0xfffff
    800038a4:	542080e7          	jalr	1346(ra) # 80002de2 <bread>
    800038a8:	8daa                	mv	s11,a0
		  for(j = 0; j < NINDIRECT; j++){
    800038aa:	05850a13          	addi	s4,a0,88
    800038ae:	45850b13          	addi	s6,a0,1112
    800038b2:	a82d                	j	800038ec <itrunc+0x12e>
				  for(int y = 0; y < NINDIRECT; y++){
    800038b4:	0491                	addi	s1,s1,4
    800038b6:	01248b63          	beq	s1,s2,800038cc <itrunc+0x10e>
					  if(a2[y])
    800038ba:	408c                	lw	a1,0(s1)
    800038bc:	dde5                	beqz	a1,800038b4 <itrunc+0xf6>
						  bfree(ip->dev, a2[y]);
    800038be:	0009a503          	lw	a0,0(s3)
    800038c2:	fffff097          	auipc	ra,0xfffff
    800038c6:	766080e7          	jalr	1894(ra) # 80003028 <bfree>
    800038ca:	b7ed                	j	800038b4 <itrunc+0xf6>
				  brelse(bp2);
    800038cc:	855e                	mv	a0,s7
    800038ce:	fffff097          	auipc	ra,0xfffff
    800038d2:	644080e7          	jalr	1604(ra) # 80002f12 <brelse>
				  bfree(ip->dev, a[j]);//free indirect block
    800038d6:	000aa583          	lw	a1,0(s5)
    800038da:	0009a503          	lw	a0,0(s3)
    800038de:	fffff097          	auipc	ra,0xfffff
    800038e2:	74a080e7          	jalr	1866(ra) # 80003028 <bfree>
		  for(j = 0; j < NINDIRECT; j++){
    800038e6:	0a11                	addi	s4,s4,4
    800038e8:	036a0263          	beq	s4,s6,8000390c <itrunc+0x14e>
			  if(a[j]){
    800038ec:	8ad2                	mv	s5,s4
    800038ee:	000a2583          	lw	a1,0(s4)
    800038f2:	d9f5                	beqz	a1,800038e6 <itrunc+0x128>
				  bp2 = bread(ip->dev, a[j]);
    800038f4:	0009a503          	lw	a0,0(s3)
    800038f8:	fffff097          	auipc	ra,0xfffff
    800038fc:	4ea080e7          	jalr	1258(ra) # 80002de2 <bread>
    80003900:	8baa                	mv	s7,a0
				  for(int y = 0; y < NINDIRECT; y++){
    80003902:	05850493          	addi	s1,a0,88
    80003906:	45850913          	addi	s2,a0,1112
    8000390a:	bf45                	j	800038ba <itrunc+0xfc>
		  brelse(bp);
    8000390c:	856e                	mv	a0,s11
    8000390e:	fffff097          	auipc	ra,0xfffff
    80003912:	604080e7          	jalr	1540(ra) # 80002f12 <brelse>
		  bfree(ip->dev, ip->addrs[NDIRECT+i]);
    80003916:	000d2583          	lw	a1,0(s10)
    8000391a:	0009a503          	lw	a0,0(s3)
    8000391e:	fffff097          	auipc	ra,0xfffff
    80003922:	70a080e7          	jalr	1802(ra) # 80003028 <bfree>
		  ip->addrs[NDIRECT+i] = 0;
    80003926:	000d2023          	sw	zero,0(s10)
    8000392a:	bdc5                	j	8000381a <itrunc+0x5c>

000000008000392c <iput>:
{
    8000392c:	1101                	addi	sp,sp,-32
    8000392e:	ec06                	sd	ra,24(sp)
    80003930:	e822                	sd	s0,16(sp)
    80003932:	e426                	sd	s1,8(sp)
    80003934:	e04a                	sd	s2,0(sp)
    80003936:	1000                	addi	s0,sp,32
    80003938:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000393a:	0001c517          	auipc	a0,0x1c
    8000393e:	e8e50513          	addi	a0,a0,-370 # 8001f7c8 <itable>
    80003942:	ffffd097          	auipc	ra,0xffffd
    80003946:	280080e7          	jalr	640(ra) # 80000bc2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000394a:	4498                	lw	a4,8(s1)
    8000394c:	4785                	li	a5,1
    8000394e:	02f70363          	beq	a4,a5,80003974 <iput+0x48>
  ip->ref--;
    80003952:	449c                	lw	a5,8(s1)
    80003954:	37fd                	addiw	a5,a5,-1
    80003956:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003958:	0001c517          	auipc	a0,0x1c
    8000395c:	e7050513          	addi	a0,a0,-400 # 8001f7c8 <itable>
    80003960:	ffffd097          	auipc	ra,0xffffd
    80003964:	316080e7          	jalr	790(ra) # 80000c76 <release>
}
    80003968:	60e2                	ld	ra,24(sp)
    8000396a:	6442                	ld	s0,16(sp)
    8000396c:	64a2                	ld	s1,8(sp)
    8000396e:	6902                	ld	s2,0(sp)
    80003970:	6105                	addi	sp,sp,32
    80003972:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003974:	40bc                	lw	a5,64(s1)
    80003976:	dff1                	beqz	a5,80003952 <iput+0x26>
    80003978:	04a49783          	lh	a5,74(s1)
    8000397c:	fbf9                	bnez	a5,80003952 <iput+0x26>
    acquiresleep(&ip->lock);
    8000397e:	01048913          	addi	s2,s1,16
    80003982:	854a                	mv	a0,s2
    80003984:	00001097          	auipc	ra,0x1
    80003988:	b54080e7          	jalr	-1196(ra) # 800044d8 <acquiresleep>
    release(&itable.lock);
    8000398c:	0001c517          	auipc	a0,0x1c
    80003990:	e3c50513          	addi	a0,a0,-452 # 8001f7c8 <itable>
    80003994:	ffffd097          	auipc	ra,0xffffd
    80003998:	2e2080e7          	jalr	738(ra) # 80000c76 <release>
    itrunc(ip);
    8000399c:	8526                	mv	a0,s1
    8000399e:	00000097          	auipc	ra,0x0
    800039a2:	e20080e7          	jalr	-480(ra) # 800037be <itrunc>
    ip->type = 0;
    800039a6:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800039aa:	8526                	mv	a0,s1
    800039ac:	00000097          	auipc	ra,0x0
    800039b0:	c3a080e7          	jalr	-966(ra) # 800035e6 <iupdate>
    ip->valid = 0;
    800039b4:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800039b8:	854a                	mv	a0,s2
    800039ba:	00001097          	auipc	ra,0x1
    800039be:	b74080e7          	jalr	-1164(ra) # 8000452e <releasesleep>
    acquire(&itable.lock);
    800039c2:	0001c517          	auipc	a0,0x1c
    800039c6:	e0650513          	addi	a0,a0,-506 # 8001f7c8 <itable>
    800039ca:	ffffd097          	auipc	ra,0xffffd
    800039ce:	1f8080e7          	jalr	504(ra) # 80000bc2 <acquire>
    800039d2:	b741                	j	80003952 <iput+0x26>

00000000800039d4 <iunlockput>:
{
    800039d4:	1101                	addi	sp,sp,-32
    800039d6:	ec06                	sd	ra,24(sp)
    800039d8:	e822                	sd	s0,16(sp)
    800039da:	e426                	sd	s1,8(sp)
    800039dc:	1000                	addi	s0,sp,32
    800039de:	84aa                	mv	s1,a0
  iunlock(ip);
    800039e0:	00000097          	auipc	ra,0x0
    800039e4:	d92080e7          	jalr	-622(ra) # 80003772 <iunlock>
  iput(ip);
    800039e8:	8526                	mv	a0,s1
    800039ea:	00000097          	auipc	ra,0x0
    800039ee:	f42080e7          	jalr	-190(ra) # 8000392c <iput>
}
    800039f2:	60e2                	ld	ra,24(sp)
    800039f4:	6442                	ld	s0,16(sp)
    800039f6:	64a2                	ld	s1,8(sp)
    800039f8:	6105                	addi	sp,sp,32
    800039fa:	8082                	ret

00000000800039fc <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800039fc:	1141                	addi	sp,sp,-16
    800039fe:	e422                	sd	s0,8(sp)
    80003a00:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003a02:	411c                	lw	a5,0(a0)
    80003a04:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003a06:	415c                	lw	a5,4(a0)
    80003a08:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003a0a:	04451783          	lh	a5,68(a0)
    80003a0e:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003a12:	04a51783          	lh	a5,74(a0)
    80003a16:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003a1a:	04c56783          	lwu	a5,76(a0)
    80003a1e:	e99c                	sd	a5,16(a1)
}
    80003a20:	6422                	ld	s0,8(sp)
    80003a22:	0141                	addi	sp,sp,16
    80003a24:	8082                	ret

0000000080003a26 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a26:	457c                	lw	a5,76(a0)
    80003a28:	0ed7e963          	bltu	a5,a3,80003b1a <readi+0xf4>
{
    80003a2c:	7159                	addi	sp,sp,-112
    80003a2e:	f486                	sd	ra,104(sp)
    80003a30:	f0a2                	sd	s0,96(sp)
    80003a32:	eca6                	sd	s1,88(sp)
    80003a34:	e8ca                	sd	s2,80(sp)
    80003a36:	e4ce                	sd	s3,72(sp)
    80003a38:	e0d2                	sd	s4,64(sp)
    80003a3a:	fc56                	sd	s5,56(sp)
    80003a3c:	f85a                	sd	s6,48(sp)
    80003a3e:	f45e                	sd	s7,40(sp)
    80003a40:	f062                	sd	s8,32(sp)
    80003a42:	ec66                	sd	s9,24(sp)
    80003a44:	e86a                	sd	s10,16(sp)
    80003a46:	e46e                	sd	s11,8(sp)
    80003a48:	1880                	addi	s0,sp,112
    80003a4a:	8baa                	mv	s7,a0
    80003a4c:	8c2e                	mv	s8,a1
    80003a4e:	8ab2                	mv	s5,a2
    80003a50:	84b6                	mv	s1,a3
    80003a52:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003a54:	9f35                	addw	a4,a4,a3
    return 0;
    80003a56:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003a58:	0ad76063          	bltu	a4,a3,80003af8 <readi+0xd2>
  if(off + n > ip->size)
    80003a5c:	00e7f463          	bgeu	a5,a4,80003a64 <readi+0x3e>
    n = ip->size - off;
    80003a60:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a64:	0a0b0963          	beqz	s6,80003b16 <readi+0xf0>
    80003a68:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a6a:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003a6e:	5cfd                	li	s9,-1
    80003a70:	a82d                	j	80003aaa <readi+0x84>
    80003a72:	020a1d93          	slli	s11,s4,0x20
    80003a76:	020ddd93          	srli	s11,s11,0x20
    80003a7a:	05890793          	addi	a5,s2,88
    80003a7e:	86ee                	mv	a3,s11
    80003a80:	963e                	add	a2,a2,a5
    80003a82:	85d6                	mv	a1,s5
    80003a84:	8562                	mv	a0,s8
    80003a86:	fffff097          	auipc	ra,0xfffff
    80003a8a:	9a2080e7          	jalr	-1630(ra) # 80002428 <either_copyout>
    80003a8e:	05950d63          	beq	a0,s9,80003ae8 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003a92:	854a                	mv	a0,s2
    80003a94:	fffff097          	auipc	ra,0xfffff
    80003a98:	47e080e7          	jalr	1150(ra) # 80002f12 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a9c:	013a09bb          	addw	s3,s4,s3
    80003aa0:	009a04bb          	addw	s1,s4,s1
    80003aa4:	9aee                	add	s5,s5,s11
    80003aa6:	0569f763          	bgeu	s3,s6,80003af4 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003aaa:	000ba903          	lw	s2,0(s7)
    80003aae:	00a4d59b          	srliw	a1,s1,0xa
    80003ab2:	855e                	mv	a0,s7
    80003ab4:	fffff097          	auipc	ra,0xfffff
    80003ab8:	722080e7          	jalr	1826(ra) # 800031d6 <bmap>
    80003abc:	0005059b          	sext.w	a1,a0
    80003ac0:	854a                	mv	a0,s2
    80003ac2:	fffff097          	auipc	ra,0xfffff
    80003ac6:	320080e7          	jalr	800(ra) # 80002de2 <bread>
    80003aca:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003acc:	3ff4f613          	andi	a2,s1,1023
    80003ad0:	40cd07bb          	subw	a5,s10,a2
    80003ad4:	413b073b          	subw	a4,s6,s3
    80003ad8:	8a3e                	mv	s4,a5
    80003ada:	2781                	sext.w	a5,a5
    80003adc:	0007069b          	sext.w	a3,a4
    80003ae0:	f8f6f9e3          	bgeu	a3,a5,80003a72 <readi+0x4c>
    80003ae4:	8a3a                	mv	s4,a4
    80003ae6:	b771                	j	80003a72 <readi+0x4c>
      brelse(bp);
    80003ae8:	854a                	mv	a0,s2
    80003aea:	fffff097          	auipc	ra,0xfffff
    80003aee:	428080e7          	jalr	1064(ra) # 80002f12 <brelse>
      tot = -1;
    80003af2:	59fd                	li	s3,-1
  }
  return tot;
    80003af4:	0009851b          	sext.w	a0,s3
}
    80003af8:	70a6                	ld	ra,104(sp)
    80003afa:	7406                	ld	s0,96(sp)
    80003afc:	64e6                	ld	s1,88(sp)
    80003afe:	6946                	ld	s2,80(sp)
    80003b00:	69a6                	ld	s3,72(sp)
    80003b02:	6a06                	ld	s4,64(sp)
    80003b04:	7ae2                	ld	s5,56(sp)
    80003b06:	7b42                	ld	s6,48(sp)
    80003b08:	7ba2                	ld	s7,40(sp)
    80003b0a:	7c02                	ld	s8,32(sp)
    80003b0c:	6ce2                	ld	s9,24(sp)
    80003b0e:	6d42                	ld	s10,16(sp)
    80003b10:	6da2                	ld	s11,8(sp)
    80003b12:	6165                	addi	sp,sp,112
    80003b14:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b16:	89da                	mv	s3,s6
    80003b18:	bff1                	j	80003af4 <readi+0xce>
    return 0;
    80003b1a:	4501                	li	a0,0
}
    80003b1c:	8082                	ret

0000000080003b1e <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b1e:	457c                	lw	a5,76(a0)
    80003b20:	10d7e963          	bltu	a5,a3,80003c32 <writei+0x114>
{
    80003b24:	7159                	addi	sp,sp,-112
    80003b26:	f486                	sd	ra,104(sp)
    80003b28:	f0a2                	sd	s0,96(sp)
    80003b2a:	eca6                	sd	s1,88(sp)
    80003b2c:	e8ca                	sd	s2,80(sp)
    80003b2e:	e4ce                	sd	s3,72(sp)
    80003b30:	e0d2                	sd	s4,64(sp)
    80003b32:	fc56                	sd	s5,56(sp)
    80003b34:	f85a                	sd	s6,48(sp)
    80003b36:	f45e                	sd	s7,40(sp)
    80003b38:	f062                	sd	s8,32(sp)
    80003b3a:	ec66                	sd	s9,24(sp)
    80003b3c:	e86a                	sd	s10,16(sp)
    80003b3e:	e46e                	sd	s11,8(sp)
    80003b40:	1880                	addi	s0,sp,112
    80003b42:	8b2a                	mv	s6,a0
    80003b44:	8c2e                	mv	s8,a1
    80003b46:	8ab2                	mv	s5,a2
    80003b48:	8936                	mv	s2,a3
    80003b4a:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003b4c:	9f35                	addw	a4,a4,a3
    80003b4e:	0ed76463          	bltu	a4,a3,80003c36 <writei+0x118>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003b52:	080437b7          	lui	a5,0x8043
    80003b56:	80078793          	addi	a5,a5,-2048 # 8042800 <_entry-0x77fbd800>
    80003b5a:	0ee7e063          	bltu	a5,a4,80003c3a <writei+0x11c>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b5e:	0c0b8863          	beqz	s7,80003c2e <writei+0x110>
    80003b62:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b64:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003b68:	5cfd                	li	s9,-1
    80003b6a:	a091                	j	80003bae <writei+0x90>
    80003b6c:	02099d93          	slli	s11,s3,0x20
    80003b70:	020ddd93          	srli	s11,s11,0x20
    80003b74:	05848793          	addi	a5,s1,88
    80003b78:	86ee                	mv	a3,s11
    80003b7a:	8656                	mv	a2,s5
    80003b7c:	85e2                	mv	a1,s8
    80003b7e:	953e                	add	a0,a0,a5
    80003b80:	fffff097          	auipc	ra,0xfffff
    80003b84:	8fe080e7          	jalr	-1794(ra) # 8000247e <either_copyin>
    80003b88:	07950263          	beq	a0,s9,80003bec <writei+0xce>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003b8c:	8526                	mv	a0,s1
    80003b8e:	00001097          	auipc	ra,0x1
    80003b92:	82a080e7          	jalr	-2006(ra) # 800043b8 <log_write>
    brelse(bp);
    80003b96:	8526                	mv	a0,s1
    80003b98:	fffff097          	auipc	ra,0xfffff
    80003b9c:	37a080e7          	jalr	890(ra) # 80002f12 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ba0:	01498a3b          	addw	s4,s3,s4
    80003ba4:	0129893b          	addw	s2,s3,s2
    80003ba8:	9aee                	add	s5,s5,s11
    80003baa:	057a7663          	bgeu	s4,s7,80003bf6 <writei+0xd8>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003bae:	000b2483          	lw	s1,0(s6)
    80003bb2:	00a9559b          	srliw	a1,s2,0xa
    80003bb6:	855a                	mv	a0,s6
    80003bb8:	fffff097          	auipc	ra,0xfffff
    80003bbc:	61e080e7          	jalr	1566(ra) # 800031d6 <bmap>
    80003bc0:	0005059b          	sext.w	a1,a0
    80003bc4:	8526                	mv	a0,s1
    80003bc6:	fffff097          	auipc	ra,0xfffff
    80003bca:	21c080e7          	jalr	540(ra) # 80002de2 <bread>
    80003bce:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bd0:	3ff97513          	andi	a0,s2,1023
    80003bd4:	40ad07bb          	subw	a5,s10,a0
    80003bd8:	414b873b          	subw	a4,s7,s4
    80003bdc:	89be                	mv	s3,a5
    80003bde:	2781                	sext.w	a5,a5
    80003be0:	0007069b          	sext.w	a3,a4
    80003be4:	f8f6f4e3          	bgeu	a3,a5,80003b6c <writei+0x4e>
    80003be8:	89ba                	mv	s3,a4
    80003bea:	b749                	j	80003b6c <writei+0x4e>
      brelse(bp);
    80003bec:	8526                	mv	a0,s1
    80003bee:	fffff097          	auipc	ra,0xfffff
    80003bf2:	324080e7          	jalr	804(ra) # 80002f12 <brelse>
  }

  if(off > ip->size)
    80003bf6:	04cb2783          	lw	a5,76(s6)
    80003bfa:	0127f463          	bgeu	a5,s2,80003c02 <writei+0xe4>
    ip->size = off;
    80003bfe:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003c02:	855a                	mv	a0,s6
    80003c04:	00000097          	auipc	ra,0x0
    80003c08:	9e2080e7          	jalr	-1566(ra) # 800035e6 <iupdate>

  return tot;
    80003c0c:	000a051b          	sext.w	a0,s4
}
    80003c10:	70a6                	ld	ra,104(sp)
    80003c12:	7406                	ld	s0,96(sp)
    80003c14:	64e6                	ld	s1,88(sp)
    80003c16:	6946                	ld	s2,80(sp)
    80003c18:	69a6                	ld	s3,72(sp)
    80003c1a:	6a06                	ld	s4,64(sp)
    80003c1c:	7ae2                	ld	s5,56(sp)
    80003c1e:	7b42                	ld	s6,48(sp)
    80003c20:	7ba2                	ld	s7,40(sp)
    80003c22:	7c02                	ld	s8,32(sp)
    80003c24:	6ce2                	ld	s9,24(sp)
    80003c26:	6d42                	ld	s10,16(sp)
    80003c28:	6da2                	ld	s11,8(sp)
    80003c2a:	6165                	addi	sp,sp,112
    80003c2c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c2e:	8a5e                	mv	s4,s7
    80003c30:	bfc9                	j	80003c02 <writei+0xe4>
    return -1;
    80003c32:	557d                	li	a0,-1
}
    80003c34:	8082                	ret
    return -1;
    80003c36:	557d                	li	a0,-1
    80003c38:	bfe1                	j	80003c10 <writei+0xf2>
    return -1;
    80003c3a:	557d                	li	a0,-1
    80003c3c:	bfd1                	j	80003c10 <writei+0xf2>

0000000080003c3e <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003c3e:	1141                	addi	sp,sp,-16
    80003c40:	e406                	sd	ra,8(sp)
    80003c42:	e022                	sd	s0,0(sp)
    80003c44:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003c46:	4639                	li	a2,14
    80003c48:	ffffd097          	auipc	ra,0xffffd
    80003c4c:	14e080e7          	jalr	334(ra) # 80000d96 <strncmp>
}
    80003c50:	60a2                	ld	ra,8(sp)
    80003c52:	6402                	ld	s0,0(sp)
    80003c54:	0141                	addi	sp,sp,16
    80003c56:	8082                	ret

0000000080003c58 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003c58:	7139                	addi	sp,sp,-64
    80003c5a:	fc06                	sd	ra,56(sp)
    80003c5c:	f822                	sd	s0,48(sp)
    80003c5e:	f426                	sd	s1,40(sp)
    80003c60:	f04a                	sd	s2,32(sp)
    80003c62:	ec4e                	sd	s3,24(sp)
    80003c64:	e852                	sd	s4,16(sp)
    80003c66:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003c68:	04451703          	lh	a4,68(a0)
    80003c6c:	4785                	li	a5,1
    80003c6e:	00f71a63          	bne	a4,a5,80003c82 <dirlookup+0x2a>
    80003c72:	892a                	mv	s2,a0
    80003c74:	89ae                	mv	s3,a1
    80003c76:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c78:	457c                	lw	a5,76(a0)
    80003c7a:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003c7c:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c7e:	e79d                	bnez	a5,80003cac <dirlookup+0x54>
    80003c80:	a8a5                	j	80003cf8 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003c82:	00005517          	auipc	a0,0x5
    80003c86:	95650513          	addi	a0,a0,-1706 # 800085d8 <syscalls+0x1a8>
    80003c8a:	ffffd097          	auipc	ra,0xffffd
    80003c8e:	8a0080e7          	jalr	-1888(ra) # 8000052a <panic>
      panic("dirlookup read");
    80003c92:	00005517          	auipc	a0,0x5
    80003c96:	95e50513          	addi	a0,a0,-1698 # 800085f0 <syscalls+0x1c0>
    80003c9a:	ffffd097          	auipc	ra,0xffffd
    80003c9e:	890080e7          	jalr	-1904(ra) # 8000052a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ca2:	24c1                	addiw	s1,s1,16
    80003ca4:	04c92783          	lw	a5,76(s2)
    80003ca8:	04f4f763          	bgeu	s1,a5,80003cf6 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003cac:	4741                	li	a4,16
    80003cae:	86a6                	mv	a3,s1
    80003cb0:	fc040613          	addi	a2,s0,-64
    80003cb4:	4581                	li	a1,0
    80003cb6:	854a                	mv	a0,s2
    80003cb8:	00000097          	auipc	ra,0x0
    80003cbc:	d6e080e7          	jalr	-658(ra) # 80003a26 <readi>
    80003cc0:	47c1                	li	a5,16
    80003cc2:	fcf518e3          	bne	a0,a5,80003c92 <dirlookup+0x3a>
    if(de.inum == 0)
    80003cc6:	fc045783          	lhu	a5,-64(s0)
    80003cca:	dfe1                	beqz	a5,80003ca2 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003ccc:	fc240593          	addi	a1,s0,-62
    80003cd0:	854e                	mv	a0,s3
    80003cd2:	00000097          	auipc	ra,0x0
    80003cd6:	f6c080e7          	jalr	-148(ra) # 80003c3e <namecmp>
    80003cda:	f561                	bnez	a0,80003ca2 <dirlookup+0x4a>
      if(poff)
    80003cdc:	000a0463          	beqz	s4,80003ce4 <dirlookup+0x8c>
        *poff = off;
    80003ce0:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003ce4:	fc045583          	lhu	a1,-64(s0)
    80003ce8:	00092503          	lw	a0,0(s2)
    80003cec:	fffff097          	auipc	ra,0xfffff
    80003cf0:	690080e7          	jalr	1680(ra) # 8000337c <iget>
    80003cf4:	a011                	j	80003cf8 <dirlookup+0xa0>
  return 0;
    80003cf6:	4501                	li	a0,0
}
    80003cf8:	70e2                	ld	ra,56(sp)
    80003cfa:	7442                	ld	s0,48(sp)
    80003cfc:	74a2                	ld	s1,40(sp)
    80003cfe:	7902                	ld	s2,32(sp)
    80003d00:	69e2                	ld	s3,24(sp)
    80003d02:	6a42                	ld	s4,16(sp)
    80003d04:	6121                	addi	sp,sp,64
    80003d06:	8082                	ret

0000000080003d08 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name, int follow, int cnt)
{
    80003d08:	7111                	addi	sp,sp,-256
    80003d0a:	fd86                	sd	ra,248(sp)
    80003d0c:	f9a2                	sd	s0,240(sp)
    80003d0e:	f5a6                	sd	s1,232(sp)
    80003d10:	f1ca                	sd	s2,224(sp)
    80003d12:	edce                	sd	s3,216(sp)
    80003d14:	e9d2                	sd	s4,208(sp)
    80003d16:	e5d6                	sd	s5,200(sp)
    80003d18:	e1da                	sd	s6,192(sp)
    80003d1a:	fd5e                	sd	s7,184(sp)
    80003d1c:	f962                	sd	s8,176(sp)
    80003d1e:	f566                	sd	s9,168(sp)
    80003d20:	0200                	addi	s0,sp,256
  // TODO: Symbolic Link to Directories
  // Modify this function to deal with symbolic links to directories.
  if(cnt >= 13) return 0;
    80003d22:	47b1                	li	a5,12
    80003d24:	1ae7cb63          	blt	a5,a4,80003eda <namex+0x1d2>
    80003d28:	84aa                	mv	s1,a0
    80003d2a:	8aae                	mv	s5,a1
    80003d2c:	8a32                	mv	s4,a2
    80003d2e:	8c36                	mv	s8,a3
    80003d30:	8bba                	mv	s7,a4
  struct inode *ip, *next;
  
  if(*path == '/')
    80003d32:	00054703          	lbu	a4,0(a0)
    80003d36:	02f00793          	li	a5,47
    80003d3a:	02f70263          	beq	a4,a5,80003d5e <namex+0x56>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003d3e:	ffffe097          	auipc	ra,0xffffe
    80003d42:	c82080e7          	jalr	-894(ra) # 800019c0 <myproc>
    80003d46:	15053503          	ld	a0,336(a0)
    80003d4a:	00000097          	auipc	ra,0x0
    80003d4e:	928080e7          	jalr	-1752(ra) # 80003672 <idup>
    80003d52:	89aa                	mv	s3,a0
  while(*path == '/')
    80003d54:	02f00913          	li	s2,47
  len = path - s;
    80003d58:	4b01                	li	s6,0
		  char path_foo[MAXPATH];
		  readi(ip, 0, (uint64)&len, 0, sizeof(int));
		  readi(ip, 0, (uint64)path_foo, sizeof(int), len + 1);
		  iunlockput(ip);
		  char name_foo[DIRSIZ];
		  if((ip = namex(path_foo, nameiparent, name_foo, 1, cnt + 1)) == 0){
    80003d5a:	2b85                	addiw	s7,s7,1
    80003d5c:	a8b9                	j	80003dba <namex+0xb2>
    ip = iget(ROOTDEV, ROOTINO);
    80003d5e:	4585                	li	a1,1
    80003d60:	4505                	li	a0,1
    80003d62:	fffff097          	auipc	ra,0xfffff
    80003d66:	61a080e7          	jalr	1562(ra) # 8000337c <iget>
    80003d6a:	89aa                	mv	s3,a0
    80003d6c:	b7e5                	j	80003d54 <namex+0x4c>
      iunlockput(ip);
    80003d6e:	854e                	mv	a0,s3
    80003d70:	00000097          	auipc	ra,0x0
    80003d74:	c64080e7          	jalr	-924(ra) # 800039d4 <iunlockput>
      return 0;
    80003d78:	4981                	li	s3,0
  if(nameiparent){
	iput(ip);
    return 0;
  } 
  return ip;
}
    80003d7a:	854e                	mv	a0,s3
    80003d7c:	70ee                	ld	ra,248(sp)
    80003d7e:	744e                	ld	s0,240(sp)
    80003d80:	74ae                	ld	s1,232(sp)
    80003d82:	790e                	ld	s2,224(sp)
    80003d84:	69ee                	ld	s3,216(sp)
    80003d86:	6a4e                	ld	s4,208(sp)
    80003d88:	6aae                	ld	s5,200(sp)
    80003d8a:	6b0e                	ld	s6,192(sp)
    80003d8c:	7bea                	ld	s7,184(sp)
    80003d8e:	7c4a                	ld	s8,176(sp)
    80003d90:	7caa                	ld	s9,168(sp)
    80003d92:	6111                	addi	sp,sp,256
    80003d94:	8082                	ret
      iunlock(ip);
    80003d96:	854e                	mv	a0,s3
    80003d98:	00000097          	auipc	ra,0x0
    80003d9c:	9da080e7          	jalr	-1574(ra) # 80003772 <iunlock>
      return ip;
    80003da0:	bfe9                	j	80003d7a <namex+0x72>
      iunlockput(ip);
    80003da2:	854e                	mv	a0,s3
    80003da4:	00000097          	auipc	ra,0x0
    80003da8:	c30080e7          	jalr	-976(ra) # 800039d4 <iunlockput>
      return 0;
    80003dac:	89e6                	mv	s3,s9
    80003dae:	b7f1                	j	80003d7a <namex+0x72>
  	} else iunlockput(ip);
    80003db0:	854e                	mv	a0,s3
    80003db2:	00000097          	auipc	ra,0x0
    80003db6:	c22080e7          	jalr	-990(ra) # 800039d4 <iunlockput>
  while(*path == '/')
    80003dba:	0004c783          	lbu	a5,0(s1)
    80003dbe:	13279963          	bne	a5,s2,80003ef0 <namex+0x1e8>
    path++;
    80003dc2:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003dc4:	0004c783          	lbu	a5,0(s1)
    80003dc8:	ff278de3          	beq	a5,s2,80003dc2 <namex+0xba>
  if(*path == 0)
    80003dcc:	10078963          	beqz	a5,80003ede <namex+0x1d6>
    path++;
    80003dd0:	85a6                	mv	a1,s1
  len = path - s;
    80003dd2:	8cda                	mv	s9,s6
    80003dd4:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80003dd6:	0f278863          	beq	a5,s2,80003ec6 <namex+0x1be>
    80003dda:	c791                	beqz	a5,80003de6 <namex+0xde>
    path++;
    80003ddc:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003dde:	0004c783          	lbu	a5,0(s1)
    80003de2:	ff279ce3          	bne	a5,s2,80003dda <namex+0xd2>
  len = path - s;
    80003de6:	40b48633          	sub	a2,s1,a1
    80003dea:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003dee:	47b5                	li	a5,13
    80003df0:	0d97db63          	bge	a5,s9,80003ec6 <namex+0x1be>
    memmove(name, s, DIRSIZ);
    80003df4:	4639                	li	a2,14
    80003df6:	8552                	mv	a0,s4
    80003df8:	ffffd097          	auipc	ra,0xffffd
    80003dfc:	f22080e7          	jalr	-222(ra) # 80000d1a <memmove>
  while(*path == '/')
    80003e00:	0004c783          	lbu	a5,0(s1)
    80003e04:	01279763          	bne	a5,s2,80003e12 <namex+0x10a>
    path++;
    80003e08:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e0a:	0004c783          	lbu	a5,0(s1)
    80003e0e:	ff278de3          	beq	a5,s2,80003e08 <namex+0x100>
    ilock(ip);
    80003e12:	854e                	mv	a0,s3
    80003e14:	00000097          	auipc	ra,0x0
    80003e18:	89c080e7          	jalr	-1892(ra) # 800036b0 <ilock>
    if(ip->type != T_DIR){
    80003e1c:	04499703          	lh	a4,68(s3)
    80003e20:	4785                	li	a5,1
    80003e22:	f4f716e3          	bne	a4,a5,80003d6e <namex+0x66>
    if(nameiparent && *path == '\0'){
    80003e26:	000a8563          	beqz	s5,80003e30 <namex+0x128>
    80003e2a:	0004c783          	lbu	a5,0(s1)
    80003e2e:	d7a5                	beqz	a5,80003d96 <namex+0x8e>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003e30:	865a                	mv	a2,s6
    80003e32:	85d2                	mv	a1,s4
    80003e34:	854e                	mv	a0,s3
    80003e36:	00000097          	auipc	ra,0x0
    80003e3a:	e22080e7          	jalr	-478(ra) # 80003c58 <dirlookup>
    80003e3e:	8caa                	mv	s9,a0
    80003e40:	d12d                	beqz	a0,80003da2 <namex+0x9a>
    iunlockput(ip);
    80003e42:	854e                	mv	a0,s3
    80003e44:	00000097          	auipc	ra,0x0
    80003e48:	b90080e7          	jalr	-1136(ra) # 800039d4 <iunlockput>
	ip = idup(ip);
    80003e4c:	8566                	mv	a0,s9
    80003e4e:	00000097          	auipc	ra,0x0
    80003e52:	824080e7          	jalr	-2012(ra) # 80003672 <idup>
    80003e56:	89aa                	mv	s3,a0
	ilock(ip);
    80003e58:	00000097          	auipc	ra,0x0
    80003e5c:	858080e7          	jalr	-1960(ra) # 800036b0 <ilock>
  	if(ip->type == T_SYMLINK && follow){
    80003e60:	04499703          	lh	a4,68(s3)
    80003e64:	4791                	li	a5,4
    80003e66:	f4f715e3          	bne	a4,a5,80003db0 <namex+0xa8>
    80003e6a:	f40c03e3          	beqz	s8,80003db0 <namex+0xa8>
		  int len = 0;
    80003e6e:	f0042623          	sw	zero,-244(s0)
		  readi(ip, 0, (uint64)&len, 0, sizeof(int));
    80003e72:	4711                	li	a4,4
    80003e74:	86da                	mv	a3,s6
    80003e76:	f0c40613          	addi	a2,s0,-244
    80003e7a:	85da                	mv	a1,s6
    80003e7c:	854e                	mv	a0,s3
    80003e7e:	00000097          	auipc	ra,0x0
    80003e82:	ba8080e7          	jalr	-1112(ra) # 80003a26 <readi>
		  readi(ip, 0, (uint64)path_foo, sizeof(int), len + 1);
    80003e86:	f0c42703          	lw	a4,-244(s0)
    80003e8a:	2705                	addiw	a4,a4,1
    80003e8c:	4691                	li	a3,4
    80003e8e:	f2040613          	addi	a2,s0,-224
    80003e92:	85da                	mv	a1,s6
    80003e94:	854e                	mv	a0,s3
    80003e96:	00000097          	auipc	ra,0x0
    80003e9a:	b90080e7          	jalr	-1136(ra) # 80003a26 <readi>
		  iunlockput(ip);
    80003e9e:	854e                	mv	a0,s3
    80003ea0:	00000097          	auipc	ra,0x0
    80003ea4:	b34080e7          	jalr	-1228(ra) # 800039d4 <iunlockput>
		  if((ip = namex(path_foo, nameiparent, name_foo, 1, cnt + 1)) == 0){
    80003ea8:	875e                	mv	a4,s7
    80003eaa:	4685                	li	a3,1
    80003eac:	f1040613          	addi	a2,s0,-240
    80003eb0:	85d6                	mv	a1,s5
    80003eb2:	f2040513          	addi	a0,s0,-224
    80003eb6:	00000097          	auipc	ra,0x0
    80003eba:	e52080e7          	jalr	-430(ra) # 80003d08 <namex>
    80003ebe:	89aa                	mv	s3,a0
    80003ec0:	ee051de3          	bnez	a0,80003dba <namex+0xb2>
    80003ec4:	bd5d                	j	80003d7a <namex+0x72>
    memmove(name, s, len);
    80003ec6:	2601                	sext.w	a2,a2
    80003ec8:	8552                	mv	a0,s4
    80003eca:	ffffd097          	auipc	ra,0xffffd
    80003ece:	e50080e7          	jalr	-432(ra) # 80000d1a <memmove>
    name[len] = 0;
    80003ed2:	9cd2                	add	s9,s9,s4
    80003ed4:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003ed8:	b725                	j	80003e00 <namex+0xf8>
  if(cnt >= 13) return 0;
    80003eda:	4981                	li	s3,0
    80003edc:	bd79                	j	80003d7a <namex+0x72>
  if(nameiparent){
    80003ede:	e80a8ee3          	beqz	s5,80003d7a <namex+0x72>
	iput(ip);
    80003ee2:	854e                	mv	a0,s3
    80003ee4:	00000097          	auipc	ra,0x0
    80003ee8:	a48080e7          	jalr	-1464(ra) # 8000392c <iput>
    return 0;
    80003eec:	4981                	li	s3,0
    80003eee:	b571                	j	80003d7a <namex+0x72>
  if(*path == 0)
    80003ef0:	d7fd                	beqz	a5,80003ede <namex+0x1d6>
  while(*path != '/' && *path != 0)
    80003ef2:	0004c783          	lbu	a5,0(s1)
    80003ef6:	85a6                	mv	a1,s1
    80003ef8:	b5cd                	j	80003dda <namex+0xd2>

0000000080003efa <dirlink>:
{
    80003efa:	7139                	addi	sp,sp,-64
    80003efc:	fc06                	sd	ra,56(sp)
    80003efe:	f822                	sd	s0,48(sp)
    80003f00:	f426                	sd	s1,40(sp)
    80003f02:	f04a                	sd	s2,32(sp)
    80003f04:	ec4e                	sd	s3,24(sp)
    80003f06:	e852                	sd	s4,16(sp)
    80003f08:	0080                	addi	s0,sp,64
    80003f0a:	892a                	mv	s2,a0
    80003f0c:	8a2e                	mv	s4,a1
    80003f0e:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003f10:	4601                	li	a2,0
    80003f12:	00000097          	auipc	ra,0x0
    80003f16:	d46080e7          	jalr	-698(ra) # 80003c58 <dirlookup>
    80003f1a:	e93d                	bnez	a0,80003f90 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f1c:	04c92483          	lw	s1,76(s2)
    80003f20:	c49d                	beqz	s1,80003f4e <dirlink+0x54>
    80003f22:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f24:	4741                	li	a4,16
    80003f26:	86a6                	mv	a3,s1
    80003f28:	fc040613          	addi	a2,s0,-64
    80003f2c:	4581                	li	a1,0
    80003f2e:	854a                	mv	a0,s2
    80003f30:	00000097          	auipc	ra,0x0
    80003f34:	af6080e7          	jalr	-1290(ra) # 80003a26 <readi>
    80003f38:	47c1                	li	a5,16
    80003f3a:	06f51163          	bne	a0,a5,80003f9c <dirlink+0xa2>
    if(de.inum == 0)
    80003f3e:	fc045783          	lhu	a5,-64(s0)
    80003f42:	c791                	beqz	a5,80003f4e <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f44:	24c1                	addiw	s1,s1,16
    80003f46:	04c92783          	lw	a5,76(s2)
    80003f4a:	fcf4ede3          	bltu	s1,a5,80003f24 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003f4e:	4639                	li	a2,14
    80003f50:	85d2                	mv	a1,s4
    80003f52:	fc240513          	addi	a0,s0,-62
    80003f56:	ffffd097          	auipc	ra,0xffffd
    80003f5a:	e7c080e7          	jalr	-388(ra) # 80000dd2 <strncpy>
  de.inum = inum;
    80003f5e:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f62:	4741                	li	a4,16
    80003f64:	86a6                	mv	a3,s1
    80003f66:	fc040613          	addi	a2,s0,-64
    80003f6a:	4581                	li	a1,0
    80003f6c:	854a                	mv	a0,s2
    80003f6e:	00000097          	auipc	ra,0x0
    80003f72:	bb0080e7          	jalr	-1104(ra) # 80003b1e <writei>
    80003f76:	872a                	mv	a4,a0
    80003f78:	47c1                	li	a5,16
  return 0;
    80003f7a:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f7c:	02f71863          	bne	a4,a5,80003fac <dirlink+0xb2>
}
    80003f80:	70e2                	ld	ra,56(sp)
    80003f82:	7442                	ld	s0,48(sp)
    80003f84:	74a2                	ld	s1,40(sp)
    80003f86:	7902                	ld	s2,32(sp)
    80003f88:	69e2                	ld	s3,24(sp)
    80003f8a:	6a42                	ld	s4,16(sp)
    80003f8c:	6121                	addi	sp,sp,64
    80003f8e:	8082                	ret
    iput(ip);
    80003f90:	00000097          	auipc	ra,0x0
    80003f94:	99c080e7          	jalr	-1636(ra) # 8000392c <iput>
    return -1;
    80003f98:	557d                	li	a0,-1
    80003f9a:	b7dd                	j	80003f80 <dirlink+0x86>
      panic("dirlink read");
    80003f9c:	00004517          	auipc	a0,0x4
    80003fa0:	66450513          	addi	a0,a0,1636 # 80008600 <syscalls+0x1d0>
    80003fa4:	ffffc097          	auipc	ra,0xffffc
    80003fa8:	586080e7          	jalr	1414(ra) # 8000052a <panic>
    panic("dirlink");
    80003fac:	00004517          	auipc	a0,0x4
    80003fb0:	76450513          	addi	a0,a0,1892 # 80008710 <syscalls+0x2e0>
    80003fb4:	ffffc097          	auipc	ra,0xffffc
    80003fb8:	576080e7          	jalr	1398(ra) # 8000052a <panic>

0000000080003fbc <namei>:

struct inode*
namei(char *path, int tag, int cnt)
{
    80003fbc:	1101                	addi	sp,sp,-32
    80003fbe:	ec06                	sd	ra,24(sp)
    80003fc0:	e822                	sd	s0,16(sp)
    80003fc2:	1000                	addi	s0,sp,32
    80003fc4:	86ae                	mv	a3,a1
    80003fc6:	8732                	mv	a4,a2
  char name[DIRSIZ];
  return namex(path, 0, name, tag, cnt);
    80003fc8:	fe040613          	addi	a2,s0,-32
    80003fcc:	4581                	li	a1,0
    80003fce:	00000097          	auipc	ra,0x0
    80003fd2:	d3a080e7          	jalr	-710(ra) # 80003d08 <namex>
}
    80003fd6:	60e2                	ld	ra,24(sp)
    80003fd8:	6442                	ld	s0,16(sp)
    80003fda:	6105                	addi	sp,sp,32
    80003fdc:	8082                	ret

0000000080003fde <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003fde:	1141                	addi	sp,sp,-16
    80003fe0:	e406                	sd	ra,8(sp)
    80003fe2:	e022                	sd	s0,0(sp)
    80003fe4:	0800                	addi	s0,sp,16
    80003fe6:	862e                	mv	a2,a1
  return namex(path, 1, name, 1, 0);
    80003fe8:	4701                	li	a4,0
    80003fea:	4685                	li	a3,1
    80003fec:	4585                	li	a1,1
    80003fee:	00000097          	auipc	ra,0x0
    80003ff2:	d1a080e7          	jalr	-742(ra) # 80003d08 <namex>
}
    80003ff6:	60a2                	ld	ra,8(sp)
    80003ff8:	6402                	ld	s0,0(sp)
    80003ffa:	0141                	addi	sp,sp,16
    80003ffc:	8082                	ret

0000000080003ffe <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003ffe:	1101                	addi	sp,sp,-32
    80004000:	ec06                	sd	ra,24(sp)
    80004002:	e822                	sd	s0,16(sp)
    80004004:	e426                	sd	s1,8(sp)
    80004006:	e04a                	sd	s2,0(sp)
    80004008:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000400a:	0001d917          	auipc	s2,0x1d
    8000400e:	26690913          	addi	s2,s2,614 # 80021270 <log>
    80004012:	01892583          	lw	a1,24(s2)
    80004016:	02892503          	lw	a0,40(s2)
    8000401a:	fffff097          	auipc	ra,0xfffff
    8000401e:	dc8080e7          	jalr	-568(ra) # 80002de2 <bread>
    80004022:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004024:	02c92683          	lw	a3,44(s2)
    80004028:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000402a:	02d05763          	blez	a3,80004058 <write_head+0x5a>
    8000402e:	0001d797          	auipc	a5,0x1d
    80004032:	27278793          	addi	a5,a5,626 # 800212a0 <log+0x30>
    80004036:	05c50713          	addi	a4,a0,92
    8000403a:	36fd                	addiw	a3,a3,-1
    8000403c:	1682                	slli	a3,a3,0x20
    8000403e:	9281                	srli	a3,a3,0x20
    80004040:	068a                	slli	a3,a3,0x2
    80004042:	0001d617          	auipc	a2,0x1d
    80004046:	26260613          	addi	a2,a2,610 # 800212a4 <log+0x34>
    8000404a:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000404c:	4390                	lw	a2,0(a5)
    8000404e:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004050:	0791                	addi	a5,a5,4
    80004052:	0711                	addi	a4,a4,4
    80004054:	fed79ce3          	bne	a5,a3,8000404c <write_head+0x4e>
  }
  bwrite(buf);
    80004058:	8526                	mv	a0,s1
    8000405a:	fffff097          	auipc	ra,0xfffff
    8000405e:	e7a080e7          	jalr	-390(ra) # 80002ed4 <bwrite>
  brelse(buf);
    80004062:	8526                	mv	a0,s1
    80004064:	fffff097          	auipc	ra,0xfffff
    80004068:	eae080e7          	jalr	-338(ra) # 80002f12 <brelse>
}
    8000406c:	60e2                	ld	ra,24(sp)
    8000406e:	6442                	ld	s0,16(sp)
    80004070:	64a2                	ld	s1,8(sp)
    80004072:	6902                	ld	s2,0(sp)
    80004074:	6105                	addi	sp,sp,32
    80004076:	8082                	ret

0000000080004078 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004078:	0001d797          	auipc	a5,0x1d
    8000407c:	2247a783          	lw	a5,548(a5) # 8002129c <log+0x2c>
    80004080:	0af05d63          	blez	a5,8000413a <install_trans+0xc2>
{
    80004084:	7139                	addi	sp,sp,-64
    80004086:	fc06                	sd	ra,56(sp)
    80004088:	f822                	sd	s0,48(sp)
    8000408a:	f426                	sd	s1,40(sp)
    8000408c:	f04a                	sd	s2,32(sp)
    8000408e:	ec4e                	sd	s3,24(sp)
    80004090:	e852                	sd	s4,16(sp)
    80004092:	e456                	sd	s5,8(sp)
    80004094:	e05a                	sd	s6,0(sp)
    80004096:	0080                	addi	s0,sp,64
    80004098:	8b2a                	mv	s6,a0
    8000409a:	0001da97          	auipc	s5,0x1d
    8000409e:	206a8a93          	addi	s5,s5,518 # 800212a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800040a2:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800040a4:	0001d997          	auipc	s3,0x1d
    800040a8:	1cc98993          	addi	s3,s3,460 # 80021270 <log>
    800040ac:	a00d                	j	800040ce <install_trans+0x56>
    brelse(lbuf);
    800040ae:	854a                	mv	a0,s2
    800040b0:	fffff097          	auipc	ra,0xfffff
    800040b4:	e62080e7          	jalr	-414(ra) # 80002f12 <brelse>
    brelse(dbuf);
    800040b8:	8526                	mv	a0,s1
    800040ba:	fffff097          	auipc	ra,0xfffff
    800040be:	e58080e7          	jalr	-424(ra) # 80002f12 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800040c2:	2a05                	addiw	s4,s4,1
    800040c4:	0a91                	addi	s5,s5,4
    800040c6:	02c9a783          	lw	a5,44(s3)
    800040ca:	04fa5e63          	bge	s4,a5,80004126 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800040ce:	0189a583          	lw	a1,24(s3)
    800040d2:	014585bb          	addw	a1,a1,s4
    800040d6:	2585                	addiw	a1,a1,1
    800040d8:	0289a503          	lw	a0,40(s3)
    800040dc:	fffff097          	auipc	ra,0xfffff
    800040e0:	d06080e7          	jalr	-762(ra) # 80002de2 <bread>
    800040e4:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800040e6:	000aa583          	lw	a1,0(s5)
    800040ea:	0289a503          	lw	a0,40(s3)
    800040ee:	fffff097          	auipc	ra,0xfffff
    800040f2:	cf4080e7          	jalr	-780(ra) # 80002de2 <bread>
    800040f6:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800040f8:	40000613          	li	a2,1024
    800040fc:	05890593          	addi	a1,s2,88
    80004100:	05850513          	addi	a0,a0,88
    80004104:	ffffd097          	auipc	ra,0xffffd
    80004108:	c16080e7          	jalr	-1002(ra) # 80000d1a <memmove>
    bwrite(dbuf);  // write dst to disk
    8000410c:	8526                	mv	a0,s1
    8000410e:	fffff097          	auipc	ra,0xfffff
    80004112:	dc6080e7          	jalr	-570(ra) # 80002ed4 <bwrite>
    if(recovering == 0)
    80004116:	f80b1ce3          	bnez	s6,800040ae <install_trans+0x36>
      bunpin(dbuf);
    8000411a:	8526                	mv	a0,s1
    8000411c:	fffff097          	auipc	ra,0xfffff
    80004120:	ed0080e7          	jalr	-304(ra) # 80002fec <bunpin>
    80004124:	b769                	j	800040ae <install_trans+0x36>
}
    80004126:	70e2                	ld	ra,56(sp)
    80004128:	7442                	ld	s0,48(sp)
    8000412a:	74a2                	ld	s1,40(sp)
    8000412c:	7902                	ld	s2,32(sp)
    8000412e:	69e2                	ld	s3,24(sp)
    80004130:	6a42                	ld	s4,16(sp)
    80004132:	6aa2                	ld	s5,8(sp)
    80004134:	6b02                	ld	s6,0(sp)
    80004136:	6121                	addi	sp,sp,64
    80004138:	8082                	ret
    8000413a:	8082                	ret

000000008000413c <initlog>:
{
    8000413c:	7179                	addi	sp,sp,-48
    8000413e:	f406                	sd	ra,40(sp)
    80004140:	f022                	sd	s0,32(sp)
    80004142:	ec26                	sd	s1,24(sp)
    80004144:	e84a                	sd	s2,16(sp)
    80004146:	e44e                	sd	s3,8(sp)
    80004148:	1800                	addi	s0,sp,48
    8000414a:	892a                	mv	s2,a0
    8000414c:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000414e:	0001d497          	auipc	s1,0x1d
    80004152:	12248493          	addi	s1,s1,290 # 80021270 <log>
    80004156:	00004597          	auipc	a1,0x4
    8000415a:	4ba58593          	addi	a1,a1,1210 # 80008610 <syscalls+0x1e0>
    8000415e:	8526                	mv	a0,s1
    80004160:	ffffd097          	auipc	ra,0xffffd
    80004164:	9d2080e7          	jalr	-1582(ra) # 80000b32 <initlock>
  log.start = sb->logstart;
    80004168:	0149a583          	lw	a1,20(s3)
    8000416c:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000416e:	0109a783          	lw	a5,16(s3)
    80004172:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004174:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004178:	854a                	mv	a0,s2
    8000417a:	fffff097          	auipc	ra,0xfffff
    8000417e:	c68080e7          	jalr	-920(ra) # 80002de2 <bread>
  log.lh.n = lh->n;
    80004182:	4d34                	lw	a3,88(a0)
    80004184:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004186:	02d05563          	blez	a3,800041b0 <initlog+0x74>
    8000418a:	05c50793          	addi	a5,a0,92
    8000418e:	0001d717          	auipc	a4,0x1d
    80004192:	11270713          	addi	a4,a4,274 # 800212a0 <log+0x30>
    80004196:	36fd                	addiw	a3,a3,-1
    80004198:	1682                	slli	a3,a3,0x20
    8000419a:	9281                	srli	a3,a3,0x20
    8000419c:	068a                	slli	a3,a3,0x2
    8000419e:	06050613          	addi	a2,a0,96
    800041a2:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    800041a4:	4390                	lw	a2,0(a5)
    800041a6:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800041a8:	0791                	addi	a5,a5,4
    800041aa:	0711                	addi	a4,a4,4
    800041ac:	fed79ce3          	bne	a5,a3,800041a4 <initlog+0x68>
  brelse(buf);
    800041b0:	fffff097          	auipc	ra,0xfffff
    800041b4:	d62080e7          	jalr	-670(ra) # 80002f12 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800041b8:	4505                	li	a0,1
    800041ba:	00000097          	auipc	ra,0x0
    800041be:	ebe080e7          	jalr	-322(ra) # 80004078 <install_trans>
  log.lh.n = 0;
    800041c2:	0001d797          	auipc	a5,0x1d
    800041c6:	0c07ad23          	sw	zero,218(a5) # 8002129c <log+0x2c>
  write_head(); // clear the log
    800041ca:	00000097          	auipc	ra,0x0
    800041ce:	e34080e7          	jalr	-460(ra) # 80003ffe <write_head>
}
    800041d2:	70a2                	ld	ra,40(sp)
    800041d4:	7402                	ld	s0,32(sp)
    800041d6:	64e2                	ld	s1,24(sp)
    800041d8:	6942                	ld	s2,16(sp)
    800041da:	69a2                	ld	s3,8(sp)
    800041dc:	6145                	addi	sp,sp,48
    800041de:	8082                	ret

00000000800041e0 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800041e0:	1101                	addi	sp,sp,-32
    800041e2:	ec06                	sd	ra,24(sp)
    800041e4:	e822                	sd	s0,16(sp)
    800041e6:	e426                	sd	s1,8(sp)
    800041e8:	e04a                	sd	s2,0(sp)
    800041ea:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800041ec:	0001d517          	auipc	a0,0x1d
    800041f0:	08450513          	addi	a0,a0,132 # 80021270 <log>
    800041f4:	ffffd097          	auipc	ra,0xffffd
    800041f8:	9ce080e7          	jalr	-1586(ra) # 80000bc2 <acquire>
  while(1){
    if(log.committing){
    800041fc:	0001d497          	auipc	s1,0x1d
    80004200:	07448493          	addi	s1,s1,116 # 80021270 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004204:	4979                	li	s2,30
    80004206:	a039                	j	80004214 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004208:	85a6                	mv	a1,s1
    8000420a:	8526                	mv	a0,s1
    8000420c:	ffffe097          	auipc	ra,0xffffe
    80004210:	e78080e7          	jalr	-392(ra) # 80002084 <sleep>
    if(log.committing){
    80004214:	50dc                	lw	a5,36(s1)
    80004216:	fbed                	bnez	a5,80004208 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004218:	509c                	lw	a5,32(s1)
    8000421a:	0017871b          	addiw	a4,a5,1
    8000421e:	0007069b          	sext.w	a3,a4
    80004222:	0027179b          	slliw	a5,a4,0x2
    80004226:	9fb9                	addw	a5,a5,a4
    80004228:	0017979b          	slliw	a5,a5,0x1
    8000422c:	54d8                	lw	a4,44(s1)
    8000422e:	9fb9                	addw	a5,a5,a4
    80004230:	00f95963          	bge	s2,a5,80004242 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004234:	85a6                	mv	a1,s1
    80004236:	8526                	mv	a0,s1
    80004238:	ffffe097          	auipc	ra,0xffffe
    8000423c:	e4c080e7          	jalr	-436(ra) # 80002084 <sleep>
    80004240:	bfd1                	j	80004214 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004242:	0001d517          	auipc	a0,0x1d
    80004246:	02e50513          	addi	a0,a0,46 # 80021270 <log>
    8000424a:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000424c:	ffffd097          	auipc	ra,0xffffd
    80004250:	a2a080e7          	jalr	-1494(ra) # 80000c76 <release>
      break;
    }
  }
}
    80004254:	60e2                	ld	ra,24(sp)
    80004256:	6442                	ld	s0,16(sp)
    80004258:	64a2                	ld	s1,8(sp)
    8000425a:	6902                	ld	s2,0(sp)
    8000425c:	6105                	addi	sp,sp,32
    8000425e:	8082                	ret

0000000080004260 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004260:	7139                	addi	sp,sp,-64
    80004262:	fc06                	sd	ra,56(sp)
    80004264:	f822                	sd	s0,48(sp)
    80004266:	f426                	sd	s1,40(sp)
    80004268:	f04a                	sd	s2,32(sp)
    8000426a:	ec4e                	sd	s3,24(sp)
    8000426c:	e852                	sd	s4,16(sp)
    8000426e:	e456                	sd	s5,8(sp)
    80004270:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004272:	0001d497          	auipc	s1,0x1d
    80004276:	ffe48493          	addi	s1,s1,-2 # 80021270 <log>
    8000427a:	8526                	mv	a0,s1
    8000427c:	ffffd097          	auipc	ra,0xffffd
    80004280:	946080e7          	jalr	-1722(ra) # 80000bc2 <acquire>
  log.outstanding -= 1;
    80004284:	509c                	lw	a5,32(s1)
    80004286:	37fd                	addiw	a5,a5,-1
    80004288:	0007891b          	sext.w	s2,a5
    8000428c:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000428e:	50dc                	lw	a5,36(s1)
    80004290:	e7b9                	bnez	a5,800042de <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004292:	04091e63          	bnez	s2,800042ee <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004296:	0001d497          	auipc	s1,0x1d
    8000429a:	fda48493          	addi	s1,s1,-38 # 80021270 <log>
    8000429e:	4785                	li	a5,1
    800042a0:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800042a2:	8526                	mv	a0,s1
    800042a4:	ffffd097          	auipc	ra,0xffffd
    800042a8:	9d2080e7          	jalr	-1582(ra) # 80000c76 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800042ac:	54dc                	lw	a5,44(s1)
    800042ae:	06f04763          	bgtz	a5,8000431c <end_op+0xbc>
    acquire(&log.lock);
    800042b2:	0001d497          	auipc	s1,0x1d
    800042b6:	fbe48493          	addi	s1,s1,-66 # 80021270 <log>
    800042ba:	8526                	mv	a0,s1
    800042bc:	ffffd097          	auipc	ra,0xffffd
    800042c0:	906080e7          	jalr	-1786(ra) # 80000bc2 <acquire>
    log.committing = 0;
    800042c4:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800042c8:	8526                	mv	a0,s1
    800042ca:	ffffe097          	auipc	ra,0xffffe
    800042ce:	f46080e7          	jalr	-186(ra) # 80002210 <wakeup>
    release(&log.lock);
    800042d2:	8526                	mv	a0,s1
    800042d4:	ffffd097          	auipc	ra,0xffffd
    800042d8:	9a2080e7          	jalr	-1630(ra) # 80000c76 <release>
}
    800042dc:	a03d                	j	8000430a <end_op+0xaa>
    panic("log.committing");
    800042de:	00004517          	auipc	a0,0x4
    800042e2:	33a50513          	addi	a0,a0,826 # 80008618 <syscalls+0x1e8>
    800042e6:	ffffc097          	auipc	ra,0xffffc
    800042ea:	244080e7          	jalr	580(ra) # 8000052a <panic>
    wakeup(&log);
    800042ee:	0001d497          	auipc	s1,0x1d
    800042f2:	f8248493          	addi	s1,s1,-126 # 80021270 <log>
    800042f6:	8526                	mv	a0,s1
    800042f8:	ffffe097          	auipc	ra,0xffffe
    800042fc:	f18080e7          	jalr	-232(ra) # 80002210 <wakeup>
  release(&log.lock);
    80004300:	8526                	mv	a0,s1
    80004302:	ffffd097          	auipc	ra,0xffffd
    80004306:	974080e7          	jalr	-1676(ra) # 80000c76 <release>
}
    8000430a:	70e2                	ld	ra,56(sp)
    8000430c:	7442                	ld	s0,48(sp)
    8000430e:	74a2                	ld	s1,40(sp)
    80004310:	7902                	ld	s2,32(sp)
    80004312:	69e2                	ld	s3,24(sp)
    80004314:	6a42                	ld	s4,16(sp)
    80004316:	6aa2                	ld	s5,8(sp)
    80004318:	6121                	addi	sp,sp,64
    8000431a:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    8000431c:	0001da97          	auipc	s5,0x1d
    80004320:	f84a8a93          	addi	s5,s5,-124 # 800212a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004324:	0001da17          	auipc	s4,0x1d
    80004328:	f4ca0a13          	addi	s4,s4,-180 # 80021270 <log>
    8000432c:	018a2583          	lw	a1,24(s4)
    80004330:	012585bb          	addw	a1,a1,s2
    80004334:	2585                	addiw	a1,a1,1
    80004336:	028a2503          	lw	a0,40(s4)
    8000433a:	fffff097          	auipc	ra,0xfffff
    8000433e:	aa8080e7          	jalr	-1368(ra) # 80002de2 <bread>
    80004342:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004344:	000aa583          	lw	a1,0(s5)
    80004348:	028a2503          	lw	a0,40(s4)
    8000434c:	fffff097          	auipc	ra,0xfffff
    80004350:	a96080e7          	jalr	-1386(ra) # 80002de2 <bread>
    80004354:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004356:	40000613          	li	a2,1024
    8000435a:	05850593          	addi	a1,a0,88
    8000435e:	05848513          	addi	a0,s1,88
    80004362:	ffffd097          	auipc	ra,0xffffd
    80004366:	9b8080e7          	jalr	-1608(ra) # 80000d1a <memmove>
    bwrite(to);  // write the log
    8000436a:	8526                	mv	a0,s1
    8000436c:	fffff097          	auipc	ra,0xfffff
    80004370:	b68080e7          	jalr	-1176(ra) # 80002ed4 <bwrite>
    brelse(from);
    80004374:	854e                	mv	a0,s3
    80004376:	fffff097          	auipc	ra,0xfffff
    8000437a:	b9c080e7          	jalr	-1124(ra) # 80002f12 <brelse>
    brelse(to);
    8000437e:	8526                	mv	a0,s1
    80004380:	fffff097          	auipc	ra,0xfffff
    80004384:	b92080e7          	jalr	-1134(ra) # 80002f12 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004388:	2905                	addiw	s2,s2,1
    8000438a:	0a91                	addi	s5,s5,4
    8000438c:	02ca2783          	lw	a5,44(s4)
    80004390:	f8f94ee3          	blt	s2,a5,8000432c <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004394:	00000097          	auipc	ra,0x0
    80004398:	c6a080e7          	jalr	-918(ra) # 80003ffe <write_head>
    install_trans(0); // Now install writes to home locations
    8000439c:	4501                	li	a0,0
    8000439e:	00000097          	auipc	ra,0x0
    800043a2:	cda080e7          	jalr	-806(ra) # 80004078 <install_trans>
    log.lh.n = 0;
    800043a6:	0001d797          	auipc	a5,0x1d
    800043aa:	ee07ab23          	sw	zero,-266(a5) # 8002129c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800043ae:	00000097          	auipc	ra,0x0
    800043b2:	c50080e7          	jalr	-944(ra) # 80003ffe <write_head>
    800043b6:	bdf5                	j	800042b2 <end_op+0x52>

00000000800043b8 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800043b8:	1101                	addi	sp,sp,-32
    800043ba:	ec06                	sd	ra,24(sp)
    800043bc:	e822                	sd	s0,16(sp)
    800043be:	e426                	sd	s1,8(sp)
    800043c0:	e04a                	sd	s2,0(sp)
    800043c2:	1000                	addi	s0,sp,32
    800043c4:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800043c6:	0001d917          	auipc	s2,0x1d
    800043ca:	eaa90913          	addi	s2,s2,-342 # 80021270 <log>
    800043ce:	854a                	mv	a0,s2
    800043d0:	ffffc097          	auipc	ra,0xffffc
    800043d4:	7f2080e7          	jalr	2034(ra) # 80000bc2 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800043d8:	02c92603          	lw	a2,44(s2)
    800043dc:	47f5                	li	a5,29
    800043de:	06c7c563          	blt	a5,a2,80004448 <log_write+0x90>
    800043e2:	0001d797          	auipc	a5,0x1d
    800043e6:	eaa7a783          	lw	a5,-342(a5) # 8002128c <log+0x1c>
    800043ea:	37fd                	addiw	a5,a5,-1
    800043ec:	04f65e63          	bge	a2,a5,80004448 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800043f0:	0001d797          	auipc	a5,0x1d
    800043f4:	ea07a783          	lw	a5,-352(a5) # 80021290 <log+0x20>
    800043f8:	06f05063          	blez	a5,80004458 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800043fc:	4781                	li	a5,0
    800043fe:	06c05563          	blez	a2,80004468 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004402:	44cc                	lw	a1,12(s1)
    80004404:	0001d717          	auipc	a4,0x1d
    80004408:	e9c70713          	addi	a4,a4,-356 # 800212a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000440c:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    8000440e:	4314                	lw	a3,0(a4)
    80004410:	04b68c63          	beq	a3,a1,80004468 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004414:	2785                	addiw	a5,a5,1
    80004416:	0711                	addi	a4,a4,4
    80004418:	fef61be3          	bne	a2,a5,8000440e <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000441c:	0621                	addi	a2,a2,8
    8000441e:	060a                	slli	a2,a2,0x2
    80004420:	0001d797          	auipc	a5,0x1d
    80004424:	e5078793          	addi	a5,a5,-432 # 80021270 <log>
    80004428:	963e                	add	a2,a2,a5
    8000442a:	44dc                	lw	a5,12(s1)
    8000442c:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000442e:	8526                	mv	a0,s1
    80004430:	fffff097          	auipc	ra,0xfffff
    80004434:	b80080e7          	jalr	-1152(ra) # 80002fb0 <bpin>
    log.lh.n++;
    80004438:	0001d717          	auipc	a4,0x1d
    8000443c:	e3870713          	addi	a4,a4,-456 # 80021270 <log>
    80004440:	575c                	lw	a5,44(a4)
    80004442:	2785                	addiw	a5,a5,1
    80004444:	d75c                	sw	a5,44(a4)
    80004446:	a835                	j	80004482 <log_write+0xca>
    panic("too big a transaction");
    80004448:	00004517          	auipc	a0,0x4
    8000444c:	1e050513          	addi	a0,a0,480 # 80008628 <syscalls+0x1f8>
    80004450:	ffffc097          	auipc	ra,0xffffc
    80004454:	0da080e7          	jalr	218(ra) # 8000052a <panic>
    panic("log_write outside of trans");
    80004458:	00004517          	auipc	a0,0x4
    8000445c:	1e850513          	addi	a0,a0,488 # 80008640 <syscalls+0x210>
    80004460:	ffffc097          	auipc	ra,0xffffc
    80004464:	0ca080e7          	jalr	202(ra) # 8000052a <panic>
  log.lh.block[i] = b->blockno;
    80004468:	00878713          	addi	a4,a5,8
    8000446c:	00271693          	slli	a3,a4,0x2
    80004470:	0001d717          	auipc	a4,0x1d
    80004474:	e0070713          	addi	a4,a4,-512 # 80021270 <log>
    80004478:	9736                	add	a4,a4,a3
    8000447a:	44d4                	lw	a3,12(s1)
    8000447c:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000447e:	faf608e3          	beq	a2,a5,8000442e <log_write+0x76>
  }
  release(&log.lock);
    80004482:	0001d517          	auipc	a0,0x1d
    80004486:	dee50513          	addi	a0,a0,-530 # 80021270 <log>
    8000448a:	ffffc097          	auipc	ra,0xffffc
    8000448e:	7ec080e7          	jalr	2028(ra) # 80000c76 <release>
}
    80004492:	60e2                	ld	ra,24(sp)
    80004494:	6442                	ld	s0,16(sp)
    80004496:	64a2                	ld	s1,8(sp)
    80004498:	6902                	ld	s2,0(sp)
    8000449a:	6105                	addi	sp,sp,32
    8000449c:	8082                	ret

000000008000449e <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000449e:	1101                	addi	sp,sp,-32
    800044a0:	ec06                	sd	ra,24(sp)
    800044a2:	e822                	sd	s0,16(sp)
    800044a4:	e426                	sd	s1,8(sp)
    800044a6:	e04a                	sd	s2,0(sp)
    800044a8:	1000                	addi	s0,sp,32
    800044aa:	84aa                	mv	s1,a0
    800044ac:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800044ae:	00004597          	auipc	a1,0x4
    800044b2:	1b258593          	addi	a1,a1,434 # 80008660 <syscalls+0x230>
    800044b6:	0521                	addi	a0,a0,8
    800044b8:	ffffc097          	auipc	ra,0xffffc
    800044bc:	67a080e7          	jalr	1658(ra) # 80000b32 <initlock>
  lk->name = name;
    800044c0:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800044c4:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800044c8:	0204a423          	sw	zero,40(s1)
}
    800044cc:	60e2                	ld	ra,24(sp)
    800044ce:	6442                	ld	s0,16(sp)
    800044d0:	64a2                	ld	s1,8(sp)
    800044d2:	6902                	ld	s2,0(sp)
    800044d4:	6105                	addi	sp,sp,32
    800044d6:	8082                	ret

00000000800044d8 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800044d8:	1101                	addi	sp,sp,-32
    800044da:	ec06                	sd	ra,24(sp)
    800044dc:	e822                	sd	s0,16(sp)
    800044de:	e426                	sd	s1,8(sp)
    800044e0:	e04a                	sd	s2,0(sp)
    800044e2:	1000                	addi	s0,sp,32
    800044e4:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800044e6:	00850913          	addi	s2,a0,8
    800044ea:	854a                	mv	a0,s2
    800044ec:	ffffc097          	auipc	ra,0xffffc
    800044f0:	6d6080e7          	jalr	1750(ra) # 80000bc2 <acquire>
  while (lk->locked) {
    800044f4:	409c                	lw	a5,0(s1)
    800044f6:	cb89                	beqz	a5,80004508 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800044f8:	85ca                	mv	a1,s2
    800044fa:	8526                	mv	a0,s1
    800044fc:	ffffe097          	auipc	ra,0xffffe
    80004500:	b88080e7          	jalr	-1144(ra) # 80002084 <sleep>
  while (lk->locked) {
    80004504:	409c                	lw	a5,0(s1)
    80004506:	fbed                	bnez	a5,800044f8 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004508:	4785                	li	a5,1
    8000450a:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000450c:	ffffd097          	auipc	ra,0xffffd
    80004510:	4b4080e7          	jalr	1204(ra) # 800019c0 <myproc>
    80004514:	591c                	lw	a5,48(a0)
    80004516:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004518:	854a                	mv	a0,s2
    8000451a:	ffffc097          	auipc	ra,0xffffc
    8000451e:	75c080e7          	jalr	1884(ra) # 80000c76 <release>
}
    80004522:	60e2                	ld	ra,24(sp)
    80004524:	6442                	ld	s0,16(sp)
    80004526:	64a2                	ld	s1,8(sp)
    80004528:	6902                	ld	s2,0(sp)
    8000452a:	6105                	addi	sp,sp,32
    8000452c:	8082                	ret

000000008000452e <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000452e:	1101                	addi	sp,sp,-32
    80004530:	ec06                	sd	ra,24(sp)
    80004532:	e822                	sd	s0,16(sp)
    80004534:	e426                	sd	s1,8(sp)
    80004536:	e04a                	sd	s2,0(sp)
    80004538:	1000                	addi	s0,sp,32
    8000453a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000453c:	00850913          	addi	s2,a0,8
    80004540:	854a                	mv	a0,s2
    80004542:	ffffc097          	auipc	ra,0xffffc
    80004546:	680080e7          	jalr	1664(ra) # 80000bc2 <acquire>
  lk->locked = 0;
    8000454a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000454e:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004552:	8526                	mv	a0,s1
    80004554:	ffffe097          	auipc	ra,0xffffe
    80004558:	cbc080e7          	jalr	-836(ra) # 80002210 <wakeup>
  release(&lk->lk);
    8000455c:	854a                	mv	a0,s2
    8000455e:	ffffc097          	auipc	ra,0xffffc
    80004562:	718080e7          	jalr	1816(ra) # 80000c76 <release>
}
    80004566:	60e2                	ld	ra,24(sp)
    80004568:	6442                	ld	s0,16(sp)
    8000456a:	64a2                	ld	s1,8(sp)
    8000456c:	6902                	ld	s2,0(sp)
    8000456e:	6105                	addi	sp,sp,32
    80004570:	8082                	ret

0000000080004572 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004572:	7179                	addi	sp,sp,-48
    80004574:	f406                	sd	ra,40(sp)
    80004576:	f022                	sd	s0,32(sp)
    80004578:	ec26                	sd	s1,24(sp)
    8000457a:	e84a                	sd	s2,16(sp)
    8000457c:	e44e                	sd	s3,8(sp)
    8000457e:	1800                	addi	s0,sp,48
    80004580:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004582:	00850913          	addi	s2,a0,8
    80004586:	854a                	mv	a0,s2
    80004588:	ffffc097          	auipc	ra,0xffffc
    8000458c:	63a080e7          	jalr	1594(ra) # 80000bc2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004590:	409c                	lw	a5,0(s1)
    80004592:	ef99                	bnez	a5,800045b0 <holdingsleep+0x3e>
    80004594:	4481                	li	s1,0
  release(&lk->lk);
    80004596:	854a                	mv	a0,s2
    80004598:	ffffc097          	auipc	ra,0xffffc
    8000459c:	6de080e7          	jalr	1758(ra) # 80000c76 <release>
  return r;
}
    800045a0:	8526                	mv	a0,s1
    800045a2:	70a2                	ld	ra,40(sp)
    800045a4:	7402                	ld	s0,32(sp)
    800045a6:	64e2                	ld	s1,24(sp)
    800045a8:	6942                	ld	s2,16(sp)
    800045aa:	69a2                	ld	s3,8(sp)
    800045ac:	6145                	addi	sp,sp,48
    800045ae:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800045b0:	0284a983          	lw	s3,40(s1)
    800045b4:	ffffd097          	auipc	ra,0xffffd
    800045b8:	40c080e7          	jalr	1036(ra) # 800019c0 <myproc>
    800045bc:	5904                	lw	s1,48(a0)
    800045be:	413484b3          	sub	s1,s1,s3
    800045c2:	0014b493          	seqz	s1,s1
    800045c6:	bfc1                	j	80004596 <holdingsleep+0x24>

00000000800045c8 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800045c8:	1141                	addi	sp,sp,-16
    800045ca:	e406                	sd	ra,8(sp)
    800045cc:	e022                	sd	s0,0(sp)
    800045ce:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800045d0:	00004597          	auipc	a1,0x4
    800045d4:	0a058593          	addi	a1,a1,160 # 80008670 <syscalls+0x240>
    800045d8:	0001d517          	auipc	a0,0x1d
    800045dc:	de050513          	addi	a0,a0,-544 # 800213b8 <ftable>
    800045e0:	ffffc097          	auipc	ra,0xffffc
    800045e4:	552080e7          	jalr	1362(ra) # 80000b32 <initlock>
}
    800045e8:	60a2                	ld	ra,8(sp)
    800045ea:	6402                	ld	s0,0(sp)
    800045ec:	0141                	addi	sp,sp,16
    800045ee:	8082                	ret

00000000800045f0 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800045f0:	1101                	addi	sp,sp,-32
    800045f2:	ec06                	sd	ra,24(sp)
    800045f4:	e822                	sd	s0,16(sp)
    800045f6:	e426                	sd	s1,8(sp)
    800045f8:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800045fa:	0001d517          	auipc	a0,0x1d
    800045fe:	dbe50513          	addi	a0,a0,-578 # 800213b8 <ftable>
    80004602:	ffffc097          	auipc	ra,0xffffc
    80004606:	5c0080e7          	jalr	1472(ra) # 80000bc2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000460a:	0001d497          	auipc	s1,0x1d
    8000460e:	dc648493          	addi	s1,s1,-570 # 800213d0 <ftable+0x18>
    80004612:	0001e717          	auipc	a4,0x1e
    80004616:	d5e70713          	addi	a4,a4,-674 # 80022370 <ftable+0xfb8>
    if(f->ref == 0){
    8000461a:	40dc                	lw	a5,4(s1)
    8000461c:	cf99                	beqz	a5,8000463a <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000461e:	02848493          	addi	s1,s1,40
    80004622:	fee49ce3          	bne	s1,a4,8000461a <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004626:	0001d517          	auipc	a0,0x1d
    8000462a:	d9250513          	addi	a0,a0,-622 # 800213b8 <ftable>
    8000462e:	ffffc097          	auipc	ra,0xffffc
    80004632:	648080e7          	jalr	1608(ra) # 80000c76 <release>
  return 0;
    80004636:	4481                	li	s1,0
    80004638:	a819                	j	8000464e <filealloc+0x5e>
      f->ref = 1;
    8000463a:	4785                	li	a5,1
    8000463c:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000463e:	0001d517          	auipc	a0,0x1d
    80004642:	d7a50513          	addi	a0,a0,-646 # 800213b8 <ftable>
    80004646:	ffffc097          	auipc	ra,0xffffc
    8000464a:	630080e7          	jalr	1584(ra) # 80000c76 <release>
}
    8000464e:	8526                	mv	a0,s1
    80004650:	60e2                	ld	ra,24(sp)
    80004652:	6442                	ld	s0,16(sp)
    80004654:	64a2                	ld	s1,8(sp)
    80004656:	6105                	addi	sp,sp,32
    80004658:	8082                	ret

000000008000465a <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000465a:	1101                	addi	sp,sp,-32
    8000465c:	ec06                	sd	ra,24(sp)
    8000465e:	e822                	sd	s0,16(sp)
    80004660:	e426                	sd	s1,8(sp)
    80004662:	1000                	addi	s0,sp,32
    80004664:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004666:	0001d517          	auipc	a0,0x1d
    8000466a:	d5250513          	addi	a0,a0,-686 # 800213b8 <ftable>
    8000466e:	ffffc097          	auipc	ra,0xffffc
    80004672:	554080e7          	jalr	1364(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    80004676:	40dc                	lw	a5,4(s1)
    80004678:	02f05263          	blez	a5,8000469c <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000467c:	2785                	addiw	a5,a5,1
    8000467e:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004680:	0001d517          	auipc	a0,0x1d
    80004684:	d3850513          	addi	a0,a0,-712 # 800213b8 <ftable>
    80004688:	ffffc097          	auipc	ra,0xffffc
    8000468c:	5ee080e7          	jalr	1518(ra) # 80000c76 <release>
  return f;
}
    80004690:	8526                	mv	a0,s1
    80004692:	60e2                	ld	ra,24(sp)
    80004694:	6442                	ld	s0,16(sp)
    80004696:	64a2                	ld	s1,8(sp)
    80004698:	6105                	addi	sp,sp,32
    8000469a:	8082                	ret
    panic("filedup");
    8000469c:	00004517          	auipc	a0,0x4
    800046a0:	fdc50513          	addi	a0,a0,-36 # 80008678 <syscalls+0x248>
    800046a4:	ffffc097          	auipc	ra,0xffffc
    800046a8:	e86080e7          	jalr	-378(ra) # 8000052a <panic>

00000000800046ac <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800046ac:	7139                	addi	sp,sp,-64
    800046ae:	fc06                	sd	ra,56(sp)
    800046b0:	f822                	sd	s0,48(sp)
    800046b2:	f426                	sd	s1,40(sp)
    800046b4:	f04a                	sd	s2,32(sp)
    800046b6:	ec4e                	sd	s3,24(sp)
    800046b8:	e852                	sd	s4,16(sp)
    800046ba:	e456                	sd	s5,8(sp)
    800046bc:	0080                	addi	s0,sp,64
    800046be:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800046c0:	0001d517          	auipc	a0,0x1d
    800046c4:	cf850513          	addi	a0,a0,-776 # 800213b8 <ftable>
    800046c8:	ffffc097          	auipc	ra,0xffffc
    800046cc:	4fa080e7          	jalr	1274(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    800046d0:	40dc                	lw	a5,4(s1)
    800046d2:	06f05163          	blez	a5,80004734 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800046d6:	37fd                	addiw	a5,a5,-1
    800046d8:	0007871b          	sext.w	a4,a5
    800046dc:	c0dc                	sw	a5,4(s1)
    800046de:	06e04363          	bgtz	a4,80004744 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800046e2:	0004a903          	lw	s2,0(s1)
    800046e6:	0094ca83          	lbu	s5,9(s1)
    800046ea:	0104ba03          	ld	s4,16(s1)
    800046ee:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800046f2:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800046f6:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800046fa:	0001d517          	auipc	a0,0x1d
    800046fe:	cbe50513          	addi	a0,a0,-834 # 800213b8 <ftable>
    80004702:	ffffc097          	auipc	ra,0xffffc
    80004706:	574080e7          	jalr	1396(ra) # 80000c76 <release>

  if(ff.type == FD_PIPE){
    8000470a:	4785                	li	a5,1
    8000470c:	04f90d63          	beq	s2,a5,80004766 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004710:	3979                	addiw	s2,s2,-2
    80004712:	4785                	li	a5,1
    80004714:	0527e063          	bltu	a5,s2,80004754 <fileclose+0xa8>
    begin_op();
    80004718:	00000097          	auipc	ra,0x0
    8000471c:	ac8080e7          	jalr	-1336(ra) # 800041e0 <begin_op>
    iput(ff.ip);
    80004720:	854e                	mv	a0,s3
    80004722:	fffff097          	auipc	ra,0xfffff
    80004726:	20a080e7          	jalr	522(ra) # 8000392c <iput>
    end_op();
    8000472a:	00000097          	auipc	ra,0x0
    8000472e:	b36080e7          	jalr	-1226(ra) # 80004260 <end_op>
    80004732:	a00d                	j	80004754 <fileclose+0xa8>
    panic("fileclose");
    80004734:	00004517          	auipc	a0,0x4
    80004738:	f4c50513          	addi	a0,a0,-180 # 80008680 <syscalls+0x250>
    8000473c:	ffffc097          	auipc	ra,0xffffc
    80004740:	dee080e7          	jalr	-530(ra) # 8000052a <panic>
    release(&ftable.lock);
    80004744:	0001d517          	auipc	a0,0x1d
    80004748:	c7450513          	addi	a0,a0,-908 # 800213b8 <ftable>
    8000474c:	ffffc097          	auipc	ra,0xffffc
    80004750:	52a080e7          	jalr	1322(ra) # 80000c76 <release>
  }
}
    80004754:	70e2                	ld	ra,56(sp)
    80004756:	7442                	ld	s0,48(sp)
    80004758:	74a2                	ld	s1,40(sp)
    8000475a:	7902                	ld	s2,32(sp)
    8000475c:	69e2                	ld	s3,24(sp)
    8000475e:	6a42                	ld	s4,16(sp)
    80004760:	6aa2                	ld	s5,8(sp)
    80004762:	6121                	addi	sp,sp,64
    80004764:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004766:	85d6                	mv	a1,s5
    80004768:	8552                	mv	a0,s4
    8000476a:	00000097          	auipc	ra,0x0
    8000476e:	34c080e7          	jalr	844(ra) # 80004ab6 <pipeclose>
    80004772:	b7cd                	j	80004754 <fileclose+0xa8>

0000000080004774 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004774:	715d                	addi	sp,sp,-80
    80004776:	e486                	sd	ra,72(sp)
    80004778:	e0a2                	sd	s0,64(sp)
    8000477a:	fc26                	sd	s1,56(sp)
    8000477c:	f84a                	sd	s2,48(sp)
    8000477e:	f44e                	sd	s3,40(sp)
    80004780:	0880                	addi	s0,sp,80
    80004782:	84aa                	mv	s1,a0
    80004784:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004786:	ffffd097          	auipc	ra,0xffffd
    8000478a:	23a080e7          	jalr	570(ra) # 800019c0 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000478e:	409c                	lw	a5,0(s1)
    80004790:	37f9                	addiw	a5,a5,-2
    80004792:	4705                	li	a4,1
    80004794:	04f76763          	bltu	a4,a5,800047e2 <filestat+0x6e>
    80004798:	892a                	mv	s2,a0
    ilock(f->ip);
    8000479a:	6c88                	ld	a0,24(s1)
    8000479c:	fffff097          	auipc	ra,0xfffff
    800047a0:	f14080e7          	jalr	-236(ra) # 800036b0 <ilock>
    stati(f->ip, &st);
    800047a4:	fb840593          	addi	a1,s0,-72
    800047a8:	6c88                	ld	a0,24(s1)
    800047aa:	fffff097          	auipc	ra,0xfffff
    800047ae:	252080e7          	jalr	594(ra) # 800039fc <stati>
    iunlock(f->ip);
    800047b2:	6c88                	ld	a0,24(s1)
    800047b4:	fffff097          	auipc	ra,0xfffff
    800047b8:	fbe080e7          	jalr	-66(ra) # 80003772 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800047bc:	46e1                	li	a3,24
    800047be:	fb840613          	addi	a2,s0,-72
    800047c2:	85ce                	mv	a1,s3
    800047c4:	05093503          	ld	a0,80(s2)
    800047c8:	ffffd097          	auipc	ra,0xffffd
    800047cc:	eb8080e7          	jalr	-328(ra) # 80001680 <copyout>
    800047d0:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800047d4:	60a6                	ld	ra,72(sp)
    800047d6:	6406                	ld	s0,64(sp)
    800047d8:	74e2                	ld	s1,56(sp)
    800047da:	7942                	ld	s2,48(sp)
    800047dc:	79a2                	ld	s3,40(sp)
    800047de:	6161                	addi	sp,sp,80
    800047e0:	8082                	ret
  return -1;
    800047e2:	557d                	li	a0,-1
    800047e4:	bfc5                	j	800047d4 <filestat+0x60>

00000000800047e6 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800047e6:	7179                	addi	sp,sp,-48
    800047e8:	f406                	sd	ra,40(sp)
    800047ea:	f022                	sd	s0,32(sp)
    800047ec:	ec26                	sd	s1,24(sp)
    800047ee:	e84a                	sd	s2,16(sp)
    800047f0:	e44e                	sd	s3,8(sp)
    800047f2:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800047f4:	00854783          	lbu	a5,8(a0)
    800047f8:	c3d5                	beqz	a5,8000489c <fileread+0xb6>
    800047fa:	84aa                	mv	s1,a0
    800047fc:	89ae                	mv	s3,a1
    800047fe:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004800:	411c                	lw	a5,0(a0)
    80004802:	4705                	li	a4,1
    80004804:	04e78963          	beq	a5,a4,80004856 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004808:	470d                	li	a4,3
    8000480a:	04e78d63          	beq	a5,a4,80004864 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000480e:	4709                	li	a4,2
    80004810:	06e79e63          	bne	a5,a4,8000488c <fileread+0xa6>
    ilock(f->ip);
    80004814:	6d08                	ld	a0,24(a0)
    80004816:	fffff097          	auipc	ra,0xfffff
    8000481a:	e9a080e7          	jalr	-358(ra) # 800036b0 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    8000481e:	874a                	mv	a4,s2
    80004820:	5094                	lw	a3,32(s1)
    80004822:	864e                	mv	a2,s3
    80004824:	4585                	li	a1,1
    80004826:	6c88                	ld	a0,24(s1)
    80004828:	fffff097          	auipc	ra,0xfffff
    8000482c:	1fe080e7          	jalr	510(ra) # 80003a26 <readi>
    80004830:	892a                	mv	s2,a0
    80004832:	00a05563          	blez	a0,8000483c <fileread+0x56>
      f->off += r;
    80004836:	509c                	lw	a5,32(s1)
    80004838:	9fa9                	addw	a5,a5,a0
    8000483a:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000483c:	6c88                	ld	a0,24(s1)
    8000483e:	fffff097          	auipc	ra,0xfffff
    80004842:	f34080e7          	jalr	-204(ra) # 80003772 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004846:	854a                	mv	a0,s2
    80004848:	70a2                	ld	ra,40(sp)
    8000484a:	7402                	ld	s0,32(sp)
    8000484c:	64e2                	ld	s1,24(sp)
    8000484e:	6942                	ld	s2,16(sp)
    80004850:	69a2                	ld	s3,8(sp)
    80004852:	6145                	addi	sp,sp,48
    80004854:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004856:	6908                	ld	a0,16(a0)
    80004858:	00000097          	auipc	ra,0x0
    8000485c:	3c0080e7          	jalr	960(ra) # 80004c18 <piperead>
    80004860:	892a                	mv	s2,a0
    80004862:	b7d5                	j	80004846 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004864:	02451783          	lh	a5,36(a0)
    80004868:	03079693          	slli	a3,a5,0x30
    8000486c:	92c1                	srli	a3,a3,0x30
    8000486e:	4725                	li	a4,9
    80004870:	02d76863          	bltu	a4,a3,800048a0 <fileread+0xba>
    80004874:	0792                	slli	a5,a5,0x4
    80004876:	0001d717          	auipc	a4,0x1d
    8000487a:	aa270713          	addi	a4,a4,-1374 # 80021318 <devsw>
    8000487e:	97ba                	add	a5,a5,a4
    80004880:	639c                	ld	a5,0(a5)
    80004882:	c38d                	beqz	a5,800048a4 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004884:	4505                	li	a0,1
    80004886:	9782                	jalr	a5
    80004888:	892a                	mv	s2,a0
    8000488a:	bf75                	j	80004846 <fileread+0x60>
    panic("fileread");
    8000488c:	00004517          	auipc	a0,0x4
    80004890:	e0450513          	addi	a0,a0,-508 # 80008690 <syscalls+0x260>
    80004894:	ffffc097          	auipc	ra,0xffffc
    80004898:	c96080e7          	jalr	-874(ra) # 8000052a <panic>
    return -1;
    8000489c:	597d                	li	s2,-1
    8000489e:	b765                	j	80004846 <fileread+0x60>
      return -1;
    800048a0:	597d                	li	s2,-1
    800048a2:	b755                	j	80004846 <fileread+0x60>
    800048a4:	597d                	li	s2,-1
    800048a6:	b745                	j	80004846 <fileread+0x60>

00000000800048a8 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800048a8:	715d                	addi	sp,sp,-80
    800048aa:	e486                	sd	ra,72(sp)
    800048ac:	e0a2                	sd	s0,64(sp)
    800048ae:	fc26                	sd	s1,56(sp)
    800048b0:	f84a                	sd	s2,48(sp)
    800048b2:	f44e                	sd	s3,40(sp)
    800048b4:	f052                	sd	s4,32(sp)
    800048b6:	ec56                	sd	s5,24(sp)
    800048b8:	e85a                	sd	s6,16(sp)
    800048ba:	e45e                	sd	s7,8(sp)
    800048bc:	e062                	sd	s8,0(sp)
    800048be:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800048c0:	00954783          	lbu	a5,9(a0)
    800048c4:	10078663          	beqz	a5,800049d0 <filewrite+0x128>
    800048c8:	892a                	mv	s2,a0
    800048ca:	8aae                	mv	s5,a1
    800048cc:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800048ce:	411c                	lw	a5,0(a0)
    800048d0:	4705                	li	a4,1
    800048d2:	02e78263          	beq	a5,a4,800048f6 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800048d6:	470d                	li	a4,3
    800048d8:	02e78663          	beq	a5,a4,80004904 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800048dc:	4709                	li	a4,2
    800048de:	0ee79163          	bne	a5,a4,800049c0 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800048e2:	0ac05d63          	blez	a2,8000499c <filewrite+0xf4>
    int i = 0;
    800048e6:	4981                	li	s3,0
    800048e8:	6b05                	lui	s6,0x1
    800048ea:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800048ee:	6b85                	lui	s7,0x1
    800048f0:	c00b8b9b          	addiw	s7,s7,-1024
    800048f4:	a861                	j	8000498c <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800048f6:	6908                	ld	a0,16(a0)
    800048f8:	00000097          	auipc	ra,0x0
    800048fc:	22e080e7          	jalr	558(ra) # 80004b26 <pipewrite>
    80004900:	8a2a                	mv	s4,a0
    80004902:	a045                	j	800049a2 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004904:	02451783          	lh	a5,36(a0)
    80004908:	03079693          	slli	a3,a5,0x30
    8000490c:	92c1                	srli	a3,a3,0x30
    8000490e:	4725                	li	a4,9
    80004910:	0cd76263          	bltu	a4,a3,800049d4 <filewrite+0x12c>
    80004914:	0792                	slli	a5,a5,0x4
    80004916:	0001d717          	auipc	a4,0x1d
    8000491a:	a0270713          	addi	a4,a4,-1534 # 80021318 <devsw>
    8000491e:	97ba                	add	a5,a5,a4
    80004920:	679c                	ld	a5,8(a5)
    80004922:	cbdd                	beqz	a5,800049d8 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004924:	4505                	li	a0,1
    80004926:	9782                	jalr	a5
    80004928:	8a2a                	mv	s4,a0
    8000492a:	a8a5                	j	800049a2 <filewrite+0xfa>
    8000492c:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004930:	00000097          	auipc	ra,0x0
    80004934:	8b0080e7          	jalr	-1872(ra) # 800041e0 <begin_op>
      ilock(f->ip);
    80004938:	01893503          	ld	a0,24(s2)
    8000493c:	fffff097          	auipc	ra,0xfffff
    80004940:	d74080e7          	jalr	-652(ra) # 800036b0 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004944:	8762                	mv	a4,s8
    80004946:	02092683          	lw	a3,32(s2)
    8000494a:	01598633          	add	a2,s3,s5
    8000494e:	4585                	li	a1,1
    80004950:	01893503          	ld	a0,24(s2)
    80004954:	fffff097          	auipc	ra,0xfffff
    80004958:	1ca080e7          	jalr	458(ra) # 80003b1e <writei>
    8000495c:	84aa                	mv	s1,a0
    8000495e:	00a05763          	blez	a0,8000496c <filewrite+0xc4>
        f->off += r;
    80004962:	02092783          	lw	a5,32(s2)
    80004966:	9fa9                	addw	a5,a5,a0
    80004968:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    8000496c:	01893503          	ld	a0,24(s2)
    80004970:	fffff097          	auipc	ra,0xfffff
    80004974:	e02080e7          	jalr	-510(ra) # 80003772 <iunlock>
      end_op();
    80004978:	00000097          	auipc	ra,0x0
    8000497c:	8e8080e7          	jalr	-1816(ra) # 80004260 <end_op>

      if(r != n1){
    80004980:	009c1f63          	bne	s8,s1,8000499e <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004984:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004988:	0149db63          	bge	s3,s4,8000499e <filewrite+0xf6>
      int n1 = n - i;
    8000498c:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004990:	84be                	mv	s1,a5
    80004992:	2781                	sext.w	a5,a5
    80004994:	f8fb5ce3          	bge	s6,a5,8000492c <filewrite+0x84>
    80004998:	84de                	mv	s1,s7
    8000499a:	bf49                	j	8000492c <filewrite+0x84>
    int i = 0;
    8000499c:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    8000499e:	013a1f63          	bne	s4,s3,800049bc <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800049a2:	8552                	mv	a0,s4
    800049a4:	60a6                	ld	ra,72(sp)
    800049a6:	6406                	ld	s0,64(sp)
    800049a8:	74e2                	ld	s1,56(sp)
    800049aa:	7942                	ld	s2,48(sp)
    800049ac:	79a2                	ld	s3,40(sp)
    800049ae:	7a02                	ld	s4,32(sp)
    800049b0:	6ae2                	ld	s5,24(sp)
    800049b2:	6b42                	ld	s6,16(sp)
    800049b4:	6ba2                	ld	s7,8(sp)
    800049b6:	6c02                	ld	s8,0(sp)
    800049b8:	6161                	addi	sp,sp,80
    800049ba:	8082                	ret
    ret = (i == n ? n : -1);
    800049bc:	5a7d                	li	s4,-1
    800049be:	b7d5                	j	800049a2 <filewrite+0xfa>
    panic("filewrite");
    800049c0:	00004517          	auipc	a0,0x4
    800049c4:	ce050513          	addi	a0,a0,-800 # 800086a0 <syscalls+0x270>
    800049c8:	ffffc097          	auipc	ra,0xffffc
    800049cc:	b62080e7          	jalr	-1182(ra) # 8000052a <panic>
    return -1;
    800049d0:	5a7d                	li	s4,-1
    800049d2:	bfc1                	j	800049a2 <filewrite+0xfa>
      return -1;
    800049d4:	5a7d                	li	s4,-1
    800049d6:	b7f1                	j	800049a2 <filewrite+0xfa>
    800049d8:	5a7d                	li	s4,-1
    800049da:	b7e1                	j	800049a2 <filewrite+0xfa>

00000000800049dc <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800049dc:	7179                	addi	sp,sp,-48
    800049de:	f406                	sd	ra,40(sp)
    800049e0:	f022                	sd	s0,32(sp)
    800049e2:	ec26                	sd	s1,24(sp)
    800049e4:	e84a                	sd	s2,16(sp)
    800049e6:	e44e                	sd	s3,8(sp)
    800049e8:	e052                	sd	s4,0(sp)
    800049ea:	1800                	addi	s0,sp,48
    800049ec:	84aa                	mv	s1,a0
    800049ee:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800049f0:	0005b023          	sd	zero,0(a1)
    800049f4:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800049f8:	00000097          	auipc	ra,0x0
    800049fc:	bf8080e7          	jalr	-1032(ra) # 800045f0 <filealloc>
    80004a00:	e088                	sd	a0,0(s1)
    80004a02:	c551                	beqz	a0,80004a8e <pipealloc+0xb2>
    80004a04:	00000097          	auipc	ra,0x0
    80004a08:	bec080e7          	jalr	-1044(ra) # 800045f0 <filealloc>
    80004a0c:	00aa3023          	sd	a0,0(s4)
    80004a10:	c92d                	beqz	a0,80004a82 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004a12:	ffffc097          	auipc	ra,0xffffc
    80004a16:	0c0080e7          	jalr	192(ra) # 80000ad2 <kalloc>
    80004a1a:	892a                	mv	s2,a0
    80004a1c:	c125                	beqz	a0,80004a7c <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004a1e:	4985                	li	s3,1
    80004a20:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004a24:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004a28:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004a2c:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004a30:	00004597          	auipc	a1,0x4
    80004a34:	c8058593          	addi	a1,a1,-896 # 800086b0 <syscalls+0x280>
    80004a38:	ffffc097          	auipc	ra,0xffffc
    80004a3c:	0fa080e7          	jalr	250(ra) # 80000b32 <initlock>
  (*f0)->type = FD_PIPE;
    80004a40:	609c                	ld	a5,0(s1)
    80004a42:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004a46:	609c                	ld	a5,0(s1)
    80004a48:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004a4c:	609c                	ld	a5,0(s1)
    80004a4e:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004a52:	609c                	ld	a5,0(s1)
    80004a54:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004a58:	000a3783          	ld	a5,0(s4)
    80004a5c:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004a60:	000a3783          	ld	a5,0(s4)
    80004a64:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004a68:	000a3783          	ld	a5,0(s4)
    80004a6c:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004a70:	000a3783          	ld	a5,0(s4)
    80004a74:	0127b823          	sd	s2,16(a5)
  return 0;
    80004a78:	4501                	li	a0,0
    80004a7a:	a025                	j	80004aa2 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004a7c:	6088                	ld	a0,0(s1)
    80004a7e:	e501                	bnez	a0,80004a86 <pipealloc+0xaa>
    80004a80:	a039                	j	80004a8e <pipealloc+0xb2>
    80004a82:	6088                	ld	a0,0(s1)
    80004a84:	c51d                	beqz	a0,80004ab2 <pipealloc+0xd6>
    fileclose(*f0);
    80004a86:	00000097          	auipc	ra,0x0
    80004a8a:	c26080e7          	jalr	-986(ra) # 800046ac <fileclose>
  if(*f1)
    80004a8e:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004a92:	557d                	li	a0,-1
  if(*f1)
    80004a94:	c799                	beqz	a5,80004aa2 <pipealloc+0xc6>
    fileclose(*f1);
    80004a96:	853e                	mv	a0,a5
    80004a98:	00000097          	auipc	ra,0x0
    80004a9c:	c14080e7          	jalr	-1004(ra) # 800046ac <fileclose>
  return -1;
    80004aa0:	557d                	li	a0,-1
}
    80004aa2:	70a2                	ld	ra,40(sp)
    80004aa4:	7402                	ld	s0,32(sp)
    80004aa6:	64e2                	ld	s1,24(sp)
    80004aa8:	6942                	ld	s2,16(sp)
    80004aaa:	69a2                	ld	s3,8(sp)
    80004aac:	6a02                	ld	s4,0(sp)
    80004aae:	6145                	addi	sp,sp,48
    80004ab0:	8082                	ret
  return -1;
    80004ab2:	557d                	li	a0,-1
    80004ab4:	b7fd                	j	80004aa2 <pipealloc+0xc6>

0000000080004ab6 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004ab6:	1101                	addi	sp,sp,-32
    80004ab8:	ec06                	sd	ra,24(sp)
    80004aba:	e822                	sd	s0,16(sp)
    80004abc:	e426                	sd	s1,8(sp)
    80004abe:	e04a                	sd	s2,0(sp)
    80004ac0:	1000                	addi	s0,sp,32
    80004ac2:	84aa                	mv	s1,a0
    80004ac4:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004ac6:	ffffc097          	auipc	ra,0xffffc
    80004aca:	0fc080e7          	jalr	252(ra) # 80000bc2 <acquire>
  if(writable){
    80004ace:	02090d63          	beqz	s2,80004b08 <pipeclose+0x52>
    pi->writeopen = 0;
    80004ad2:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004ad6:	21848513          	addi	a0,s1,536
    80004ada:	ffffd097          	auipc	ra,0xffffd
    80004ade:	736080e7          	jalr	1846(ra) # 80002210 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004ae2:	2204b783          	ld	a5,544(s1)
    80004ae6:	eb95                	bnez	a5,80004b1a <pipeclose+0x64>
    release(&pi->lock);
    80004ae8:	8526                	mv	a0,s1
    80004aea:	ffffc097          	auipc	ra,0xffffc
    80004aee:	18c080e7          	jalr	396(ra) # 80000c76 <release>
    kfree((char*)pi);
    80004af2:	8526                	mv	a0,s1
    80004af4:	ffffc097          	auipc	ra,0xffffc
    80004af8:	ee2080e7          	jalr	-286(ra) # 800009d6 <kfree>
  } else
    release(&pi->lock);
}
    80004afc:	60e2                	ld	ra,24(sp)
    80004afe:	6442                	ld	s0,16(sp)
    80004b00:	64a2                	ld	s1,8(sp)
    80004b02:	6902                	ld	s2,0(sp)
    80004b04:	6105                	addi	sp,sp,32
    80004b06:	8082                	ret
    pi->readopen = 0;
    80004b08:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004b0c:	21c48513          	addi	a0,s1,540
    80004b10:	ffffd097          	auipc	ra,0xffffd
    80004b14:	700080e7          	jalr	1792(ra) # 80002210 <wakeup>
    80004b18:	b7e9                	j	80004ae2 <pipeclose+0x2c>
    release(&pi->lock);
    80004b1a:	8526                	mv	a0,s1
    80004b1c:	ffffc097          	auipc	ra,0xffffc
    80004b20:	15a080e7          	jalr	346(ra) # 80000c76 <release>
}
    80004b24:	bfe1                	j	80004afc <pipeclose+0x46>

0000000080004b26 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004b26:	711d                	addi	sp,sp,-96
    80004b28:	ec86                	sd	ra,88(sp)
    80004b2a:	e8a2                	sd	s0,80(sp)
    80004b2c:	e4a6                	sd	s1,72(sp)
    80004b2e:	e0ca                	sd	s2,64(sp)
    80004b30:	fc4e                	sd	s3,56(sp)
    80004b32:	f852                	sd	s4,48(sp)
    80004b34:	f456                	sd	s5,40(sp)
    80004b36:	f05a                	sd	s6,32(sp)
    80004b38:	ec5e                	sd	s7,24(sp)
    80004b3a:	e862                	sd	s8,16(sp)
    80004b3c:	1080                	addi	s0,sp,96
    80004b3e:	84aa                	mv	s1,a0
    80004b40:	8aae                	mv	s5,a1
    80004b42:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004b44:	ffffd097          	auipc	ra,0xffffd
    80004b48:	e7c080e7          	jalr	-388(ra) # 800019c0 <myproc>
    80004b4c:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004b4e:	8526                	mv	a0,s1
    80004b50:	ffffc097          	auipc	ra,0xffffc
    80004b54:	072080e7          	jalr	114(ra) # 80000bc2 <acquire>
  while(i < n){
    80004b58:	0b405363          	blez	s4,80004bfe <pipewrite+0xd8>
  int i = 0;
    80004b5c:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b5e:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004b60:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004b64:	21c48b93          	addi	s7,s1,540
    80004b68:	a089                	j	80004baa <pipewrite+0x84>
      release(&pi->lock);
    80004b6a:	8526                	mv	a0,s1
    80004b6c:	ffffc097          	auipc	ra,0xffffc
    80004b70:	10a080e7          	jalr	266(ra) # 80000c76 <release>
      return -1;
    80004b74:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004b76:	854a                	mv	a0,s2
    80004b78:	60e6                	ld	ra,88(sp)
    80004b7a:	6446                	ld	s0,80(sp)
    80004b7c:	64a6                	ld	s1,72(sp)
    80004b7e:	6906                	ld	s2,64(sp)
    80004b80:	79e2                	ld	s3,56(sp)
    80004b82:	7a42                	ld	s4,48(sp)
    80004b84:	7aa2                	ld	s5,40(sp)
    80004b86:	7b02                	ld	s6,32(sp)
    80004b88:	6be2                	ld	s7,24(sp)
    80004b8a:	6c42                	ld	s8,16(sp)
    80004b8c:	6125                	addi	sp,sp,96
    80004b8e:	8082                	ret
      wakeup(&pi->nread);
    80004b90:	8562                	mv	a0,s8
    80004b92:	ffffd097          	auipc	ra,0xffffd
    80004b96:	67e080e7          	jalr	1662(ra) # 80002210 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004b9a:	85a6                	mv	a1,s1
    80004b9c:	855e                	mv	a0,s7
    80004b9e:	ffffd097          	auipc	ra,0xffffd
    80004ba2:	4e6080e7          	jalr	1254(ra) # 80002084 <sleep>
  while(i < n){
    80004ba6:	05495d63          	bge	s2,s4,80004c00 <pipewrite+0xda>
    if(pi->readopen == 0 || pr->killed){
    80004baa:	2204a783          	lw	a5,544(s1)
    80004bae:	dfd5                	beqz	a5,80004b6a <pipewrite+0x44>
    80004bb0:	0289a783          	lw	a5,40(s3)
    80004bb4:	fbdd                	bnez	a5,80004b6a <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004bb6:	2184a783          	lw	a5,536(s1)
    80004bba:	21c4a703          	lw	a4,540(s1)
    80004bbe:	2007879b          	addiw	a5,a5,512
    80004bc2:	fcf707e3          	beq	a4,a5,80004b90 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004bc6:	4685                	li	a3,1
    80004bc8:	01590633          	add	a2,s2,s5
    80004bcc:	faf40593          	addi	a1,s0,-81
    80004bd0:	0509b503          	ld	a0,80(s3)
    80004bd4:	ffffd097          	auipc	ra,0xffffd
    80004bd8:	b38080e7          	jalr	-1224(ra) # 8000170c <copyin>
    80004bdc:	03650263          	beq	a0,s6,80004c00 <pipewrite+0xda>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004be0:	21c4a783          	lw	a5,540(s1)
    80004be4:	0017871b          	addiw	a4,a5,1
    80004be8:	20e4ae23          	sw	a4,540(s1)
    80004bec:	1ff7f793          	andi	a5,a5,511
    80004bf0:	97a6                	add	a5,a5,s1
    80004bf2:	faf44703          	lbu	a4,-81(s0)
    80004bf6:	00e78c23          	sb	a4,24(a5)
      i++;
    80004bfa:	2905                	addiw	s2,s2,1
    80004bfc:	b76d                	j	80004ba6 <pipewrite+0x80>
  int i = 0;
    80004bfe:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004c00:	21848513          	addi	a0,s1,536
    80004c04:	ffffd097          	auipc	ra,0xffffd
    80004c08:	60c080e7          	jalr	1548(ra) # 80002210 <wakeup>
  release(&pi->lock);
    80004c0c:	8526                	mv	a0,s1
    80004c0e:	ffffc097          	auipc	ra,0xffffc
    80004c12:	068080e7          	jalr	104(ra) # 80000c76 <release>
  return i;
    80004c16:	b785                	j	80004b76 <pipewrite+0x50>

0000000080004c18 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004c18:	715d                	addi	sp,sp,-80
    80004c1a:	e486                	sd	ra,72(sp)
    80004c1c:	e0a2                	sd	s0,64(sp)
    80004c1e:	fc26                	sd	s1,56(sp)
    80004c20:	f84a                	sd	s2,48(sp)
    80004c22:	f44e                	sd	s3,40(sp)
    80004c24:	f052                	sd	s4,32(sp)
    80004c26:	ec56                	sd	s5,24(sp)
    80004c28:	e85a                	sd	s6,16(sp)
    80004c2a:	0880                	addi	s0,sp,80
    80004c2c:	84aa                	mv	s1,a0
    80004c2e:	892e                	mv	s2,a1
    80004c30:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004c32:	ffffd097          	auipc	ra,0xffffd
    80004c36:	d8e080e7          	jalr	-626(ra) # 800019c0 <myproc>
    80004c3a:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004c3c:	8526                	mv	a0,s1
    80004c3e:	ffffc097          	auipc	ra,0xffffc
    80004c42:	f84080e7          	jalr	-124(ra) # 80000bc2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c46:	2184a703          	lw	a4,536(s1)
    80004c4a:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c4e:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c52:	02f71463          	bne	a4,a5,80004c7a <piperead+0x62>
    80004c56:	2244a783          	lw	a5,548(s1)
    80004c5a:	c385                	beqz	a5,80004c7a <piperead+0x62>
    if(pr->killed){
    80004c5c:	028a2783          	lw	a5,40(s4)
    80004c60:	ebc1                	bnez	a5,80004cf0 <piperead+0xd8>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c62:	85a6                	mv	a1,s1
    80004c64:	854e                	mv	a0,s3
    80004c66:	ffffd097          	auipc	ra,0xffffd
    80004c6a:	41e080e7          	jalr	1054(ra) # 80002084 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c6e:	2184a703          	lw	a4,536(s1)
    80004c72:	21c4a783          	lw	a5,540(s1)
    80004c76:	fef700e3          	beq	a4,a5,80004c56 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c7a:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c7c:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c7e:	05505363          	blez	s5,80004cc4 <piperead+0xac>
    if(pi->nread == pi->nwrite)
    80004c82:	2184a783          	lw	a5,536(s1)
    80004c86:	21c4a703          	lw	a4,540(s1)
    80004c8a:	02f70d63          	beq	a4,a5,80004cc4 <piperead+0xac>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004c8e:	0017871b          	addiw	a4,a5,1
    80004c92:	20e4ac23          	sw	a4,536(s1)
    80004c96:	1ff7f793          	andi	a5,a5,511
    80004c9a:	97a6                	add	a5,a5,s1
    80004c9c:	0187c783          	lbu	a5,24(a5)
    80004ca0:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004ca4:	4685                	li	a3,1
    80004ca6:	fbf40613          	addi	a2,s0,-65
    80004caa:	85ca                	mv	a1,s2
    80004cac:	050a3503          	ld	a0,80(s4)
    80004cb0:	ffffd097          	auipc	ra,0xffffd
    80004cb4:	9d0080e7          	jalr	-1584(ra) # 80001680 <copyout>
    80004cb8:	01650663          	beq	a0,s6,80004cc4 <piperead+0xac>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004cbc:	2985                	addiw	s3,s3,1
    80004cbe:	0905                	addi	s2,s2,1
    80004cc0:	fd3a91e3          	bne	s5,s3,80004c82 <piperead+0x6a>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004cc4:	21c48513          	addi	a0,s1,540
    80004cc8:	ffffd097          	auipc	ra,0xffffd
    80004ccc:	548080e7          	jalr	1352(ra) # 80002210 <wakeup>
  release(&pi->lock);
    80004cd0:	8526                	mv	a0,s1
    80004cd2:	ffffc097          	auipc	ra,0xffffc
    80004cd6:	fa4080e7          	jalr	-92(ra) # 80000c76 <release>
  return i;
}
    80004cda:	854e                	mv	a0,s3
    80004cdc:	60a6                	ld	ra,72(sp)
    80004cde:	6406                	ld	s0,64(sp)
    80004ce0:	74e2                	ld	s1,56(sp)
    80004ce2:	7942                	ld	s2,48(sp)
    80004ce4:	79a2                	ld	s3,40(sp)
    80004ce6:	7a02                	ld	s4,32(sp)
    80004ce8:	6ae2                	ld	s5,24(sp)
    80004cea:	6b42                	ld	s6,16(sp)
    80004cec:	6161                	addi	sp,sp,80
    80004cee:	8082                	ret
      release(&pi->lock);
    80004cf0:	8526                	mv	a0,s1
    80004cf2:	ffffc097          	auipc	ra,0xffffc
    80004cf6:	f84080e7          	jalr	-124(ra) # 80000c76 <release>
      return -1;
    80004cfa:	59fd                	li	s3,-1
    80004cfc:	bff9                	j	80004cda <piperead+0xc2>

0000000080004cfe <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004cfe:	de010113          	addi	sp,sp,-544
    80004d02:	20113c23          	sd	ra,536(sp)
    80004d06:	20813823          	sd	s0,528(sp)
    80004d0a:	20913423          	sd	s1,520(sp)
    80004d0e:	21213023          	sd	s2,512(sp)
    80004d12:	ffce                	sd	s3,504(sp)
    80004d14:	fbd2                	sd	s4,496(sp)
    80004d16:	f7d6                	sd	s5,488(sp)
    80004d18:	f3da                	sd	s6,480(sp)
    80004d1a:	efde                	sd	s7,472(sp)
    80004d1c:	ebe2                	sd	s8,464(sp)
    80004d1e:	e7e6                	sd	s9,456(sp)
    80004d20:	e3ea                	sd	s10,448(sp)
    80004d22:	ff6e                	sd	s11,440(sp)
    80004d24:	1400                	addi	s0,sp,544
    80004d26:	892a                	mv	s2,a0
    80004d28:	dea43423          	sd	a0,-536(s0)
    80004d2c:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004d30:	ffffd097          	auipc	ra,0xffffd
    80004d34:	c90080e7          	jalr	-880(ra) # 800019c0 <myproc>
    80004d38:	84aa                	mv	s1,a0

  begin_op();
    80004d3a:	fffff097          	auipc	ra,0xfffff
    80004d3e:	4a6080e7          	jalr	1190(ra) # 800041e0 <begin_op>

  if((ip = namei(path, 1, 0)) == 0){
    80004d42:	4601                	li	a2,0
    80004d44:	4585                	li	a1,1
    80004d46:	854a                	mv	a0,s2
    80004d48:	fffff097          	auipc	ra,0xfffff
    80004d4c:	274080e7          	jalr	628(ra) # 80003fbc <namei>
    80004d50:	c93d                	beqz	a0,80004dc6 <exec+0xc8>
    80004d52:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004d54:	fffff097          	auipc	ra,0xfffff
    80004d58:	95c080e7          	jalr	-1700(ra) # 800036b0 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004d5c:	04000713          	li	a4,64
    80004d60:	4681                	li	a3,0
    80004d62:	e4840613          	addi	a2,s0,-440
    80004d66:	4581                	li	a1,0
    80004d68:	8556                	mv	a0,s5
    80004d6a:	fffff097          	auipc	ra,0xfffff
    80004d6e:	cbc080e7          	jalr	-836(ra) # 80003a26 <readi>
    80004d72:	04000793          	li	a5,64
    80004d76:	00f51a63          	bne	a0,a5,80004d8a <exec+0x8c>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004d7a:	e4842703          	lw	a4,-440(s0)
    80004d7e:	464c47b7          	lui	a5,0x464c4
    80004d82:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004d86:	04f70663          	beq	a4,a5,80004dd2 <exec+0xd4>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004d8a:	8556                	mv	a0,s5
    80004d8c:	fffff097          	auipc	ra,0xfffff
    80004d90:	c48080e7          	jalr	-952(ra) # 800039d4 <iunlockput>
    end_op();
    80004d94:	fffff097          	auipc	ra,0xfffff
    80004d98:	4cc080e7          	jalr	1228(ra) # 80004260 <end_op>
  }
  return -1;
    80004d9c:	557d                	li	a0,-1
}
    80004d9e:	21813083          	ld	ra,536(sp)
    80004da2:	21013403          	ld	s0,528(sp)
    80004da6:	20813483          	ld	s1,520(sp)
    80004daa:	20013903          	ld	s2,512(sp)
    80004dae:	79fe                	ld	s3,504(sp)
    80004db0:	7a5e                	ld	s4,496(sp)
    80004db2:	7abe                	ld	s5,488(sp)
    80004db4:	7b1e                	ld	s6,480(sp)
    80004db6:	6bfe                	ld	s7,472(sp)
    80004db8:	6c5e                	ld	s8,464(sp)
    80004dba:	6cbe                	ld	s9,456(sp)
    80004dbc:	6d1e                	ld	s10,448(sp)
    80004dbe:	7dfa                	ld	s11,440(sp)
    80004dc0:	22010113          	addi	sp,sp,544
    80004dc4:	8082                	ret
    end_op();
    80004dc6:	fffff097          	auipc	ra,0xfffff
    80004dca:	49a080e7          	jalr	1178(ra) # 80004260 <end_op>
    return -1;
    80004dce:	557d                	li	a0,-1
    80004dd0:	b7f9                	j	80004d9e <exec+0xa0>
  if((pagetable = proc_pagetable(p)) == 0)
    80004dd2:	8526                	mv	a0,s1
    80004dd4:	ffffd097          	auipc	ra,0xffffd
    80004dd8:	cb0080e7          	jalr	-848(ra) # 80001a84 <proc_pagetable>
    80004ddc:	8b2a                	mv	s6,a0
    80004dde:	d555                	beqz	a0,80004d8a <exec+0x8c>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004de0:	e6842783          	lw	a5,-408(s0)
    80004de4:	e8045703          	lhu	a4,-384(s0)
    80004de8:	c735                	beqz	a4,80004e54 <exec+0x156>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004dea:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004dec:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004df0:	6a05                	lui	s4,0x1
    80004df2:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004df6:	dee43023          	sd	a4,-544(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    80004dfa:	6d85                	lui	s11,0x1
    80004dfc:	7d7d                	lui	s10,0xfffff
    80004dfe:	ac1d                	j	80005034 <exec+0x336>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004e00:	00004517          	auipc	a0,0x4
    80004e04:	8b850513          	addi	a0,a0,-1864 # 800086b8 <syscalls+0x288>
    80004e08:	ffffb097          	auipc	ra,0xffffb
    80004e0c:	722080e7          	jalr	1826(ra) # 8000052a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004e10:	874a                	mv	a4,s2
    80004e12:	009c86bb          	addw	a3,s9,s1
    80004e16:	4581                	li	a1,0
    80004e18:	8556                	mv	a0,s5
    80004e1a:	fffff097          	auipc	ra,0xfffff
    80004e1e:	c0c080e7          	jalr	-1012(ra) # 80003a26 <readi>
    80004e22:	2501                	sext.w	a0,a0
    80004e24:	1aa91863          	bne	s2,a0,80004fd4 <exec+0x2d6>
  for(i = 0; i < sz; i += PGSIZE){
    80004e28:	009d84bb          	addw	s1,s11,s1
    80004e2c:	013d09bb          	addw	s3,s10,s3
    80004e30:	1f74f263          	bgeu	s1,s7,80005014 <exec+0x316>
    pa = walkaddr(pagetable, va + i);
    80004e34:	02049593          	slli	a1,s1,0x20
    80004e38:	9181                	srli	a1,a1,0x20
    80004e3a:	95e2                	add	a1,a1,s8
    80004e3c:	855a                	mv	a0,s6
    80004e3e:	ffffc097          	auipc	ra,0xffffc
    80004e42:	250080e7          	jalr	592(ra) # 8000108e <walkaddr>
    80004e46:	862a                	mv	a2,a0
    if(pa == 0)
    80004e48:	dd45                	beqz	a0,80004e00 <exec+0x102>
      n = PGSIZE;
    80004e4a:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004e4c:	fd49f2e3          	bgeu	s3,s4,80004e10 <exec+0x112>
      n = sz - i;
    80004e50:	894e                	mv	s2,s3
    80004e52:	bf7d                	j	80004e10 <exec+0x112>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004e54:	4481                	li	s1,0
  iunlockput(ip);
    80004e56:	8556                	mv	a0,s5
    80004e58:	fffff097          	auipc	ra,0xfffff
    80004e5c:	b7c080e7          	jalr	-1156(ra) # 800039d4 <iunlockput>
  end_op();
    80004e60:	fffff097          	auipc	ra,0xfffff
    80004e64:	400080e7          	jalr	1024(ra) # 80004260 <end_op>
  p = myproc();
    80004e68:	ffffd097          	auipc	ra,0xffffd
    80004e6c:	b58080e7          	jalr	-1192(ra) # 800019c0 <myproc>
    80004e70:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004e72:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004e76:	6785                	lui	a5,0x1
    80004e78:	17fd                	addi	a5,a5,-1
    80004e7a:	94be                	add	s1,s1,a5
    80004e7c:	77fd                	lui	a5,0xfffff
    80004e7e:	8fe5                	and	a5,a5,s1
    80004e80:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004e84:	6609                	lui	a2,0x2
    80004e86:	963e                	add	a2,a2,a5
    80004e88:	85be                	mv	a1,a5
    80004e8a:	855a                	mv	a0,s6
    80004e8c:	ffffc097          	auipc	ra,0xffffc
    80004e90:	5a4080e7          	jalr	1444(ra) # 80001430 <uvmalloc>
    80004e94:	8c2a                	mv	s8,a0
  ip = 0;
    80004e96:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004e98:	12050e63          	beqz	a0,80004fd4 <exec+0x2d6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004e9c:	75f9                	lui	a1,0xffffe
    80004e9e:	95aa                	add	a1,a1,a0
    80004ea0:	855a                	mv	a0,s6
    80004ea2:	ffffc097          	auipc	ra,0xffffc
    80004ea6:	7ac080e7          	jalr	1964(ra) # 8000164e <uvmclear>
  stackbase = sp - PGSIZE;
    80004eaa:	7afd                	lui	s5,0xfffff
    80004eac:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004eae:	df043783          	ld	a5,-528(s0)
    80004eb2:	6388                	ld	a0,0(a5)
    80004eb4:	c925                	beqz	a0,80004f24 <exec+0x226>
    80004eb6:	e8840993          	addi	s3,s0,-376
    80004eba:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80004ebe:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004ec0:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004ec2:	ffffc097          	auipc	ra,0xffffc
    80004ec6:	f80080e7          	jalr	-128(ra) # 80000e42 <strlen>
    80004eca:	0015079b          	addiw	a5,a0,1
    80004ece:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004ed2:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004ed6:	13596363          	bltu	s2,s5,80004ffc <exec+0x2fe>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004eda:	df043d83          	ld	s11,-528(s0)
    80004ede:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004ee2:	8552                	mv	a0,s4
    80004ee4:	ffffc097          	auipc	ra,0xffffc
    80004ee8:	f5e080e7          	jalr	-162(ra) # 80000e42 <strlen>
    80004eec:	0015069b          	addiw	a3,a0,1
    80004ef0:	8652                	mv	a2,s4
    80004ef2:	85ca                	mv	a1,s2
    80004ef4:	855a                	mv	a0,s6
    80004ef6:	ffffc097          	auipc	ra,0xffffc
    80004efa:	78a080e7          	jalr	1930(ra) # 80001680 <copyout>
    80004efe:	10054363          	bltz	a0,80005004 <exec+0x306>
    ustack[argc] = sp;
    80004f02:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004f06:	0485                	addi	s1,s1,1
    80004f08:	008d8793          	addi	a5,s11,8
    80004f0c:	def43823          	sd	a5,-528(s0)
    80004f10:	008db503          	ld	a0,8(s11)
    80004f14:	c911                	beqz	a0,80004f28 <exec+0x22a>
    if(argc >= MAXARG)
    80004f16:	09a1                	addi	s3,s3,8
    80004f18:	fb3c95e3          	bne	s9,s3,80004ec2 <exec+0x1c4>
  sz = sz1;
    80004f1c:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f20:	4a81                	li	s5,0
    80004f22:	a84d                	j	80004fd4 <exec+0x2d6>
  sp = sz;
    80004f24:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004f26:	4481                	li	s1,0
  ustack[argc] = 0;
    80004f28:	00349793          	slli	a5,s1,0x3
    80004f2c:	f9040713          	addi	a4,s0,-112
    80004f30:	97ba                	add	a5,a5,a4
    80004f32:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffd8ef8>
  sp -= (argc+1) * sizeof(uint64);
    80004f36:	00148693          	addi	a3,s1,1
    80004f3a:	068e                	slli	a3,a3,0x3
    80004f3c:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004f40:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004f44:	01597663          	bgeu	s2,s5,80004f50 <exec+0x252>
  sz = sz1;
    80004f48:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f4c:	4a81                	li	s5,0
    80004f4e:	a059                	j	80004fd4 <exec+0x2d6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004f50:	e8840613          	addi	a2,s0,-376
    80004f54:	85ca                	mv	a1,s2
    80004f56:	855a                	mv	a0,s6
    80004f58:	ffffc097          	auipc	ra,0xffffc
    80004f5c:	728080e7          	jalr	1832(ra) # 80001680 <copyout>
    80004f60:	0a054663          	bltz	a0,8000500c <exec+0x30e>
  p->trapframe->a1 = sp;
    80004f64:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    80004f68:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004f6c:	de843783          	ld	a5,-536(s0)
    80004f70:	0007c703          	lbu	a4,0(a5)
    80004f74:	cf11                	beqz	a4,80004f90 <exec+0x292>
    80004f76:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004f78:	02f00693          	li	a3,47
    80004f7c:	a039                	j	80004f8a <exec+0x28c>
      last = s+1;
    80004f7e:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80004f82:	0785                	addi	a5,a5,1
    80004f84:	fff7c703          	lbu	a4,-1(a5)
    80004f88:	c701                	beqz	a4,80004f90 <exec+0x292>
    if(*s == '/')
    80004f8a:	fed71ce3          	bne	a4,a3,80004f82 <exec+0x284>
    80004f8e:	bfc5                	j	80004f7e <exec+0x280>
  safestrcpy(p->name, last, sizeof(p->name));
    80004f90:	4641                	li	a2,16
    80004f92:	de843583          	ld	a1,-536(s0)
    80004f96:	158b8513          	addi	a0,s7,344
    80004f9a:	ffffc097          	auipc	ra,0xffffc
    80004f9e:	e76080e7          	jalr	-394(ra) # 80000e10 <safestrcpy>
  oldpagetable = p->pagetable;
    80004fa2:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80004fa6:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80004faa:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004fae:	058bb783          	ld	a5,88(s7)
    80004fb2:	e6043703          	ld	a4,-416(s0)
    80004fb6:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004fb8:	058bb783          	ld	a5,88(s7)
    80004fbc:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004fc0:	85ea                	mv	a1,s10
    80004fc2:	ffffd097          	auipc	ra,0xffffd
    80004fc6:	b5e080e7          	jalr	-1186(ra) # 80001b20 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004fca:	0004851b          	sext.w	a0,s1
    80004fce:	bbc1                	j	80004d9e <exec+0xa0>
    80004fd0:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    80004fd4:	df843583          	ld	a1,-520(s0)
    80004fd8:	855a                	mv	a0,s6
    80004fda:	ffffd097          	auipc	ra,0xffffd
    80004fde:	b46080e7          	jalr	-1210(ra) # 80001b20 <proc_freepagetable>
  if(ip){
    80004fe2:	da0a94e3          	bnez	s5,80004d8a <exec+0x8c>
  return -1;
    80004fe6:	557d                	li	a0,-1
    80004fe8:	bb5d                	j	80004d9e <exec+0xa0>
    80004fea:	de943c23          	sd	s1,-520(s0)
    80004fee:	b7dd                	j	80004fd4 <exec+0x2d6>
    80004ff0:	de943c23          	sd	s1,-520(s0)
    80004ff4:	b7c5                	j	80004fd4 <exec+0x2d6>
    80004ff6:	de943c23          	sd	s1,-520(s0)
    80004ffa:	bfe9                	j	80004fd4 <exec+0x2d6>
  sz = sz1;
    80004ffc:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005000:	4a81                	li	s5,0
    80005002:	bfc9                	j	80004fd4 <exec+0x2d6>
  sz = sz1;
    80005004:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005008:	4a81                	li	s5,0
    8000500a:	b7e9                	j	80004fd4 <exec+0x2d6>
  sz = sz1;
    8000500c:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005010:	4a81                	li	s5,0
    80005012:	b7c9                	j	80004fd4 <exec+0x2d6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005014:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005018:	e0843783          	ld	a5,-504(s0)
    8000501c:	0017869b          	addiw	a3,a5,1
    80005020:	e0d43423          	sd	a3,-504(s0)
    80005024:	e0043783          	ld	a5,-512(s0)
    80005028:	0387879b          	addiw	a5,a5,56
    8000502c:	e8045703          	lhu	a4,-384(s0)
    80005030:	e2e6d3e3          	bge	a3,a4,80004e56 <exec+0x158>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005034:	2781                	sext.w	a5,a5
    80005036:	e0f43023          	sd	a5,-512(s0)
    8000503a:	03800713          	li	a4,56
    8000503e:	86be                	mv	a3,a5
    80005040:	e1040613          	addi	a2,s0,-496
    80005044:	4581                	li	a1,0
    80005046:	8556                	mv	a0,s5
    80005048:	fffff097          	auipc	ra,0xfffff
    8000504c:	9de080e7          	jalr	-1570(ra) # 80003a26 <readi>
    80005050:	03800793          	li	a5,56
    80005054:	f6f51ee3          	bne	a0,a5,80004fd0 <exec+0x2d2>
    if(ph.type != ELF_PROG_LOAD)
    80005058:	e1042783          	lw	a5,-496(s0)
    8000505c:	4705                	li	a4,1
    8000505e:	fae79de3          	bne	a5,a4,80005018 <exec+0x31a>
    if(ph.memsz < ph.filesz)
    80005062:	e3843603          	ld	a2,-456(s0)
    80005066:	e3043783          	ld	a5,-464(s0)
    8000506a:	f8f660e3          	bltu	a2,a5,80004fea <exec+0x2ec>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000506e:	e2043783          	ld	a5,-480(s0)
    80005072:	963e                	add	a2,a2,a5
    80005074:	f6f66ee3          	bltu	a2,a5,80004ff0 <exec+0x2f2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005078:	85a6                	mv	a1,s1
    8000507a:	855a                	mv	a0,s6
    8000507c:	ffffc097          	auipc	ra,0xffffc
    80005080:	3b4080e7          	jalr	948(ra) # 80001430 <uvmalloc>
    80005084:	dea43c23          	sd	a0,-520(s0)
    80005088:	d53d                	beqz	a0,80004ff6 <exec+0x2f8>
    if(ph.vaddr % PGSIZE != 0)
    8000508a:	e2043c03          	ld	s8,-480(s0)
    8000508e:	de043783          	ld	a5,-544(s0)
    80005092:	00fc77b3          	and	a5,s8,a5
    80005096:	ff9d                	bnez	a5,80004fd4 <exec+0x2d6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005098:	e1842c83          	lw	s9,-488(s0)
    8000509c:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800050a0:	f60b8ae3          	beqz	s7,80005014 <exec+0x316>
    800050a4:	89de                	mv	s3,s7
    800050a6:	4481                	li	s1,0
    800050a8:	b371                	j	80004e34 <exec+0x136>

00000000800050aa <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800050aa:	7179                	addi	sp,sp,-48
    800050ac:	f406                	sd	ra,40(sp)
    800050ae:	f022                	sd	s0,32(sp)
    800050b0:	ec26                	sd	s1,24(sp)
    800050b2:	e84a                	sd	s2,16(sp)
    800050b4:	1800                	addi	s0,sp,48
    800050b6:	892e                	mv	s2,a1
    800050b8:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800050ba:	fdc40593          	addi	a1,s0,-36
    800050be:	ffffe097          	auipc	ra,0xffffe
    800050c2:	9b6080e7          	jalr	-1610(ra) # 80002a74 <argint>
    800050c6:	04054063          	bltz	a0,80005106 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800050ca:	fdc42703          	lw	a4,-36(s0)
    800050ce:	47bd                	li	a5,15
    800050d0:	02e7ed63          	bltu	a5,a4,8000510a <argfd+0x60>
    800050d4:	ffffd097          	auipc	ra,0xffffd
    800050d8:	8ec080e7          	jalr	-1812(ra) # 800019c0 <myproc>
    800050dc:	fdc42703          	lw	a4,-36(s0)
    800050e0:	01a70793          	addi	a5,a4,26
    800050e4:	078e                	slli	a5,a5,0x3
    800050e6:	953e                	add	a0,a0,a5
    800050e8:	611c                	ld	a5,0(a0)
    800050ea:	c395                	beqz	a5,8000510e <argfd+0x64>
    return -1;
  if(pfd)
    800050ec:	00090463          	beqz	s2,800050f4 <argfd+0x4a>
    *pfd = fd;
    800050f0:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800050f4:	4501                	li	a0,0
  if(pf)
    800050f6:	c091                	beqz	s1,800050fa <argfd+0x50>
    *pf = f;
    800050f8:	e09c                	sd	a5,0(s1)
}
    800050fa:	70a2                	ld	ra,40(sp)
    800050fc:	7402                	ld	s0,32(sp)
    800050fe:	64e2                	ld	s1,24(sp)
    80005100:	6942                	ld	s2,16(sp)
    80005102:	6145                	addi	sp,sp,48
    80005104:	8082                	ret
    return -1;
    80005106:	557d                	li	a0,-1
    80005108:	bfcd                	j	800050fa <argfd+0x50>
    return -1;
    8000510a:	557d                	li	a0,-1
    8000510c:	b7fd                	j	800050fa <argfd+0x50>
    8000510e:	557d                	li	a0,-1
    80005110:	b7ed                	j	800050fa <argfd+0x50>

0000000080005112 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005112:	1101                	addi	sp,sp,-32
    80005114:	ec06                	sd	ra,24(sp)
    80005116:	e822                	sd	s0,16(sp)
    80005118:	e426                	sd	s1,8(sp)
    8000511a:	1000                	addi	s0,sp,32
    8000511c:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000511e:	ffffd097          	auipc	ra,0xffffd
    80005122:	8a2080e7          	jalr	-1886(ra) # 800019c0 <myproc>
    80005126:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005128:	0d050793          	addi	a5,a0,208
    8000512c:	4501                	li	a0,0
    8000512e:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005130:	6398                	ld	a4,0(a5)
    80005132:	cb19                	beqz	a4,80005148 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005134:	2505                	addiw	a0,a0,1
    80005136:	07a1                	addi	a5,a5,8
    80005138:	fed51ce3          	bne	a0,a3,80005130 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000513c:	557d                	li	a0,-1
}
    8000513e:	60e2                	ld	ra,24(sp)
    80005140:	6442                	ld	s0,16(sp)
    80005142:	64a2                	ld	s1,8(sp)
    80005144:	6105                	addi	sp,sp,32
    80005146:	8082                	ret
      p->ofile[fd] = f;
    80005148:	01a50793          	addi	a5,a0,26
    8000514c:	078e                	slli	a5,a5,0x3
    8000514e:	963e                	add	a2,a2,a5
    80005150:	e204                	sd	s1,0(a2)
      return fd;
    80005152:	b7f5                	j	8000513e <fdalloc+0x2c>

0000000080005154 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005154:	715d                	addi	sp,sp,-80
    80005156:	e486                	sd	ra,72(sp)
    80005158:	e0a2                	sd	s0,64(sp)
    8000515a:	fc26                	sd	s1,56(sp)
    8000515c:	f84a                	sd	s2,48(sp)
    8000515e:	f44e                	sd	s3,40(sp)
    80005160:	f052                	sd	s4,32(sp)
    80005162:	ec56                	sd	s5,24(sp)
    80005164:	0880                	addi	s0,sp,80
    80005166:	89ae                	mv	s3,a1
    80005168:	8ab2                	mv	s5,a2
    8000516a:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000516c:	fb040593          	addi	a1,s0,-80
    80005170:	fffff097          	auipc	ra,0xfffff
    80005174:	e6e080e7          	jalr	-402(ra) # 80003fde <nameiparent>
    80005178:	892a                	mv	s2,a0
    8000517a:	12050e63          	beqz	a0,800052b6 <create+0x162>
    return 0;

  ilock(dp);
    8000517e:	ffffe097          	auipc	ra,0xffffe
    80005182:	532080e7          	jalr	1330(ra) # 800036b0 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005186:	4601                	li	a2,0
    80005188:	fb040593          	addi	a1,s0,-80
    8000518c:	854a                	mv	a0,s2
    8000518e:	fffff097          	auipc	ra,0xfffff
    80005192:	aca080e7          	jalr	-1334(ra) # 80003c58 <dirlookup>
    80005196:	84aa                	mv	s1,a0
    80005198:	c921                	beqz	a0,800051e8 <create+0x94>
    iunlockput(dp);
    8000519a:	854a                	mv	a0,s2
    8000519c:	fffff097          	auipc	ra,0xfffff
    800051a0:	838080e7          	jalr	-1992(ra) # 800039d4 <iunlockput>
    ilock(ip);
    800051a4:	8526                	mv	a0,s1
    800051a6:	ffffe097          	auipc	ra,0xffffe
    800051aa:	50a080e7          	jalr	1290(ra) # 800036b0 <ilock>
	// checkpoint
	/*if(type == T_SYMLINK) return ip;*/
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800051ae:	2981                	sext.w	s3,s3
    800051b0:	4789                	li	a5,2
    800051b2:	02f99463          	bne	s3,a5,800051da <create+0x86>
    800051b6:	0444d783          	lhu	a5,68(s1)
    800051ba:	37f9                	addiw	a5,a5,-2
    800051bc:	17c2                	slli	a5,a5,0x30
    800051be:	93c1                	srli	a5,a5,0x30
    800051c0:	4705                	li	a4,1
    800051c2:	00f76c63          	bltu	a4,a5,800051da <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800051c6:	8526                	mv	a0,s1
    800051c8:	60a6                	ld	ra,72(sp)
    800051ca:	6406                	ld	s0,64(sp)
    800051cc:	74e2                	ld	s1,56(sp)
    800051ce:	7942                	ld	s2,48(sp)
    800051d0:	79a2                	ld	s3,40(sp)
    800051d2:	7a02                	ld	s4,32(sp)
    800051d4:	6ae2                	ld	s5,24(sp)
    800051d6:	6161                	addi	sp,sp,80
    800051d8:	8082                	ret
    iunlockput(ip);
    800051da:	8526                	mv	a0,s1
    800051dc:	ffffe097          	auipc	ra,0xffffe
    800051e0:	7f8080e7          	jalr	2040(ra) # 800039d4 <iunlockput>
    return 0;
    800051e4:	4481                	li	s1,0
    800051e6:	b7c5                	j	800051c6 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800051e8:	85ce                	mv	a1,s3
    800051ea:	00092503          	lw	a0,0(s2)
    800051ee:	ffffe097          	auipc	ra,0xffffe
    800051f2:	32a080e7          	jalr	810(ra) # 80003518 <ialloc>
    800051f6:	84aa                	mv	s1,a0
    800051f8:	c521                	beqz	a0,80005240 <create+0xec>
  ilock(ip);
    800051fa:	ffffe097          	auipc	ra,0xffffe
    800051fe:	4b6080e7          	jalr	1206(ra) # 800036b0 <ilock>
  ip->major = major;
    80005202:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005206:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    8000520a:	4a05                	li	s4,1
    8000520c:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    80005210:	8526                	mv	a0,s1
    80005212:	ffffe097          	auipc	ra,0xffffe
    80005216:	3d4080e7          	jalr	980(ra) # 800035e6 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000521a:	2981                	sext.w	s3,s3
    8000521c:	03498a63          	beq	s3,s4,80005250 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    80005220:	40d0                	lw	a2,4(s1)
    80005222:	fb040593          	addi	a1,s0,-80
    80005226:	854a                	mv	a0,s2
    80005228:	fffff097          	auipc	ra,0xfffff
    8000522c:	cd2080e7          	jalr	-814(ra) # 80003efa <dirlink>
    80005230:	06054b63          	bltz	a0,800052a6 <create+0x152>
  iunlockput(dp);
    80005234:	854a                	mv	a0,s2
    80005236:	ffffe097          	auipc	ra,0xffffe
    8000523a:	79e080e7          	jalr	1950(ra) # 800039d4 <iunlockput>
  return ip;
    8000523e:	b761                	j	800051c6 <create+0x72>
    panic("create: ialloc");
    80005240:	00003517          	auipc	a0,0x3
    80005244:	49850513          	addi	a0,a0,1176 # 800086d8 <syscalls+0x2a8>
    80005248:	ffffb097          	auipc	ra,0xffffb
    8000524c:	2e2080e7          	jalr	738(ra) # 8000052a <panic>
    dp->nlink++;  // for ".."
    80005250:	04a95783          	lhu	a5,74(s2)
    80005254:	2785                	addiw	a5,a5,1
    80005256:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    8000525a:	854a                	mv	a0,s2
    8000525c:	ffffe097          	auipc	ra,0xffffe
    80005260:	38a080e7          	jalr	906(ra) # 800035e6 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005264:	40d0                	lw	a2,4(s1)
    80005266:	00003597          	auipc	a1,0x3
    8000526a:	48258593          	addi	a1,a1,1154 # 800086e8 <syscalls+0x2b8>
    8000526e:	8526                	mv	a0,s1
    80005270:	fffff097          	auipc	ra,0xfffff
    80005274:	c8a080e7          	jalr	-886(ra) # 80003efa <dirlink>
    80005278:	00054f63          	bltz	a0,80005296 <create+0x142>
    8000527c:	00492603          	lw	a2,4(s2)
    80005280:	00003597          	auipc	a1,0x3
    80005284:	47058593          	addi	a1,a1,1136 # 800086f0 <syscalls+0x2c0>
    80005288:	8526                	mv	a0,s1
    8000528a:	fffff097          	auipc	ra,0xfffff
    8000528e:	c70080e7          	jalr	-912(ra) # 80003efa <dirlink>
    80005292:	f80557e3          	bgez	a0,80005220 <create+0xcc>
      panic("create dots");
    80005296:	00003517          	auipc	a0,0x3
    8000529a:	46250513          	addi	a0,a0,1122 # 800086f8 <syscalls+0x2c8>
    8000529e:	ffffb097          	auipc	ra,0xffffb
    800052a2:	28c080e7          	jalr	652(ra) # 8000052a <panic>
    panic("create: dirlink");
    800052a6:	00003517          	auipc	a0,0x3
    800052aa:	46250513          	addi	a0,a0,1122 # 80008708 <syscalls+0x2d8>
    800052ae:	ffffb097          	auipc	ra,0xffffb
    800052b2:	27c080e7          	jalr	636(ra) # 8000052a <panic>
    return 0;
    800052b6:	84aa                	mv	s1,a0
    800052b8:	b739                	j	800051c6 <create+0x72>

00000000800052ba <sys_dup>:
{
    800052ba:	7179                	addi	sp,sp,-48
    800052bc:	f406                	sd	ra,40(sp)
    800052be:	f022                	sd	s0,32(sp)
    800052c0:	ec26                	sd	s1,24(sp)
    800052c2:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800052c4:	fd840613          	addi	a2,s0,-40
    800052c8:	4581                	li	a1,0
    800052ca:	4501                	li	a0,0
    800052cc:	00000097          	auipc	ra,0x0
    800052d0:	dde080e7          	jalr	-546(ra) # 800050aa <argfd>
    return -1;
    800052d4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800052d6:	02054363          	bltz	a0,800052fc <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800052da:	fd843503          	ld	a0,-40(s0)
    800052de:	00000097          	auipc	ra,0x0
    800052e2:	e34080e7          	jalr	-460(ra) # 80005112 <fdalloc>
    800052e6:	84aa                	mv	s1,a0
    return -1;
    800052e8:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800052ea:	00054963          	bltz	a0,800052fc <sys_dup+0x42>
  filedup(f);
    800052ee:	fd843503          	ld	a0,-40(s0)
    800052f2:	fffff097          	auipc	ra,0xfffff
    800052f6:	368080e7          	jalr	872(ra) # 8000465a <filedup>
  return fd;
    800052fa:	87a6                	mv	a5,s1
}
    800052fc:	853e                	mv	a0,a5
    800052fe:	70a2                	ld	ra,40(sp)
    80005300:	7402                	ld	s0,32(sp)
    80005302:	64e2                	ld	s1,24(sp)
    80005304:	6145                	addi	sp,sp,48
    80005306:	8082                	ret

0000000080005308 <sys_read>:
{
    80005308:	7179                	addi	sp,sp,-48
    8000530a:	f406                	sd	ra,40(sp)
    8000530c:	f022                	sd	s0,32(sp)
    8000530e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005310:	fe840613          	addi	a2,s0,-24
    80005314:	4581                	li	a1,0
    80005316:	4501                	li	a0,0
    80005318:	00000097          	auipc	ra,0x0
    8000531c:	d92080e7          	jalr	-622(ra) # 800050aa <argfd>
    return -1;
    80005320:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005322:	04054163          	bltz	a0,80005364 <sys_read+0x5c>
    80005326:	fe440593          	addi	a1,s0,-28
    8000532a:	4509                	li	a0,2
    8000532c:	ffffd097          	auipc	ra,0xffffd
    80005330:	748080e7          	jalr	1864(ra) # 80002a74 <argint>
    return -1;
    80005334:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005336:	02054763          	bltz	a0,80005364 <sys_read+0x5c>
    8000533a:	fd840593          	addi	a1,s0,-40
    8000533e:	4505                	li	a0,1
    80005340:	ffffd097          	auipc	ra,0xffffd
    80005344:	756080e7          	jalr	1878(ra) # 80002a96 <argaddr>
    return -1;
    80005348:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000534a:	00054d63          	bltz	a0,80005364 <sys_read+0x5c>
  return fileread(f, p, n);
    8000534e:	fe442603          	lw	a2,-28(s0)
    80005352:	fd843583          	ld	a1,-40(s0)
    80005356:	fe843503          	ld	a0,-24(s0)
    8000535a:	fffff097          	auipc	ra,0xfffff
    8000535e:	48c080e7          	jalr	1164(ra) # 800047e6 <fileread>
    80005362:	87aa                	mv	a5,a0
}
    80005364:	853e                	mv	a0,a5
    80005366:	70a2                	ld	ra,40(sp)
    80005368:	7402                	ld	s0,32(sp)
    8000536a:	6145                	addi	sp,sp,48
    8000536c:	8082                	ret

000000008000536e <sys_write>:
{
    8000536e:	7179                	addi	sp,sp,-48
    80005370:	f406                	sd	ra,40(sp)
    80005372:	f022                	sd	s0,32(sp)
    80005374:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005376:	fe840613          	addi	a2,s0,-24
    8000537a:	4581                	li	a1,0
    8000537c:	4501                	li	a0,0
    8000537e:	00000097          	auipc	ra,0x0
    80005382:	d2c080e7          	jalr	-724(ra) # 800050aa <argfd>
    return -1;
    80005386:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005388:	04054163          	bltz	a0,800053ca <sys_write+0x5c>
    8000538c:	fe440593          	addi	a1,s0,-28
    80005390:	4509                	li	a0,2
    80005392:	ffffd097          	auipc	ra,0xffffd
    80005396:	6e2080e7          	jalr	1762(ra) # 80002a74 <argint>
    return -1;
    8000539a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000539c:	02054763          	bltz	a0,800053ca <sys_write+0x5c>
    800053a0:	fd840593          	addi	a1,s0,-40
    800053a4:	4505                	li	a0,1
    800053a6:	ffffd097          	auipc	ra,0xffffd
    800053aa:	6f0080e7          	jalr	1776(ra) # 80002a96 <argaddr>
    return -1;
    800053ae:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053b0:	00054d63          	bltz	a0,800053ca <sys_write+0x5c>
  return filewrite(f, p, n);
    800053b4:	fe442603          	lw	a2,-28(s0)
    800053b8:	fd843583          	ld	a1,-40(s0)
    800053bc:	fe843503          	ld	a0,-24(s0)
    800053c0:	fffff097          	auipc	ra,0xfffff
    800053c4:	4e8080e7          	jalr	1256(ra) # 800048a8 <filewrite>
    800053c8:	87aa                	mv	a5,a0
}
    800053ca:	853e                	mv	a0,a5
    800053cc:	70a2                	ld	ra,40(sp)
    800053ce:	7402                	ld	s0,32(sp)
    800053d0:	6145                	addi	sp,sp,48
    800053d2:	8082                	ret

00000000800053d4 <sys_close>:
{
    800053d4:	1101                	addi	sp,sp,-32
    800053d6:	ec06                	sd	ra,24(sp)
    800053d8:	e822                	sd	s0,16(sp)
    800053da:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800053dc:	fe040613          	addi	a2,s0,-32
    800053e0:	fec40593          	addi	a1,s0,-20
    800053e4:	4501                	li	a0,0
    800053e6:	00000097          	auipc	ra,0x0
    800053ea:	cc4080e7          	jalr	-828(ra) # 800050aa <argfd>
    return -1;
    800053ee:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800053f0:	02054463          	bltz	a0,80005418 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800053f4:	ffffc097          	auipc	ra,0xffffc
    800053f8:	5cc080e7          	jalr	1484(ra) # 800019c0 <myproc>
    800053fc:	fec42783          	lw	a5,-20(s0)
    80005400:	07e9                	addi	a5,a5,26
    80005402:	078e                	slli	a5,a5,0x3
    80005404:	97aa                	add	a5,a5,a0
    80005406:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    8000540a:	fe043503          	ld	a0,-32(s0)
    8000540e:	fffff097          	auipc	ra,0xfffff
    80005412:	29e080e7          	jalr	670(ra) # 800046ac <fileclose>
  return 0;
    80005416:	4781                	li	a5,0
}
    80005418:	853e                	mv	a0,a5
    8000541a:	60e2                	ld	ra,24(sp)
    8000541c:	6442                	ld	s0,16(sp)
    8000541e:	6105                	addi	sp,sp,32
    80005420:	8082                	ret

0000000080005422 <sys_fstat>:
{
    80005422:	1101                	addi	sp,sp,-32
    80005424:	ec06                	sd	ra,24(sp)
    80005426:	e822                	sd	s0,16(sp)
    80005428:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000542a:	fe840613          	addi	a2,s0,-24
    8000542e:	4581                	li	a1,0
    80005430:	4501                	li	a0,0
    80005432:	00000097          	auipc	ra,0x0
    80005436:	c78080e7          	jalr	-904(ra) # 800050aa <argfd>
    return -1;
    8000543a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000543c:	02054563          	bltz	a0,80005466 <sys_fstat+0x44>
    80005440:	fe040593          	addi	a1,s0,-32
    80005444:	4505                	li	a0,1
    80005446:	ffffd097          	auipc	ra,0xffffd
    8000544a:	650080e7          	jalr	1616(ra) # 80002a96 <argaddr>
    return -1;
    8000544e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005450:	00054b63          	bltz	a0,80005466 <sys_fstat+0x44>
  return filestat(f, st);
    80005454:	fe043583          	ld	a1,-32(s0)
    80005458:	fe843503          	ld	a0,-24(s0)
    8000545c:	fffff097          	auipc	ra,0xfffff
    80005460:	318080e7          	jalr	792(ra) # 80004774 <filestat>
    80005464:	87aa                	mv	a5,a0
}
    80005466:	853e                	mv	a0,a5
    80005468:	60e2                	ld	ra,24(sp)
    8000546a:	6442                	ld	s0,16(sp)
    8000546c:	6105                	addi	sp,sp,32
    8000546e:	8082                	ret

0000000080005470 <sys_link>:
{
    80005470:	7169                	addi	sp,sp,-304
    80005472:	f606                	sd	ra,296(sp)
    80005474:	f222                	sd	s0,288(sp)
    80005476:	ee26                	sd	s1,280(sp)
    80005478:	ea4a                	sd	s2,272(sp)
    8000547a:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000547c:	08000613          	li	a2,128
    80005480:	ed040593          	addi	a1,s0,-304
    80005484:	4501                	li	a0,0
    80005486:	ffffd097          	auipc	ra,0xffffd
    8000548a:	632080e7          	jalr	1586(ra) # 80002ab8 <argstr>
    return -1;
    8000548e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005490:	12054063          	bltz	a0,800055b0 <sys_link+0x140>
    80005494:	08000613          	li	a2,128
    80005498:	f5040593          	addi	a1,s0,-176
    8000549c:	4505                	li	a0,1
    8000549e:	ffffd097          	auipc	ra,0xffffd
    800054a2:	61a080e7          	jalr	1562(ra) # 80002ab8 <argstr>
    return -1;
    800054a6:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800054a8:	10054463          	bltz	a0,800055b0 <sys_link+0x140>
  begin_op();
    800054ac:	fffff097          	auipc	ra,0xfffff
    800054b0:	d34080e7          	jalr	-716(ra) # 800041e0 <begin_op>
  if((ip = namei(old, 1, 0)) == 0){
    800054b4:	4601                	li	a2,0
    800054b6:	4585                	li	a1,1
    800054b8:	ed040513          	addi	a0,s0,-304
    800054bc:	fffff097          	auipc	ra,0xfffff
    800054c0:	b00080e7          	jalr	-1280(ra) # 80003fbc <namei>
    800054c4:	84aa                	mv	s1,a0
    800054c6:	c551                	beqz	a0,80005552 <sys_link+0xe2>
  ilock(ip);
    800054c8:	ffffe097          	auipc	ra,0xffffe
    800054cc:	1e8080e7          	jalr	488(ra) # 800036b0 <ilock>
  if(ip->type == T_DIR){
    800054d0:	04449703          	lh	a4,68(s1)
    800054d4:	4785                	li	a5,1
    800054d6:	08f70463          	beq	a4,a5,8000555e <sys_link+0xee>
  ip->nlink++;
    800054da:	04a4d783          	lhu	a5,74(s1)
    800054de:	2785                	addiw	a5,a5,1
    800054e0:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800054e4:	8526                	mv	a0,s1
    800054e6:	ffffe097          	auipc	ra,0xffffe
    800054ea:	100080e7          	jalr	256(ra) # 800035e6 <iupdate>
  iunlock(ip);
    800054ee:	8526                	mv	a0,s1
    800054f0:	ffffe097          	auipc	ra,0xffffe
    800054f4:	282080e7          	jalr	642(ra) # 80003772 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800054f8:	fd040593          	addi	a1,s0,-48
    800054fc:	f5040513          	addi	a0,s0,-176
    80005500:	fffff097          	auipc	ra,0xfffff
    80005504:	ade080e7          	jalr	-1314(ra) # 80003fde <nameiparent>
    80005508:	892a                	mv	s2,a0
    8000550a:	c935                	beqz	a0,8000557e <sys_link+0x10e>
  ilock(dp);
    8000550c:	ffffe097          	auipc	ra,0xffffe
    80005510:	1a4080e7          	jalr	420(ra) # 800036b0 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005514:	00092703          	lw	a4,0(s2)
    80005518:	409c                	lw	a5,0(s1)
    8000551a:	04f71d63          	bne	a4,a5,80005574 <sys_link+0x104>
    8000551e:	40d0                	lw	a2,4(s1)
    80005520:	fd040593          	addi	a1,s0,-48
    80005524:	854a                	mv	a0,s2
    80005526:	fffff097          	auipc	ra,0xfffff
    8000552a:	9d4080e7          	jalr	-1580(ra) # 80003efa <dirlink>
    8000552e:	04054363          	bltz	a0,80005574 <sys_link+0x104>
  iunlockput(dp);
    80005532:	854a                	mv	a0,s2
    80005534:	ffffe097          	auipc	ra,0xffffe
    80005538:	4a0080e7          	jalr	1184(ra) # 800039d4 <iunlockput>
  iput(ip);
    8000553c:	8526                	mv	a0,s1
    8000553e:	ffffe097          	auipc	ra,0xffffe
    80005542:	3ee080e7          	jalr	1006(ra) # 8000392c <iput>
  end_op();
    80005546:	fffff097          	auipc	ra,0xfffff
    8000554a:	d1a080e7          	jalr	-742(ra) # 80004260 <end_op>
  return 0;
    8000554e:	4781                	li	a5,0
    80005550:	a085                	j	800055b0 <sys_link+0x140>
    end_op();
    80005552:	fffff097          	auipc	ra,0xfffff
    80005556:	d0e080e7          	jalr	-754(ra) # 80004260 <end_op>
    return -1;
    8000555a:	57fd                	li	a5,-1
    8000555c:	a891                	j	800055b0 <sys_link+0x140>
    iunlockput(ip);
    8000555e:	8526                	mv	a0,s1
    80005560:	ffffe097          	auipc	ra,0xffffe
    80005564:	474080e7          	jalr	1140(ra) # 800039d4 <iunlockput>
    end_op();
    80005568:	fffff097          	auipc	ra,0xfffff
    8000556c:	cf8080e7          	jalr	-776(ra) # 80004260 <end_op>
    return -1;
    80005570:	57fd                	li	a5,-1
    80005572:	a83d                	j	800055b0 <sys_link+0x140>
    iunlockput(dp);
    80005574:	854a                	mv	a0,s2
    80005576:	ffffe097          	auipc	ra,0xffffe
    8000557a:	45e080e7          	jalr	1118(ra) # 800039d4 <iunlockput>
  ilock(ip);
    8000557e:	8526                	mv	a0,s1
    80005580:	ffffe097          	auipc	ra,0xffffe
    80005584:	130080e7          	jalr	304(ra) # 800036b0 <ilock>
  ip->nlink--;
    80005588:	04a4d783          	lhu	a5,74(s1)
    8000558c:	37fd                	addiw	a5,a5,-1
    8000558e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005592:	8526                	mv	a0,s1
    80005594:	ffffe097          	auipc	ra,0xffffe
    80005598:	052080e7          	jalr	82(ra) # 800035e6 <iupdate>
  iunlockput(ip);
    8000559c:	8526                	mv	a0,s1
    8000559e:	ffffe097          	auipc	ra,0xffffe
    800055a2:	436080e7          	jalr	1078(ra) # 800039d4 <iunlockput>
  end_op();
    800055a6:	fffff097          	auipc	ra,0xfffff
    800055aa:	cba080e7          	jalr	-838(ra) # 80004260 <end_op>
  return -1;
    800055ae:	57fd                	li	a5,-1
}
    800055b0:	853e                	mv	a0,a5
    800055b2:	70b2                	ld	ra,296(sp)
    800055b4:	7412                	ld	s0,288(sp)
    800055b6:	64f2                	ld	s1,280(sp)
    800055b8:	6952                	ld	s2,272(sp)
    800055ba:	6155                	addi	sp,sp,304
    800055bc:	8082                	ret

00000000800055be <sys_unlink>:
{
    800055be:	7151                	addi	sp,sp,-240
    800055c0:	f586                	sd	ra,232(sp)
    800055c2:	f1a2                	sd	s0,224(sp)
    800055c4:	eda6                	sd	s1,216(sp)
    800055c6:	e9ca                	sd	s2,208(sp)
    800055c8:	e5ce                	sd	s3,200(sp)
    800055ca:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800055cc:	08000613          	li	a2,128
    800055d0:	f3040593          	addi	a1,s0,-208
    800055d4:	4501                	li	a0,0
    800055d6:	ffffd097          	auipc	ra,0xffffd
    800055da:	4e2080e7          	jalr	1250(ra) # 80002ab8 <argstr>
    800055de:	18054163          	bltz	a0,80005760 <sys_unlink+0x1a2>
  begin_op();
    800055e2:	fffff097          	auipc	ra,0xfffff
    800055e6:	bfe080e7          	jalr	-1026(ra) # 800041e0 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800055ea:	fb040593          	addi	a1,s0,-80
    800055ee:	f3040513          	addi	a0,s0,-208
    800055f2:	fffff097          	auipc	ra,0xfffff
    800055f6:	9ec080e7          	jalr	-1556(ra) # 80003fde <nameiparent>
    800055fa:	84aa                	mv	s1,a0
    800055fc:	c979                	beqz	a0,800056d2 <sys_unlink+0x114>
  ilock(dp);
    800055fe:	ffffe097          	auipc	ra,0xffffe
    80005602:	0b2080e7          	jalr	178(ra) # 800036b0 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005606:	00003597          	auipc	a1,0x3
    8000560a:	0e258593          	addi	a1,a1,226 # 800086e8 <syscalls+0x2b8>
    8000560e:	fb040513          	addi	a0,s0,-80
    80005612:	ffffe097          	auipc	ra,0xffffe
    80005616:	62c080e7          	jalr	1580(ra) # 80003c3e <namecmp>
    8000561a:	14050a63          	beqz	a0,8000576e <sys_unlink+0x1b0>
    8000561e:	00003597          	auipc	a1,0x3
    80005622:	0d258593          	addi	a1,a1,210 # 800086f0 <syscalls+0x2c0>
    80005626:	fb040513          	addi	a0,s0,-80
    8000562a:	ffffe097          	auipc	ra,0xffffe
    8000562e:	614080e7          	jalr	1556(ra) # 80003c3e <namecmp>
    80005632:	12050e63          	beqz	a0,8000576e <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005636:	f2c40613          	addi	a2,s0,-212
    8000563a:	fb040593          	addi	a1,s0,-80
    8000563e:	8526                	mv	a0,s1
    80005640:	ffffe097          	auipc	ra,0xffffe
    80005644:	618080e7          	jalr	1560(ra) # 80003c58 <dirlookup>
    80005648:	892a                	mv	s2,a0
    8000564a:	12050263          	beqz	a0,8000576e <sys_unlink+0x1b0>
  ilock(ip);
    8000564e:	ffffe097          	auipc	ra,0xffffe
    80005652:	062080e7          	jalr	98(ra) # 800036b0 <ilock>
  if(ip->nlink < 1)
    80005656:	04a91783          	lh	a5,74(s2)
    8000565a:	08f05263          	blez	a5,800056de <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000565e:	04491703          	lh	a4,68(s2)
    80005662:	4785                	li	a5,1
    80005664:	08f70563          	beq	a4,a5,800056ee <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005668:	4641                	li	a2,16
    8000566a:	4581                	li	a1,0
    8000566c:	fc040513          	addi	a0,s0,-64
    80005670:	ffffb097          	auipc	ra,0xffffb
    80005674:	64e080e7          	jalr	1614(ra) # 80000cbe <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005678:	4741                	li	a4,16
    8000567a:	f2c42683          	lw	a3,-212(s0)
    8000567e:	fc040613          	addi	a2,s0,-64
    80005682:	4581                	li	a1,0
    80005684:	8526                	mv	a0,s1
    80005686:	ffffe097          	auipc	ra,0xffffe
    8000568a:	498080e7          	jalr	1176(ra) # 80003b1e <writei>
    8000568e:	47c1                	li	a5,16
    80005690:	0af51563          	bne	a0,a5,8000573a <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005694:	04491703          	lh	a4,68(s2)
    80005698:	4785                	li	a5,1
    8000569a:	0af70863          	beq	a4,a5,8000574a <sys_unlink+0x18c>
  iunlockput(dp);
    8000569e:	8526                	mv	a0,s1
    800056a0:	ffffe097          	auipc	ra,0xffffe
    800056a4:	334080e7          	jalr	820(ra) # 800039d4 <iunlockput>
  ip->nlink--;
    800056a8:	04a95783          	lhu	a5,74(s2)
    800056ac:	37fd                	addiw	a5,a5,-1
    800056ae:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800056b2:	854a                	mv	a0,s2
    800056b4:	ffffe097          	auipc	ra,0xffffe
    800056b8:	f32080e7          	jalr	-206(ra) # 800035e6 <iupdate>
  iunlockput(ip);
    800056bc:	854a                	mv	a0,s2
    800056be:	ffffe097          	auipc	ra,0xffffe
    800056c2:	316080e7          	jalr	790(ra) # 800039d4 <iunlockput>
  end_op();
    800056c6:	fffff097          	auipc	ra,0xfffff
    800056ca:	b9a080e7          	jalr	-1126(ra) # 80004260 <end_op>
  return 0;
    800056ce:	4501                	li	a0,0
    800056d0:	a84d                	j	80005782 <sys_unlink+0x1c4>
    end_op();
    800056d2:	fffff097          	auipc	ra,0xfffff
    800056d6:	b8e080e7          	jalr	-1138(ra) # 80004260 <end_op>
    return -1;
    800056da:	557d                	li	a0,-1
    800056dc:	a05d                	j	80005782 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800056de:	00003517          	auipc	a0,0x3
    800056e2:	03a50513          	addi	a0,a0,58 # 80008718 <syscalls+0x2e8>
    800056e6:	ffffb097          	auipc	ra,0xffffb
    800056ea:	e44080e7          	jalr	-444(ra) # 8000052a <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800056ee:	04c92703          	lw	a4,76(s2)
    800056f2:	02000793          	li	a5,32
    800056f6:	f6e7f9e3          	bgeu	a5,a4,80005668 <sys_unlink+0xaa>
    800056fa:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800056fe:	4741                	li	a4,16
    80005700:	86ce                	mv	a3,s3
    80005702:	f1840613          	addi	a2,s0,-232
    80005706:	4581                	li	a1,0
    80005708:	854a                	mv	a0,s2
    8000570a:	ffffe097          	auipc	ra,0xffffe
    8000570e:	31c080e7          	jalr	796(ra) # 80003a26 <readi>
    80005712:	47c1                	li	a5,16
    80005714:	00f51b63          	bne	a0,a5,8000572a <sys_unlink+0x16c>
    if(de.inum != 0)
    80005718:	f1845783          	lhu	a5,-232(s0)
    8000571c:	e7a1                	bnez	a5,80005764 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000571e:	29c1                	addiw	s3,s3,16
    80005720:	04c92783          	lw	a5,76(s2)
    80005724:	fcf9ede3          	bltu	s3,a5,800056fe <sys_unlink+0x140>
    80005728:	b781                	j	80005668 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    8000572a:	00003517          	auipc	a0,0x3
    8000572e:	00650513          	addi	a0,a0,6 # 80008730 <syscalls+0x300>
    80005732:	ffffb097          	auipc	ra,0xffffb
    80005736:	df8080e7          	jalr	-520(ra) # 8000052a <panic>
    panic("unlink: writei");
    8000573a:	00003517          	auipc	a0,0x3
    8000573e:	00e50513          	addi	a0,a0,14 # 80008748 <syscalls+0x318>
    80005742:	ffffb097          	auipc	ra,0xffffb
    80005746:	de8080e7          	jalr	-536(ra) # 8000052a <panic>
    dp->nlink--;
    8000574a:	04a4d783          	lhu	a5,74(s1)
    8000574e:	37fd                	addiw	a5,a5,-1
    80005750:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005754:	8526                	mv	a0,s1
    80005756:	ffffe097          	auipc	ra,0xffffe
    8000575a:	e90080e7          	jalr	-368(ra) # 800035e6 <iupdate>
    8000575e:	b781                	j	8000569e <sys_unlink+0xe0>
    return -1;
    80005760:	557d                	li	a0,-1
    80005762:	a005                	j	80005782 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005764:	854a                	mv	a0,s2
    80005766:	ffffe097          	auipc	ra,0xffffe
    8000576a:	26e080e7          	jalr	622(ra) # 800039d4 <iunlockput>
  iunlockput(dp);
    8000576e:	8526                	mv	a0,s1
    80005770:	ffffe097          	auipc	ra,0xffffe
    80005774:	264080e7          	jalr	612(ra) # 800039d4 <iunlockput>
  end_op();
    80005778:	fffff097          	auipc	ra,0xfffff
    8000577c:	ae8080e7          	jalr	-1304(ra) # 80004260 <end_op>
  return -1;
    80005780:	557d                	li	a0,-1
}
    80005782:	70ae                	ld	ra,232(sp)
    80005784:	740e                	ld	s0,224(sp)
    80005786:	64ee                	ld	s1,216(sp)
    80005788:	694e                	ld	s2,208(sp)
    8000578a:	69ae                	ld	s3,200(sp)
    8000578c:	616d                	addi	sp,sp,240
    8000578e:	8082                	ret

0000000080005790 <sys_open>:

uint64
sys_open(void)
{
    80005790:	7131                	addi	sp,sp,-192
    80005792:	fd06                	sd	ra,184(sp)
    80005794:	f922                	sd	s0,176(sp)
    80005796:	f526                	sd	s1,168(sp)
    80005798:	f14a                	sd	s2,160(sp)
    8000579a:	ed4e                	sd	s3,152(sp)
    8000579c:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000579e:	08000613          	li	a2,128
    800057a2:	f5040593          	addi	a1,s0,-176
    800057a6:	4501                	li	a0,0
    800057a8:	ffffd097          	auipc	ra,0xffffd
    800057ac:	310080e7          	jalr	784(ra) # 80002ab8 <argstr>
    return -1;
    800057b0:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800057b2:	0c054163          	bltz	a0,80005874 <sys_open+0xe4>
    800057b6:	f4c40593          	addi	a1,s0,-180
    800057ba:	4505                	li	a0,1
    800057bc:	ffffd097          	auipc	ra,0xffffd
    800057c0:	2b8080e7          	jalr	696(ra) # 80002a74 <argint>
    800057c4:	0a054863          	bltz	a0,80005874 <sys_open+0xe4>

  begin_op();
    800057c8:	fffff097          	auipc	ra,0xfffff
    800057cc:	a18080e7          	jalr	-1512(ra) # 800041e0 <begin_op>

  if(omode & O_CREATE){
    800057d0:	f4c42583          	lw	a1,-180(s0)
    800057d4:	2005f793          	andi	a5,a1,512
    800057d8:	cbdd                	beqz	a5,8000588e <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800057da:	4681                	li	a3,0
    800057dc:	4601                	li	a2,0
    800057de:	4589                	li	a1,2
    800057e0:	f5040513          	addi	a0,s0,-176
    800057e4:	00000097          	auipc	ra,0x0
    800057e8:	970080e7          	jalr	-1680(ra) # 80005154 <create>
    800057ec:	892a                	mv	s2,a0
    if(ip == 0){
    800057ee:	c959                	beqz	a0,80005884 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800057f0:	04491703          	lh	a4,68(s2)
    800057f4:	478d                	li	a5,3
    800057f6:	00f71763          	bne	a4,a5,80005804 <sys_open+0x74>
    800057fa:	04695703          	lhu	a4,70(s2)
    800057fe:	47a5                	li	a5,9
    80005800:	0ee7e263          	bltu	a5,a4,800058e4 <sys_open+0x154>
  /*        end_op();*/
  /*        return -1;*/
  /*    }*/
  /*}*/

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005804:	fffff097          	auipc	ra,0xfffff
    80005808:	dec080e7          	jalr	-532(ra) # 800045f0 <filealloc>
    8000580c:	89aa                	mv	s3,a0
    8000580e:	10050863          	beqz	a0,8000591e <sys_open+0x18e>
    80005812:	00000097          	auipc	ra,0x0
    80005816:	900080e7          	jalr	-1792(ra) # 80005112 <fdalloc>
    8000581a:	84aa                	mv	s1,a0
    8000581c:	0e054c63          	bltz	a0,80005914 <sys_open+0x184>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005820:	04491703          	lh	a4,68(s2)
    80005824:	478d                	li	a5,3
    80005826:	0cf70a63          	beq	a4,a5,800058fa <sys_open+0x16a>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    8000582a:	4789                	li	a5,2
    8000582c:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005830:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005834:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005838:	f4c42783          	lw	a5,-180(s0)
    8000583c:	0017c713          	xori	a4,a5,1
    80005840:	8b05                	andi	a4,a4,1
    80005842:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005846:	0037f713          	andi	a4,a5,3
    8000584a:	00e03733          	snez	a4,a4
    8000584e:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005852:	4007f793          	andi	a5,a5,1024
    80005856:	c791                	beqz	a5,80005862 <sys_open+0xd2>
    80005858:	04491703          	lh	a4,68(s2)
    8000585c:	4789                	li	a5,2
    8000585e:	0af70563          	beq	a4,a5,80005908 <sys_open+0x178>
    itrunc(ip);
  }

  iunlock(ip);
    80005862:	854a                	mv	a0,s2
    80005864:	ffffe097          	auipc	ra,0xffffe
    80005868:	f0e080e7          	jalr	-242(ra) # 80003772 <iunlock>
  end_op();
    8000586c:	fffff097          	auipc	ra,0xfffff
    80005870:	9f4080e7          	jalr	-1548(ra) # 80004260 <end_op>

  return fd;
}
    80005874:	8526                	mv	a0,s1
    80005876:	70ea                	ld	ra,184(sp)
    80005878:	744a                	ld	s0,176(sp)
    8000587a:	74aa                	ld	s1,168(sp)
    8000587c:	790a                	ld	s2,160(sp)
    8000587e:	69ea                	ld	s3,152(sp)
    80005880:	6129                	addi	sp,sp,192
    80005882:	8082                	ret
      end_op();
    80005884:	fffff097          	auipc	ra,0xfffff
    80005888:	9dc080e7          	jalr	-1572(ra) # 80004260 <end_op>
      return -1;
    8000588c:	b7e5                	j	80005874 <sys_open+0xe4>
    if((ip = namei(path, !(omode & O_NOFOLLOW), 0)) == 0){
    8000588e:	4025d59b          	sraiw	a1,a1,0x2
    80005892:	0015c593          	xori	a1,a1,1
    80005896:	4601                	li	a2,0
    80005898:	8985                	andi	a1,a1,1
    8000589a:	f5040513          	addi	a0,s0,-176
    8000589e:	ffffe097          	auipc	ra,0xffffe
    800058a2:	71e080e7          	jalr	1822(ra) # 80003fbc <namei>
    800058a6:	892a                	mv	s2,a0
    800058a8:	c905                	beqz	a0,800058d8 <sys_open+0x148>
    ilock(ip);
    800058aa:	ffffe097          	auipc	ra,0xffffe
    800058ae:	e06080e7          	jalr	-506(ra) # 800036b0 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800058b2:	04491703          	lh	a4,68(s2)
    800058b6:	4785                	li	a5,1
    800058b8:	f2f71ce3          	bne	a4,a5,800057f0 <sys_open+0x60>
    800058bc:	f4c42783          	lw	a5,-180(s0)
    800058c0:	d3b1                	beqz	a5,80005804 <sys_open+0x74>
      iunlockput(ip);
    800058c2:	854a                	mv	a0,s2
    800058c4:	ffffe097          	auipc	ra,0xffffe
    800058c8:	110080e7          	jalr	272(ra) # 800039d4 <iunlockput>
      end_op();
    800058cc:	fffff097          	auipc	ra,0xfffff
    800058d0:	994080e7          	jalr	-1644(ra) # 80004260 <end_op>
      return -1;
    800058d4:	54fd                	li	s1,-1
    800058d6:	bf79                	j	80005874 <sys_open+0xe4>
      end_op();
    800058d8:	fffff097          	auipc	ra,0xfffff
    800058dc:	988080e7          	jalr	-1656(ra) # 80004260 <end_op>
      return -1;
    800058e0:	54fd                	li	s1,-1
    800058e2:	bf49                	j	80005874 <sys_open+0xe4>
    iunlockput(ip);
    800058e4:	854a                	mv	a0,s2
    800058e6:	ffffe097          	auipc	ra,0xffffe
    800058ea:	0ee080e7          	jalr	238(ra) # 800039d4 <iunlockput>
    end_op();
    800058ee:	fffff097          	auipc	ra,0xfffff
    800058f2:	972080e7          	jalr	-1678(ra) # 80004260 <end_op>
    return -1;
    800058f6:	54fd                	li	s1,-1
    800058f8:	bfb5                	j	80005874 <sys_open+0xe4>
    f->type = FD_DEVICE;
    800058fa:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800058fe:	04691783          	lh	a5,70(s2)
    80005902:	02f99223          	sh	a5,36(s3)
    80005906:	b73d                	j	80005834 <sys_open+0xa4>
    itrunc(ip);
    80005908:	854a                	mv	a0,s2
    8000590a:	ffffe097          	auipc	ra,0xffffe
    8000590e:	eb4080e7          	jalr	-332(ra) # 800037be <itrunc>
    80005912:	bf81                	j	80005862 <sys_open+0xd2>
      fileclose(f);
    80005914:	854e                	mv	a0,s3
    80005916:	fffff097          	auipc	ra,0xfffff
    8000591a:	d96080e7          	jalr	-618(ra) # 800046ac <fileclose>
    iunlockput(ip);
    8000591e:	854a                	mv	a0,s2
    80005920:	ffffe097          	auipc	ra,0xffffe
    80005924:	0b4080e7          	jalr	180(ra) # 800039d4 <iunlockput>
    end_op();
    80005928:	fffff097          	auipc	ra,0xfffff
    8000592c:	938080e7          	jalr	-1736(ra) # 80004260 <end_op>
    return -1;
    80005930:	54fd                	li	s1,-1
    80005932:	b789                	j	80005874 <sys_open+0xe4>

0000000080005934 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005934:	7175                	addi	sp,sp,-144
    80005936:	e506                	sd	ra,136(sp)
    80005938:	e122                	sd	s0,128(sp)
    8000593a:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    8000593c:	fffff097          	auipc	ra,0xfffff
    80005940:	8a4080e7          	jalr	-1884(ra) # 800041e0 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005944:	08000613          	li	a2,128
    80005948:	f7040593          	addi	a1,s0,-144
    8000594c:	4501                	li	a0,0
    8000594e:	ffffd097          	auipc	ra,0xffffd
    80005952:	16a080e7          	jalr	362(ra) # 80002ab8 <argstr>
    80005956:	02054963          	bltz	a0,80005988 <sys_mkdir+0x54>
    8000595a:	4681                	li	a3,0
    8000595c:	4601                	li	a2,0
    8000595e:	4585                	li	a1,1
    80005960:	f7040513          	addi	a0,s0,-144
    80005964:	fffff097          	auipc	ra,0xfffff
    80005968:	7f0080e7          	jalr	2032(ra) # 80005154 <create>
    8000596c:	cd11                	beqz	a0,80005988 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000596e:	ffffe097          	auipc	ra,0xffffe
    80005972:	066080e7          	jalr	102(ra) # 800039d4 <iunlockput>
  end_op();
    80005976:	fffff097          	auipc	ra,0xfffff
    8000597a:	8ea080e7          	jalr	-1814(ra) # 80004260 <end_op>
  return 0;
    8000597e:	4501                	li	a0,0
}
    80005980:	60aa                	ld	ra,136(sp)
    80005982:	640a                	ld	s0,128(sp)
    80005984:	6149                	addi	sp,sp,144
    80005986:	8082                	ret
    end_op();
    80005988:	fffff097          	auipc	ra,0xfffff
    8000598c:	8d8080e7          	jalr	-1832(ra) # 80004260 <end_op>
    return -1;
    80005990:	557d                	li	a0,-1
    80005992:	b7fd                	j	80005980 <sys_mkdir+0x4c>

0000000080005994 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005994:	7135                	addi	sp,sp,-160
    80005996:	ed06                	sd	ra,152(sp)
    80005998:	e922                	sd	s0,144(sp)
    8000599a:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    8000599c:	fffff097          	auipc	ra,0xfffff
    800059a0:	844080e7          	jalr	-1980(ra) # 800041e0 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800059a4:	08000613          	li	a2,128
    800059a8:	f7040593          	addi	a1,s0,-144
    800059ac:	4501                	li	a0,0
    800059ae:	ffffd097          	auipc	ra,0xffffd
    800059b2:	10a080e7          	jalr	266(ra) # 80002ab8 <argstr>
    800059b6:	04054a63          	bltz	a0,80005a0a <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    800059ba:	f6c40593          	addi	a1,s0,-148
    800059be:	4505                	li	a0,1
    800059c0:	ffffd097          	auipc	ra,0xffffd
    800059c4:	0b4080e7          	jalr	180(ra) # 80002a74 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800059c8:	04054163          	bltz	a0,80005a0a <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    800059cc:	f6840593          	addi	a1,s0,-152
    800059d0:	4509                	li	a0,2
    800059d2:	ffffd097          	auipc	ra,0xffffd
    800059d6:	0a2080e7          	jalr	162(ra) # 80002a74 <argint>
     argint(1, &major) < 0 ||
    800059da:	02054863          	bltz	a0,80005a0a <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800059de:	f6841683          	lh	a3,-152(s0)
    800059e2:	f6c41603          	lh	a2,-148(s0)
    800059e6:	458d                	li	a1,3
    800059e8:	f7040513          	addi	a0,s0,-144
    800059ec:	fffff097          	auipc	ra,0xfffff
    800059f0:	768080e7          	jalr	1896(ra) # 80005154 <create>
     argint(2, &minor) < 0 ||
    800059f4:	c919                	beqz	a0,80005a0a <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800059f6:	ffffe097          	auipc	ra,0xffffe
    800059fa:	fde080e7          	jalr	-34(ra) # 800039d4 <iunlockput>
  end_op();
    800059fe:	fffff097          	auipc	ra,0xfffff
    80005a02:	862080e7          	jalr	-1950(ra) # 80004260 <end_op>
  return 0;
    80005a06:	4501                	li	a0,0
    80005a08:	a031                	j	80005a14 <sys_mknod+0x80>
    end_op();
    80005a0a:	fffff097          	auipc	ra,0xfffff
    80005a0e:	856080e7          	jalr	-1962(ra) # 80004260 <end_op>
    return -1;
    80005a12:	557d                	li	a0,-1
}
    80005a14:	60ea                	ld	ra,152(sp)
    80005a16:	644a                	ld	s0,144(sp)
    80005a18:	610d                	addi	sp,sp,160
    80005a1a:	8082                	ret

0000000080005a1c <sys_chdir>:

uint64
sys_chdir(void)
{
    80005a1c:	7135                	addi	sp,sp,-160
    80005a1e:	ed06                	sd	ra,152(sp)
    80005a20:	e922                	sd	s0,144(sp)
    80005a22:	e526                	sd	s1,136(sp)
    80005a24:	e14a                	sd	s2,128(sp)
    80005a26:	1100                	addi	s0,sp,160
  // You can modify this to cd into a symbolic link
  // The modification may not be necessary,
  // depending on you implementation.
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005a28:	ffffc097          	auipc	ra,0xffffc
    80005a2c:	f98080e7          	jalr	-104(ra) # 800019c0 <myproc>
    80005a30:	892a                	mv	s2,a0
  
  begin_op();
    80005a32:	ffffe097          	auipc	ra,0xffffe
    80005a36:	7ae080e7          	jalr	1966(ra) # 800041e0 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path, 1, 0)) == 0){
    80005a3a:	08000613          	li	a2,128
    80005a3e:	f6040593          	addi	a1,s0,-160
    80005a42:	4501                	li	a0,0
    80005a44:	ffffd097          	auipc	ra,0xffffd
    80005a48:	074080e7          	jalr	116(ra) # 80002ab8 <argstr>
    80005a4c:	04054d63          	bltz	a0,80005aa6 <sys_chdir+0x8a>
    80005a50:	4601                	li	a2,0
    80005a52:	4585                	li	a1,1
    80005a54:	f6040513          	addi	a0,s0,-160
    80005a58:	ffffe097          	auipc	ra,0xffffe
    80005a5c:	564080e7          	jalr	1380(ra) # 80003fbc <namei>
    80005a60:	84aa                	mv	s1,a0
    80005a62:	c131                	beqz	a0,80005aa6 <sys_chdir+0x8a>
    end_op();
    return -1;
  }
  ilock(ip);
    80005a64:	ffffe097          	auipc	ra,0xffffe
    80005a68:	c4c080e7          	jalr	-948(ra) # 800036b0 <ilock>
  if(ip->type != T_DIR){
    80005a6c:	04449703          	lh	a4,68(s1)
    80005a70:	4785                	li	a5,1
    80005a72:	04f71063          	bne	a4,a5,80005ab2 <sys_chdir+0x96>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005a76:	8526                	mv	a0,s1
    80005a78:	ffffe097          	auipc	ra,0xffffe
    80005a7c:	cfa080e7          	jalr	-774(ra) # 80003772 <iunlock>
  iput(p->cwd);
    80005a80:	15093503          	ld	a0,336(s2)
    80005a84:	ffffe097          	auipc	ra,0xffffe
    80005a88:	ea8080e7          	jalr	-344(ra) # 8000392c <iput>
  end_op();
    80005a8c:	ffffe097          	auipc	ra,0xffffe
    80005a90:	7d4080e7          	jalr	2004(ra) # 80004260 <end_op>
  p->cwd = ip;
    80005a94:	14993823          	sd	s1,336(s2)
  return 0;
    80005a98:	4501                	li	a0,0
}
    80005a9a:	60ea                	ld	ra,152(sp)
    80005a9c:	644a                	ld	s0,144(sp)
    80005a9e:	64aa                	ld	s1,136(sp)
    80005aa0:	690a                	ld	s2,128(sp)
    80005aa2:	610d                	addi	sp,sp,160
    80005aa4:	8082                	ret
    end_op();
    80005aa6:	ffffe097          	auipc	ra,0xffffe
    80005aaa:	7ba080e7          	jalr	1978(ra) # 80004260 <end_op>
    return -1;
    80005aae:	557d                	li	a0,-1
    80005ab0:	b7ed                	j	80005a9a <sys_chdir+0x7e>
    iunlockput(ip);
    80005ab2:	8526                	mv	a0,s1
    80005ab4:	ffffe097          	auipc	ra,0xffffe
    80005ab8:	f20080e7          	jalr	-224(ra) # 800039d4 <iunlockput>
    end_op();
    80005abc:	ffffe097          	auipc	ra,0xffffe
    80005ac0:	7a4080e7          	jalr	1956(ra) # 80004260 <end_op>
    return -1;
    80005ac4:	557d                	li	a0,-1
    80005ac6:	bfd1                	j	80005a9a <sys_chdir+0x7e>

0000000080005ac8 <sys_exec>:

uint64
sys_exec(void)
{
    80005ac8:	7145                	addi	sp,sp,-464
    80005aca:	e786                	sd	ra,456(sp)
    80005acc:	e3a2                	sd	s0,448(sp)
    80005ace:	ff26                	sd	s1,440(sp)
    80005ad0:	fb4a                	sd	s2,432(sp)
    80005ad2:	f74e                	sd	s3,424(sp)
    80005ad4:	f352                	sd	s4,416(sp)
    80005ad6:	ef56                	sd	s5,408(sp)
    80005ad8:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005ada:	08000613          	li	a2,128
    80005ade:	f4040593          	addi	a1,s0,-192
    80005ae2:	4501                	li	a0,0
    80005ae4:	ffffd097          	auipc	ra,0xffffd
    80005ae8:	fd4080e7          	jalr	-44(ra) # 80002ab8 <argstr>
    return -1;
    80005aec:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005aee:	0c054a63          	bltz	a0,80005bc2 <sys_exec+0xfa>
    80005af2:	e3840593          	addi	a1,s0,-456
    80005af6:	4505                	li	a0,1
    80005af8:	ffffd097          	auipc	ra,0xffffd
    80005afc:	f9e080e7          	jalr	-98(ra) # 80002a96 <argaddr>
    80005b00:	0c054163          	bltz	a0,80005bc2 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005b04:	10000613          	li	a2,256
    80005b08:	4581                	li	a1,0
    80005b0a:	e4040513          	addi	a0,s0,-448
    80005b0e:	ffffb097          	auipc	ra,0xffffb
    80005b12:	1b0080e7          	jalr	432(ra) # 80000cbe <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005b16:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005b1a:	89a6                	mv	s3,s1
    80005b1c:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005b1e:	02000a13          	li	s4,32
    80005b22:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005b26:	00391793          	slli	a5,s2,0x3
    80005b2a:	e3040593          	addi	a1,s0,-464
    80005b2e:	e3843503          	ld	a0,-456(s0)
    80005b32:	953e                	add	a0,a0,a5
    80005b34:	ffffd097          	auipc	ra,0xffffd
    80005b38:	ea6080e7          	jalr	-346(ra) # 800029da <fetchaddr>
    80005b3c:	02054a63          	bltz	a0,80005b70 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005b40:	e3043783          	ld	a5,-464(s0)
    80005b44:	c3b9                	beqz	a5,80005b8a <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005b46:	ffffb097          	auipc	ra,0xffffb
    80005b4a:	f8c080e7          	jalr	-116(ra) # 80000ad2 <kalloc>
    80005b4e:	85aa                	mv	a1,a0
    80005b50:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005b54:	cd11                	beqz	a0,80005b70 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005b56:	6605                	lui	a2,0x1
    80005b58:	e3043503          	ld	a0,-464(s0)
    80005b5c:	ffffd097          	auipc	ra,0xffffd
    80005b60:	ed0080e7          	jalr	-304(ra) # 80002a2c <fetchstr>
    80005b64:	00054663          	bltz	a0,80005b70 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005b68:	0905                	addi	s2,s2,1
    80005b6a:	09a1                	addi	s3,s3,8
    80005b6c:	fb491be3          	bne	s2,s4,80005b22 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b70:	10048913          	addi	s2,s1,256
    80005b74:	6088                	ld	a0,0(s1)
    80005b76:	c529                	beqz	a0,80005bc0 <sys_exec+0xf8>
    kfree(argv[i]);
    80005b78:	ffffb097          	auipc	ra,0xffffb
    80005b7c:	e5e080e7          	jalr	-418(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b80:	04a1                	addi	s1,s1,8
    80005b82:	ff2499e3          	bne	s1,s2,80005b74 <sys_exec+0xac>
  return -1;
    80005b86:	597d                	li	s2,-1
    80005b88:	a82d                	j	80005bc2 <sys_exec+0xfa>
      argv[i] = 0;
    80005b8a:	0a8e                	slli	s5,s5,0x3
    80005b8c:	fc040793          	addi	a5,s0,-64
    80005b90:	9abe                	add	s5,s5,a5
    80005b92:	e80ab023          	sd	zero,-384(s5) # ffffffffffffee80 <end+0xffffffff7ffd8e80>
  int ret = exec(path, argv);
    80005b96:	e4040593          	addi	a1,s0,-448
    80005b9a:	f4040513          	addi	a0,s0,-192
    80005b9e:	fffff097          	auipc	ra,0xfffff
    80005ba2:	160080e7          	jalr	352(ra) # 80004cfe <exec>
    80005ba6:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ba8:	10048993          	addi	s3,s1,256
    80005bac:	6088                	ld	a0,0(s1)
    80005bae:	c911                	beqz	a0,80005bc2 <sys_exec+0xfa>
    kfree(argv[i]);
    80005bb0:	ffffb097          	auipc	ra,0xffffb
    80005bb4:	e26080e7          	jalr	-474(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005bb8:	04a1                	addi	s1,s1,8
    80005bba:	ff3499e3          	bne	s1,s3,80005bac <sys_exec+0xe4>
    80005bbe:	a011                	j	80005bc2 <sys_exec+0xfa>
  return -1;
    80005bc0:	597d                	li	s2,-1
}
    80005bc2:	854a                	mv	a0,s2
    80005bc4:	60be                	ld	ra,456(sp)
    80005bc6:	641e                	ld	s0,448(sp)
    80005bc8:	74fa                	ld	s1,440(sp)
    80005bca:	795a                	ld	s2,432(sp)
    80005bcc:	79ba                	ld	s3,424(sp)
    80005bce:	7a1a                	ld	s4,416(sp)
    80005bd0:	6afa                	ld	s5,408(sp)
    80005bd2:	6179                	addi	sp,sp,464
    80005bd4:	8082                	ret

0000000080005bd6 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005bd6:	7139                	addi	sp,sp,-64
    80005bd8:	fc06                	sd	ra,56(sp)
    80005bda:	f822                	sd	s0,48(sp)
    80005bdc:	f426                	sd	s1,40(sp)
    80005bde:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005be0:	ffffc097          	auipc	ra,0xffffc
    80005be4:	de0080e7          	jalr	-544(ra) # 800019c0 <myproc>
    80005be8:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005bea:	fd840593          	addi	a1,s0,-40
    80005bee:	4501                	li	a0,0
    80005bf0:	ffffd097          	auipc	ra,0xffffd
    80005bf4:	ea6080e7          	jalr	-346(ra) # 80002a96 <argaddr>
    return -1;
    80005bf8:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005bfa:	0e054063          	bltz	a0,80005cda <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005bfe:	fc840593          	addi	a1,s0,-56
    80005c02:	fd040513          	addi	a0,s0,-48
    80005c06:	fffff097          	auipc	ra,0xfffff
    80005c0a:	dd6080e7          	jalr	-554(ra) # 800049dc <pipealloc>
    return -1;
    80005c0e:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005c10:	0c054563          	bltz	a0,80005cda <sys_pipe+0x104>
  fd0 = -1;
    80005c14:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005c18:	fd043503          	ld	a0,-48(s0)
    80005c1c:	fffff097          	auipc	ra,0xfffff
    80005c20:	4f6080e7          	jalr	1270(ra) # 80005112 <fdalloc>
    80005c24:	fca42223          	sw	a0,-60(s0)
    80005c28:	08054c63          	bltz	a0,80005cc0 <sys_pipe+0xea>
    80005c2c:	fc843503          	ld	a0,-56(s0)
    80005c30:	fffff097          	auipc	ra,0xfffff
    80005c34:	4e2080e7          	jalr	1250(ra) # 80005112 <fdalloc>
    80005c38:	fca42023          	sw	a0,-64(s0)
    80005c3c:	06054863          	bltz	a0,80005cac <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c40:	4691                	li	a3,4
    80005c42:	fc440613          	addi	a2,s0,-60
    80005c46:	fd843583          	ld	a1,-40(s0)
    80005c4a:	68a8                	ld	a0,80(s1)
    80005c4c:	ffffc097          	auipc	ra,0xffffc
    80005c50:	a34080e7          	jalr	-1484(ra) # 80001680 <copyout>
    80005c54:	02054063          	bltz	a0,80005c74 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005c58:	4691                	li	a3,4
    80005c5a:	fc040613          	addi	a2,s0,-64
    80005c5e:	fd843583          	ld	a1,-40(s0)
    80005c62:	0591                	addi	a1,a1,4
    80005c64:	68a8                	ld	a0,80(s1)
    80005c66:	ffffc097          	auipc	ra,0xffffc
    80005c6a:	a1a080e7          	jalr	-1510(ra) # 80001680 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005c6e:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c70:	06055563          	bgez	a0,80005cda <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005c74:	fc442783          	lw	a5,-60(s0)
    80005c78:	07e9                	addi	a5,a5,26
    80005c7a:	078e                	slli	a5,a5,0x3
    80005c7c:	97a6                	add	a5,a5,s1
    80005c7e:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005c82:	fc042503          	lw	a0,-64(s0)
    80005c86:	0569                	addi	a0,a0,26
    80005c88:	050e                	slli	a0,a0,0x3
    80005c8a:	9526                	add	a0,a0,s1
    80005c8c:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005c90:	fd043503          	ld	a0,-48(s0)
    80005c94:	fffff097          	auipc	ra,0xfffff
    80005c98:	a18080e7          	jalr	-1512(ra) # 800046ac <fileclose>
    fileclose(wf);
    80005c9c:	fc843503          	ld	a0,-56(s0)
    80005ca0:	fffff097          	auipc	ra,0xfffff
    80005ca4:	a0c080e7          	jalr	-1524(ra) # 800046ac <fileclose>
    return -1;
    80005ca8:	57fd                	li	a5,-1
    80005caa:	a805                	j	80005cda <sys_pipe+0x104>
    if(fd0 >= 0)
    80005cac:	fc442783          	lw	a5,-60(s0)
    80005cb0:	0007c863          	bltz	a5,80005cc0 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005cb4:	01a78513          	addi	a0,a5,26
    80005cb8:	050e                	slli	a0,a0,0x3
    80005cba:	9526                	add	a0,a0,s1
    80005cbc:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005cc0:	fd043503          	ld	a0,-48(s0)
    80005cc4:	fffff097          	auipc	ra,0xfffff
    80005cc8:	9e8080e7          	jalr	-1560(ra) # 800046ac <fileclose>
    fileclose(wf);
    80005ccc:	fc843503          	ld	a0,-56(s0)
    80005cd0:	fffff097          	auipc	ra,0xfffff
    80005cd4:	9dc080e7          	jalr	-1572(ra) # 800046ac <fileclose>
    return -1;
    80005cd8:	57fd                	li	a5,-1
}
    80005cda:	853e                	mv	a0,a5
    80005cdc:	70e2                	ld	ra,56(sp)
    80005cde:	7442                	ld	s0,48(sp)
    80005ce0:	74a2                	ld	s1,40(sp)
    80005ce2:	6121                	addi	sp,sp,64
    80005ce4:	8082                	ret

0000000080005ce6 <sys_symlink>:

uint64
sys_symlink(void)
{
    80005ce6:	7169                	addi	sp,sp,-304
    80005ce8:	f606                	sd	ra,296(sp)
    80005cea:	f222                	sd	s0,288(sp)
    80005cec:	ee26                	sd	s1,280(sp)
    80005cee:	1a00                	addi	s0,sp,304
  // TODO: symbolic link
  // You should implement this symlink system call.
  char target[MAXPATH], path[MAXPATH];

  if(argstr(0, target, MAXPATH) < 0 || argstr(1, path, MAXPATH) < 0)
    80005cf0:	08000613          	li	a2,128
    80005cf4:	f6040593          	addi	a1,s0,-160
    80005cf8:	4501                	li	a0,0
    80005cfa:	ffffd097          	auipc	ra,0xffffd
    80005cfe:	dbe080e7          	jalr	-578(ra) # 80002ab8 <argstr>
    return -1;
    80005d02:	57fd                	li	a5,-1
  if(argstr(0, target, MAXPATH) < 0 || argstr(1, path, MAXPATH) < 0)
    80005d04:	08054a63          	bltz	a0,80005d98 <sys_symlink+0xb2>
    80005d08:	08000613          	li	a2,128
    80005d0c:	ee040593          	addi	a1,s0,-288
    80005d10:	4505                	li	a0,1
    80005d12:	ffffd097          	auipc	ra,0xffffd
    80005d16:	da6080e7          	jalr	-602(ra) # 80002ab8 <argstr>
    return -1;
    80005d1a:	57fd                	li	a5,-1
  if(argstr(0, target, MAXPATH) < 0 || argstr(1, path, MAXPATH) < 0)
    80005d1c:	06054e63          	bltz	a0,80005d98 <sys_symlink+0xb2>

  begin_op();
    80005d20:	ffffe097          	auipc	ra,0xffffe
    80005d24:	4c0080e7          	jalr	1216(ra) # 800041e0 <begin_op>
  struct inode *ip = create(path, T_SYMLINK, 0, 0);
    80005d28:	4681                	li	a3,0
    80005d2a:	4601                	li	a2,0
    80005d2c:	4591                	li	a1,4
    80005d2e:	ee040513          	addi	a0,s0,-288
    80005d32:	fffff097          	auipc	ra,0xfffff
    80005d36:	422080e7          	jalr	1058(ra) # 80005154 <create>
    80005d3a:	84aa                	mv	s1,a0
  if(ip == 0){
    80005d3c:	c525                	beqz	a0,80005da4 <sys_symlink+0xbe>
    end_op();
    return -1;
  }

  int len = strlen(target);
    80005d3e:	f6040513          	addi	a0,s0,-160
    80005d42:	ffffb097          	auipc	ra,0xffffb
    80005d46:	100080e7          	jalr	256(ra) # 80000e42 <strlen>
    80005d4a:	eca42e23          	sw	a0,-292(s0)
  writei(ip, 0, (uint64)&len, 0, sizeof(int));
    80005d4e:	4711                	li	a4,4
    80005d50:	4681                	li	a3,0
    80005d52:	edc40613          	addi	a2,s0,-292
    80005d56:	4581                	li	a1,0
    80005d58:	8526                	mv	a0,s1
    80005d5a:	ffffe097          	auipc	ra,0xffffe
    80005d5e:	dc4080e7          	jalr	-572(ra) # 80003b1e <writei>
  writei(ip, 0, (uint64)target, sizeof(int), len + 1);
    80005d62:	edc42703          	lw	a4,-292(s0)
    80005d66:	2705                	addiw	a4,a4,1
    80005d68:	4691                	li	a3,4
    80005d6a:	f6040613          	addi	a2,s0,-160
    80005d6e:	4581                	li	a1,0
    80005d70:	8526                	mv	a0,s1
    80005d72:	ffffe097          	auipc	ra,0xffffe
    80005d76:	dac080e7          	jalr	-596(ra) # 80003b1e <writei>
  iupdate(ip);
    80005d7a:	8526                	mv	a0,s1
    80005d7c:	ffffe097          	auipc	ra,0xffffe
    80005d80:	86a080e7          	jalr	-1942(ra) # 800035e6 <iupdate>
  iunlockput(ip);
    80005d84:	8526                	mv	a0,s1
    80005d86:	ffffe097          	auipc	ra,0xffffe
    80005d8a:	c4e080e7          	jalr	-946(ra) # 800039d4 <iunlockput>

  end_op();
    80005d8e:	ffffe097          	auipc	ra,0xffffe
    80005d92:	4d2080e7          	jalr	1234(ra) # 80004260 <end_op>
  return 0;
    80005d96:	4781                	li	a5,0
}
    80005d98:	853e                	mv	a0,a5
    80005d9a:	70b2                	ld	ra,296(sp)
    80005d9c:	7412                	ld	s0,288(sp)
    80005d9e:	64f2                	ld	s1,280(sp)
    80005da0:	6155                	addi	sp,sp,304
    80005da2:	8082                	ret
    end_op();
    80005da4:	ffffe097          	auipc	ra,0xffffe
    80005da8:	4bc080e7          	jalr	1212(ra) # 80004260 <end_op>
    return -1;
    80005dac:	57fd                	li	a5,-1
    80005dae:	b7ed                	j	80005d98 <sys_symlink+0xb2>

0000000080005db0 <kernelvec>:
    80005db0:	7111                	addi	sp,sp,-256
    80005db2:	e006                	sd	ra,0(sp)
    80005db4:	e40a                	sd	sp,8(sp)
    80005db6:	e80e                	sd	gp,16(sp)
    80005db8:	ec12                	sd	tp,24(sp)
    80005dba:	f016                	sd	t0,32(sp)
    80005dbc:	f41a                	sd	t1,40(sp)
    80005dbe:	f81e                	sd	t2,48(sp)
    80005dc0:	fc22                	sd	s0,56(sp)
    80005dc2:	e0a6                	sd	s1,64(sp)
    80005dc4:	e4aa                	sd	a0,72(sp)
    80005dc6:	e8ae                	sd	a1,80(sp)
    80005dc8:	ecb2                	sd	a2,88(sp)
    80005dca:	f0b6                	sd	a3,96(sp)
    80005dcc:	f4ba                	sd	a4,104(sp)
    80005dce:	f8be                	sd	a5,112(sp)
    80005dd0:	fcc2                	sd	a6,120(sp)
    80005dd2:	e146                	sd	a7,128(sp)
    80005dd4:	e54a                	sd	s2,136(sp)
    80005dd6:	e94e                	sd	s3,144(sp)
    80005dd8:	ed52                	sd	s4,152(sp)
    80005dda:	f156                	sd	s5,160(sp)
    80005ddc:	f55a                	sd	s6,168(sp)
    80005dde:	f95e                	sd	s7,176(sp)
    80005de0:	fd62                	sd	s8,184(sp)
    80005de2:	e1e6                	sd	s9,192(sp)
    80005de4:	e5ea                	sd	s10,200(sp)
    80005de6:	e9ee                	sd	s11,208(sp)
    80005de8:	edf2                	sd	t3,216(sp)
    80005dea:	f1f6                	sd	t4,224(sp)
    80005dec:	f5fa                	sd	t5,232(sp)
    80005dee:	f9fe                	sd	t6,240(sp)
    80005df0:	ab7fc0ef          	jal	ra,800028a6 <kerneltrap>
    80005df4:	6082                	ld	ra,0(sp)
    80005df6:	6122                	ld	sp,8(sp)
    80005df8:	61c2                	ld	gp,16(sp)
    80005dfa:	7282                	ld	t0,32(sp)
    80005dfc:	7322                	ld	t1,40(sp)
    80005dfe:	73c2                	ld	t2,48(sp)
    80005e00:	7462                	ld	s0,56(sp)
    80005e02:	6486                	ld	s1,64(sp)
    80005e04:	6526                	ld	a0,72(sp)
    80005e06:	65c6                	ld	a1,80(sp)
    80005e08:	6666                	ld	a2,88(sp)
    80005e0a:	7686                	ld	a3,96(sp)
    80005e0c:	7726                	ld	a4,104(sp)
    80005e0e:	77c6                	ld	a5,112(sp)
    80005e10:	7866                	ld	a6,120(sp)
    80005e12:	688a                	ld	a7,128(sp)
    80005e14:	692a                	ld	s2,136(sp)
    80005e16:	69ca                	ld	s3,144(sp)
    80005e18:	6a6a                	ld	s4,152(sp)
    80005e1a:	7a8a                	ld	s5,160(sp)
    80005e1c:	7b2a                	ld	s6,168(sp)
    80005e1e:	7bca                	ld	s7,176(sp)
    80005e20:	7c6a                	ld	s8,184(sp)
    80005e22:	6c8e                	ld	s9,192(sp)
    80005e24:	6d2e                	ld	s10,200(sp)
    80005e26:	6dce                	ld	s11,208(sp)
    80005e28:	6e6e                	ld	t3,216(sp)
    80005e2a:	7e8e                	ld	t4,224(sp)
    80005e2c:	7f2e                	ld	t5,232(sp)
    80005e2e:	7fce                	ld	t6,240(sp)
    80005e30:	6111                	addi	sp,sp,256
    80005e32:	10200073          	sret
    80005e36:	00000013          	nop
    80005e3a:	00000013          	nop
    80005e3e:	0001                	nop

0000000080005e40 <timervec>:
    80005e40:	34051573          	csrrw	a0,mscratch,a0
    80005e44:	e10c                	sd	a1,0(a0)
    80005e46:	e510                	sd	a2,8(a0)
    80005e48:	e914                	sd	a3,16(a0)
    80005e4a:	6d0c                	ld	a1,24(a0)
    80005e4c:	7110                	ld	a2,32(a0)
    80005e4e:	6194                	ld	a3,0(a1)
    80005e50:	96b2                	add	a3,a3,a2
    80005e52:	e194                	sd	a3,0(a1)
    80005e54:	4589                	li	a1,2
    80005e56:	14459073          	csrw	sip,a1
    80005e5a:	6914                	ld	a3,16(a0)
    80005e5c:	6510                	ld	a2,8(a0)
    80005e5e:	610c                	ld	a1,0(a0)
    80005e60:	34051573          	csrrw	a0,mscratch,a0
    80005e64:	30200073          	mret
	...

0000000080005e6a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005e6a:	1141                	addi	sp,sp,-16
    80005e6c:	e422                	sd	s0,8(sp)
    80005e6e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005e70:	0c0007b7          	lui	a5,0xc000
    80005e74:	4705                	li	a4,1
    80005e76:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005e78:	c3d8                	sw	a4,4(a5)
}
    80005e7a:	6422                	ld	s0,8(sp)
    80005e7c:	0141                	addi	sp,sp,16
    80005e7e:	8082                	ret

0000000080005e80 <plicinithart>:

void
plicinithart(void)
{
    80005e80:	1141                	addi	sp,sp,-16
    80005e82:	e406                	sd	ra,8(sp)
    80005e84:	e022                	sd	s0,0(sp)
    80005e86:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005e88:	ffffc097          	auipc	ra,0xffffc
    80005e8c:	b0c080e7          	jalr	-1268(ra) # 80001994 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005e90:	0085171b          	slliw	a4,a0,0x8
    80005e94:	0c0027b7          	lui	a5,0xc002
    80005e98:	97ba                	add	a5,a5,a4
    80005e9a:	40200713          	li	a4,1026
    80005e9e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005ea2:	00d5151b          	slliw	a0,a0,0xd
    80005ea6:	0c2017b7          	lui	a5,0xc201
    80005eaa:	953e                	add	a0,a0,a5
    80005eac:	00052023          	sw	zero,0(a0)
}
    80005eb0:	60a2                	ld	ra,8(sp)
    80005eb2:	6402                	ld	s0,0(sp)
    80005eb4:	0141                	addi	sp,sp,16
    80005eb6:	8082                	ret

0000000080005eb8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005eb8:	1141                	addi	sp,sp,-16
    80005eba:	e406                	sd	ra,8(sp)
    80005ebc:	e022                	sd	s0,0(sp)
    80005ebe:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005ec0:	ffffc097          	auipc	ra,0xffffc
    80005ec4:	ad4080e7          	jalr	-1324(ra) # 80001994 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005ec8:	00d5179b          	slliw	a5,a0,0xd
    80005ecc:	0c201537          	lui	a0,0xc201
    80005ed0:	953e                	add	a0,a0,a5
  return irq;
}
    80005ed2:	4148                	lw	a0,4(a0)
    80005ed4:	60a2                	ld	ra,8(sp)
    80005ed6:	6402                	ld	s0,0(sp)
    80005ed8:	0141                	addi	sp,sp,16
    80005eda:	8082                	ret

0000000080005edc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005edc:	1101                	addi	sp,sp,-32
    80005ede:	ec06                	sd	ra,24(sp)
    80005ee0:	e822                	sd	s0,16(sp)
    80005ee2:	e426                	sd	s1,8(sp)
    80005ee4:	1000                	addi	s0,sp,32
    80005ee6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005ee8:	ffffc097          	auipc	ra,0xffffc
    80005eec:	aac080e7          	jalr	-1364(ra) # 80001994 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005ef0:	00d5151b          	slliw	a0,a0,0xd
    80005ef4:	0c2017b7          	lui	a5,0xc201
    80005ef8:	97aa                	add	a5,a5,a0
    80005efa:	c3c4                	sw	s1,4(a5)
}
    80005efc:	60e2                	ld	ra,24(sp)
    80005efe:	6442                	ld	s0,16(sp)
    80005f00:	64a2                	ld	s1,8(sp)
    80005f02:	6105                	addi	sp,sp,32
    80005f04:	8082                	ret

0000000080005f06 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005f06:	1141                	addi	sp,sp,-16
    80005f08:	e406                	sd	ra,8(sp)
    80005f0a:	e022                	sd	s0,0(sp)
    80005f0c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005f0e:	479d                	li	a5,7
    80005f10:	06a7c963          	blt	a5,a0,80005f82 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005f14:	0001d797          	auipc	a5,0x1d
    80005f18:	0ec78793          	addi	a5,a5,236 # 80023000 <disk>
    80005f1c:	00a78733          	add	a4,a5,a0
    80005f20:	6789                	lui	a5,0x2
    80005f22:	97ba                	add	a5,a5,a4
    80005f24:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005f28:	e7ad                	bnez	a5,80005f92 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005f2a:	00451793          	slli	a5,a0,0x4
    80005f2e:	0001f717          	auipc	a4,0x1f
    80005f32:	0d270713          	addi	a4,a4,210 # 80025000 <disk+0x2000>
    80005f36:	6314                	ld	a3,0(a4)
    80005f38:	96be                	add	a3,a3,a5
    80005f3a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005f3e:	6314                	ld	a3,0(a4)
    80005f40:	96be                	add	a3,a3,a5
    80005f42:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005f46:	6314                	ld	a3,0(a4)
    80005f48:	96be                	add	a3,a3,a5
    80005f4a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005f4e:	6318                	ld	a4,0(a4)
    80005f50:	97ba                	add	a5,a5,a4
    80005f52:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005f56:	0001d797          	auipc	a5,0x1d
    80005f5a:	0aa78793          	addi	a5,a5,170 # 80023000 <disk>
    80005f5e:	97aa                	add	a5,a5,a0
    80005f60:	6509                	lui	a0,0x2
    80005f62:	953e                	add	a0,a0,a5
    80005f64:	4785                	li	a5,1
    80005f66:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005f6a:	0001f517          	auipc	a0,0x1f
    80005f6e:	0ae50513          	addi	a0,a0,174 # 80025018 <disk+0x2018>
    80005f72:	ffffc097          	auipc	ra,0xffffc
    80005f76:	29e080e7          	jalr	670(ra) # 80002210 <wakeup>
}
    80005f7a:	60a2                	ld	ra,8(sp)
    80005f7c:	6402                	ld	s0,0(sp)
    80005f7e:	0141                	addi	sp,sp,16
    80005f80:	8082                	ret
    panic("free_desc 1");
    80005f82:	00002517          	auipc	a0,0x2
    80005f86:	7d650513          	addi	a0,a0,2006 # 80008758 <syscalls+0x328>
    80005f8a:	ffffa097          	auipc	ra,0xffffa
    80005f8e:	5a0080e7          	jalr	1440(ra) # 8000052a <panic>
    panic("free_desc 2");
    80005f92:	00002517          	auipc	a0,0x2
    80005f96:	7d650513          	addi	a0,a0,2006 # 80008768 <syscalls+0x338>
    80005f9a:	ffffa097          	auipc	ra,0xffffa
    80005f9e:	590080e7          	jalr	1424(ra) # 8000052a <panic>

0000000080005fa2 <virtio_disk_init>:
{
    80005fa2:	1101                	addi	sp,sp,-32
    80005fa4:	ec06                	sd	ra,24(sp)
    80005fa6:	e822                	sd	s0,16(sp)
    80005fa8:	e426                	sd	s1,8(sp)
    80005faa:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005fac:	00002597          	auipc	a1,0x2
    80005fb0:	7cc58593          	addi	a1,a1,1996 # 80008778 <syscalls+0x348>
    80005fb4:	0001f517          	auipc	a0,0x1f
    80005fb8:	17450513          	addi	a0,a0,372 # 80025128 <disk+0x2128>
    80005fbc:	ffffb097          	auipc	ra,0xffffb
    80005fc0:	b76080e7          	jalr	-1162(ra) # 80000b32 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005fc4:	100017b7          	lui	a5,0x10001
    80005fc8:	4398                	lw	a4,0(a5)
    80005fca:	2701                	sext.w	a4,a4
    80005fcc:	747277b7          	lui	a5,0x74727
    80005fd0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005fd4:	0ef71163          	bne	a4,a5,800060b6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005fd8:	100017b7          	lui	a5,0x10001
    80005fdc:	43dc                	lw	a5,4(a5)
    80005fde:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005fe0:	4705                	li	a4,1
    80005fe2:	0ce79a63          	bne	a5,a4,800060b6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005fe6:	100017b7          	lui	a5,0x10001
    80005fea:	479c                	lw	a5,8(a5)
    80005fec:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005fee:	4709                	li	a4,2
    80005ff0:	0ce79363          	bne	a5,a4,800060b6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005ff4:	100017b7          	lui	a5,0x10001
    80005ff8:	47d8                	lw	a4,12(a5)
    80005ffa:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005ffc:	554d47b7          	lui	a5,0x554d4
    80006000:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006004:	0af71963          	bne	a4,a5,800060b6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006008:	100017b7          	lui	a5,0x10001
    8000600c:	4705                	li	a4,1
    8000600e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006010:	470d                	li	a4,3
    80006012:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006014:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006016:	c7ffe737          	lui	a4,0xc7ffe
    8000601a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    8000601e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006020:	2701                	sext.w	a4,a4
    80006022:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006024:	472d                	li	a4,11
    80006026:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006028:	473d                	li	a4,15
    8000602a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000602c:	6705                	lui	a4,0x1
    8000602e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006030:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006034:	5bdc                	lw	a5,52(a5)
    80006036:	2781                	sext.w	a5,a5
  if(max == 0)
    80006038:	c7d9                	beqz	a5,800060c6 <virtio_disk_init+0x124>
  if(max < NUM)
    8000603a:	471d                	li	a4,7
    8000603c:	08f77d63          	bgeu	a4,a5,800060d6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006040:	100014b7          	lui	s1,0x10001
    80006044:	47a1                	li	a5,8
    80006046:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006048:	6609                	lui	a2,0x2
    8000604a:	4581                	li	a1,0
    8000604c:	0001d517          	auipc	a0,0x1d
    80006050:	fb450513          	addi	a0,a0,-76 # 80023000 <disk>
    80006054:	ffffb097          	auipc	ra,0xffffb
    80006058:	c6a080e7          	jalr	-918(ra) # 80000cbe <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000605c:	0001d717          	auipc	a4,0x1d
    80006060:	fa470713          	addi	a4,a4,-92 # 80023000 <disk>
    80006064:	00c75793          	srli	a5,a4,0xc
    80006068:	2781                	sext.w	a5,a5
    8000606a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000606c:	0001f797          	auipc	a5,0x1f
    80006070:	f9478793          	addi	a5,a5,-108 # 80025000 <disk+0x2000>
    80006074:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006076:	0001d717          	auipc	a4,0x1d
    8000607a:	00a70713          	addi	a4,a4,10 # 80023080 <disk+0x80>
    8000607e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006080:	0001e717          	auipc	a4,0x1e
    80006084:	f8070713          	addi	a4,a4,-128 # 80024000 <disk+0x1000>
    80006088:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000608a:	4705                	li	a4,1
    8000608c:	00e78c23          	sb	a4,24(a5)
    80006090:	00e78ca3          	sb	a4,25(a5)
    80006094:	00e78d23          	sb	a4,26(a5)
    80006098:	00e78da3          	sb	a4,27(a5)
    8000609c:	00e78e23          	sb	a4,28(a5)
    800060a0:	00e78ea3          	sb	a4,29(a5)
    800060a4:	00e78f23          	sb	a4,30(a5)
    800060a8:	00e78fa3          	sb	a4,31(a5)
}
    800060ac:	60e2                	ld	ra,24(sp)
    800060ae:	6442                	ld	s0,16(sp)
    800060b0:	64a2                	ld	s1,8(sp)
    800060b2:	6105                	addi	sp,sp,32
    800060b4:	8082                	ret
    panic("could not find virtio disk");
    800060b6:	00002517          	auipc	a0,0x2
    800060ba:	6d250513          	addi	a0,a0,1746 # 80008788 <syscalls+0x358>
    800060be:	ffffa097          	auipc	ra,0xffffa
    800060c2:	46c080e7          	jalr	1132(ra) # 8000052a <panic>
    panic("virtio disk has no queue 0");
    800060c6:	00002517          	auipc	a0,0x2
    800060ca:	6e250513          	addi	a0,a0,1762 # 800087a8 <syscalls+0x378>
    800060ce:	ffffa097          	auipc	ra,0xffffa
    800060d2:	45c080e7          	jalr	1116(ra) # 8000052a <panic>
    panic("virtio disk max queue too short");
    800060d6:	00002517          	auipc	a0,0x2
    800060da:	6f250513          	addi	a0,a0,1778 # 800087c8 <syscalls+0x398>
    800060de:	ffffa097          	auipc	ra,0xffffa
    800060e2:	44c080e7          	jalr	1100(ra) # 8000052a <panic>

00000000800060e6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800060e6:	7119                	addi	sp,sp,-128
    800060e8:	fc86                	sd	ra,120(sp)
    800060ea:	f8a2                	sd	s0,112(sp)
    800060ec:	f4a6                	sd	s1,104(sp)
    800060ee:	f0ca                	sd	s2,96(sp)
    800060f0:	ecce                	sd	s3,88(sp)
    800060f2:	e8d2                	sd	s4,80(sp)
    800060f4:	e4d6                	sd	s5,72(sp)
    800060f6:	e0da                	sd	s6,64(sp)
    800060f8:	fc5e                	sd	s7,56(sp)
    800060fa:	f862                	sd	s8,48(sp)
    800060fc:	f466                	sd	s9,40(sp)
    800060fe:	f06a                	sd	s10,32(sp)
    80006100:	ec6e                	sd	s11,24(sp)
    80006102:	0100                	addi	s0,sp,128
    80006104:	8aaa                	mv	s5,a0
    80006106:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006108:	00c52c83          	lw	s9,12(a0)
    8000610c:	001c9c9b          	slliw	s9,s9,0x1
    80006110:	1c82                	slli	s9,s9,0x20
    80006112:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006116:	0001f517          	auipc	a0,0x1f
    8000611a:	01250513          	addi	a0,a0,18 # 80025128 <disk+0x2128>
    8000611e:	ffffb097          	auipc	ra,0xffffb
    80006122:	aa4080e7          	jalr	-1372(ra) # 80000bc2 <acquire>
  for(int i = 0; i < 3; i++){
    80006126:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006128:	44a1                	li	s1,8
      disk.free[i] = 0;
    8000612a:	0001dc17          	auipc	s8,0x1d
    8000612e:	ed6c0c13          	addi	s8,s8,-298 # 80023000 <disk>
    80006132:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80006134:	4b0d                	li	s6,3
    80006136:	a0ad                	j	800061a0 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80006138:	00fc0733          	add	a4,s8,a5
    8000613c:	975e                	add	a4,a4,s7
    8000613e:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006142:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006144:	0207c563          	bltz	a5,8000616e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006148:	2905                	addiw	s2,s2,1
    8000614a:	0611                	addi	a2,a2,4
    8000614c:	19690d63          	beq	s2,s6,800062e6 <virtio_disk_rw+0x200>
    idx[i] = alloc_desc();
    80006150:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006152:	0001f717          	auipc	a4,0x1f
    80006156:	ec670713          	addi	a4,a4,-314 # 80025018 <disk+0x2018>
    8000615a:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000615c:	00074683          	lbu	a3,0(a4)
    80006160:	fee1                	bnez	a3,80006138 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006162:	2785                	addiw	a5,a5,1
    80006164:	0705                	addi	a4,a4,1
    80006166:	fe979be3          	bne	a5,s1,8000615c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000616a:	57fd                	li	a5,-1
    8000616c:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    8000616e:	01205d63          	blez	s2,80006188 <virtio_disk_rw+0xa2>
    80006172:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006174:	000a2503          	lw	a0,0(s4)
    80006178:	00000097          	auipc	ra,0x0
    8000617c:	d8e080e7          	jalr	-626(ra) # 80005f06 <free_desc>
      for(int j = 0; j < i; j++)
    80006180:	2d85                	addiw	s11,s11,1
    80006182:	0a11                	addi	s4,s4,4
    80006184:	ffb918e3          	bne	s2,s11,80006174 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006188:	0001f597          	auipc	a1,0x1f
    8000618c:	fa058593          	addi	a1,a1,-96 # 80025128 <disk+0x2128>
    80006190:	0001f517          	auipc	a0,0x1f
    80006194:	e8850513          	addi	a0,a0,-376 # 80025018 <disk+0x2018>
    80006198:	ffffc097          	auipc	ra,0xffffc
    8000619c:	eec080e7          	jalr	-276(ra) # 80002084 <sleep>
  for(int i = 0; i < 3; i++){
    800061a0:	f8040a13          	addi	s4,s0,-128
{
    800061a4:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    800061a6:	894e                	mv	s2,s3
    800061a8:	b765                	j	80006150 <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800061aa:	0001f697          	auipc	a3,0x1f
    800061ae:	e566b683          	ld	a3,-426(a3) # 80025000 <disk+0x2000>
    800061b2:	96ba                	add	a3,a3,a4
    800061b4:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800061b8:	0001d817          	auipc	a6,0x1d
    800061bc:	e4880813          	addi	a6,a6,-440 # 80023000 <disk>
    800061c0:	0001f697          	auipc	a3,0x1f
    800061c4:	e4068693          	addi	a3,a3,-448 # 80025000 <disk+0x2000>
    800061c8:	6290                	ld	a2,0(a3)
    800061ca:	963a                	add	a2,a2,a4
    800061cc:	00c65583          	lhu	a1,12(a2) # 200c <_entry-0x7fffdff4>
    800061d0:	0015e593          	ori	a1,a1,1
    800061d4:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    800061d8:	f8842603          	lw	a2,-120(s0)
    800061dc:	628c                	ld	a1,0(a3)
    800061de:	972e                	add	a4,a4,a1
    800061e0:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800061e4:	20050593          	addi	a1,a0,512
    800061e8:	0592                	slli	a1,a1,0x4
    800061ea:	95c2                	add	a1,a1,a6
    800061ec:	577d                	li	a4,-1
    800061ee:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800061f2:	00461713          	slli	a4,a2,0x4
    800061f6:	6290                	ld	a2,0(a3)
    800061f8:	963a                	add	a2,a2,a4
    800061fa:	03078793          	addi	a5,a5,48
    800061fe:	97c2                	add	a5,a5,a6
    80006200:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    80006202:	629c                	ld	a5,0(a3)
    80006204:	97ba                	add	a5,a5,a4
    80006206:	4605                	li	a2,1
    80006208:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000620a:	629c                	ld	a5,0(a3)
    8000620c:	97ba                	add	a5,a5,a4
    8000620e:	4809                	li	a6,2
    80006210:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006214:	629c                	ld	a5,0(a3)
    80006216:	973e                	add	a4,a4,a5
    80006218:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000621c:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    80006220:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006224:	6698                	ld	a4,8(a3)
    80006226:	00275783          	lhu	a5,2(a4)
    8000622a:	8b9d                	andi	a5,a5,7
    8000622c:	0786                	slli	a5,a5,0x1
    8000622e:	97ba                	add	a5,a5,a4
    80006230:	00a79223          	sh	a0,4(a5)

  __sync_synchronize();
    80006234:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006238:	6698                	ld	a4,8(a3)
    8000623a:	00275783          	lhu	a5,2(a4)
    8000623e:	2785                	addiw	a5,a5,1
    80006240:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006244:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006248:	100017b7          	lui	a5,0x10001
    8000624c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006250:	004aa783          	lw	a5,4(s5)
    80006254:	02c79163          	bne	a5,a2,80006276 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    80006258:	0001f917          	auipc	s2,0x1f
    8000625c:	ed090913          	addi	s2,s2,-304 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006260:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006262:	85ca                	mv	a1,s2
    80006264:	8556                	mv	a0,s5
    80006266:	ffffc097          	auipc	ra,0xffffc
    8000626a:	e1e080e7          	jalr	-482(ra) # 80002084 <sleep>
  while(b->disk == 1) {
    8000626e:	004aa783          	lw	a5,4(s5)
    80006272:	fe9788e3          	beq	a5,s1,80006262 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    80006276:	f8042903          	lw	s2,-128(s0)
    8000627a:	20090793          	addi	a5,s2,512
    8000627e:	00479713          	slli	a4,a5,0x4
    80006282:	0001d797          	auipc	a5,0x1d
    80006286:	d7e78793          	addi	a5,a5,-642 # 80023000 <disk>
    8000628a:	97ba                	add	a5,a5,a4
    8000628c:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006290:	0001f997          	auipc	s3,0x1f
    80006294:	d7098993          	addi	s3,s3,-656 # 80025000 <disk+0x2000>
    80006298:	00491713          	slli	a4,s2,0x4
    8000629c:	0009b783          	ld	a5,0(s3)
    800062a0:	97ba                	add	a5,a5,a4
    800062a2:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800062a6:	854a                	mv	a0,s2
    800062a8:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800062ac:	00000097          	auipc	ra,0x0
    800062b0:	c5a080e7          	jalr	-934(ra) # 80005f06 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800062b4:	8885                	andi	s1,s1,1
    800062b6:	f0ed                	bnez	s1,80006298 <virtio_disk_rw+0x1b2>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800062b8:	0001f517          	auipc	a0,0x1f
    800062bc:	e7050513          	addi	a0,a0,-400 # 80025128 <disk+0x2128>
    800062c0:	ffffb097          	auipc	ra,0xffffb
    800062c4:	9b6080e7          	jalr	-1610(ra) # 80000c76 <release>
}
    800062c8:	70e6                	ld	ra,120(sp)
    800062ca:	7446                	ld	s0,112(sp)
    800062cc:	74a6                	ld	s1,104(sp)
    800062ce:	7906                	ld	s2,96(sp)
    800062d0:	69e6                	ld	s3,88(sp)
    800062d2:	6a46                	ld	s4,80(sp)
    800062d4:	6aa6                	ld	s5,72(sp)
    800062d6:	6b06                	ld	s6,64(sp)
    800062d8:	7be2                	ld	s7,56(sp)
    800062da:	7c42                	ld	s8,48(sp)
    800062dc:	7ca2                	ld	s9,40(sp)
    800062de:	7d02                	ld	s10,32(sp)
    800062e0:	6de2                	ld	s11,24(sp)
    800062e2:	6109                	addi	sp,sp,128
    800062e4:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800062e6:	f8042503          	lw	a0,-128(s0)
    800062ea:	20050793          	addi	a5,a0,512
    800062ee:	0792                	slli	a5,a5,0x4
  if(write)
    800062f0:	0001d817          	auipc	a6,0x1d
    800062f4:	d1080813          	addi	a6,a6,-752 # 80023000 <disk>
    800062f8:	00f80733          	add	a4,a6,a5
    800062fc:	01a036b3          	snez	a3,s10
    80006300:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    80006304:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006308:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    8000630c:	7679                	lui	a2,0xffffe
    8000630e:	963e                	add	a2,a2,a5
    80006310:	0001f697          	auipc	a3,0x1f
    80006314:	cf068693          	addi	a3,a3,-784 # 80025000 <disk+0x2000>
    80006318:	6298                	ld	a4,0(a3)
    8000631a:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000631c:	0a878593          	addi	a1,a5,168
    80006320:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006322:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006324:	6298                	ld	a4,0(a3)
    80006326:	9732                	add	a4,a4,a2
    80006328:	45c1                	li	a1,16
    8000632a:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000632c:	6298                	ld	a4,0(a3)
    8000632e:	9732                	add	a4,a4,a2
    80006330:	4585                	li	a1,1
    80006332:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006336:	f8442703          	lw	a4,-124(s0)
    8000633a:	628c                	ld	a1,0(a3)
    8000633c:	962e                	add	a2,a2,a1
    8000633e:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>
  disk.desc[idx[1]].addr = (uint64) b->data;
    80006342:	0712                	slli	a4,a4,0x4
    80006344:	6290                	ld	a2,0(a3)
    80006346:	963a                	add	a2,a2,a4
    80006348:	058a8593          	addi	a1,s5,88
    8000634c:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    8000634e:	6294                	ld	a3,0(a3)
    80006350:	96ba                	add	a3,a3,a4
    80006352:	40000613          	li	a2,1024
    80006356:	c690                	sw	a2,8(a3)
  if(write)
    80006358:	e40d19e3          	bnez	s10,800061aa <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000635c:	0001f697          	auipc	a3,0x1f
    80006360:	ca46b683          	ld	a3,-860(a3) # 80025000 <disk+0x2000>
    80006364:	96ba                	add	a3,a3,a4
    80006366:	4609                	li	a2,2
    80006368:	00c69623          	sh	a2,12(a3)
    8000636c:	b5b1                	j	800061b8 <virtio_disk_rw+0xd2>

000000008000636e <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000636e:	1101                	addi	sp,sp,-32
    80006370:	ec06                	sd	ra,24(sp)
    80006372:	e822                	sd	s0,16(sp)
    80006374:	e426                	sd	s1,8(sp)
    80006376:	e04a                	sd	s2,0(sp)
    80006378:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000637a:	0001f517          	auipc	a0,0x1f
    8000637e:	dae50513          	addi	a0,a0,-594 # 80025128 <disk+0x2128>
    80006382:	ffffb097          	auipc	ra,0xffffb
    80006386:	840080e7          	jalr	-1984(ra) # 80000bc2 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000638a:	10001737          	lui	a4,0x10001
    8000638e:	533c                	lw	a5,96(a4)
    80006390:	8b8d                	andi	a5,a5,3
    80006392:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006394:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006398:	0001f797          	auipc	a5,0x1f
    8000639c:	c6878793          	addi	a5,a5,-920 # 80025000 <disk+0x2000>
    800063a0:	6b94                	ld	a3,16(a5)
    800063a2:	0207d703          	lhu	a4,32(a5)
    800063a6:	0026d783          	lhu	a5,2(a3)
    800063aa:	06f70163          	beq	a4,a5,8000640c <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800063ae:	0001d917          	auipc	s2,0x1d
    800063b2:	c5290913          	addi	s2,s2,-942 # 80023000 <disk>
    800063b6:	0001f497          	auipc	s1,0x1f
    800063ba:	c4a48493          	addi	s1,s1,-950 # 80025000 <disk+0x2000>
    __sync_synchronize();
    800063be:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800063c2:	6898                	ld	a4,16(s1)
    800063c4:	0204d783          	lhu	a5,32(s1)
    800063c8:	8b9d                	andi	a5,a5,7
    800063ca:	078e                	slli	a5,a5,0x3
    800063cc:	97ba                	add	a5,a5,a4
    800063ce:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800063d0:	20078713          	addi	a4,a5,512
    800063d4:	0712                	slli	a4,a4,0x4
    800063d6:	974a                	add	a4,a4,s2
    800063d8:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800063dc:	e731                	bnez	a4,80006428 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800063de:	20078793          	addi	a5,a5,512
    800063e2:	0792                	slli	a5,a5,0x4
    800063e4:	97ca                	add	a5,a5,s2
    800063e6:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    800063e8:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800063ec:	ffffc097          	auipc	ra,0xffffc
    800063f0:	e24080e7          	jalr	-476(ra) # 80002210 <wakeup>

    disk.used_idx += 1;
    800063f4:	0204d783          	lhu	a5,32(s1)
    800063f8:	2785                	addiw	a5,a5,1
    800063fa:	17c2                	slli	a5,a5,0x30
    800063fc:	93c1                	srli	a5,a5,0x30
    800063fe:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006402:	6898                	ld	a4,16(s1)
    80006404:	00275703          	lhu	a4,2(a4)
    80006408:	faf71be3          	bne	a4,a5,800063be <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000640c:	0001f517          	auipc	a0,0x1f
    80006410:	d1c50513          	addi	a0,a0,-740 # 80025128 <disk+0x2128>
    80006414:	ffffb097          	auipc	ra,0xffffb
    80006418:	862080e7          	jalr	-1950(ra) # 80000c76 <release>
}
    8000641c:	60e2                	ld	ra,24(sp)
    8000641e:	6442                	ld	s0,16(sp)
    80006420:	64a2                	ld	s1,8(sp)
    80006422:	6902                	ld	s2,0(sp)
    80006424:	6105                	addi	sp,sp,32
    80006426:	8082                	ret
      panic("virtio_disk_intr status");
    80006428:	00002517          	auipc	a0,0x2
    8000642c:	3c050513          	addi	a0,a0,960 # 800087e8 <syscalls+0x3b8>
    80006430:	ffffa097          	auipc	ra,0xffffa
    80006434:	0fa080e7          	jalr	250(ra) # 8000052a <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
