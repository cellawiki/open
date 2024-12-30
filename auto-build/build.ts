import terser from "@rollup/plugin-terser"
import typescript from "@rollup/plugin-typescript"
import chalk, {ChalkInstance} from "chalk"
import {generateDtsBundle} from "dts-bundle-generator"
import {writeFileSync} from "node:fs"
import {join, parse, sep} from "node:path"
import {OutputOptions, rollup, RollupBuild, RollupOptions} from "rollup"

/** Shortcut of chalk colorization. */
const output = chalk.dim.green("output")

/** Format a path with colors that with dim base and colored name. */
function formatPath(raw: string, color: ChalkInstance) {
  const path = parse(raw)
  const dim = chalk.dim
  return `${dim(path.dir)}${dim(sep)}${color(path.base)}`
}

/**
 * Such formatter will only output in milliseconds or seconds.
 * @param startTimestamp when the time counter started, in ms since epoch.
 * @returns the formatted and colored output.
 */
function formatDuration(startTimestamp: number) {
  const dim = chalk.dim
  const duration = new Date().getTime() - startTimestamp
  if (duration < 1000) return `${chalk.cyan(duration)} ${dim("ms")}`
  const ms = duration % 1000
  const s = (duration - ms) / 1000
  return `${chalk.cyan(s)} ${dim("s")} ${chalk.cyan(ms)} ${dim("ms")}`
}

/**
 * How to externalize a import.
 * This function is defined as a template to be called frequently.
 *
 * @param source name of the source to import.
 * @param _importer this value is ignored, but necessary in parameter table.
 * @param isResolved whether such import is already resolved.
 * @returns whether such import should be externalized.
 */
function external(
  source: string,
  _importer: string | undefined,
  isResolved: boolean,
): boolean {
  if (isResolved) return false
  const libs = ["chalk", "dts-bundle-generator", "rollup", "yaml"]
  return (
    libs.includes(source) ||
    source.startsWith("node:") ||
    source.startsWith("@rollup/")
  )
}

/** Encapsulation of generating a rollup output and its log. */
async function rollupOutput(options: OutputOptions, bundle: RollupBuild) {
  await bundle.write(options)

  // Log to mark where the output file is.
  console.log(`${output} ${formatPath(options.file!, chalk.yellow)}`)
  if (!options.sourcemap) return
  const path = `${options.file}.map`
  console.log(`${output} ${formatPath(path, chalk.dim.yellowBright)}`)
}

/**
 * Build as a {@link RollupOptions} defined.
 * This is an encapsulation of building a rollup bundle as library.
 */
async function buildRollup(options: RollupOptions): Promise<void> {
  const bundle = await rollup(options)
  await (Array.isArray(options.output)
    ? Promise.allSettled(options.output.map((o) => rollupOutput(o, bundle)))
    : rollupOutput(options.output as OutputOptions, bundle))
  return bundle.close()
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
 * @param root where the "package.json" locates.
 */
async function buildAsManifest(root: string): Promise<void> {
  const {exports} = await import(`${root}/package.json`)
  if (!exports || typeof exports !== "object") {
    throw new Error(`invalid package.json: ${join(root, "package.json")}`)
  }
  const tasks: Promise<void>[] = []
  for (const [key, value] of Object.entries(exports)) {
    // Validate values.
    if (typeof value !== "object") continue
    const src = (value as {[k: string]: any})["src"]
    if (typeof src !== "string") continue

    // Build libraries.
    const options: OutputOptions[] = []
    const i = (value as {[k: string]: any})["import"]
    const r = (value as {[k: string]: any})["require"]
    if (i) options.push({file: join(root, i), format: "esm", sourcemap: true})
    if (r) options.push({file: join(root, r), format: "cjs", sourcemap: true})
    const input = join(root, src)
    const plugins = [typescript(), terser()]
    tasks.push(buildRollup({plugins, external, input, output: options}))

    // Build declarations.
    const types = (value as {[k: string]: any})["types"]
    if (!types) continue
    const task = (async () => {
      const content = generateDtsBundle([{filePath: join(root, src)}])
      const path = join(root, types)
      writeFileSync(path, content[0])
      console.log(`${output} ${formatPath(path, chalk.blue)}`)
    })()
    tasks.push(task)
  }
  // Reverse to show output earlier, which **seems** smoother.
  await Promise.allSettled(tasks.reverse())
}

/** Entrypoint. */
async function main() {
  // Setup time counter and init basic info.
  const root = import.meta.dirname
  const counter = new Date().getTime()
  console.log(chalk.blue("generating output..."))

  // Build the output.
  await buildAsManifest(root)

  // Log the counter when finished.
  const duration = formatDuration(counter)
  console.log(`${chalk.green("done")} ${chalk.dim("in")} ${duration}`)
  console.log()
}
main()
