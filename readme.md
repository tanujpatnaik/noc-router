# 2×2 Asynchronous Network-on-Chip (NoC)


A Verilog RTL implementation of a **2×2 asynchronous Network-on-Chip (NoC)** featuring deterministic XY routing, priority + aging arbitration with round-robin tie-breaking, 5×5 crossbar switching, synchronous input buffering, and asynchronous FIFO-based clock-domain crossing between routers.


The design was verified using a self-checking randomized testbench with **4956 injected flits, 4956 received flits, 0 errors, and 0 lost flits**.


---


## Architecture


```text
                         2×2 ASYNCHRONOUS NoC


              clk00                         clk10
                │                             │
        ┌───────▼───────┐             ┌──────▼───────┐
        │      R00      │             │      R10      │
        │    (0,0)      │             │    (1,0)      │
        │               │             │               │
        │  XY Routing   │             │  XY Routing   │
        │ P+A Arbiter   │             │ P+A Arbiter   │
        │ 5×5 Crossbar  │             │ 5×5 Crossbar  │
        │  Sync FIFOs   │             │  Sync FIFOs   │
        └───────┬───────┘             └──────┬────────┘
                │                             │
                │       Async FIFO Links      │
                ├─────────────────────────────┤
                │                             │
        ┌───────▼───────┐             ┌──────▼───────┐
        │      R01      │             │      R11      │
        │    (0,1)      │             │    (1,1)      │
        │               │             │               │
        │  XY Routing   │             │  XY Routing   │
        │ P+A Arbiter   │             │ P+A Arbiter   │
        │ 5×5 Crossbar  │             │ 5×5 Crossbar  │
        │  Sync FIFOs   │             │ Sync FIFOs    │
        └───────────────┘             └───────────────┘

Each router contains:

5 input/output ports: NORTH, SOUTH, EAST, WEST, LOCAL
5 synchronous input FIFOs
5 XY routing units
5 priority + aging arbiters
5×5 crossbar

Inter-router communication uses asynchronous FIFOs for clock-domain crossing.

Features
2×2 mesh NoC
4 independent routers
32-bit flit architecture
5-port routers
Deterministic XY routing
Priority + aging arbitration
Round-robin tie-breaking
Starvation prevention
5×5 crossbar
Synchronous FIFO buffering inside routers
Asynchronous FIFO between routers
Gray-coded CDC pointers
2-FF synchronizers
Independent router clock domains
Ready/valid flow control
Backpressure handling
Show-ahead FIFO operation
Self-checking randomized verification
Flit Format

The NoC uses a 32-bit flit.

31                    28 27      26 25      24 23                    0
┌──────────────────────┬──────────┬──────────┬────────────────────────┐
│       Reserved       │  Dest X  │  Dest Y  │        Payload         │
└──────────────────────┴──────────┴──────────┴────────────────────────┘
Field	Bits	Description
Reserved	[31:28]	Reserved
Destination X	[27:26]	Destination X coordinate
Destination Y	[25:24]	Destination Y coordinate
Payload	[23:0]	User payload

RTL:

wire [1:0] dest_x = flit[27:26];
wire [1:0] dest_y = flit[25:24];
Router Datapath
Input
  │
  ▼
Synchronous FIFO
  │
  ▼
XY Routing
  │
  ▼
Request Generation
  │
  ▼
Priority + Aging Arbitration
  │
  ▼
5×5 Crossbar
  │
  ▼
Output

The FIFO head is inspected before it is popped. This allows the router to determine the destination before committing the transfer.

XY Routing

The router uses deterministic XY routing.

The X dimension is always resolved before the Y dimension.

if destination X > current X
        EAST


else if destination X < current X
        WEST


else if destination Y > current Y
        NORTH


else if destination Y < current Y
        SOUTH


else
        LOCAL

Direction encoding:

bit 0 = NORTH
bit 1 = SOUTH
bit 2 = EAST
bit 3 = WEST
bit 4 = LOCAL

Therefore:

NORTH = 00001
SOUTH = 00010
EAST  = 00100
WEST  = 01000
LOCAL = 10000

For example:

Current Router = (0,0)
Destination    = (1,1)

The packet first resolves the X dimension:

R00 ── EAST ──► R10

and then resolves the Y dimension according to the configured router coordinates.

Request Matrix

Each input produces a one-hot output request:

req_dir[input][output]

The request matrix is reorganized for each output arbiter:

out_req[output][input]

For example:

NORTH → EAST
SOUTH → EAST
LOCAL → LOCAL

results in:

EAST output:
    NORTH + SOUTH requesting


LOCAL output:
    LOCAL requesting

The EAST arbiter selects one of the two requesters.

Priority + Aging Arbitration

Each output has one priority_aging_arbiter.

                 Requests
                    │
                    ▼
             Base Priority
                    │
                    +
                  Age
                    │
                    ▼
          Effective Priority
                    │
                    ▼
          Highest Priority
                    │
                    ▼
        Round-Robin Tie Break
                    │
                    ▼
                  Grant

The effective priority is:

effective_priority = base_priority + age

The effective priority saturates at the maximum representable value.

Aging

When a requester continues waiting:

age = age + 1

When it successfully transfers:

age = 0

When it stops requesting:

age = 0

This provides starvation prevention.

Round-Robin Tie Breaking

If multiple requesters have the same effective priority, round-robin determines the winner.

The round-robin pointer advances only when an actual transfer occurs:

transfer = grant_valid && out_ready;

Therefore, if:

grant_valid = 1
out_ready   = 0

the requester remains blocked and the RR pointer does not advance.

5×5 Crossbar

The router contains a 5×5 crossbar.

                  OUTPUTS


             N    S    E    W    L
             │    │    │    │    │
          ┌──┼────┼────┼────┼────┼──┐
          │  │    │    │    │    │  │
N INPUT ──┤  │    │    │    │    │  │
S INPUT ──┤  │    │    │    │    │  │
E INPUT ──┤  │    │    │    │    │  │
W INPUT ──┤  │    │    │    │    │  │
L INPUT ──┤  │    │    │    │    │  │
          └──┴────┴────┴────┴────┴──┘

Each output receives at most one input because each arbiter generates a one-hot grant.

Flow Control

The design uses valid/ready flow control.

A transfer occurs when:

valid && ready

If:

valid = 1
ready = 0

the transfer is stalled.

This allows backpressure to propagate through the network without losing flits.

FIFO Architecture

Two different FIFO types are intentionally used.

Inside Router
      │
      ▼
Synchronous FIFO


Between Routers
      │
      ▼
Asynchronous FIFO
Synchronous FIFO

The synchronous FIFO operates entirely within one clock domain.

It contains:

Memory
Write pointer
Read pointer
Occupancy counter
Full flag
Empty flag

It uses show-ahead read behavior:

assign data_out = mem[rd_ptr];

Therefore the head flit is visible before it is popped.

This allows the routing logic to inspect the destination fields before removing the flit.

Asynchronous FIFO

The asynchronous FIFO is used only for inter-router links.

It supports:

write clock != read clock

It contains:

Binary write pointer
Binary read pointer
Gray-coded pointers
Two-flop synchronizers
Full detection
Empty detection
Dual-clock operation
Clock-Domain Crossing

Inter-router communication crosses independent clock domains.

       Clock Domain A
            │
            ▼
       ┌─────────┐
       │ Router A│
       └────┬────┘
            │
            ▼
       ┌─────────┐
       │  Async  │
       │   FIFO  │
       │         │
       │ Gray Ptr│
       │  2-FF   │
       └────┬────┘
            │
            ▼
       ┌─────────┐
       │ Router B│
       └─────────┘
            │
       Clock Domain B

The asynchronous FIFO uses Gray-coded pointers and two-stage synchronizers to safely communicate pointer state between clock domains.

Inter-Router Link

noc_link.v is a wrapper around async_fifo.v.

Example:

R00 EAST output
       │
       ▼
   noc_link
       │
       ▼
  Async FIFO
       │
       ▼
R10 WEST input

A bidirectional connection uses two independent asynchronous links:

R00 EAST ──► Async FIFO ──► R10 WEST


R10 WEST ──► Async FIFO ──► R00 EAST

The source and destination routers can operate using independent clocks.

Module Hierarchy
noc_top
│
├── noc_router × 4
│   │
│   ├── sync_fifo × 5
│   ├── xy_routing × 5
│   ├── priority_aging_arbiter × 5
│   └── 5×5 crossbar
│
└── noc_link
    │
    └── async_fifo
RTL Files
File	Function
noc_top.v	Top-level 2×2 NoC
noc_router.v	Five-port router
noc_link.v	Inter-router CDC link
async_fifo.v	Dual-clock asynchronous FIFO
sync_fifo.v	Single-clock FIFO
xy_routing.v	Deterministic XY routing
priority_aging_arbiter.v	Priority + aging arbitration
Verification

A self-checking randomized testbench was used to verify the design.

The testbench checks:

Correct packet delivery
Correct destination
Duplicate flits
Misrouted flits
Lost flits
Total injected flits
Total received flits
Verification Result
==========================================================
 NoC 2x2 mesh self-checking testbench report
 Total injected : 4956
 Total received : 4956
 Errors (unexpected/duplicate/misrouted) : 0
 Lost flits     : 0
 RESULT: PASS
==========================================================
Verification Summary
Metric	Result
Total injected	4956
Total received	4956
Errors	0
Lost flits	0
Result pass
