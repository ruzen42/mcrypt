# TODO: liboqs C shim

## Algorithm support

- Replace the single compile-time `MCRYPT_SIG_ALG` selection with an explicit
  algorithm identifier passed through the C shim API.
- Add support for additional liboqs signature algorithms, starting with the
  algorithms enabled in the project's liboqs build.
- Expose the selected algorithm's canonical name and key/signature sizes so the
  Haskell layer can validate stored keys and signature files.
- Reject unknown or disabled algorithm identifiers with a distinct error code.
- Keep the algorithm list consistent with the algorithms enabled at build time.

## API and resource handling

- Avoid constructing and freeing an `OQS_SIG` object for every size query and
  operation. Use a reusable per-algorithm context or another ownership model
  that is safe for concurrent calls.
- Define and document stable error codes for unavailable algorithms, invalid
  inputs, allocation failures, and cryptographic operation failures.
- Validate pointers and lengths at the shim boundary before calling liboqs.
- Keep the C declarations in `oqs_shim.h` synchronized with the implementation
  and the Haskell FFI declarations.

## Performance

- Measure key generation, signing, verification, and context creation before
  optimizing; record representative results for supported algorithms.
- Remove repeated context creation from hot paths where benchmarks show a
  measurable cost.
- Avoid unnecessary copies and allocations when passing message and key buffers
  between Haskell and liboqs.
- Benchmark optimized builds and available liboqs CPU implementations, while
  preserving a portable fallback.
- Add benchmarks for concurrent workloads to detect contention or unsafe shared
  state in any context cache.
