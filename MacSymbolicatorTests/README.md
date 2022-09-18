# Testing

For validating the behavior of MacSymbolicator, we need to follow these steps:

1. Create the binaries and the dSYMs of the test project
	- Run `MacSymbolicatorTests/create_binaries_and_dsyms.sh`
	- This script will build the test apps, then move the binaries and dSYMs to their respective folders.
	- This script will also create a `Payload.zip` that we will use later
2. On a second computer, create the crash files, the sample files, and the spindumps
	- Transfer `Payload.zip` to your second computer and extract it
	- Run `create_crashes_samples_spindumps.sh` from the extracted directory (requires sudo to sample/spindump processes)
	- This script will create a `Result.zip` that we will transfer back to the first computer
3. Back on the main computer, extract `Result.zip` into `MacSymbolicatorTests/Resources`
4. Create the "expect output" of symbolication
	- Run `MacSymbolicatorTests/create_expected_output.sh`
	- This script will build `MacSymbolicatorCLI` and use it to symbolicate the reports from the second computer
	- This script will save the symbolicated output files suffixed with `_symbolicated`
5. Manually check that the expected output is symbolicated correctly
6. Run the tests in Xcode, which will symbolicate the reports and compare them to the expected output


### Q&A

- Why is it done this way?
	- So that we don't have include all the binaries, the dSYMs, the samples, and spindumps which are pretty big for git, pollute the history, but also might contain information about my computer that I don't want to share.
- For step 2, why need a second computer?
	- If you use the same computer that created the crashing binary (and dSYM), when macOS creates a crash report for an app it will also automatically symbolicate it. My guess is that dSYMs are indexed by Xcode as soon as they're created.
- For step 5, doesn't manually checking the output defeat the point of automated testing?
	- Yes, but at least the expected output is created automatically which saves a LOT of time.
