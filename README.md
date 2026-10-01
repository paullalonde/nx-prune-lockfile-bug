# Reproduction: `@nx/js:prune-lockfile` fails to map packages

## Current Behavior

Running `@nx/js:prune-lockfile` on a project in this npm workspace fails
to map a number of packages from the root `package-lock.json`. NX then
falls back to writing the full root lockfile as the "pruned" output and
emits:

```
NX   An error occurred while creating pruned lockfile
...
Original error: Following packages could not be mapped to the NPM lockfile:
- npm:semver@7.8.5
- npm:readable-stream@2.3.8
- npm:isarray@1.0.0
- npm:safe-buffer@5.1.2
- npm:string_decoder@1.1.1
- npm:@opentelemetry/exporter-metrics-otlp-grpc@0.220.0
- npm:@opentelemetry/core@2.9.0
  ... (51 packages total — see "Full error output" below)
    at nestMappedPackages (node_modules/nx/dist/src/plugins/js/lock-file/npm-parser.js:461:15)
    at nestMappedPackages (node_modules/nx/dist/src/plugins/js/lock-file/npm-parser.js:467:9)
    ...
    at mapSnapshots (node_modules/nx/dist/src/plugins/js/lock-file/npm-parser.js:403:9)
    at stringifyNpmLockfile (node_modules/nx/dist/src/plugins/js/lock-file/npm-parser.js:274:28)
    at buildLockFile (node_modules/nx/dist/src/plugins/js/lock-file/lock-file.js:271:58)
    at createPrunedLockfile (node_modules/nx/dist/src/plugins/js/lock-file/lock-file.js:326:29)
    at generatePrunedDeployOutput (node_modules/nx/dist/src/plugins/js/lock-file/lock-file.js:393:41)

NX   The pruned output falls back to the root lockfile
...
`npm ci` in the output will fail; run `npm install` instead.
```

The target reports success but the written `dist/package-lock.json` is a
copy of the root lockfile, not a pruned subset. As the warning says,
`npm ci` in the output directory fails because the lockfile contains
packages that are not in `dist/package.json`.

## Expected Behavior

The pruned `dist/package-lock.json` should contain only the resolved
dependency tree needed for the project's production dependencies, and
`npm ci` in the output directory should succeed.

## Reproduction

1. Install the required version of Node, if necessary:

   ```
   nvm install 22.22.3
   ```

1. Install dependencies from the committed `package-lock.json`:

   ```
   nvm use
   npm ci --no-audit --no-fund --ignore-scripts
   ```

1. The `prune-lockfile` target writes to `projects/backend/dist`,
   so create that directory first (normally this is produced by the
   project's `build` target, which is not needed to reproduce the bug):

   ```
   mkdir -p projects/backend/dist
   ```

1. Run the target:

   ```
   npx nx run backend:prune-lockfile
   ```

   The error output described above is produced.

## Environment

- NX: `23.2.1` (declared in root `package.json`)
- Node: tested with v22.22.3
- npm: tested with 10.x
- OS: macOS (Darwin 25.6.0), but the parser is platform-independent

## About this repro workspace

This is a stripped copy of a real NX monorepo. The project source
(`.ts` / `.js`), build output, `node_modules`, and `.nx` cache have
been removed. Only the files needed to make `nx` resolve the project
graph and read the lockfile are included:

- Root `package.json`, `package-lock.json`, `nx.json`
- `projects/*/package.json` and `projects/*/project.json`

The failing target is defined in
`projects/backend/package.json` under `nx.targets.prune-lockfile`.

Project directory names and `@internal/*` package names in this repro
have been renamed from the originals; the lockfile has been updated to
match. All other content is intact.

## Suspected trigger

The error list contains three distinct groups of packages:

1. **Aliased packages introduced via `isolate-package` → `@pnpm/*`**:
   - `pnpm_lockfile_file_v9@npm:@pnpm/lockfile.fs@1100.2.2`
   - `pnpm_prune_lockfile_v9@npm:@pnpm/prune-lockfile@6.0.0`
   - `js-yaml@npm:@zkochan/js-yaml@0.0.11`
   - Multiple `@pnpm/types` versions (`1101.9.0`, `10.0.0`, `9.4.2`)
   - `@pnpm/constants` (`1101.0.0`, `8.0.0`)

2. **OpenTelemetry packages at version `0.220.0` / `2.9.0`** introduced
   by `@opentelemetry/sdk-node@^0.220.0`:
   - `@opentelemetry/exporter-*`, `@opentelemetry/sdk-*`,
     `@opentelemetry/propagator-*`, etc.

3. **Common transitive packages** (`semver@7.8.5`, `glob@13.0.6`,
   `readable-stream@2.3.8`, `fs-extra@11.4.1`, `strip-json-comments@5.0.3`,
   `split2@4.2.0`, `safe-buffer@5.1.2`, `string_decoder@1.1.1`,
   `isarray@1.0.0`).

The call stack points at `nestMappedPackages` recursing through nested
`node_modules` entries in the npm lockfile. The parser appears to miss
packages that live deeper in the lockfile tree, particularly:

- `npm:` aliased deps (`"pkg": "npm:other@x"`)
- Deep nested duplicates (`node_modules/A/node_modules/B/node_modules/C`)

## Full error output

See [error-output.txt](./error-output.txt) for the complete console
output captured from a reproduction run.
