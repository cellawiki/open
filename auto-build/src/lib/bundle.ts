import terser from "@rollup/plugin-terser"
import typescript from "@rollup/plugin-typescript"
import chalk from "chalk"
import {generateDtsBundle} from "dts-bundle-generator"
import {writeFileSync} from "node:fs"
import {join} from "node:path"
import {OutputOptions, rollup, RollupBuild, RollupOptions} from "rollup"
import {formatPath} from "./format"

/** Logger code reuse. */
const output = chalk.dim.green("output")

/**
 * Build as a rollup {@link OutputOptions}
 * and {@link log} if necessary.
 */
async function rollupOutput(
  options: OutputOptions,
  bundle: RollupBuild,
  log = true,
): Promise<void> {
  await bundle.write(options)

  if (!log) return
  console.log(`${output} ${formatPath(options.file!, chalk.yellow)}`)
  if (!options.sourcemap) return
  const path = `${options.file}.map`
  console.log(`${output} ${formatPath(path, chalk.dim.yellowBright)}`)
}

/**
 * Build as a {@link RollupOptions} defined,
 * and {@link log} if necessary.
 */
export async function buildRollup(option: RollupOptions, log = true) {
  const bundle = await rollup(option)
  await (Array.isArray(option.output)
    ? Promise.allSettled(option.output.map((o) => rollupOutput(o, bundle, log)))
    : rollupOutput(option.output as OutputOptions, bundle, log))
  return bundle.close()
}

/**
 * Generate a new regular expression of package name.
 * The regex must be refreshed, or the index must be reset.
 * This is a shortcut for generate a new one when necessary.
 */
export const packageNameRegex = () => {
  return new RegExp(
    "^(?:(?:@(?:[a-z0-9-*~][a-z0-9-*._~]*)?/[a-z0-9-._~])|[a-z0-9-~])" +
      "[a-z0-9-._~]*$",
  )
}

/** Parse all dependencies in a "package.json". */
export function parseDependencies(manifest: any): string[] {
  const dependencies = manifest["dependencies"]
  if (!dependencies) return []
  return Object.keys(dependencies).filter((name) =>
    packageNameRegex().test(name),
  )
}

/**
 * @param rootManifest manifest parsed from the current "package.json".
 * @param monorepoManifest manifest parsed from the monorepo's "package.json".
 * @returns what the "external" option in {@link RollupOptions} required.
 */
export function resolveExternal(rootManifest: any, monorepoManifest?: any) {
  const dependencies = parseDependencies(rootManifest)
  if (monorepoManifest) {
    dependencies.push(...parseDependencies(monorepoManifest))
  }
  const names: string[] = []
  for (const name of dependencies) if (!names.includes(name)) names.push(name)
  return (source: string, _: string | undefined, isResolved: boolean) => {
    if (isResolved) return false
    return (
      source.startsWith("node:") ||
      source === "vscode" ||
      names.includes(source)
    )
  }
}

/**
 * Generate library output as the configurations inside "package.json".
 *
 * 1. The "package.json" file should apply the nodenext scheme.
 * 2. You should specify the "src" property inside the "exports" items
 *    to tell where the entrypoint is.
 *
 * Example of "package.json":
 *
 * ```json
 * {
 *   ...
 *   "exports": {
 *     "./name": {
 *       "src": "./src/name.ts",
 *       "types": "./out/name.d.ts",
 *       "import": "./out/name.js",
 *       "require": "./out/name.cjs"
 *     }
 *   }
 *   ...
 * }
 * ```
 *
 * @param root the folder where the "package.json" locates.
 * @param monorepo the folder where the monorepo's "package.json" locates.
 */
export async function buildAsManifest(
  root: string,
  monorepo?: string,
  log = true,
) {
  const manifest = await import(`${root}/package.json`)
  const exports = manifest["export"]
  if (!exports || typeof exports !== "object") {
    throw new Error(`invalid package.json: ${join(root, "package.json")}`)
  }
  const external = await (async function generateExternal() {
    let monorepoManifest: any | undefined = undefined
    if (monorepo) monorepoManifest = await import(`${monorepo}/package.json`)
    return resolveExternal(manifest, monorepoManifest)
  })()

  const tasks: Promise<void>[] = []
  for (const [key, value] of Object.entries(exports)) {
    // Validate values.
    if (typeof value !== "object") continue
    const src = (value as any)["src"]
    if (typeof src !== "string") continue

    // Build libraries.
    const options: OutputOptions[] = []
    const i = (value as any)["import"]
    const r = (value as any)["require"]
    if (i) options.push({file: join(root, i), format: "esm", sourcemap: true})
    if (r) options.push({file: join(root, r), format: "cjs", sourcemap: true})
    const input = join(root, src)
    const plugins = [typescript(), terser()]
    tasks.push(buildRollup({plugins, external, input, output: options}, log))

    // Build declarations.
    const types = (value as any)["types"]
    if (!types) continue
    const task = (async () => {
      const content = generateDtsBundle([{filePath: join(root, src)}])
      const path = join(root, types)
      writeFileSync(path, content[0])
      if (log) console.log(`${output} ${formatPath(path, chalk.blue)}`)
    })()
    tasks.push(task)
  }
  // Reverse to show output earlier, which **seems** smoother.
  await Promise.allSettled(tasks.reverse())
}
