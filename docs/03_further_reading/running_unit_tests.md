Running Unit Tests
==================

If doing any development on Scorched, such as if you want to fork it or contribute patches to it, you will probably want to run the suite of tests that accompany it. The few dependancies required for running the Scorched unit tests are installed either when you install the Scorched gem, or by running `bundle` in the root of the Scorched source tree.

All unit tests have been written using RSpec. To run the tests, `cd` into the root of the Scorched source tree from a terminal, and run `rspec`. Alternatively, you can run `rake spec` which will achieve the same result.