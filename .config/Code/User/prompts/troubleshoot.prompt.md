---
mode: 'agent'
---
Explicitly show and work through the 3 phase framework to troubleshoot a problem. Don't proceed to #3 until #1 is complete.

1. Reproduce The Problem (Minimally And On Demand)
    - Write and execute a minimal specific test case or a small example to show the issue in its simplistic environment context.
    - The test case should repeatably reproduce the problem, on demand.
    - On execution, the test case should reproduce the issue in under 30 seconds.
1. Instrument And Debug It
    - Enable verbose logging. Use DEBUG or TRACE level logging to get detailed information about the program's execution.
    - On linux, use common linux tools to observe the system. 
    - Use assertions to validate assumptions about the state of the program.
1. Fix It
    - First, state observations and assumptions about the cause of the problem. 
    - Implement a minimal fix.
    - Re-run the test case to verify the fix. Ensure that it resolves the issue and does not introduce new problems.
    - Review code and suggest refactors to improve maintainability. Don't implment them yet.